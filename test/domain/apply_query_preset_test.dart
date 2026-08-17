import 'package:filetagger/domain/entities/file_filter.dart';
import 'package:filetagger/domain/entities/file_grouping.dart';
import 'package:filetagger/domain/entities/file_sort.dart';
import 'package:filetagger/domain/entities/query_preset.dart';
import 'package:filetagger/domain/usecases/apply_query_preset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const preset = QueryPreset(
    name: '읽던 만화',
    filter: FileFilter(
      conditions: [
        FilterCondition(tagDefinitionId: 1),
        FilterCondition(tagDefinitionId: 2, exclude: true),
      ],
    ),
    sort: FileSortOrder(
      keys: [
        SortKey(tagDefinitionId: 1, direction: SortDirection.descending),
        SortKey(tagDefinitionId: 3),
      ],
    ),
    grouping: FileGrouping(keys: [FolderHierarchyGroupKey(), TagGroupKey(2)]),
    nameSources: [3, 2],
    subtitleSources: [2, 1],
    thumbnailSources: [2],
  );

  test('태그가 모두 살아 있으면 조건·표시 출처를 그대로 낸다', () {
    final applied = resolvePresetApplication(preset, {1, 2, 3});

    expect(applied.filter, preset.filter);
    expect(applied.sort, preset.sort);
    expect(applied.grouping, preset.grouping);
    expect(applied.nameSources, preset.nameSources);
    expect(applied.subtitleSources, preset.subtitleSources);
    expect(applied.thumbnailSources, preset.thumbnailSources);
    expect(applied.droppedCount, 0);
  });

  test('사라진 태그를 가리키는 조각만 빼고 그 수를 센다', () {
    // 태그 2가 지워진 상황: 필터 조건 1개, 그룹 단계 1개, 이름 출처 1개, 부제 출처
    // 1개, 썸네일 출처 1개가 걸 수 없게 된다.
    final applied = resolvePresetApplication(preset, {1, 3});

    expect(applied.filter.conditions.single.tagDefinitionId, 1);
    expect(applied.sort, preset.sort);
    // 폴더 계층 키는 진짜 태그가 아니라 늘 남는다.
    expect(applied.grouping.keys, [const FolderHierarchyGroupKey()]);
    expect(applied.nameSources, [3]);
    expect(applied.subtitleSources, [1]);
    expect(applied.thumbnailSources, isEmpty);
    expect(applied.droppedCount, 5);
  });

  test('원본 프리셋은 고쳐지지 않는다(정리가 아니라 걸러 내기다)', () {
    resolvePresetApplication(preset, const <int>{});

    expect(preset.filter.conditions.length, 2);
    expect(preset.sort.keys.length, 2);
    expect(preset.grouping.keys.length, 2);
    expect(preset.nameSources.length, 2);
    expect(preset.subtitleSources.length, 2);
    expect(preset.thumbnailSources.length, 1);
  });

  test('빈 프리셋은 조건을 모두 지우고 표시도 기본으로 되돌리는 뜻이다', () {
    const empty = QueryPreset(name: '모두 보기');

    final applied = resolvePresetApplication(empty, {1, 2, 3});

    expect(applied.filter.isEmpty, isTrue);
    expect(applied.sort.isEmpty, isTrue);
    expect(applied.grouping.isEmpty, isTrue);
    // 비면 파일 이름·경로·기본 썸네일로 돌아간다(부분 병합이 없으므로 "안 담김"과
    // 구분하지 않는다).
    expect(applied.nameSources, isEmpty);
    expect(applied.subtitleSources, isEmpty);
    expect(applied.thumbnailSources, isEmpty);
    expect(applied.droppedCount, 0);
  });

  test('같은지는 값으로 견준다(활성 프리셋 표시)', () {
    expect(
      preset.matchesQuery(
        filter: preset.filter,
        sort: preset.sort,
        grouping: preset.grouping,
        nameSources: preset.nameSources,
        subtitleSources: preset.subtitleSources,
        thumbnailSources: preset.thumbnailSources,
      ),
      isTrue,
    );
    // 정렬 단계의 순서는 우선순위라, 뒤집히면 같은 조건이 아니다.
    expect(
      preset.matchesQuery(
        filter: preset.filter,
        sort: FileSortOrder(keys: preset.sort.keys.reversed.toList()),
        grouping: preset.grouping,
        nameSources: preset.nameSources,
        subtitleSources: preset.subtitleSources,
        thumbnailSources: preset.thumbnailSources,
      ),
      isFalse,
    );
    // 표시 출처도 우선순위라 순서가 다르면 다른 프리셋이다.
    expect(
      preset.matchesQuery(
        filter: preset.filter,
        sort: preset.sort,
        grouping: preset.grouping,
        nameSources: preset.nameSources.reversed.toList(),
        subtitleSources: preset.subtitleSources,
        thumbnailSources: preset.thumbnailSources,
      ),
      isFalse,
    );
    // 조건이 같아도 썸네일 출처가 다르면 활성으로 보지 않는다.
    expect(
      preset.matchesQuery(
        filter: preset.filter,
        sort: preset.sort,
        grouping: preset.grouping,
        nameSources: preset.nameSources,
        subtitleSources: preset.subtitleSources,
        thumbnailSources: const [],
      ),
      isFalse,
    );
    // 부제 출처도 마찬가지다(이름·썸네일과 같은 자격으로 프리셋에 담긴다).
    expect(
      preset.matchesQuery(
        filter: preset.filter,
        sort: preset.sort,
        grouping: preset.grouping,
        nameSources: preset.nameSources,
        subtitleSources: const [],
        thumbnailSources: preset.thumbnailSources,
      ),
      isFalse,
    );
  });
}
