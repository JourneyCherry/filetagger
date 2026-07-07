import 'package:drift/drift.dart';

import '../../domain/entities/nested_tagger_mode.dart';
import '../../domain/repositories/nested_workspace_repository.dart';
import '../db/app_database.dart';

/// [NestedWorkspaceRepository]의 Drift 구현.
class DriftNestedWorkspaceRepository implements NestedWorkspaceRepository {
  DriftNestedWorkspaceRepository(this._db);

  final AppDatabase _db;

  @override
  Future<Set<String>> decidedPaths() async {
    final rows = await _db.select(_db.nestedWorkspaces).get();
    return {for (final r in rows) r.path};
  }

  @override
  Future<void> record(String childRelPath, NestedTaggerMode mode) async {
    await _db
        .into(_db.nestedWorkspaces)
        .insert(
          NestedWorkspacesCompanion.insert(path: childRelPath, mode: mode),
          onConflict: DoUpdate(
            (_) => NestedWorkspacesCompanion(mode: Value(mode)),
            target: [_db.nestedWorkspaces.path],
          ),
        );
  }

  @override
  Future<void> remove(String childRelPath) async {
    await (_db.delete(
      _db.nestedWorkspaces,
    )..where((t) => t.path.equals(childRelPath))).go();
  }
}
