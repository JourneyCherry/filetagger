import 'dart:io';

import 'package:filetagger/data/settings/view_settings_store.dart';
import 'package:filetagger/domain/entities/file_filter.dart';
import 'package:filetagger/domain/entities/file_grouping.dart';
import 'package:filetagger/domain/entities/file_sort.dart';
import 'package:filetagger/domain/entities/folder_manage_mode.dart';
import 'package:filetagger/domain/entities/workspace_view_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('filetagger_view_');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('저장한 필터·정렬을 그대로 다시 불러온다', () async {
    final store = JsonViewSettingsStore(root.path);
    const settings = WorkspaceViewSettings(
      filter: FileFilter(
        conditions: [
          FilterCondition(tagDefinitionId: 1),
          FilterCondition(
            tagDefinitionId: 2,
            operator: FilterOperator.greaterThan,
            operand: '5',
          ),
          FilterCondition(tagDefinitionId: 3, exclude: true),
        ],
      ),
      sort: FileSortOrder(
        keys: [
          SortKey(tagDefinitionId: 2, direction: SortDirection.descending),
          SortKey(tagDefinitionId: 1),
        ],
      ),
    );

    await store.save(settings);
    final loaded = await store.load();

    expect(loaded.filter.conditions, hasLength(3));
    final c1 = loaded.filter.conditions[1];
    expect(c1.tagDefinitionId, 2);
    expect(c1.operator, FilterOperator.greaterThan);
    expect(c1.operand, '5');
    expect(loaded.filter.conditions[2].exclude, isTrue);

    expect(loaded.sort.keys, hasLength(2));
    expect(loaded.sort.keys[0].tagDefinitionId, 2);
    expect(loaded.sort.keys[0].direction, SortDirection.descending);
    expect(loaded.sort.keys[1].direction, SortDirection.ascending);
  });

  test('프리뷰 비율을 저장하고 그대로 불러온다', () async {
    final store = JsonViewSettingsStore(root.path);
    await store.save(const WorkspaceViewSettings(previewRatio: 0.5));
    final loaded = await store.load();
    expect(loaded.previewRatio, 0.5);
  });

  test('루트 관리 방식을 저장하고 그대로 불러온다', () async {
    final store = JsonViewSettingsStore(root.path);
    await store.save(
      const WorkspaceViewSettings(
        rootManageMode: FolderManageMode.managedRecursive,
      ),
    );
    final loaded = await store.load();
    expect(loaded.rootManageMode, FolderManageMode.managedRecursive);
  });

  test('루트 관리 방식이 없으면 기본값(managed)을 쓴다', () async {
    final loaded = await JsonViewSettingsStore(root.path).load();
    expect(loaded.rootManageMode, kDefaultRootManageMode);
  });

  test('루트 관리 방식이 불투명으로 저장돼 있어도 기본값으로 되돌린다', () async {
    final file = File('${root.path}/.filetagger/view.json');
    await file.create(recursive: true);
    await file.writeAsString('{"rootManageMode":"opaque"}');
    final loaded = await JsonViewSettingsStore(root.path).load();
    expect(loaded.rootManageMode, kDefaultRootManageMode);
  });

  test('저장된 프리뷰 비율이 범위를 벗어나면 가둔다', () async {
    final file = File('${root.path}/.filetagger/view.json');
    await file.create(recursive: true);
    await file.writeAsString('{"previewRatio":0.95}');
    final loaded = await JsonViewSettingsStore(root.path).load();
    expect(loaded.previewRatio, kPreviewRatioMax);
  });

  test('프리뷰 비율이 없거나 숫자가 아니면 기본값을 쓴다', () async {
    final file = File('${root.path}/.filetagger/view.json');
    await file.create(recursive: true);
    await file.writeAsString('{"previewRatio":"oops"}');
    final loaded = await JsonViewSettingsStore(root.path).load();
    expect(loaded.previewRatio, kDefaultPreviewRatio);
  });

  test('표시할 시스템 태그 id 집합을 저장하고 그대로 불러온다', () async {
    final store = JsonViewSettingsStore(root.path);
    await store.save(
      const WorkspaceViewSettings(visibleSystemTagIds: {-1, -5}),
    );
    final loaded = await store.load();
    expect(loaded.visibleSystemTagIds, {-1, -5});
  });

  test('시스템 태그 설정이 없으면 빈 집합(전부 숨김)이 기본', () async {
    final loaded = await JsonViewSettingsStore(root.path).load();
    expect(loaded.visibleSystemTagIds, isEmpty);
  });

  test('시스템 태그 항목이 형식에 안 맞으면 빈 집합으로 복구한다', () async {
    final file = File('${root.path}/.filetagger/view.json');
    await file.create(recursive: true);
    await file.writeAsString('{"systemTags":"oops"}');
    final loaded = await JsonViewSettingsStore(root.path).load();
    expect(loaded.visibleSystemTagIds, isEmpty);
  });

  test('태그 표시 순서를 저장하고 그대로 불러온다', () async {
    final store = JsonViewSettingsStore(root.path);
    await store.save(const WorkspaceViewSettings(tagDisplayOrder: [3, -1, 1]));
    final loaded = await store.load();
    expect(loaded.tagDisplayOrder, [3, -1, 1]);
  });

  test('태그 표시 순서가 없거나 형식에 안 맞으면 빈 목록이 기본', () async {
    final file = File('${root.path}/.filetagger/view.json');
    await file.create(recursive: true);
    await file.writeAsString('{"tagOrder":"oops"}');
    final loaded = await JsonViewSettingsStore(root.path).load();
    expect(loaded.tagDisplayOrder, isEmpty);
  });

  test('태그 표시 순서의 중복·비정수 항목은 걸러낸다', () async {
    final file = File('${root.path}/.filetagger/view.json');
    await file.create(recursive: true);
    await file.writeAsString('{"tagOrder":[2,"x",1,2]}');
    final loaded = await JsonViewSettingsStore(root.path).load();
    expect(loaded.tagDisplayOrder, [2, 1]);
  });

  test('펼쳐 둔 폴더 경로를 저장하고 그대로 불러온다', () async {
    final store = JsonViewSettingsStore(root.path);
    await store.save(
      const WorkspaceViewSettings(expandedFolders: {'a', 'a/b'}),
    );
    final loaded = await store.load();
    expect(loaded.expandedFolders, {'a', 'a/b'});
  });

  test('펼침 상태가 없거나 형식에 안 맞으면 빈 집합(전부 접힘)이 기본', () async {
    final file = File('${root.path}/.filetagger/view.json');
    await file.create(recursive: true);
    await file.writeAsString('{"expanded":"oops"}');
    final loaded = await JsonViewSettingsStore(root.path).load();
    expect(loaded.expandedFolders, isEmpty);
  });

  test('그룹 단계를 저장하고 그대로 불러온다(폴더 계층 + 태그 키)', () async {
    final store = JsonViewSettingsStore(root.path);
    const grouping = FileGrouping(
      keys: [TagGroupKey(7), FolderHierarchyGroupKey()],
    );
    await store.save(const WorkspaceViewSettings(grouping: grouping));
    final loaded = await store.load();
    expect(loaded.grouping.keys, hasLength(2));
    expect((loaded.grouping.keys.first as TagGroupKey).tagDefinitionId, 7);
    expect(loaded.grouping.keys.last, isA<FolderHierarchyGroupKey>());
  });

  test('그룹 설정이 없으면 기본값(폴더 계층)을 쓴다', () async {
    final loaded = await JsonViewSettingsStore(root.path).load();
    expect(loaded.grouping.keys, [const FolderHierarchyGroupKey()]);
  });

  test('구버전 grouped=true는 폴더 계층 그룹으로 마이그레이션된다', () async {
    final file = File('${root.path}/.filetagger/view.json');
    await file.create(recursive: true);
    await file.writeAsString('{"grouped":true}');
    final loaded = await JsonViewSettingsStore(root.path).load();
    expect(loaded.grouping.keys, [const FolderHierarchyGroupKey()]);
  });

  test('구버전 grouped=false는 평면(빈 그룹)으로 마이그레이션된다', () async {
    final file = File('${root.path}/.filetagger/view.json');
    await file.create(recursive: true);
    await file.writeAsString('{"grouped":false}');
    final loaded = await JsonViewSettingsStore(root.path).load();
    expect(loaded.grouping.isEmpty, isTrue);
  });

  test('저장 파일이 없으면 기본값(빈 설정)을 준다', () async {
    final loaded = await JsonViewSettingsStore(root.path).load();
    expect(loaded.isEmpty, isTrue);
    expect(loaded.previewRatio, kDefaultPreviewRatio);
  });

  test('손상된 JSON은 기본값으로 복구한다', () async {
    final file = File('${root.path}/.filetagger/view.json');
    await file.create(recursive: true);
    await file.writeAsString('{ this is not json');

    final loaded = await JsonViewSettingsStore(root.path).load();
    expect(loaded.isEmpty, isTrue);
  });

  test('알 수 없는 연산자·방향 항목은 건너뛴다', () async {
    final file = File('${root.path}/.filetagger/view.json');
    await file.create(recursive: true);
    await file.writeAsString(
      '{"filter":{"conditions":['
      '{"tag":1,"op":"bogusOp","exclude":false},'
      '{"tag":2,"op":"exists","exclude":false}]},'
      '"sort":{"keys":['
      '{"tag":1,"direction":"sideways"},'
      '{"tag":2,"direction":"ascending"}]}}',
    );

    final loaded = await JsonViewSettingsStore(root.path).load();
    expect(loaded.filter.conditions, hasLength(1));
    expect(loaded.filter.conditions.single.tagDefinitionId, 2);
    expect(loaded.sort.keys, hasLength(1));
    expect(loaded.sort.keys.single.tagDefinitionId, 2);
  });
}
