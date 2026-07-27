import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings/query_preset_store.dart';
import '../../domain/entities/query_preset.dart';
import '../../domain/repositories/query_preset_repository.dart';
import 'file_view_provider.dart';
import 'workspace_provider.dart';

/// 현재 워크스페이스의 조건 프리셋 저장소(`.filetagger/` JSON). 열린 폴더가 없으면 null.
final queryPresetRepositoryProvider = Provider<QueryPresetRepository?>((ref) {
  final root = ref.watch(workspaceRootProvider);
  if (root == null) return null;
  return JsonQueryPresetStore(root);
});

/// 저장된 조건 프리셋 목록의 단일 출처(목록 순서 = 사용자가 배치한 순서).
///
/// 워크스페이스를 열면 저장소에서 불러오고(그전까지는 빈 목록), 바뀔 때마다 다시
/// 저장한다. 폴더를 바꾸면 저장소가 교체되어 build가 다시 돌아 새 폴더의 목록을 읽는다.
final queryPresetsProvider =
    NotifierProvider<QueryPresetsNotifier, List<QueryPreset>>(
      QueryPresetsNotifier.new,
    );

class QueryPresetsNotifier extends Notifier<List<QueryPreset>> {
  QueryPresetRepository? _repo;

  /// 디스크 로드가 끝나기 전에 사용자가 이미 목록을 고쳤는지. 그 경우 뒤늦게 도착한
  /// 로드 결과로 갈아끼우지 않는다(방금 만든 프리셋이 사라지지 않도록).
  bool _dirty = false;

  @override
  List<QueryPreset> build() {
    final repo = ref.watch(queryPresetRepositoryProvider);
    _repo = repo;
    _dirty = false;
    if (repo != null) _load(repo);
    return const [];
  }

  Future<void> _load(QueryPresetRepository repo) async {
    final loaded = await repo.load();
    // 로드 도중 워크스페이스가 바뀌었거나 사용자가 이미 고쳤으면 결과를 버린다.
    if (_repo != repo || _dirty) return;
    state = loaded;
  }

  /// 지금 걸린 조건을 [name]으로 저장한다. 같은 이름이 이미 있으면 **그 자리에서**
  /// 덮어써(순서가 튀지 않게), 없으면 목록 끝에 붙인다.
  void saveCurrent(String name) {
    final preset = QueryPreset(
      name: name,
      filter: ref.read(fileFilterProvider),
      sort: ref.read(fileSortProvider),
      grouping: ref.read(groupingProvider),
    );
    final index = indexOfName(name);
    _set(
      index == null
          ? [...state, preset]
          : [
              for (var i = 0; i < state.length; i++)
                if (i == index) preset else state[i],
            ],
    );
  }

  /// [index] 프리셋의 조건을 지금 걸린 조건으로 갈아끼운다(이름은 그대로).
  void overwriteAt(int index) {
    final current = state[index];
    _set([
      for (var i = 0; i < state.length; i++)
        if (i == index)
          current.copyWith(
            filter: ref.read(fileFilterProvider),
            sort: ref.read(fileSortProvider),
            grouping: ref.read(groupingProvider),
          )
        else
          state[i],
    ]);
  }

  void renameAt(int index, String name) {
    _set([
      for (var i = 0; i < state.length; i++)
        if (i == index) state[i].copyWith(name: name) else state[i],
    ]);
  }

  void removeAt(int index) {
    _set([
      for (var i = 0; i < state.length; i++)
        if (i != index) state[i],
    ]);
  }

  void reorder(int oldIndex, int newIndex) {
    final next = [...state];
    next.insert(newIndex, next.removeAt(oldIndex));
    _set(next);
  }

  /// [name]과 같은 이름을 가진 프리셋의 자리(없으면 null). 저장 다이얼로그가 덮어쓸지
  /// 물어볼 때와, 이름 변경이 다른 프리셋과 부딪히는지 볼 때 함께 쓴다.
  int? indexOfName(String name) {
    for (var i = 0; i < state.length; i++) {
      if (state[i].name == name) return i;
    }
    return null;
  }

  void _set(List<QueryPreset> next) {
    state = next;
    _dirty = true;
    // 저장 실패는 조용히 무시한다(다음 변경 때 다시 시도된다).
    _repo?.save(next);
  }
}

/// 지금 걸린 조건과 똑같은 프리셋의 자리(없으면 null). 그 캡슐을 활성으로 그려,
/// 지금 보고 있는 것이 어느 프리셋인지 보이게 한다.
final activeQueryPresetProvider = Provider<int?>((ref) {
  final presets = ref.watch(queryPresetsProvider);
  final filter = ref.watch(fileFilterProvider);
  final sort = ref.watch(fileSortProvider);
  final grouping = ref.watch(groupingProvider);
  for (var i = 0; i < presets.length; i++) {
    if (presets[i].matchesQuery(
      filter: filter,
      sort: sort,
      grouping: grouping,
    )) {
      return i;
    }
  }
  return null;
});
