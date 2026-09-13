import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:filetagger/data/db/app_database.dart';
import 'package:filetagger/data/repositories/drift_file_node_repository.dart';
import 'package:filetagger/domain/entities/folder_manage_mode.dart';
import 'package:filetagger/domain/entities/node_kind.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// 스캔 정합이 **겹치는 스캔들 사이에서** 무엇을 사라진 것으로 보는지에 대한 가드레일.
///
/// 스캔의 관측은 스냅샷이 아니라 구간이라, 늦게 끝난 스캔이 더 오래된 관측을 들고 있을
/// 수 있다. 그때 "내가 못 본 것은 사라졌다"로 덮으면 남이 방금 넣은 노드가 지워진다.
void main() {
  late AppDatabase db;
  late DriftFileNodeRepository nodes;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    nodes = DriftFileNodeRepository(db);
  });

  tearDown(() async => db.close());

  Future<int> insertFile(String path, {required DateTime lastSeenAt}) => db
      .into(db.fileNodes)
      .insert(
        FileNodesCompanion.insert(
          path: path,
          kind: NodeKind.file,
          lastSeenAt: lastSeenAt,
        ),
      );

  Future<FileNodeRow?> rowOf(String path) => (db.select(
    db.fileNodes,
  )..where((t) => t.path.equals(path))).getSingleOrNull();

  /// 아무것도 관측하지 못한 스캔의 정합. [startedAt]이 사라짐 판정의 기준이다.
  Future<void> reconcileEmptyScan(DateTime startedAt) => nodes.applyScan(
    const [],
    rootManageMode: FolderManageMode.managed,
    priorPaths: const {},
    unreadableDirs: const {},
    scanStartedAt: startedAt,
  );

  test('내 시작 뒤에 관측된 노드는 사라진 것으로 보지 않는다', () async {
    final now = DateTime.now();
    // 다른 스캔이 내 시작보다 나중에 이 노드를 보고 도장을 찍어 둔 모습.
    await insertFile('a.png', lastSeenAt: now);

    await reconcileEmptyScan(now.subtract(const Duration(minutes: 1)));

    final row = await rowOf('a.png');
    expect(row, isNotNull, reason: '남의 최신 관측을 내 낡은 관측으로 지우면 안 된다');
    // 연결 끊김 표시조차 남기지 않는다 — 사라진 적이 없다.
    expect(row!.missingSince, isNull);
  });

  test('아무도 새로 보지 못한 노드는 그대로 정리된다', () async {
    final now = DateTime.now();
    await insertFile(
      'a.png',
      lastSeenAt: now.subtract(const Duration(hours: 1)),
    );

    await reconcileEmptyScan(now);

    // 태그가 없는 노드는 잃을 것이 없으므로 보존 대상도 아니다.
    expect(await rowOf('a.png'), isNull);
  });

  test('기준 시각과 같은 초에 찍힌 도장은 남기는 쪽으로 읽는다', () async {
    // 저장된 도장은 초 정밀도라 같은 초 안의 앞뒤를 가릴 수 없다. 잘못 남기면 다음
    // 스캔이 정리하지만, 잘못 지우면 태그가 함께 사라진다.
    final second = DateTime(2026, 1, 2, 3, 4, 5);
    await insertFile('a.png', lastSeenAt: second);

    await reconcileEmptyScan(second);

    expect(await rowOf('a.png'), isNotNull);
  });

  test('태그가 붙은 노드는 지우지 않고 연결 끊김으로 보존한다', () async {
    final now = DateTime.now();
    final id = await insertFile(
      'a.png',
      lastSeenAt: now.subtract(const Duration(hours: 1)),
    );
    final tag = await db
        .into(db.tagDefinitions)
        .insertReturning(
          TagDefinitionsCompanion.insert(
            name: '평점',
            valueType: TagValueType.number,
          ),
        );
    await db
        .into(db.tagAssignments)
        .insert(
          TagAssignmentsCompanion.insert(
            fileNodeId: id,
            tagDefinitionId: tag.id,
            value: const Value('5'),
          ),
        );

    await reconcileEmptyScan(now);

    final row = await rowOf('a.png');
    expect(row, isNotNull);
    expect(row!.missingSince, isNotNull);
  });
}
