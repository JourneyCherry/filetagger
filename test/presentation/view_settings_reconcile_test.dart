import 'package:filetagger/domain/entities/file_filter.dart';
import 'package:filetagger/domain/entities/file_sort.dart';
import 'package:filetagger/domain/entities/system_tag.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/domain/entities/workspace_view_settings.dart';
import 'package:filetagger/domain/repositories/view_settings_repository.dart';
import 'package:filetagger/presentation/providers/file_view_provider.dart';
import 'package:filetagger/presentation/providers/tag_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 저장된 설정을 그대로 돌려주고, 저장 요청을 기록하는 가짜 저장소.
class _FakeStore implements ViewSettingsRepository {
  _FakeStore(this._current);

  WorkspaceViewSettings _current;
  WorkspaceViewSettings? lastSaved;

  @override
  Future<WorkspaceViewSettings> load() async => _current;

  @override
  Future<void> save(WorkspaceViewSettings settings) async {
    lastSaved = settings;
    _current = settings;
  }
}

TagDefinition _def(int id) =>
    TagDefinition(id: id, name: 't$id', valueType: TagValueType.label);

/// 이벤트 루프를 몇 바퀴 돌려 비동기 로드·스트림 방출·정리가 끝나게 한다.
Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('삭제된 태그를 참조하는 필터·정렬 조건을 자동으로 걷어낸다', () async {
    final store = _FakeStore(
      const WorkspaceViewSettings(
        filter: FileFilter(
          conditions: [
            FilterCondition(tagDefinitionId: 1),
            FilterCondition(tagDefinitionId: 2),
          ],
        ),
        sort: FileSortOrder(
          keys: [SortKey(tagDefinitionId: 1), SortKey(tagDefinitionId: 2)],
        ),
      ),
    );

    // 태그 2가 삭제되어 정의에는 태그 1만 남은 상태.
    final container = ProviderContainer(
      overrides: [
        viewSettingsRepositoryProvider.overrideWithValue(store),
        tagDefinitionsProvider.overrideWith((ref) => Stream.value([_def(1)])),
      ],
    );
    addTearDown(container.dispose);
    container.listen(viewSettingsProvider, (_, __) {});

    await _settle();

    final state = container.read(viewSettingsProvider);
    expect(state.filter.conditions.map((c) => c.tagDefinitionId), [1]);
    expect(state.sort.keys.map((k) => k.tagDefinitionId), [1]);
    // 정리 결과가 디스크에도 반영돼야 한다.
    expect(store.lastSaved, isNotNull);
    expect(store.lastSaved!.filter.conditions.single.tagDefinitionId, 1);
  });

  test('시스템 태그(음수 id)를 참조하는 필터·정렬은 정리로 지워지지 않는다', () async {
    final store = _FakeStore(
      WorkspaceViewSettings(
        filter: FileFilter(
          conditions: [
            const FilterCondition(tagDefinitionId: 1),
            FilterCondition(tagDefinitionId: SystemTag.fileSize.id),
          ],
        ),
        sort: FileSortOrder(
          keys: [SortKey(tagDefinitionId: SystemTag.modifiedTime.id)],
        ),
      ),
    );

    // 사용자 정의에는 태그 1만 있고 시스템 태그는 정의 목록에 없다.
    final container = ProviderContainer(
      overrides: [
        viewSettingsRepositoryProvider.overrideWithValue(store),
        tagDefinitionsProvider.overrideWith((ref) => Stream.value([_def(1)])),
      ],
    );
    addTearDown(container.dispose);
    container.listen(viewSettingsProvider, (_, __) {});

    await _settle();

    final state = container.read(viewSettingsProvider);
    // 시스템 태그 참조가 그대로 남는다(사용자 태그 1도 유효하므로 정리 없음).
    expect(state.filter.conditions.map((c) => c.tagDefinitionId), [
      1,
      SystemTag.fileSize.id,
    ]);
    expect(state.sort.keys.single.tagDefinitionId, SystemTag.modifiedTime.id);
    expect(store.lastSaved, isNull);
  });

  test('모든 태그가 유효하면 정리하지 않는다(불필요한 저장 없음)', () async {
    final store = _FakeStore(
      const WorkspaceViewSettings(
        filter: FileFilter(conditions: [FilterCondition(tagDefinitionId: 1)]),
        sort: FileSortOrder(keys: [SortKey(tagDefinitionId: 2)]),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        viewSettingsRepositoryProvider.overrideWithValue(store),
        tagDefinitionsProvider.overrideWith(
          (ref) => Stream.value([_def(1), _def(2)]),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(viewSettingsProvider, (_, __) {});

    await _settle();

    final state = container.read(viewSettingsProvider);
    expect(state.filter.conditions.single.tagDefinitionId, 1);
    expect(state.sort.keys.single.tagDefinitionId, 2);
    // 걷어낼 게 없으면 저장을 호출하지 않는다.
    expect(store.lastSaved, isNull);
  });
}
