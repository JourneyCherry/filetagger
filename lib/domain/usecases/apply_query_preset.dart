import '../entities/file_filter.dart';
import '../entities/file_grouping.dart';
import '../entities/file_sort.dart';
import '../entities/query_preset.dart';

/// 프리셋을 실제로 걸 수 있는 형태로 푼 결과.
///
/// 세 조건과 세 표시 출처는 그대로 갈아끼울 값이고, [droppedCount]는 태그가 사라져
/// 걸 수 없어 버린 조각의 수다(사용자에게 알리는 용도 — 0이면 알릴 것이 없다).
class QueryPresetApplication {
  const QueryPresetApplication({
    required this.filter,
    required this.sort,
    required this.grouping,
    required this.nameSources,
    required this.subtitleSources,
    required this.thumbnailSources,
    required this.droppedCount,
  });

  final FileFilter filter;
  final FileSortOrder sort;
  final FileGrouping grouping;
  final List<int> nameSources;
  final List<int> subtitleSources;
  final List<int> thumbnailSources;
  final int droppedCount;
}

/// 프리셋을 지금의 유효한 태그 정의 집합([validTagIds])에 비추어 푼다.
///
/// 저장해 둔 뒤 태그가 지워졌다면 그 조각은 걸 수 없으므로 걸러 내고 개수만 센다.
/// 프리셋 자체는 고치지 않는다 — 태그 하나를 지웠다고 사용자가 만든 프리셋들이
/// 조용히 갉히면 되돌릴 수 없기 때문이다(정리 대신 불러올 때마다 걸러 낸다).
///
/// 폴더 계층 그룹 키는 진짜 태그가 아니라 늘 유효하다.
QueryPresetApplication resolvePresetApplication(
  QueryPreset preset,
  Set<int> validTagIds,
) {
  final conditions = [
    for (final c in preset.filter.conditions)
      if (validTagIds.contains(c.tagDefinitionId)) c,
  ];
  final sortKeys = [
    for (final k in preset.sort.keys)
      if (validTagIds.contains(k.tagDefinitionId)) k,
  ];
  final groupKeys = [
    for (final k in preset.grouping.keys)
      if (k is FolderHierarchyGroupKey || validTagIds.contains(groupKeyId(k)))
        k,
  ];
  final nameSources = [
    for (final id in preset.nameSources)
      if (validTagIds.contains(id)) id,
  ];
  final subtitleSources = [
    for (final id in preset.subtitleSources)
      if (validTagIds.contains(id)) id,
  ];
  final thumbnailSources = [
    for (final id in preset.thumbnailSources)
      if (validTagIds.contains(id)) id,
  ];
  final dropped =
      (preset.filter.conditions.length - conditions.length) +
      (preset.sort.keys.length - sortKeys.length) +
      (preset.grouping.keys.length - groupKeys.length) +
      (preset.nameSources.length - nameSources.length) +
      (preset.subtitleSources.length - subtitleSources.length) +
      (preset.thumbnailSources.length - thumbnailSources.length);
  return QueryPresetApplication(
    filter: FileFilter(conditions: conditions),
    sort: FileSortOrder(keys: sortKeys),
    grouping: FileGrouping(keys: groupKeys),
    nameSources: nameSources,
    subtitleSources: subtitleSources,
    thumbnailSources: thumbnailSources,
    droppedCount: dropped,
  );
}
