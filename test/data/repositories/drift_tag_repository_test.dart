import 'package:drift/native.dart';
import 'package:filetagger/data/db/app_database.dart';
import 'package:filetagger/data/repositories/drift_tag_repository.dart';
import 'package:filetagger/domain/entities/node_kind.dart';
import 'package:filetagger/domain/entities/system_tag.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftTagRepository tags;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    tags = DriftTagRepository(db);
  });

  tearDown(() async => db.close());

  /// 부여를 걸 파일 노드 하나.
  Future<int> insertNode() => db
      .into(db.fileNodes)
      .insert(
        FileNodesCompanion.insert(
          path: '신작/01.png',
          kind: NodeKind.file,
          lastSeenAt: DateTime.now(),
        ),
      );

  group('가리키는 곳이 없는 부여 걷어내기', () {
    test('정의 없는 태그를 가리키는 부여만 지운다', () async {
      final node = await insertNode();
      final definition = await tags.createDefinition(
        name: '작가',
        valueType: TagValueType.text,
        allowMultiple: false,
      );
      await tags.assignToFiles(
        fileNodeIds: [node],
        tagDefinitionId: definition.id!,
        value: '홍길동',
      );
      // 외래키를 끈 채 쓰인 적이 있는 DB의 모습을 그대로 만든다 — 켜 두면 애초에
      // 들어가지 않으므로, 지울 것이 생기는 자리를 재현할 길이 이것뿐이다.
      await db.customStatement('PRAGMA foreign_keys = OFF');
      await db
          .into(db.tagAssignments)
          .insert(
            TagAssignmentsCompanion.insert(
              fileNodeId: node,
              // 시스템 태그의 id는 정의 행을 갖지 않는다.
              tagDefinitionId: SystemTag.fileName.id,
            ),
          );
      await db.customStatement('PRAGMA foreign_keys = ON');

      expect(await tags.deleteDanglingAssignments(), 1);

      final left = await tags.assignmentsOfFile(node);
      expect(left, hasLength(1));
      expect(left.single.tagDefinitionId, definition.id);
    });

    test('성한 DB에서는 지울 것이 없다', () async {
      final node = await insertNode();
      final definition = await tags.createDefinition(
        name: '작가',
        valueType: TagValueType.text,
        allowMultiple: false,
      );
      await tags.assignToFiles(
        fileNodeIds: [node],
        tagDefinitionId: definition.id!,
        value: '홍길동',
      );

      expect(await tags.deleteDanglingAssignments(), 0);
      expect(await tags.assignmentsOfFile(node), hasLength(1));
    });
  });
}
