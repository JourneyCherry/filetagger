import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings/view_settings_store.dart';
import '../../domain/entities/file_filter.dart';
import '../../domain/entities/file_sort.dart';
import '../../domain/entities/file_tree_node.dart';
import '../../domain/entities/folder_manage_mode.dart';
import '../../domain/entities/system_tag.dart';
import '../../domain/entities/tag_definition.dart';
import '../../domain/entities/workspace_view_settings.dart';
import '../../domain/repositories/view_settings_repository.dart';
import '../../domain/usecases/build_file_tree.dart';
import '../../domain/usecases/folder_index_scope.dart';
import 'file_node_provider.dart';
import 'system_tag_provider.dart';
import 'tag_provider.dart';
import 'workspace_provider.dart';

/// 현재 워크스페이스의 보기 설정 저장소(`.filetagger/` JSON). 열린 폴더가 없으면 null.
final viewSettingsRepositoryProvider = Provider<ViewSettingsRepository?>((ref) {
  final root = ref.watch(workspaceRootProvider);
  if (root == null) return null;
  return JsonViewSettingsStore(root);
});

/// 필터·정렬 상태의 단일 출처.
///
/// 워크스페이스를 열면 저장소에서 설정을 비동기로 불러오고(그전까지는 기본값),
/// 바뀔 때마다 다시 저장한다. 폴더를 바꾸면 저장소가 교체되어 build가 다시 돌아
/// 새 폴더의 설정을 불러온다.
final viewSettingsProvider =
    NotifierProvider<ViewSettingsNotifier, WorkspaceViewSettings>(
      ViewSettingsNotifier.new,
    );

class ViewSettingsNotifier extends Notifier<WorkspaceViewSettings> {
  ViewSettingsRepository? _repo;

  /// 디스크 로드가 끝났는지. 로드 전에는 정리(reconcile)를 미룬다 — 아직 불러오지
  /// 않은 조건을 "없는 태그"로 오인해 지우고 저장하는 사고를 막기 위함.
  bool _loaded = false;

  @override
  WorkspaceViewSettings build() {
    final repo = ref.watch(viewSettingsRepositoryProvider);
    _repo = repo;
    _loaded = false;
    // 태그 정의가 바뀌면(삭제 등) 사라진 태그를 참조하는 필터·정렬 조건을 정리한다.
    ref.listen(tagDefinitionsProvider, (_, next) {
      final defs = next.valueOrNull;
      if (defs != null) _reconcile(defs);
    });
    if (repo != null) _load(repo);
    return const WorkspaceViewSettings();
  }

  Future<void> _load(ViewSettingsRepository repo) async {
    final loaded = await repo.load();
    // 로드 도중 워크스페이스가 바뀌어 저장소가 교체됐으면 결과를 버린다.
    if (_repo != repo) return;
    state = loaded;
    _loaded = true;
    // 로드가 태그 정의보다 늦었을 수 있으니, 현재 정의 기준으로 즉시 정리한다.
    final defs = ref.read(tagDefinitionsProvider).valueOrNull;
    if (defs != null) _reconcile(defs);
  }

  /// 유효한 태그 정의 집합에 없는 조건·정렬 단계를 걷어낸다. 사라진 태그의 부여
  /// 기록은 FK cascade로 이미 지워지므로, 남는 것은 보기 설정의 참조뿐이다.
  void _reconcile(List<TagDefinition> defs) {
    if (!_loaded) return;
    final validIds = {
      // 시스템 태그(계산 태그)는 항상 유효하다 — 그 참조 필터·정렬을 정리로 지우지
      // 않는다(표시 여부 토글과 무관하게 필터·정렬은 계속 동작).
      for (final t in SystemTag.values) t.id,
      for (final d in defs)
        if (d.id != null) d.id!,
    };
    final conditions = state.filter.conditions;
    final keys = state.sort.keys;
    final keptConditions = conditions
        .where((c) => validIds.contains(c.tagDefinitionId))
        .toList();
    final keptKeys = keys
        .where((k) => validIds.contains(k.tagDefinitionId))
        .toList();
    if (keptConditions.length == conditions.length &&
        keptKeys.length == keys.length) {
      return; // 사라진 참조 없음 — 그대로 둔다(불필요한 저장 방지).
    }
    _set(
      state.copyWith(
        filter: FileFilter(conditions: keptConditions),
        sort: FileSortOrder(keys: keptKeys),
      ),
    );
  }

