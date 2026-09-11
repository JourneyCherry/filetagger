import 'package:filetagger/domain/entities/file_filter.dart';
import 'package:filetagger/domain/entities/file_grouping.dart';
import 'package:filetagger/domain/entities/file_sort.dart';
import 'package:filetagger/domain/entities/query_preset.dart';
import 'package:filetagger/domain/entities/system_tag.dart';
import 'package:filetagger/domain/entities/workspace_view_settings.dart';
import 'package:filetagger/domain/usecases/purge_retired_system_tags.dart';
import 'package:flutter_test/flutter_test.dart';

/// 없앤 시스템 태그의 id 하나. **값을 적어 두지 않고 카탈로그의 구멍에서 찾는다** —
/// 없앤 id는 다시 쓰이지 않으므로 구멍이 곧 그것이고, 나중에 또 하나를 없애도 이
/// 테스트는 그대로 선다.
final int _retired = () {
  var id = -1;
  while (systemTagById(id) != null) {
    id--;
  }
  return id;
}();

/// 지금 살아 있는 시스템 태그와 사용자 태그. 걷어내기가 이 둘을 건드리면 안 된다.
final int _live = SystemTag.fileName.id;
const int _user = 1;

void main() {
  test('없앤 시스템 태그의 id는 카탈로그에 구멍으로 남는다', () {
    expect(isRetiredSystemTagId(_retired), isTrue);
    expect(isRetiredSystemTagId(_live), isFalse);
    expect(isRetiredSystemTagId(_user), isFalse);
  });

  group('보기 설정', () {
    WorkspaceViewSettings settingsWith(int id) => WorkspaceViewSettings(
      filter: FileFilter(conditions: [FilterCondition(tagDefinitionId: id)]),
      sort: FileSortOrder(keys: [SortKey(tagDefinitionId: id)]),
      detailSort: FileSortOrder(keys: [SortKey(tagDefinitionId: id)]),
      grouping: FileGrouping(keys: [TagGroupKey(id)]),
      visibleSystemTagIds: {id},
      hiddenTagIds: {id},
      tagDisplayOrder: [id],
      detailColumnWidths: {id: 100},
      thumbnailSources: [id],
      nameSources: [id],
      subtitleSources: [id],
    );

    test('없앤 시스템 태그를 가리키는 자리를 모두 걷어낸다', () {
      final purged = purgeRetiredFromViewSettings(settingsWith(_retired));

      // 열한 자리가 태그 id를 담는다 — 하나라도 빠뜨리면 여기서 드러난다.
      expect(purged.removed, 11);
      final s = purged.value;
      expect(s.filter.conditions, isEmpty);
      expect(s.sort.keys, isEmpty);
      expect(s.detailSort.keys, isEmpty);
      expect(s.grouping.keys, isEmpty);
      expect(s.visibleSystemTagIds, isEmpty);
      expect(s.hiddenTagIds, isEmpty);
      expect(s.tagDisplayOrder, isEmpty);
      expect(s.detailColumnWidths, isEmpty);
      expect(s.thumbnailSources, isEmpty);
      expect(s.nameSources, isEmpty);
      expect(s.subtitleSources, isEmpty);
    });

    test('살아 있는 시스템 태그와 사용자 태그는 그대로 둔다', () {
      for (final id in [_live, _user]) {
        final purged = purgeRetiredFromViewSettings(settingsWith(id));
        expect(purged.removed, 0, reason: '$id');
        expect(purged.changed, isFalse, reason: '$id');
      }
    });

    test('손댈 것이 없으면 받은 값을 그대로 준다', () {
      // 부르는 쪽이 이것을 보고 다시 쓸지 정한다 — 같은 내용을 덮어쓰면 수정 시각만
      // 흔들려 백업·동기화가 매번 달라진 것으로 본다.
      const settings = WorkspaceViewSettings();
      final purged = purgeRetiredFromViewSettings(settings);

      expect(purged.changed, isFalse);
      expect(identical(purged.value, settings), isTrue);
    });

    test('폴더 계층 그룹 키는 태그가 아니라 늘 남는다', () {
      final purged = purgeRetiredFromViewSettings(
        WorkspaceViewSettings(
          grouping: FileGrouping(
            keys: [const FolderHierarchyGroupKey(), TagGroupKey(_retired)],
          ),
        ),
      );

      expect(purged.removed, 1);
      expect(purged.value.grouping.keys, [const FolderHierarchyGroupKey()]);
    });
  });

  group('프리셋', () {
    QueryPreset presetWith(String name, int id) => QueryPreset(
      name: name,
      filter: FileFilter(conditions: [FilterCondition(tagDefinitionId: id)]),
      sort: FileSortOrder(keys: [SortKey(tagDefinitionId: id)]),
      grouping: FileGrouping(keys: [TagGroupKey(id)]),
      nameSources: [id],
      subtitleSources: [id],
      thumbnailSources: [id],
    );

    test('없앤 시스템 태그를 가리키는 자리를 걷어내고 이름은 둔다', () {
      final purged = purgeRetiredFromPreset(presetWith('읽을 것', _retired));

      expect(purged.removed, 6);
      expect(purged.value.name, '읽을 것');
      expect(purged.value.filter.conditions, isEmpty);
      expect(purged.value.sort.keys, isEmpty);
      expect(purged.value.grouping.keys, isEmpty);
      expect(purged.value.nameSources, isEmpty);
      expect(purged.value.subtitleSources, isEmpty);
      expect(purged.value.thumbnailSources, isEmpty);
    });

    test('목록의 차례는 그대로이고 걷어낸 수는 모두 더한다', () {
      final purged = purgeRetiredFromPresets([
        presetWith('가', _retired),
        presetWith('나', _user),
        presetWith('다', _retired),
      ]);

      expect(purged.removed, 12);
      expect([for (final p in purged.value) p.name], ['가', '나', '다']);
      // 손댈 것이 없던 프리셋은 값이 그대로다.
      expect(purged.value[1].nameSources, [_user]);
    });

    test('손댈 것이 없으면 받은 목록을 그대로 준다', () {
      final presets = [presetWith('가', _user)];
      final purged = purgeRetiredFromPresets(presets);

      expect(purged.changed, isFalse);
      expect(identical(purged.value, presets), isTrue);
    });
  });
}
