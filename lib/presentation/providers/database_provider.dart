import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import 'workspace_provider.dart';

/// 현재 워크스페이스에 종속된 태그 DB.
///
/// 열린 폴더가 없으면 null. 폴더가 바뀌면 이전 DB를 닫고(새 watch로 재생성)
/// 새 폴더의 `.filetagger/` DB로 다시 연다.
final databaseProvider = Provider<AppDatabase?>((ref) {
  final root = ref.watch(workspaceRootProvider);
  if (root == null) return null;

  final db = AppDatabase.forWorkspace(root);
  ref.onDispose(db.close);
  return db;
});
