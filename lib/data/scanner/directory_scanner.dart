import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:pool/pool.dart';

import '../../core/constants.dart';
import '../../core/file_types.dart';
import '../../domain/entities/file_node.dart';
import '../../domain/entities/folder_manage_mode.dart';
import '../../domain/entities/node_kind.dart';
import '../../domain/entities/scan_progress.dart';
import '../../domain/entities/scan_result.dart';
import '../../domain/repositories/workspace_scanner.dart';
import '../../domain/usecases/folder_index_scope.dart';
import 'hidden_entry.dart';
import 'image_dimensions.dart';

/// 순회가 만나 인덱싱으로 넘기는 파일. 경로는 이미 루트 기준으로 정규화되어
/// 있어, 인덱싱 단계는 파일시스템 I/O만 하면 된다.
class _PendingFile {
  const _PendingFile(this.file, this.relativePath);

  final File file;
  final String relativePath;
}

/// dart:io 기반 재귀 디렉토리 스캐너.
class DirectoryScanner implements WorkspaceScanner {
  const DirectoryScanner();

  /// 이동 추적용 부분 해시를 계산할 때 파일 앞에서 읽는 최대 바이트 수.
  /// 큰 파일도 한 번의 짧은 읽기로 끝나도록 상한을 둔다.
  static const int _hashPrefixBytes = 64 * 1024;

  /// 파일 인덱싱 I/O(stat·앞부분 읽기)를 동시에 몇 개까지 띄울지. 하나씩 기다리면
  /// 왕복 지연이 파일 수만큼 그대로 쌓이는데, 그 지연은 계산이 아니라 대기라
  /// 기준은 코어 수가 아니라 **디스크·OS 큐에 얼마나 채워 두느냐**다. 특히 캐시에
  /// 없는 첫 스캔에서 차이가 크다(따라오지 못할 만큼 올리면 이득 없이 다른 I/O만
  /// 굶기므로 상한을 둔다).
  static const int _fileIoConcurrency = 16;

  @override
  Future<ScanResult> scan(
    String workspaceRoot, {
    Map<String, FileNode> priorIndex = const {},
    FolderManageMode rootManageMode = FolderManageMode.managed,
    void Function(ScanProgress progress)? onProgress,
  }) async {
    // 스캔은 화면과 다른 isolate에서 돌린다. 나열·숨김 판정·해시·노드 생성은
    // 저마다 동기 구간을 품고 있어, 화면 isolate에서 돌면 폴더가 클수록 그 시간만큼
    // 프레임이 멈춘다(앱이 멎은 것처럼 보인다). 결과는 순수 데이터라 그대로 건너온다.
    if (onProgress == null) {
      return _runInIsolate(workspaceRoot, priorIndex, rootManageMode, null);
    }

    // 진행 상태를 건네받을 채널. 스캔이 끝나면(성공이든 실패든) 닫는다.
    final updates = ReceivePort();
    updates.listen((message) {
      if (message is ScanProgress) onProgress(message);
    });
    try {
      return await _runInIsolate(
        workspaceRoot,
        priorIndex,
        rootManageMode,
        updates.sendPort,
      );
    } finally {
      // 스캔이 끝나는 순간 보내진 마지막 보고가 아직 큐에 있을 수 있다. 한 번
      // 양보해 받아 둔 뒤 닫아, 최종 집계가 사라지지 않게 한다.
      await Future<void>.delayed(Duration.zero);
      updates.close();
    }
  }

  /// 스캔 본체를 다른 isolate에서 돌린다.
  ///
  /// **[scan]에서 곧바로 `Isolate.run`을 부르면 안 된다.** Dart 클로저는 변수 하나가
  /// 아니라 **스코프의 컨텍스트를 통째로** 붙든다. [scan]의 스코프에는 진행 콜백이
  /// 함께 있고 그 콜백은 화면 상태(위젯 트리·provider)를 붙들고 있어, 같은 스코프에서
  /// 클로저를 만들면 보낼 수 없는 객체가 통째로 딸려가 스캔이 실패한다. 보낼 것만
  /// 인자로 받는 이 자리에서 클로저를 만들어 그 고리를 끊는다.
  static Future<ScanResult> _runInIsolate(
    String workspaceRoot,
    Map<String, FileNode> priorIndex,
    FolderManageMode rootManageMode,
    SendPort? updates,
  ) {
    return Isolate.run(
      () => _scanTree(workspaceRoot, priorIndex, rootManageMode, updates),
    );
  }

