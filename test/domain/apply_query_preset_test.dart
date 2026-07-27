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
  );

  test('태그가 모두 살아 있으면 조건을 그대로 낸다', () {
    final applied = resolvePresetApplication(preset, {1, 2, 3});

    expect(applied.filter, preset.filter);
    expect(applied.sort, preset.sort);
    expect(applied.grouping, preset.grouping);
    expect(applied.droppedCount, 0);
  });

  test('사라진 태그를 가리키는 조각만 빼고 그 수를 센다', () {
    // 태그 2가 지워진 상황: 필터 조건 1개와 그룹 단계 1개가 걸 수 없게 된다.
    final applied = resolvePresetApplication(preset, {1, 3});

    expect(applied.filter.conditions.single.tagDefinitionId, 1);
    expect(applied.sort, preset.sort);
    // 폴더 계층 키는 진짜 태그가 아니라 늘 남는다.
    expect(applied.grouping.keys, [const FolderHierarchyGroupKey()]);
    expect(applied.droppedCount, 2);
  });

  test('원본 프리셋은 고쳐지지 않는다(정리가 아니라 걸러 내기다)', () {
    resolvePresetApplication(preset, const <int>{});

    expect(preset.filter.conditions.length, 2);
    expect(preset.sort.keys.length, 2);
    expect(preset.grouping.keys.length, 2);
  });

  test('빈 조건 프리셋은 조건을 모두 지우는 뜻이다', () {
    const empty = QueryPreset(name: '모두 보기');

    final applied = resolvePresetApplication(empty, {1, 2, 3});

    expect(applied.filter.isEmpty, isTrue);
    expect(applied.sort.isEmpty, isTrue);
    expect(applied.grouping.isEmpty, isTrue);
    expect(applied.droppedCount, 0);
  });

  test('조건이 같은지는 값으로 견준다(활성 프리셋 표시)', () {
    expect(
      preset.matchesQuery(
        filter: preset.filter,
        sort: preset.sort,
        grouping: preset.grouping,
      ),
      isTrue,
    );
    // 정렬 단계의 순서는 우선순위라, 뒤집히면 같은 조건이 아니다.
    expect(
      preset.matchesQuery(
        filter: preset.filter,
        sort: FileSortOrder(keys: preset.sort.keys.reversed.toList()),
        grouping: preset.grouping,
      ),
      isFalse,
    );
  });
}
