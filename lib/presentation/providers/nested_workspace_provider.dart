import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/merge/drift_nested_workspace_merger.dart';
import '../../data/repositories/drift_nested_workspace_repository.dart';
import '../../domain/repositories/nested_workspace_merger.dart';
import '../../domain/repositories/nested_workspace_repository.dart';
import '../../domain/usecases/resolve_nested_workspace.dart';
import 'database_provider.dart';
import 'file_node_provider.dart';

/// 현재 워크스페이스 DB에 종속된 중첩 병합 확정 기록 저장소. 열린 폴더가 없으면 null.
final nestedWorkspaceRepositoryProvider =
    Provider<NestedWorkspaceRepository?>((ref) {
      final db = ref.watch(databaseProvider);
      if (db == null) return null;
      return DriftNestedWorkspaceRepository(db);
    });

/// 하위 태거 DB를 현재 워크스페이스로 흡수하는 병합기. 열린 폴더가 없으면 null.
final nestedWorkspaceMergerProvider = Provider<NestedWorkspaceMerger?>((ref) {
  final db = ref.watch(databaseProvider);
  if (db == null) return null;
  return DriftNestedWorkspaceMerger(db);
});

/// 중첩 워크스페이스 결정을 적용하는 유즈케이스. 열린 폴더가 없으면 null.
final resolveNestedWorkspaceProvider = Provider<ResolveNestedWorkspace?>((ref) {
  final files = ref.watch(fileNodeRepositoryProvider);
  final nested = ref.watch(nestedWorkspaceRepositoryProvider);
  final merger = ref.watch(nestedWorkspaceMergerProvider);
  if (files == null || nested == null || merger == null) return null;
  return ResolveNestedWorkspace(files, nested, merger);
});