  /// 스캔 본체. isolate로 보내는 클로저가 데이터만 담도록 인스턴스에 매이지 않은
  /// static으로 둔다.
  static Future<ScanResult> _scanTree(
    String workspaceRoot,
    Map<String, FileNode> priorIndex,
    FolderManageMode rootManageMode,
    SendPort? updates,
  ) async {
    final nodes = <FileNode>[];
    final nested = <String>[];
    final fileTasks = <Future<FileNode>>[];
    final progress = _ProgressReporter(updates);
    // 파일 I/O 동시 실행 수를 잡아 두는 일꾼. 순회가 파일을 만나는 즉시 여기에
    // 맡기고 기다리지 않으므로, 나열과 파일 읽기가 겹쳐 돌고 파일 노드도 순회
    // 도중에 나온다.
    final pool = Pool(_fileIoConcurrency);
    await _walk(
      dir: Directory(workspaceRoot),
      workspaceRoot: workspaceRoot,
      isRoot: true,
      effectiveMode: rootManageMode,
      storedOverride: null,
      nodes: nodes,
      indexFile: (file) =>
          fileTasks.add(_indexFileTask(pool, file, priorIndex, progress)),
      nestedFiletaggerDirs: nested,
      priorIndex: priorIndex,
      progress: progress,
    );
    // 순회 몫이 끝나는 자리에서 지금까지의 수를 한 번 확정해 보낸다(아직 읽는
    // 중인 파일이 남아 있어도 나열은 여기서 끝난다).
    progress.flush();
    // 결과 순서는 순회가 파일을 만난 순서 그대로다(Future.wait이 입력 순서를 지켜,
    // 인덱싱이 끝나는 차례가 결과에 새지 않는다).
    nodes.addAll(await Future.wait(fileTasks).whenComplete(pool.close));
    // 마지막 집계는 간격에 걸려 빠지기 쉬우므로 끝에서 한 번 더 확정해 보낸다.
    progress.flush();
    return ScanResult(nodes: nodes, nestedFiletaggerDirs: nested);
  }

