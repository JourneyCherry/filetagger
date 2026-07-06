import 'package:drift/drift.dart';

import '../../domain/entities/assigned_tag.dart';
import '../../domain/entities/tag_assignment.dart';
import '../../domain/entities/tag_definition.dart';
import '../../domain/entities/tag_value_type.dart';
import '../../domain/repositories/tag_repository.dart';
import '../db/app_database.dart';

/// [TagRepository]의 Drift 구현. 도메인 엔티티 ↔ 테이블 row를 매핑한다.
class DriftTagRepository implements TagRepository {
  DriftTagRepository(this._db);

  final AppDatabase _db;

  // ── 태그 정의 ──

  @override
  Stream<List<TagDefinition>> watchDefinitions() {
    final query = _db.select(_db.tagDefinitions)
      ..orderBy([(t) => OrderingTerm(expression: t.name)]);
    return query.watch().map((rows) => rows.map(_toDefinition).toList());
  }

  @override
  Future<TagDefinition> createDefinition({
    required String name,
    required TagValueType valueType,
    int? color,
    required bool allowMultiple,
  }) async {
    final row = await _db
        .into(_db.tagDefinitions)
        .insertReturning(
          TagDefinitionsCompanion.insert(
            name: name,
            valueType: valueType,
            color: Value(color),
            allowMultiple: Value(allowMultiple),
          ),
        );
    return _toDefinition(row);
  }

  @override
  Future<void> updateDefinition(TagDefinition definition) async {
    final id = definition.id;
    if (id == null) return;
    await (_db.update(_db.tagDefinitions)..where((t) => t.id.equals(id))).write(
      TagDefinitionsCompanion(
        name: Value(definition.name),
        valueType: Value(definition.valueType),
        color: Value(definition.color),
        allowMultiple: Value(definition.allowMultiple),
      ),
    );
  }

  @override
  Future<void> deleteDefinition(int id) async {
    await (_db.delete(_db.tagDefinitions)..where((t) => t.id.equals(id))).go();
  }

  // ── 태그 부여 ──

  @override
  Stream<List<AssignedTag>> watchAssignments() {
    final query = _db.select(_db.tagAssignments).join([
      innerJoin(
        _db.tagDefinitions,
        _db.tagDefinitions.id.equalsExp(_db.tagAssignments.tagDefinitionId),
      ),
    ]);
    return query.watch().map((rows) {
      return rows.map((row) {
        return AssignedTag(
          assignment: _toAssignment(row.readTable(_db.tagAssignments)),
          definition: _toDefinition(row.readTable(_db.tagDefinitions)),
        );
      }).toList();
    });
  }

  @override
  Future<void> assignToFiles({
    required List<int> fileNodeIds,
    required int tagDefinitionId,
    String? value,
  }) async {
    if (fileNodeIds.isEmpty) return;
    final def = await (_db.select(
      _db.tagDefinitions,
    )..where((t) => t.id.equals(tagDefinitionId))).getSingleOrNull();
    if (def == null) return;

    await _db.transaction(() async {
      for (final fileNodeId in fileNodeIds) {
        if (def.allowMultiple) {
          await _insertAssignment(fileNodeId, tagDefinitionId, value);
          continue;
        }
        // 1회 제한: 이미 있으면 값만 갱신, 없으면 새로 부여(파일별 upsert).
        final existing =
            await (_db.select(_db.tagAssignments)
                  ..where(
                    (t) =>
                        t.fileNodeId.equals(fileNodeId) &
                        t.tagDefinitionId.equals(tagDefinitionId),
                  )
                  ..limit(1))
                .getSingleOrNull();
        if (existing == null) {
          await _insertAssignment(fileNodeId, tagDefinitionId, value);
        } else {
          await (_db.update(_db.tagAssignments)
                ..where((t) => t.id.equals(existing.id)))
              .write(TagAssignmentsCompanion(value: Value(value)));
        }
      }
    });
  }

  @override
  Future<void> updateAssignmentValue({
    required int assignmentId,
    String? value,
  }) async {
    await (_db.update(_db.tagAssignments)
          ..where((t) => t.id.equals(assignmentId)))
        .write(TagAssignmentsCompanion(value: Value(value)));
  }

  @override
  Future<void> unassign(int assignmentId) async {
    await (_db.delete(
      _db.tagAssignments,
    )..where((t) => t.id.equals(assignmentId))).go();
  }

  @override
  Future<void> unassignFromFiles({
    required List<int> fileNodeIds,
    required int tagDefinitionId,
  }) async {
    if (fileNodeIds.isEmpty) return;
    await (_db.delete(_db.tagAssignments)..where(
          (t) =>
              t.tagDefinitionId.equals(tagDefinitionId) &
              t.fileNodeId.isIn(fileNodeIds),
        ))
        .go();
  }

  Future<void> _insertAssignment(
    int fileNodeId,
    int tagDefinitionId,
    String? value,
  ) {
    return _db
        .into(_db.tagAssignments)
        .insert(
          TagAssignmentsCompanion.insert(
            fileNodeId: fileNodeId,
            tagDefinitionId: tagDefinitionId,
            value: Value(value),
          ),
        );
  }

  TagDefinition _toDefinition(TagDefinitionRow row) => TagDefinition(
    id: row.id,
    name: row.name,
    valueType: row.valueType,
    color: row.color,
    allowMultiple: row.allowMultiple,
  );

  TagAssignment _toAssignment(TagAssignmentRow row) => TagAssignment(
    id: row.id,
    fileNodeId: row.fileNodeId,
    tagDefinitionId: row.tagDefinitionId,
    value: row.value,
  );
}
