import 'package:drift/drift.dart';

import '../../domain/entities/file_node.dart';
import '../../domain/entities/folder_manage_mode.dart';
import '../../domain/repositories/file_node_repository.dart';
import '../../domain/usecases/folder_index_scope.dart';
import '../../domain/usecases/move_tracker.dart';
import '../db/app_database.dart';
import '../fs/node_renamer.dart';

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
  Future<Map<String, FileNode>> indexByPath() async {
    final rows = await _db.select(_db.fileNodes).get();
    return {for (final r in rows) r.path: _toEntity(r)};
  }

  @override
  Future<void> applyScan(
    List<FileNode> scanned, {
    required FolderManageMode rootManageMode,
  }) async {
    // 경로 기준 upsert 후 사라진 노드를 정리한다. 정리 전에 (1) 태그된 사라진
    // 노드를 내용 시그니처로 새 노드에 자동 재연결하고, (2) 그래도 태그가 남은
    // (자동 재연결 실패) 노드는 삭제 대신 "연결 끊김"으로 보존한다. 단 (3) 더 이상
    // 관리되지 않는(범위 밖) 서브트리의 노드는 연결 끊김이라도 보존하지 않고 제거.
    final seenAt = DateTime.now();
    await _db.transaction(() async {
      // 스캔 전 인덱스 스냅샷(이동 추적용).
      final before = await _db.select(_db.fileNodes).get();
      final beforePaths = {for (final r in before) r.path};
      final scannedPaths = {for (final n in scanned) n.path};

      // 같은 경로로 다시 나타난 노드는 upsert가 missingSince를 지워 되살린다.
      for (final node in scanned) {
        await _db
            .into(_db.fileNodes)
            .insert(
              _toCompanion(node, seenAt),
              onConflict: DoUpdate(
                (_) => _toCompanion(node, seenAt),
                target: [_db.fileNodes.path],
              ),
            );
      }

      final disappeared = before
          .where((r) => !scannedPaths.contains(r.path))
          .toList();
      if (disappeared.isEmpty) return;

      // 사라진 노드가 아직 인덱싱 범위 안인지(=부모 폴더가 직속 내용을 인덱싱하는지).
      // 범위 밖(부모가 불투명이 되었거나 함께 사라짐)이면 되살아나거나 재연결될 수
      // 없으므로 연결 끊김이라도 보존하지 않는다.
      final indexing = indexingFolderPaths(scanned, rootManageMode);
      bool inScope(FileNodeRow r) => indexing.contains(parentDirPath(r.path));

      // 새로 추가된 노드(이번 스캔에서 처음 본 경로). 이게 하나도 없으면 파일이
      // 다른 곳으로 이동한 게 아니라 사용자가 제거한 것으로 판단해, 이번에 새로
      // 사라진 노드는 태그가 있어도 보존하지 않는다(요청 2).
      final appeared = scanned
          .where((n) => !beforePaths.contains(n.path))
          .toList();

      // 이미 보존(연결 끊김) 중인 노드는 사용자가 재연결/제거하거나 파일이
      // 되돌아올 때까지 유지하되, 범위를 벗어난 것은 유지하지 않는다.
      final alreadyMissing = disappeared
          .where((r) => r.missingSince != null && inScope(r))
          .map((r) => r.id)
          .toSet();
      // 범위 안에서 새로 사라진 노드만 이동 재연결·보존 대상이다. 범위 밖으로
      // 밀려난 노드는 아래에서 그냥 제거된다.
      final newlyInScope = disappeared
          .where((r) => r.missingSince == null && inScope(r))
          .toList();

      // 새로 사라진 태그 노드를 내용 시그니처로 자동 재연결(옮긴 파일).
      if (appeared.isNotEmpty) {
        await _relinkMoves(newlyInScope, appeared);
      }

      // 자동 재연결 후에도 태그가 남은 새로 사라진 노드는, 새 노드가 있을 때만
      // 보존(연결 끊김) 대상으로 삼는다. 새 노드가 없으면 제거로 판단한다.
      final newlyPreserved = appeared.isEmpty
          ? <int>{}
          : await _taggedNodeIds(newlyInScope.map((r) => r.id).toList());
      if (newlyPreserved.isNotEmpty) {
        await (_db.update(_db.fileNodes)..where(
              (t) => t.id.isIn(newlyPreserved) & t.missingSince.isNull(),
            ))
            .write(FileNodesCompanion(missingSince: Value(seenAt)));
      }

      final preserved = {...alreadyMissing, ...newlyPreserved};
      final toDelete = disappeared
          .map((r) => r.id)
          .where((id) => !preserved.contains(id))
          .toList();
      if (toDelete.isNotEmpty) {
        await (_db.delete(
          _db.fileNodes,
        )..where((t) => t.id.isIn(toDelete))).go();
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
      await (_db.delete(
        _db.fileNodes,
      )..where((t) => t.id.equals(missingNodeId))).go();
    });
  }

  @override
  Future<void> renameNode({
    required String oldPath,
    required String newPath,
  }) async {
    // 인덱스 전체를 훑어 이름 변경에 영향받는 경로(자기 자신 + 폴더면 하위)를
    // 재기록한다. LIKE의 '_'/'%' 오매칭을 피하려 SQL 패턴 대신 순수 헬퍼로 가른다.
    await _db.transaction(() async {
      final rows = await _db.select(_db.fileNodes).get();
      for (final row in rows) {
        final updated = rewriteRenamedPath(row.path, oldPath, newPath);
        if (updated == null || updated == row.path) continue;
        await (_db.update(_db.fileNodes)..where((t) => t.id.equals(row.id)))
            .write(FileNodesCompanion(path: Value(updated)));
      }
    });
  }

  @override
  Future<void> removeNode(int nodeId) async {
    // FK(onDelete cascade)로 태그 부여 기록도 함께 정리된다.
    await (_db.delete(_db.fileNodes)..where((t) => t.id.equals(nodeId))).go();
  }

  @override
  Future<void> setManageMode({
    required int nodeId,
    required FolderManageMode mode,
  }) async {
    // 폴더의 명시적 override만 갱신한다. 범위가 줄어 사라질 하위 노드(및 태그)의
    // 정리는 호출부가 이어서 도는 재스캔이 처리한다(사라진 노드 제거). 범위가
    // 늘면(관리/재귀) 재스캔이 새 하위를 인덱싱한다.
    await (_db.update(_db.fileNodes)
          ..where((t) => t.id.equals(nodeId) & t.isDirectory.equals(true)))
        .write(FileNodesCompanion(manageMode: Value(mode)));
  }

  @override
  Future<void> setManageModeByPath({
    required String path,
    required FolderManageMode mode,
  }) async {
    await (_db.update(_db.fileNodes)
          ..where((t) => t.path.equals(path) & t.isDirectory.equals(true)))
        .write(FileNodesCompanion(manageMode: Value(mode)));
  }

  /// 사라진 태그된 노드를 새로 나타난 동일-내용 노드에 재연결한다. 옛 노드는
  /// 곧 정리(delete)되므로, 그 전에 태그 부여 기록을 새 노드로 옮긴다.
  Future<void> _relinkMoves(
    List<FileNodeRow> candidates,
    List<FileNode> appeared,
  ) async {
    // 재연결은 태그를 잃지 않으려는 것이므로 태그된 노드만 후보로 본다.
    final taggedIds = await _taggedNodeIds(
      candidates.map((r) => r.id).toList(),
    );
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
      // 폴더가 옮겨졌으면 관리 방식을 새 노드로 이관해, 옮긴 뒤에도 같은 방식으로
      // 다뤄지게 한다(관리 폴더는 다음 스캔에서 내부가 다시 인덱싱된다).
      if (oldRow.isDirectory && oldRow.manageMode != null) {
        await (_db.update(_db.fileNodes)..where((t) => t.id.equals(newId)))
            .write(FileNodesCompanion(manageMode: Value(oldRow.manageMode)));
      }
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
    final row =
        await (_db.select(_db.fileNodes)
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
    manageMode: row.manageMode,
    childSignature: row.childSignature,
    imageDimensions: row.imageDimensions,
  );

  FileNodesCompanion _toCompanion(FileNode node, DateTime seenAt) =>
      FileNodesCompanion.insert(
        path: node.path,
        isDirectory: node.isDirectory,
        size: Value(node.size),
        modifiedAt: Value(node.modifiedAt),
        contentHashPrefix: Value(node.contentHashPrefix),
        lastSeenAt: seenAt,
        manageMode: Value(node.manageMode),
        childSignature: Value(node.childSignature),
        imageDimensions: Value(node.imageDimensions),
        // 스캐너가 만든 노드는 실제 존재하므로 연결 끊김 상태를 항상 해제한다
        // (같은 경로로 되살아난 보존 노드의 missingSince를 upsert가 지운다).
        missingSince: const Value(null),
      );
}