  /// [dir]을 인덱싱한다. 루트가 아니면 자기 자신을 폴더 노드로 추가(override는
  /// 그대로 보존)하고, effective 모드가 불투명이면 내부(자식 노드·재귀)를 건너뛴다.
  /// override 없는 하위 폴더는 부모의 effective 모드에서 상속한다. 만난 파일은
  /// 그 자리에서 [indexFile]에 넘겨 인덱싱을 띄우되 **기다리지 않고** 순회를
  /// 이어 간다.
  static Future<void> _walk({
    required Directory dir,
    required String workspaceRoot,
    required bool isRoot,
    required FolderManageMode effectiveMode,
    required FolderManageMode? storedOverride,
    required List<FileNode> nodes,
    required void Function(_PendingFile file) indexFile,
    required List<String> nestedFiletaggerDirs,
    required Map<String, FileNode> priorIndex,
    required _ProgressReporter progress,
  }) async {
    final List<FileSystemEntity> entries;
    try {
      entries = await dir.list(followLinks: false).toList();
    } on FileSystemException {
      // 권한이 없거나 읽을 수 없는 디렉토리는 조용히 건너뛴다.
      return;
    }

    // OS 숨김 파일/폴더는 인덱싱·재귀·이동 시그니처에서 모두 제외한다(완전 제외,
    // 하위도 순회하지 않음). 판정은 항목마다 묻지 않고 이 폴더 몫을 한 번에 준비해
    // 조회한다(그 편이 훨씬 싼 이유는 hiddenLookupFor 문서에). 단 .filetagger/는
    // POSIX에선 dot-prefix라 이 필터에 걸리지만 중첩 워크스페이스 병합 후보 탐지에는
    // 필요하므로, 아래 hasNested 판정만은 필터 전 목록(entries)으로 본다.
    final hidden = hiddenLookupFor(dir.path);
    final visible = entries.where((e) => !hidden.isHidden(e)).toList();

    // 루트는 자기 자신을 노드로 만들지 않는다. 진행 표시에서는 빈 경로로 나타낸다.
    final rel = isRoot ? '' : _relativePosix(workspaceRoot, dir.path);
    progress.folderScanned(rel, visible.length);

    if (!isRoot) {
      // 이 폴더가 자체 .filetagger/를 가지면(중첩 워크스페이스) 소유 폴더를 병합
      // 후보로 수집한다. 불투명 폴더라도 직속 자식은 훑으므로 발견된다.
      final hasNested = entries.any(
        (e) => e is Directory && p.basename(e.path) == filetaggerDirName,
      );
      if (hasNested) nestedFiletaggerDirs.add(rel);

      final node = FileNode(
        path: rel,
        kind: NodeKind.directory,
        // 저장값은 명시적 override(null=상속). effective는 저장하지 않고
        // 스캔·표시 시 부모 체인으로 다시 계산한다.
        manageMode: storedOverride,
        // 내용 해시가 없는 폴더의 이동 추적용 시그니처. 내부를 인덱싱하지
        // 않는 불투명 폴더라도 직속 자식 구성만은 담아 이동을 알아본다.
        childSignature: _signatureOf(visible),
        // 시그니처와 같은 목록에서 세므로 불투명 폴더에서도 추가 접근이 없다.
        childFileCount: _fileCountOf(visible),
      );
      nodes.add(node);
      progress.nodeFound(node);
    }
    // 불투명 폴더는 내부를 인덱싱하지 않는다(자식 노드 미추가·미재귀).
    if (effectiveMode == FolderManageMode.opaque) return;

    // **파일을 먼저 넘기고 하위 폴더로 내려간다.** 나열이 폴더를 앞에 두면(이름순
    // 이면 흔하다) 한 덩어리로 훑을 때 이 폴더의 파일이 서브트리를 다 마친 뒤에야
    // 시작되어, 깊은 트리에서는 사실상 순회가 끝나야 첫 파일이 나온다.
    final subdirectories = <Directory>[];
    for (final entity in visible) {
      if (entity is Directory) {
        // .filetagger/는 내부를 스캔하지 않는다. 루트 자신의 것은 조용히 제외하고,
        // 중첩된 것은 위에서 이미 소유 폴더를 병합 후보로 수집했다.
        if (p.basename(entity.path) == filetaggerDirName) continue;
        subdirectories.add(entity);
      } else if (entity is File) {
        indexFile(
          _PendingFile(entity, _relativePosix(workspaceRoot, entity.path)),
        );
      }
    }

    for (final entity in subdirectories) {
      final childRel = _relativePosix(workspaceRoot, entity.path);
      final childOverride = priorIndex[childRel]?.manageMode;
      final childEffective = childOverride ?? inheritedChildMode(effectiveMode);
      await _walk(
        dir: entity,
        workspaceRoot: workspaceRoot,
        isRoot: false,
        effectiveMode: childEffective,
        storedOverride: childOverride,
        nodes: nodes,
        indexFile: indexFile,
        nestedFiletaggerDirs: nestedFiletaggerDirs,
        priorIndex: priorIndex,
        progress: progress,
      );
    }
  }

  /// 파일 하나의 인덱싱을 [pool]에 맡겨 띄운다. 한꺼번에 다 띄우지 않도록 풀이
  /// 동시에 도는 수를 잡아 주고, 하나가 디스크를 기다리는 동안 다음 파일이 그
  /// 자리를 채운다. 부르는 쪽(순회)은 기다리지 않고 곧바로 나아간다.
  static Future<FileNode> _indexFileTask(
    Pool pool,
    _PendingFile file,
    Map<String, FileNode> priorIndex,
    _ProgressReporter progress,
  ) {
    return pool.withResource(() async {
      final node = await _indexFile(file, priorIndex);
      progress.nodeFound(node);
      return node;
    });
  }

