import 'dart:io';

import 'package:filetagger/core/constants.dart';
import 'package:filetagger/data/settings/query_preset_store.dart';
import 'package:filetagger/domain/entities/file_filter.dart';
import 'package:filetagger/domain/entities/file_grouping.dart';
import 'package:filetagger/domain/entities/file_sort.dart';
import 'package:filetagger/domain/entities/query_preset.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('filetagger_presets_test');
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test('저장한 프리셋을 그대로 다시 읽는다', () async {
    final store = JsonQueryPresetStore(root.path);
    const presets = [
      QueryPreset(
        name: '읽던 만화',
        filter: FileFilter(
          conditions: [
            FilterCondition(
              tagDefinitionId: 1,
              operator: FilterOperator.contains,
              operand: '판타지',
            ),
            FilterCondition(tagDefinitionId: 2, exclude: true),
          ],
        ),
        sort: FileSortOrder(
          keys: [
            SortKey(tagDefinitionId: 3, direction: SortDirection.descending),
          ],
        ),
        grouping: FileGrouping(
          keys: [FolderHierarchyGroupKey(), TagGroupKey(1)],
        ),
        nameSources: [4, 1],
        subtitleSources: [1],
        thumbnailSources: [5],
      ),
      QueryPreset(name: '모두 보기'),
    ];

    await store.save(presets);

    expect(await store.load(), presets);
  });

  test('표시 출처가 없는 옛 프리셋은 빈 목록으로 읽힌다(=기본으로 되돌림)', () async {
    final file = File(
      p.join(root.path, filetaggerDirName, queryPresetsFileName),
    )..createSync(recursive: true);
    file.writeAsStringSync('{"presets":[{"name":"옛것"}]}');

    final loaded = await JsonQueryPresetStore(root.path).load();

    expect(loaded.single.nameSources, isEmpty);
    expect(loaded.single.subtitleSources, isEmpty);
    expect(loaded.single.thumbnailSources, isEmpty);
  });

  test('워크스페이스 안(.filetagger)에 저장한다', () async {
    await JsonQueryPresetStore(root.path).save(const [QueryPreset(name: 'a')]);

    expect(
      File(
        p.join(root.path, filetaggerDirName, queryPresetsFileName),
      ).existsSync(),
      isTrue,
    );
  });

  test('파일이 없거나 깨졌으면 빈 목록', () async {
    final store = JsonQueryPresetStore(root.path);
    expect(await store.load(), isEmpty);

    final file = File(
      p.join(root.path, filetaggerDirName, queryPresetsFileName),
    )..createSync(recursive: true);
    file.writeAsStringSync('{ 이건 JSON이 아니다');

    expect(await store.load(), isEmpty);
  });

  test('이름 없는 항목은 건너뛴다(가리킬 수단이 없다)', () async {
    final file = File(
      p.join(root.path, filetaggerDirName, queryPresetsFileName),
    )..createSync(recursive: true);
    file.writeAsStringSync('{"presets":[{"name":""},{"name":"쓸모 있음"}]}');

    final loaded = await JsonQueryPresetStore(root.path).load();

    expect(loaded.single.name, '쓸모 있음');
  });
}
