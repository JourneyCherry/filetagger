/// 저장된 보기 설정·프리셋에서 **없앤 시스템 태그**를 가리키는 참조를 걷어낸다.
///
/// 시스템 태그는 DB에 행으로 살지 않고 노드에서 계산되므로, 태그 하나를 없애도 지워야
/// 할 부여 기록이 없다. 대신 그 id를 **가리키던 참조**는 `.filetagger/`의 보기 설정과
/// 조건 프리셋에 그대로 남는다 — 조건·정렬·그룹·표시 출처·칩 표시 설정·자세히 컬럼 폭이
/// 모두 태그 id로 저장되기 때문이다.
///
/// **사용자가 지운 태그와 성격이 다르다.** 그쪽은 실수로 지웠을 수 있어 저장된 참조를
/// 남겨 두고 불러오는 순간에만 걸러 내지만([resolvePresetApplication]), 없앤 시스템 태그의
/// id는 **다시 쓰이지 않으므로**([SystemTag]) 남겨 둘 값이 없다. 그래서 이쪽만 실제로
/// 지운다 — 프리셋을 고치지 않는다는 결정의 근거("되돌릴 수 없다")가 여기엔 없다.
///
/// 순수 계산이라 파일도 DB도 모른다. 읽어 와 걸고 다시 쓰는 것은 부르는 쪽의 몫이다.
library;

import '../entities/file_filter.dart';
import '../entities/file_grouping.dart';
import '../entities/file_sort.dart';
import '../entities/query_preset.dart';
import '../entities/system_tag.dart';
import '../entities/workspace_view_settings.dart';

/// 걷어낸 뒤의 값과 **몇 개를 걷어냈는지**. 0이면 손댈 것이 없었다는 뜻이라 부르는
/// 쪽이 다시 쓰지 않아도 된다(쓸데없는 저장을 막는다).
class Purged<T> {
  const Purged(this.value, this.removed);

  final T value;
  final int removed;

  bool get changed => removed > 0;
}

/// 보기 설정 한 벌에서 없앤 시스템 태그 참조를 걷어낸다.
///
/// **펼침 상태·보기 모드·크기 배율은 태그를 가리키지 않아** 손대지 않는다.
Purged<WorkspaceViewSettings> purgeRetiredFromViewSettings(
  WorkspaceViewSettings settings,
) {
  final conditions = _keepConditions(settings.filter.conditions);
  final sortKeys = _keepSortKeys(settings.sort.keys);
  final detailSortKeys = _keepSortKeys(settings.detailSort.keys);
  final groupKeys = _keepGroupKeys(settings.grouping.keys);
  final visibleSystem = _keepIds(settings.visibleSystemTagIds);
  final hidden = _keepIds(settings.hiddenTagIds);
  final order = _keepIds(settings.tagDisplayOrder);
  final widths = {
    for (final e in settings.detailColumnWidths.entries)
      if (!isRetiredSystemTagId(e.key)) e.key: e.value,
  };
  final thumbnails = _keepIds(settings.thumbnailSources);
  final names = _keepIds(settings.nameSources);
  final subtitles = _keepIds(settings.subtitleSources);

  final removed =
      (settings.filter.conditions.length - conditions.length) +
      (settings.sort.keys.length - sortKeys.length) +
      (settings.detailSort.keys.length - detailSortKeys.length) +
      (settings.grouping.keys.length - groupKeys.length) +
      (settings.visibleSystemTagIds.length - visibleSystem.length) +
      (settings.hiddenTagIds.length - hidden.length) +
      (settings.tagDisplayOrder.length - order.length) +
      (settings.detailColumnWidths.length - widths.length) +
      (settings.thumbnailSources.length - thumbnails.length) +
      (settings.nameSources.length - names.length) +
      (settings.subtitleSources.length - subtitles.length);
  if (removed == 0) return Purged(settings, 0);

  return Purged(
    settings.copyWith(
      filter: FileFilter(conditions: conditions),
      sort: FileSortOrder(keys: sortKeys),
      detailSort: FileSortOrder(keys: detailSortKeys),
      grouping: FileGrouping(keys: groupKeys),
      visibleSystemTagIds: visibleSystem.toSet(),
      hiddenTagIds: hidden.toSet(),
      tagDisplayOrder: order,
      detailColumnWidths: widths,
      thumbnailSources: thumbnails,
      nameSources: names,
      subtitleSources: subtitles,
    ),
    removed,
  );
}

/// 프리셋 하나에서 없앤 시스템 태그 참조를 걷어낸다.
Purged<QueryPreset> purgeRetiredFromPreset(QueryPreset preset) {
  final conditions = _keepConditions(preset.filter.conditions);
  final sortKeys = _keepSortKeys(preset.sort.keys);
  final groupKeys = _keepGroupKeys(preset.grouping.keys);
  final names = _keepIds(preset.nameSources);
  final subtitles = _keepIds(preset.subtitleSources);
  final thumbnails = _keepIds(preset.thumbnailSources);

  final removed =
      (preset.filter.conditions.length - conditions.length) +
      (preset.sort.keys.length - sortKeys.length) +
      (preset.grouping.keys.length - groupKeys.length) +
      (preset.nameSources.length - names.length) +
      (preset.subtitleSources.length - subtitles.length) +
      (preset.thumbnailSources.length - thumbnails.length);
  if (removed == 0) return Purged(preset, 0);

  return Purged(
    QueryPreset(
      name: preset.name,
      filter: FileFilter(conditions: conditions),
      sort: FileSortOrder(keys: sortKeys),
      grouping: FileGrouping(keys: groupKeys),
      nameSources: names,
      subtitleSources: subtitles,
      thumbnailSources: thumbnails,
    ),
    removed,
  );
}

/// 프리셋 목록 전체. **이름은 건드리지 않으므로** 목록의 차례도 그대로다.
Purged<List<QueryPreset>> purgeRetiredFromPresets(List<QueryPreset> presets) {
  final purged = [for (final p in presets) purgeRetiredFromPreset(p)];
  var removed = 0;
  for (final p in purged) {
    removed += p.removed;
  }
  if (removed == 0) return Purged(presets, 0);
  return Purged([for (final p in purged) p.value], removed);
}

List<FilterCondition> _keepConditions(List<FilterCondition> conditions) => [
  for (final c in conditions)
    if (!isRetiredSystemTagId(c.tagDefinitionId)) c,
];

List<SortKey> _keepSortKeys(List<SortKey> keys) => [
  for (final k in keys)
    if (!isRetiredSystemTagId(k.tagDefinitionId)) k,
];

/// 폴더 계층 키는 진짜 태그가 아니라 늘 남는다.
List<GroupKey> _keepGroupKeys(List<GroupKey> keys) => [
  for (final k in keys)
    if (k is FolderHierarchyGroupKey || !isRetiredSystemTagId(groupKeyId(k))) k,
];

List<int> _keepIds(Iterable<int> ids) => [
  for (final id in ids)
    if (!isRetiredSystemTagId(id)) id,
];