  /// 파일 하나를 노드로 만든다. 직전 인덱스와 크기·수정시각이 그대로면 저장된
  /// 해시·이미지 크기를 재사용해 파일을 다시 열어 읽지 않는다. 단 이미지인데 크기가
  /// 아직 없으면(컬럼 신설 직후 등) 한 번은 읽어 채운다. 재사용 못 하면 앞부분을
  /// 읽어 새로 계산한다.
  static Future<FileNode> _indexFile(
    _PendingFile pending,
    Map<String, FileNode> priorIndex,
  ) async {
    final stat = await pending.file.stat();
    final prior = priorIndex[pending.relativePath];
    final isImage = isImagePath(pending.relativePath);
    final unchanged = _isUnchanged(prior, stat);
    final canReuse =
        unchanged &&
        prior!.contentHashPrefix != null &&
        (!isImage || prior.imageDimensions != null);

    String? hash;
    String? dimensions;
    if (canReuse) {
      hash = prior.contentHashPrefix;
      dimensions = prior.imageDimensions;
    } else {
      final bytes = await _readPrefix(pending.file, stat.size);
      if (bytes != null) {
        hash = _contentHash(bytes);
        if (isImage) dimensions = readImageDimensions(bytes);
      }
    }

    return FileNode(
      path: pending.relativePath,
      kind: NodeKind.file,
      size: stat.size,
      modifiedAt: stat.modified,
      contentHashPrefix: hash,
      imageDimensions: dimensions,
    );
  }

  /// 폴더의 직속 자식 구성으로 이동 추적용 시그니처를 만든다. 자식 이름(폴더는
  /// '/' 접미)을 정렬해 해시한다. `.filetagger/`는 제외해 태그 DB 유무에 시그니처가
  /// 흔들리지 않게 한다. 자식이 없으면(빈 폴더) null — 내용으로 구별 불가라 이동
  /// 매칭 대상에서 빠진다.
  static String? _signatureOf(List<FileSystemEntity> entries) {
    final names = <String>[];
    for (final e in entries) {
      final name = p.basename(e.path);
      if (name == filetaggerDirName) continue;
      names.add(e is Directory ? '$name/' : name);
    }
    if (names.isEmpty) return null;
    names.sort();
    return _contentHash(utf8.encode(names.join('\n')));
  }

  /// 폴더가 직속으로 담은 **파일**의 수. 하위 폴더는 세지 않으므로 `.filetagger/`도
  /// 저절로 빠진다(디렉토리라 애초에 후보가 아니다). 시그니처와 달리 자식이 없어도
  /// 0으로 남긴다 — 폴더에는 늘 값이 있어야 이 시스템 태그가 폴더 표식 노릇을 겸한다.
  static int _fileCountOf(List<FileSystemEntity> entries) =>
      entries.whereType<File>().length;

  /// 루트 기준 상대 경로를 플랫폼 무관하게 '/' 구분으로 정규화한다.
  static String _relativePosix(String workspaceRoot, String path) =>
      p.split(p.relative(path, from: workspaceRoot)).join('/');

  /// 직전 인덱스 노드가 같은 파일(크기 일치 + 수정시각이 초 단위로 일치)인지.
  /// 그러면 저장된 해시·이미지 크기를 재사용해 파일을 다시 열어 읽지 않아도 된다.
  ///
  /// 수정시각을 초 단위로 비교하는 이유는 MoveTracker와 같다: 저장된 값은 초
  /// 정밀도(Drift 기본 DateTime 저장)라 새로 stat한 값과 그대로 비교하면 어긋난다.
  static bool _isUnchanged(FileNode? prior, FileStat stat) {
    if (prior == null) return false;
    if (prior.size != stat.size) return false;
    final priorModified = prior.modifiedAt;
    if (priorModified == null) return false;
    return _epochSeconds(priorModified) == _epochSeconds(stat.modified);
  }

