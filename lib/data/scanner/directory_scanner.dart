import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/constants.dart';
import '../../domain/entities/file_node.dart';
import '../../domain/entities/scan_result.dart';
import '../../domain/repositories/workspace_scanner.dart';

/// dart:io 기반 재귀 디렉토리 스캐너.
class DirectoryScanner implements WorkspaceScanner {
  const DirectoryScanner();

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
        ));
      }
    }
  }

  /// 루트 기준 상대 경로를 플랫폼 무관하게 '/' 구분으로 정규화한다.
  String _relativePosix(String workspaceRoot, String path) =>
      p.split(p.relative(path, from: workspaceRoot)).join('/');
}
