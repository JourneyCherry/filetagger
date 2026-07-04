import 'package:drift/drift.dart';

import '../../domain/entities/file_node.dart';
import '../../domain/repositories/file_node_repository.dart';
import '../db/app_database.dart';

/// [FileNodeRepository]의 Drift 구현. 도메인 엔티티 ↔ 테이블 row를 매핑한다.
class DriftFileNodeRepository implements FileNodeRepository {
  DriftFileNodeRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<FileNode>> watchAll() {
    final query = _db.select(_db.fileNodes)
      ..orderBy([(t) => OrderingTerm(expression: t.path)]);
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<void> applyScan(List<FileNode> scanned) async {
    // 이번 스캔에서 본 노드에 공통 타임스탬프를 찍고, 그보다 오래된(=이번에
    // 관측되지 않은) 노드를 제거해 증분 갱신한다.
    final seenAt = DateTime.now();
    await _db.transaction(() async {
      for (final node in scanned) {
        await _db.into(_db.fileNodes).insert(
              _toCompanion(node, seenAt),
              onConflict: DoUpdate(
                (_) => _toCompanion(node, seenAt),
                target: [_db.fileNodes.path],
              ),
            );
      }
      await (_db.delete(_db.fileNodes)
            ..where((t) => t.lastSeenAt.isSmallerThanValue(seenAt)))
          .go();
    });
  }

  FileNode _toEntity(FileNodeRow row) => FileNode(
        id: row.id,
        path: row.path,
        isDirectory: row.isDirectory,
        size: row.size,
        modifiedAt: row.modifiedAt,
        contentHashPrefix: row.contentHashPrefix,
      );

  FileNodesCompanion _toCompanion(FileNode node, DateTime seenAt) =>
      FileNodesCompanion.insert(
        path: node.path,
        isDirectory: node.isDirectory,
        size: Value(node.size),
        modifiedAt: Value(node.modifiedAt),
        contentHashPrefix: Value(node.contentHashPrefix),
        lastSeenAt: seenAt,
      );
}
