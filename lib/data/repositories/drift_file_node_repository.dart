import 'package:drift/drift.dart';

import '../../domain/entities/file_node.dart';
import '../../domain/repositories/file_node_repository.dart';
import '../../domain/usecases/move_tracker.dart';
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
    // 경로 기준 upsert 후 사라진 노드를 정리한다. 정리 전에 (1) 태그된 사라진
    // 노드를 내용 시그니처로 새 노드에 자동 재연결하고, (2) 그래도 태그가 남은
    // (자동 재연결 실패) 노드는 삭제 대신 "연결 끊김"으로 보존한다.
    final seenAt = DateTime.now();
    await _db.transaction(() async {
      // 스캔 전 인덱스 스냅샷(이동 추적용).
      final before = await _db.select(_db.fileNodes).get();
      final beforePaths = {for (final r in before) r.path};
      final scannedPaths = {for (final n in scanned) n.path};

      // 같은 경로로 다시 나타난 노드는 upsert가 missingSince를 지워 되살린다.
      for (final node in scanned) {
        await _db.into(_db.fileNodes).insert(
              _toCompanion(node, seenAt),
              onConflict: DoUpdate(
                (_) => _toCompanion(node, seenAt),
                target: [_db.fileNodes.path],
              ),
            );
      }

      final disappeared =
          before.where((r) => !scannedPaths.contains(r.path)).toList();
      if (disappeared.isEmpty) return;

      // 새로 추가된 노드(이번 스캔에서 처음 본 경로). 이게 하나도 없으면 파일이
      // 다른 곳으로 이동한 게 아니라 사용자가 제거한 것으로 판단해, 이번에 새로
      // 사라진 노드는 태그가 있어도 보존하지 않는다(요청 2).
      final appeared =
          scanned.where((n) => !beforePaths.contains(n.path)).toList();

      // 이미 보존(연결 끊김) 중인 노드는 사용자가 재연결/제거하거나 파일이
      // 되돌아올 때까지 항상 유지한다.
      final alreadyMissing = disappeared
          .where((r) => r.missingSince != null)
          .map((r) => r.id)
          .toSet();
      final newlyDisappeared =
          disappeared.where((r) => r.missingSince == null).toList();

      // 새로 사라진 태그 노드를 내용 시그니처로 자동 재연결(옮긴 파일).
      if (appeared.isNotEmpty) {
        await _relinkMoves(newlyDisappeared, appeared);
      }

      // 자동 재연결 후에도 태그가 남은 새로 사라진 노드는, 새 노드가 있을 때만
      // 보존(연결 끊김) 대상으로 삼는다. 새 노드가 없으면 제거로 판단한다.
      final newlyPreserved = appeared.isEmpty
          ? <int>{}
          : await _taggedNodeIds(newlyDisappeared.map((r) => r.id).toList());
      if (newlyPreserved.isNotEmpty) {
        await (_db.update(_db.fileNodes)
              ..where((t) => t.id.isIn(newlyPreserved) & t.missingSince.isNull()))
            .write(FileNodesCompanion(missingSince: Value(seenAt)));
      }

      final preserved = {...alreadyMissing, ...newlyPreserved};
      final toDelete = disappeared
          .map((r) => r.id)
          .where((id) => !preserved.contains(id))
          .toList();
      if (toDelete.isNotEmpty) {
        await (_db.delete(_db.fileNodes)..where((t) => t.id.isIn(toDelete)))
            .go();
      }
    });
  }

  @override
  Future<void> reconnectNode({
    required int missingNodeId,
    required int targetNodeId,
  }) async {
    await _db.transaction(() async {
      // 보존 노드의 태그를 사용자가 고른 원본 노드로 옮기고 보존 노드는 정리.
      await (_db.update(_db.tagAssignments)
            ..where((t) => t.fileNodeId.equals(missingNodeId)))
          .write(TagAssignmentsCompanion(fileNodeId: Value(targetNodeId)));
      await (_db.delete(_db.fileNodes)..where((t) => t.id.equals(missingNodeId)))
          .go();
    });
  }

  @override
  Future<void> removeNode(int nodeId) async {
    // FK(onDelete cascade)로 태그 부여 기록도 함께 정리된다.
    await (_db.delete(_db.fileNodes)..where((t) => t.id.equals(nodeId))).go();
  }

  /// 사라진 태그된 노드를 새로 나타난 동일-내용 노드에 재연결한다. 옛 노드는
  /// 곧 정리(delete)되므로, 그 전에 태그 부여 기록을 새 노드로 옮긴다.
  Future<void> _relinkMoves(
    List<FileNodeRow> candidates,
    List<FileNode> appeared,
  ) async {
    // 재연결은 태그를 잃지 않으려는 것이므로 태그된 노드만 후보로 본다.
    final taggedIds = await _taggedNodeIds(candidates.map((r) => r.id).toList());
    if (taggedIds.isEmpty) return;
    final tagged = candidates
        .where((r) => taggedIds.contains(r.id))
        .map(_toEntity)
        .toList();

    final moves = const MoveTracker().match(tagged, appeared);

    for (final entry in moves.entries) {
      final oldRow = candidates.firstWhere((r) => r.path == entry.key.path);
      final newId = await _idForPath(entry.value.path);
      if (newId == null) continue;
      await (_db.update(_db.tagAssignments)
            ..where((t) => t.fileNodeId.equals(oldRow.id)))
          .write(TagAssignmentsCompanion(fileNodeId: Value(newId)));
    }
  }

  /// 주어진 노드 id들 중 태그가 하나라도 부여된 것들의 id 집합.
  Future<Set<int>> _taggedNodeIds(List<int> nodeIds) async {
    if (nodeIds.isEmpty) return {};
    final query = _db.selectOnly(_db.tagAssignments, distinct: true)
      ..addColumns([_db.tagAssignments.fileNodeId])
      ..where(_db.tagAssignments.fileNodeId.isIn(nodeIds));
    final rows = await query.get();
    return rows
        .map((r) => r.read(_db.tagAssignments.fileNodeId))
        .whereType<int>()
        .toSet();
  }

  /// 경로로 노드 id를 찾는다(방금 upsert된 새 노드의 id 조회용).
  Future<int?> _idForPath(String path) async {
    final row = await (_db.select(_db.fileNodes)
          ..where((t) => t.path.equals(path))
          ..limit(1))
        .getSingleOrNull();
    return row?.id;
  }

  FileNode _toEntity(FileNodeRow row) => FileNode(
        id: row.id,
        path: row.path,
        isDirectory: row.isDirectory,
        size: row.size,
        modifiedAt: row.modifiedAt,
        contentHashPrefix: row.contentHashPrefix,
        missingSince: row.missingSince,
      );

  FileNodesCompanion _toCompanion(FileNode node, DateTime seenAt) =>
      FileNodesCompanion.insert(
        path: node.path,
        isDirectory: node.isDirectory,
        size: Value(node.size),
        modifiedAt: Value(node.modifiedAt),
        contentHashPrefix: Value(node.contentHashPrefix),
        lastSeenAt: seenAt,
        // 스캐너가 만든 노드는 실제 존재하므로 연결 끊김 상태를 항상 해제한다
        // (같은 경로로 되살아난 보존 노드의 missingSince를 upsert가 지운다).
        missingSince: const Value(null),
      );
}
