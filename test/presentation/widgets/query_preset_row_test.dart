import 'package:filetagger/domain/entities/file_filter.dart';
import 'package:filetagger/domain/entities/file_sort.dart';
import 'package:filetagger/domain/entities/query_preset.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/domain/entities/workspace_view_settings.dart';
import 'package:filetagger/domain/repositories/query_preset_repository.dart';
import 'package:filetagger/domain/repositories/view_settings_repository.dart';
import 'package:filetagger/presentation/providers/file_view_provider.dart';
import 'package:filetagger/presentation/providers/query_preset_provider.dart';
import 'package:filetagger/presentation/providers/tag_provider.dart';
import 'package:filetagger/presentation/tag_visuals.dart';
import 'package:filetagger/presentation/widgets/file_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _rating = TagDefinition(
  id: 1,
  name: '평점',
  valueType: TagValueType.number,
);
const _read = TagDefinition(id: 2, name: '읽음', valueType: TagValueType.label);

/// 조건만 담은 프리셋 하나. 정렬·그룹이 비어 있어, 불러오면 지금 걸린 정렬·그룹까지
/// 지워져야 한다("모두 지우고 불러온다").
const _preset = QueryPreset(
  name: '읽던 만화',
  filter: FileFilter(conditions: [FilterCondition(tagDefinitionId: 1)]),
);

class _FakeViewStore implements ViewSettingsRepository {
  _FakeViewStore(this._current);

  final WorkspaceViewSettings _current;

  @override
  Future<WorkspaceViewSettings> load() async => _current;

  @override
  Future<void> save(WorkspaceViewSettings settings) async {}
}

class _FakePresetStore implements QueryPresetRepository {
  _FakePresetStore(this._current);

  final List<QueryPreset> _current;

  @override
  Future<List<QueryPreset>> load() async => _current;

  @override
  Future<void> save(List<QueryPreset> presets) async {}
}

Future<ProviderContainer> pumpPresetRow(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [
      viewSettingsRepositoryProvider.overrideWithValue(
        _FakeViewStore(
          const WorkspaceViewSettings(
            filter: FileFilter(
              conditions: [FilterCondition(tagDefinitionId: 2)],
            ),
            sort: FileSortOrder(keys: [SortKey(tagDefinitionId: 1)]),
            grouping: kDefaultGrouping,
          ),
        ),
      ),
      queryPresetRepositoryProvider.overrideWithValue(
        _FakePresetStore(const [_preset]),
      ),
      tagDefinitionsProvider.overrideWith(
        (ref) => Stream.value([_rating, _read]),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            // 프리셋 줄만 남겨, 눌린 캡슐이 아래 세 줄을 어떻게 바꾸는지만 본다.
            child: FileToolbar(
              showFilter: false,
              showSort: false,
              showGroup: false,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('프리셋 캡슐을 누르면 조건이 통째로 갈린다', (tester) async {
    final container = await pumpPresetRow(tester);
    expect(container.read(groupingProvider).keys, isNotEmpty);

    await tester.tap(find.text('읽던 만화'));
    await tester.pumpAndSettle();

    // 프리셋의 필터로 대체되고, 프리셋이 담지 않은 정렬·그룹은 비워진다.
    expect(
      container.read(fileFilterProvider).conditions.single.tagDefinitionId,
      1,
    );
    expect(container.read(fileSortProvider).isEmpty, isTrue);
    expect(container.read(groupingProvider).isEmpty, isTrue);
  });

  testWidgets('걸린 조건과 같아진 프리셋은 활성으로 표시된다', (tester) async {
    final container = await pumpPresetRow(tester);
    expect(container.read(activeQueryPresetProvider), isNull);

    await tester.tap(find.text('읽던 만화'));
    await tester.pumpAndSettle();

    expect(container.read(activeQueryPresetProvider), 0);
  });

  testWidgets('프리셋이 없으면 빈 자리 문구만 둔다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tagDefinitionsProvider.overrideWith((ref) => Stream.value([_rating])),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              child: FileToolbar(
                showFilter: false,
                showSort: false,
                showGroup: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(kEmptyQueryLabel), findsOneWidget);
  });
}
