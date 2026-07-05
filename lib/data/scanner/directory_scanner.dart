import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/constants.dart';
import '../../domain/entities/file_node.dart';
import '../../domain/entities/scan_result.dart';
import '../../domain/repositories/workspace_scanner.dart';

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
  Future<ScanResult> scan(String workspaceRoot) async {
    final nodes = <FileNode>[];
    final nested = <String>[];
    await _walk(
      dir: Directory(workspaceRoot),
      workspaceRoot: workspaceRoot,
      isRoot: true,
      nodes: nodes,
      nestedFiletaggerDirs: nested,
    );
    return ScanResult(nodes: nodes, nestedFiletaggerDirs: nested);
  }

  Future<void> _walk({
    required Directory dir,
    required String workspaceRoot,
    required bool isRoot,
    required List<FileNode> nodes,
    required List<String> nestedFiletaggerDirs,
  }) async {
    final List<FileSystemEntity> entries;
    try {
      entries = await dir.list(followLinks: false).toList();
    } on FileSystemException {
      // 권한이 없거나 읽을 수 없는 디렉토리는 조용히 건너뛴다.
      return;
    }

    for (final entity in entries) {
      final name = p.basename(entity.path);

      if (entity is Directory) {
        if (name == filetaggerDirName) {
          // 루트 자신의 메타 폴더는 조용히 제외하고, 중첩된 것은 소유
          // 폴더(부모)를 병합 후보로 수집한다. 어느 경우든 내부는 스캔 안 함.
          if (!isRoot) {
            nestedFiletaggerDirs.add(
              _relativePosix(workspaceRoot, p.dirname(entity.path)),
            );
          }
          continue;
        }
        nodes.add(FileNode(
          path: _relativePosix(workspaceRoot, entity.path),
          isDirectory: true,
        ));
        await _walk(
          dir: entity,
          workspaceRoot: workspaceRoot,
          isRoot: false,
          nodes: nodes,
          nestedFiletaggerDirs: nestedFiletaggerDirs,
        );
      } else if (entity is File) {
        final stat = await entity.stat();
        nodes.add(FileNode(
          path: _relativePosix(workspaceRoot, entity.path),
          isDirectory: false,
          size: stat.size,
          modifiedAt: stat.modified,
          contentHashPrefix: await _hashPrefix(entity, stat.size),
        ));
      }
    }
  }

  /// 루트 기준 상대 경로를 플랫폼 무관하게 '/' 구분으로 정규화한다.
  String _relativePosix(String workspaceRoot, String path) =>
      p.split(p.relative(path, from: workspaceRoot)).join('/');

  /// 파일 앞부분을 읽어 이동 추적용 부분 해시를 계산한다. 읽지 못하면(권한 등)
  /// null을 돌려주며, 그 파일은 이동 추적 대상에서만 빠진다.
  Future<String?> _hashPrefix(File file, int size) async {
    final length = size < _hashPrefixBytes ? size : _hashPrefixBytes;
    try {
      final raf = await file.open();
      try {
        final bytes = await raf.read(length);
        return _fnv1a(bytes);
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