  void updateFilter(FileFilter filter) => _set(state.copyWith(filter: filter));

  void updateSort(FileSortOrder sort) => _set(state.copyWith(sort: sort));

  /// 시스템 태그 [id]를 목록·프리뷰 칩으로 표시할지 토글·저장한다(값 계산·필터·
  /// 정렬은 표시 여부와 무관하게 늘 동작).
  void updateSystemTagVisibility(int id, bool visible) {
    final next = {...state.visibleSystemTagIds};
    if (visible) {
      next.add(id);
    } else {
      next.remove(id);
    }
    _set(state.copyWith(visibleSystemTagIds: next));
  }

  /// 프리뷰 분할 비율을 갱신·저장한다(분할선 드래그가 끝났을 때 호출).
  void updatePreviewRatio(double ratio) =>
      _set(state.copyWith(previewRatio: ratio));

  /// 루트 폴더의 관리 방식(관리/재귀 관리)을 갱신·저장한다. 호출부가 이어서
  /// 재스캔해 새 범위를 반영한다.
  void updateRootManageMode(FolderManageMode mode) =>
      _set(state.copyWith(rootManageMode: mode));

  void _set(WorkspaceViewSettings next) {
    state = next;
    // 저장 실패는 조용히 무시한다(다음 변경 때 다시 시도된다).
    _repo?.save(next);
  }
}

/// 현재 적용 중인 태그 조합 필터. 쓰기는 [viewSettingsProvider]를 통한다.
final fileFilterProvider = Provider<FileFilter>(
  (ref) => ref.watch(viewSettingsProvider).filter,
);

/// 현재 정렬 순서(비면 이름순). 쓰기는 [viewSettingsProvider]를 통한다.
final fileSortProvider = Provider<FileSortOrder>(
  (ref) => ref.watch(viewSettingsProvider).sort,
);

/// 루트 폴더의 관리 방식. 쓰기는 [viewSettingsProvider]를 통한다.
final rootManageModeProvider = Provider<FolderManageMode>(
  (ref) => ref.watch(viewSettingsProvider).rootManageMode,
);

/// 폴더 경로 → effective 관리 모드(상속 반영). 목록 타일 메뉴·힌트가 각 폴더의
/// 실제 관리 상태를 표시하는 데 쓴다. override(저장값)와 루트 모드로 계산한다.
final folderResolvedModesProvider = Provider<Map<String, FolderManageMode>>((
  ref,
) {
  final nodes = ref.watch(fileNodesProvider).valueOrNull ?? const [];
  final rootMode = ref.watch(rootManageModeProvider);
  return resolveManageModes(nodes, rootMode);
});

/// 태그 정의를 id로 빠르게 찾기 위한 조회 맵. 정렬 시 valueType 조회 등에서
/// 시스템 태그도 찾을 수 있도록 시스템 정의를 함께 담는다.
final definitionsByIdProvider = Provider<Map<int, TagDefinition>>((ref) {
  final defs = ref.watch(tagDefinitionsProvider).valueOrNull ?? const [];
  return {
    for (final d in systemTagDefinitions) d.id!: d,
    for (final d in defs)
      if (d.id != null) d.id!: d,
  };
});

/// 필터·정렬을 적용한 표시용 **계층 트리**(그룹 UI). 형제끼리 정렬하고, 필터가
/// 걸리면 매치된 노드와 그 조상만 남긴다. 로딩/에러 상태는 그대로 전달한다.
final fileTreeProvider = Provider<AsyncValue<List<FileTreeNode>>>((ref) {
  final nodes = ref.watch(fileNodesProvider);
  final assignments = ref.watch(effectiveAssignmentsByFileProvider);
  final definitionsById = ref.watch(definitionsByIdProvider);
  final filter = ref.watch(fileFilterProvider);
  final sort = ref.watch(fileSortProvider);

  return nodes.whenData(
    (files) => const BuildFileTree()(
      files: files,
      assignmentsByFile: assignments,
      filter: filter,
      sort: sort,
      definitionsById: definitionsById,
    ),
  );
});
