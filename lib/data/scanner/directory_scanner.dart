import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/constants.dart';
import '../../core/file_types.dart';
import '../../domain/entities/file_node.dart';
import '../../domain/entities/folder_manage_mode.dart';
import '../../domain/entities/scan_result.dart';
import '../../domain/repositories/workspace_scanner.dart';
import '../../domain/usecases/folder_index_scope.dart';
import 'hidden_entry.dart';
import 'image_dimensions.dart';

/// dart:io 기반 재귀 디렉토리 스캐너.
class DirectoryScanner implements WorkspaceScanner {
  const DirectoryScanner();

  /// 이동 추적용 부분 해시를 계산할 때 파일 앞에서 읽는 최대 바이트 수.
  /// 큰 파일도 한 번의 짧은 읽기로 끝나도록 상한을 둔다.
  static const int _hashPrefixBytes = 64 * 1024;

  /// FNV-1a(32비트) 상수. 암호학적 강도는 필요 없고, 같은 크기·수정시각을 가진
  /// 후보들 사이에서 내용을 가려내기 위한 비암호 해시다.
  static const int _fnvOffset = 0x811c9dc5;
  static const int _fnvPrime = 0x01000193;
  static const int _mask32 = 0xffffffff;

  @override
  Future<ScanResult> scan(
    String workspaceRoot, {
    Map<String, FileNode> priorIndex = const {},
    FolderManageMode rootManageMode = FolderManageMode.managed,
  }) async {
    final nodes = <FileNode>[];
    final nested = <String>[];
    await _walk(
      dir: Directory(workspaceRoot),
      workspaceRoot: workspaceRoot,
      isRoot: true,
      effectiveMode: rootManageMode,
      storedOverride: null,
      nodes: nodes,
      nestedFiletaggerDirs: nested,
      priorIndex: priorIndex,
    );
    return ScanResult(nodes: nodes, nestedFiletaggerDirs: nested);
  }

  /// [dir]을 인덱싱한다. 루트가 아니면 자기 자신을 폴더 노드로 추가(override는
  /// 그대로 보존)하고, effective 모드가 불투명이면 내부(자식 노드·재귀)를 건너뛴다.
  /// override 없는 하위 폴더는 부모의 effective 모드에서 상속한다.
  Future<void> _walk({
    required Directory dir,
    required String workspaceRoot,
    required bool isRoot,
    required FolderManageMode effectiveMode,
    required FolderManageMode? storedOverride,
    required List<FileNode> nodes,
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
          isDirectory: true,
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
          nestedFiletaggerDirs: nestedFiletaggerDirs,
          priorIndex: priorIndex,
        );
      } else if (entity is File) {
        final relativePath = _relativePosix(workspaceRoot, entity.path);
        final stat = await entity.stat();
        final prior = priorIndex[relativePath];
        final isImage = isImagePath(relativePath);
        // 직전 인덱스와 크기·수정시각이 그대로면 저장된 해시·이미지 크기를 재사용해
        // 파일을 다시 열어 읽지 않는다. 단 이미지인데 크기가 아직 없으면(컬럼 신설
        // 직후 등) 한 번은 읽어 채운다. 재사용 못 하면 앞부분을 읽어 새로 계산한다.
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
          final bytes = await _readPrefix(entity, stat.size);
          if (bytes != null) {
            hash = _fnv1a(bytes);
            if (isImage) dimensions = readImageDimensions(bytes);
          }
        }

        nodes.add(
          FileNode(
            path: relativePath,
            isDirectory: false,
            size: stat.size,
            modifiedAt: stat.modified,
            contentHashPrefix: hash,
            imageDimensions: dimensions,
          ),
        );
      }
    }
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
    return _fnv1a(utf8.encode(names.join('\n')));
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

  /// 바이트열의 FNV-1a(32비트) 해시를 16진 문자열로 반환한다.
  String _fnv1a(List<int> bytes) {
    var hash = _fnvOffset;
    for (final byte in bytes) {
      hash = (hash ^ byte) & _mask32;
      hash = (hash * _fnvPrime) & _mask32;
    }
    return hash.toRadixString(16);
  }
}