  static int _epochSeconds(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

  /// 파일 앞부분을 읽어 돌려준다(이동 추적 해시·이미지 크기 계산의 공통 재료).
  /// 읽지 못하면(권한 등) null을 돌려주며, 그 파일은 해시·크기 대상에서 빠진다.
  static Future<List<int>?> _readPrefix(File file, int size) async {
    final length = size < _hashPrefixBytes ? size : _hashPrefixBytes;
    try {
      final raf = await file.open();
      try {
        return await raf.read(length);
      } finally {
        await raf.close();
      }
    } on FileSystemException {
      return null;
    }
  }

  /// 바이트열의 내용 해시를 16진 문자열로. 이동 추적에서 **같은 크기·수정시각을
  /// 가진 후보들 사이의 내용 판별자**로 쓴다 — 막을 상대가 없어 암호 강도가 필요한
  /// 자리는 아니지만, 해시를 손으로 짜는 대신 표준 구현을 쓴다.
  static String _contentHash(List<int> bytes) => md5.convert(bytes).toString();
}

/// 스캔 진행 상태를 화면 isolate로 보내는 보고기.
///
/// 폴더 하나·파일 하나마다 보내면 보고가 스캔보다 비싸질 수 있어 최소 간격을 두고
/// 보낸다. 진행 표시는 "작업 중"임을 알리는 것이 목적이라 매 건이 다 도착할 필요가
/// 없다. 받을 곳이 없으면(진행 표시를 원하지 않는 호출) 세기만 하고 보내지 않는다.
class _ProgressReporter {
  _ProgressReporter(this._sink);

  /// 보고를 받을 곳. null이면 아무 것도 보내지 않는다.
  final SendPort? _sink;

  /// 마지막 보고 이후 흐른 시간(보고 간격을 재는 기준).
  final Stopwatch _sinceLastReport = Stopwatch()..start();

  /// 마지막으로 노드를 실어 보낸 뒤 흐른 시간.
  final Stopwatch _sinceNodesSent = Stopwatch()..start();

  /// 아직 실어 보내지 않은, 새로 관측한 노드들.
  final List<FileNode> _pendingNodes = [];

  int _entriesSeen = 0;
  int _filesIndexed = 0;
  String _currentPath = '';

  /// 진행 보고를 보내는 최소 간격. 사람이 "멈춘 것 같다"고 느끼기 전에 숫자가
  /// 바뀌면 충분하다.
  static const Duration _reportInterval = Duration(milliseconds: 120);

  /// 관측한 노드를 실어 보내는 최소 간격. 수치와 달리 노드는 받는 쪽에서 저장과
  /// 목록 재계산을 부르므로, 훨씬 성기게 보내야 미리 보여 주려다 도리어 느려지지
  /// 않는다.
  static const Duration _nodeInterval = Duration(milliseconds: 400);

  /// 간격을 기다리지 않고 곧바로 실어 보낼 만큼 쌓인 노드 수. 파일이 빠르게
  /// 쏟아지는 구간에서 한 번에 너무 많이 몰리지 않게 한다.
  static const int _nodeBatchSize = 500;

  /// 폴더 하나를 훑을 때마다 부른다.
  void folderScanned(String relativePath, int entries) {
    _entriesSeen += entries;
    _currentPath = relativePath;
    _reportIfDue();
  }

  /// 노드 하나를 새로 관측할 때마다 부른다(훑다 만난 폴더, 인덱싱을 마친 파일).
  void nodeFound(FileNode node) {
    if (!node.isDirectory) _filesIndexed++;
    _pendingNodes.add(node);
    _reportIfDue();
  }

  /// 간격과 무관하게 지금 상태를 보낸다(단계가 바뀌는 자리에서 쓴다). 쌓인 노드도
  /// 함께 비운다.
  void flush() => _send(withNodes: true);

  void _reportIfDue() {
    if (_sink == null) return;
    if (_sinceLastReport.elapsed < _reportInterval) return;
    _send(withNodes: _nodesAreDue);
  }

  bool get _nodesAreDue =>
      _pendingNodes.length >= _nodeBatchSize ||
      _sinceNodesSent.elapsed >= _nodeInterval;

  void _send({required bool withNodes}) {
    _sinceLastReport.reset();
    var nodes = const <FileNode>[];
    if (withNodes && _pendingNodes.isNotEmpty) {
      nodes = List<FileNode>.of(_pendingNodes);
      _pendingNodes.clear();
      _sinceNodesSent.reset();
    }
    _sink?.send(
      ScanProgress(
        entriesSeen: _entriesSeen,
        filesIndexed: _filesIndexed,
        currentPath: _currentPath,
        newNodes: nodes,
      ),
    );
  }
}
