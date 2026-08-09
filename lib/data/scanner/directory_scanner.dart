import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:pool/pool.dart';

import '../../core/constants.dart';
import '../../core/file_types.dart';
import '../../domain/entities/file_node.dart';
import '../../domain/entities/folder_manage_mode.dart';
import '../../domain/entities/node_kind.dart';
import '../../domain/entities/scan_result.dart';
import '../../domain/repositories/workspace_scanner.dart';
import '../../domain/usecases/folder_index_scope.dart';
import 'hidden_entry.dart';
import 'image_dimensions.dart';

/// 순회가 찾아 두었으나 아직 열어 보지 않은 파일. 경로는 이미 루트 기준으로
/// 정규화되어 있어, 인덱싱 단계는 파일시스템 I/O만 하면 된다.
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
  }) async {
    final nodes = <FileNode>[];
    final nested = <String>[];
    final files = <_PendingFile>[];
    await _walk(
      dir: Directory(workspaceRoot),
      workspaceRoot: workspaceRoot,
      isRoot: true,
      effectiveMode: rootManageMode,
      storedOverride: null,
      nodes: nodes,
      pendingFiles: files,
      nestedFiletaggerDirs: nested,
      priorIndex: priorIndex,
    );
    // 순회는 폴더 관리 방식을 부모에서 물려받아야 해 순서를 지켜야 하지만, 파일
    // 인덱싱은 서로 독립이라 순회가 끝난 뒤 한꺼번에 동시에 돌린다.
    nodes.addAll(await _indexFiles(files, priorIndex));
    return ScanResult(nodes: nodes, nestedFiletaggerDirs: nested);
  }

  /// [dir]을 인덱싱한다. 루트가 아니면 자기 자신을 폴더 노드로 추가(override는
  /// 그대로 보존)하고, effective 모드가 불투명이면 내부(자식 노드·재귀)를 건너뛴다.
  /// override 없는 하위 폴더는 부모의 effective 모드에서 상속한다. 만난 파일은
  /// 여기서 열지 않고 [pendingFiles]에 모아 두었다가 나중에 함께 인덱싱한다.
  Future<void> _walk({
    required Directory dir,
    required String workspaceRoot,
    required bool isRoot,
    required FolderManageMode effectiveMode,
    required FolderManageMode? storedOverride,
    required List<FileNode> nodes,
    required List<_PendingFile> pendingFiles,
    required List<String> nestedFiletaggerDirs,
    required Map<String, FileNode> priorIndex,
  }) async {
    final List<FileSystemEntity> entries;
    try {
      entries = await dir.list(followLinks: false).toList();
    } on FileSystemException {
      // 권한이 없거나 읽을 수 없는 디렉토리는 조용히 건너뛴다.
      return;
    }

    // OS 숨김 파일/폴더는 인덱싱·재귀·이동 시그니처에서 모두 제외한다(완전 제외,
    // 하위도 순회하지 않음). 단 .filetagger/는 POSIX에선 dot-prefix라 이 필터에
    // 걸리지만 중첩 워크스페이스 병합 후보 탐지에는 필요하므로, 아래 hasNested
    // 판정만은 필터 전 목록(entries)으로 본다.
    final visible = entries.where((e) => !isHiddenEntry(e)).toList();

    if (!isRoot) {
      final rel = _relativePosix(workspaceRoot, dir.path);
      // 이 폴더가 자체 .filetagger/를 가지면(중첩 워크스페이스) 소유 폴더를 병합
      // 후보로 수집한다. 불투명 폴더라도 직속 자식은 훑으므로 발견된다.
      final hasNested = entries.any(
        (e) => e is Directory && p.basename(e.path) == filetaggerDirName,
      );
      if (hasNested) nestedFiletaggerDirs.add(rel);

      nodes.add(
        FileNode(
          path: rel,
          kind: NodeKind.directory,
          // 저장값은 명시적 override(null=상속). effective는 저장하지 않고
          // 스캔·표시 시 부모 체인으로 다시 계산한다.
          manageMode: storedOverride,
          // 내용 해시가 없는 폴더의 이동 추적용 시그니처. 내부를 인덱싱하지
          // 않는 불투명 폴더라도 직속 자식 구성만은 담아 이동을 알아본다.
          childSignature: _signatureOf(visible),
        ),
      );
    }
    // 불투명 폴더는 내부를 인덱싱하지 않는다(자식 노드 미추가·미재귀).
    if (effectiveMode == FolderManageMode.opaque) return;

    for (final entity in visible) {
      final name = p.basename(entity.path);

      if (entity is Directory) {
        // .filetagger/는 내부를 스캔하지 않는다. 루트 자신의 것은 조용히 제외하고,
        // 중첩된 것은 위에서 이미 소유 폴더를 병합 후보로 수집했다.
        if (name == filetaggerDirName) continue;
        final childRel = _relativePosix(workspaceRoot, entity.path);
        final childOverride = priorIndex[childRel]?.manageMode;
        final childEffective =
            childOverride ?? inheritedChildMode(effectiveMode);
        await _walk(
          dir: entity,
          workspaceRoot: workspaceRoot,
          isRoot: false,
          effectiveMode: childEffective,
          storedOverride: childOverride,
          nodes: nodes,
          pendingFiles: pendingFiles,
          nestedFiletaggerDirs: nestedFiletaggerDirs,
          priorIndex: priorIndex,
        );
      } else if (entity is File) {
        pendingFiles.add(
          _PendingFile(entity, _relativePosix(workspaceRoot, entity.path)),
        );
      }
    }
  }

  /// 모아 둔 파일들을 노드로 만든다. 한꺼번에 다 띄우지 않도록 [Pool]이 동시에
  /// 도는 수를 잡아 주고, 하나가 디스크를 기다리는 동안 다음 파일이 그 자리를
  /// 채운다. 결과 순서는 입력 순서 그대로다.
  Future<List<FileNode>> _indexFiles(
    List<_PendingFile> pending,
    Map<String, FileNode> priorIndex,
  ) {
    final pool = Pool(_fileIoConcurrency);
    return Future.wait<FileNode>([
      for (final file in pending)
        pool.withResource(() => _indexFile(file, priorIndex)),
    ]).whenComplete(pool.close);
  }

  /// 파일 하나를 노드로 만든다. 직전 인덱스와 크기·수정시각이 그대로면 저장된
  /// 해시·이미지 크기를 재사용해 파일을 다시 열어 읽지 않는다. 단 이미지인데 크기가
  /// 아직 없으면(컬럼 신설 직후 등) 한 번은 읽어 채운다. 재사용 못 하면 앞부분을
  /// 읽어 새로 계산한다.
  Future<FileNode> _indexFile(
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
  String? _signatureOf(List<FileSystemEntity> entries) {
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

  /// 루트 기준 상대 경로를 플랫폼 무관하게 '/' 구분으로 정규화한다.
  String _relativePosix(String workspaceRoot, String path) =>
      p.split(p.relative(path, from: workspaceRoot)).join('/');

  /// 직전 인덱스 노드가 같은 파일(크기 일치 + 수정시각이 초 단위로 일치)인지.
  /// 그러면 저장된 해시·이미지 크기를 재사용해 파일을 다시 열어 읽지 않아도 된다.
  ///
  /// 수정시각을 초 단위로 비교하는 이유는 MoveTracker와 같다: 저장된 값은 초
  /// 정밀도(Drift 기본 DateTime 저장)라 새로 stat한 값과 그대로 비교하면 어긋난다.
  bool _isUnchanged(FileNode? prior, FileStat stat) {
    if (prior == null) return false;
    if (prior.size != stat.size) return false;
    final priorModified = prior.modifiedAt;
    if (priorModified == null) return false;
    return _epochSeconds(priorModified) == _epochSeconds(stat.modified);
  }

  int _epochSeconds(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

  /// 파일 앞부분을 읽어 돌려준다(이동 추적 해시·이미지 크기 계산의 공통 재료).
  /// 읽지 못하면(권한 등) null을 돌려주며, 그 파일은 해시·크기 대상에서 빠진다.
  Future<List<int>?> _readPrefix(File file, int size) async {
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
  String _contentHash(List<int> bytes) => md5.convert(bytes).toString();
}
