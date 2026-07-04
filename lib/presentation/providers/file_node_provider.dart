import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/drift_file_node_repository.dart';
import '../../data/scanner/directory_scanner.dart';
import '../../domain/entities/file_node.dart';
import '../../domain/repositories/file_node_repository.dart';
import '../../domain/repositories/workspace_scanner.dart';
import '../../domain/usecases/scan_workspace.dart';
import 'database_provider.dart';

/// 파일시스템 스캐너. 플랫폼 구현은 data 계층에 있다.
final workspaceScannerProvider = Provider<WorkspaceScanner>(
  (ref) => const DirectoryScanner(),
);

/// 현재 워크스페이스 DB에 종속된 파일 노드 저장소. 열린 폴더가 없으면 null.
final fileNodeRepositoryProvider = Provider<FileNodeRepository?>((ref) {
  final db = ref.watch(databaseProvider);
  if (db == null) return null;
  return DriftFileNodeRepository(db);
});

/// 스캔→저장 오케스트레이션 유즈케이스. 열린 폴더가 없으면 null.
final scanWorkspaceProvider = Provider<ScanWorkspace?>((ref) {
  final repo = ref.watch(fileNodeRepositoryProvider);
  if (repo == null) return null;
  return ScanWorkspace(ref.watch(workspaceScannerProvider), repo);
});

/// 현재 워크스페이스의 인덱싱된 파일/폴더 목록 스트림.
final fileNodesProvider = StreamProvider<List<FileNode>>((ref) {
  final repo = ref.watch(fileNodeRepositoryProvider);
  if (repo == null) return Stream.value(const []);
  return repo.watchAll();
});
