import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings/view_settings_store.dart';
import '../../domain/entities/file_filter.dart';
import '../../domain/entities/file_grouping.dart';
import '../../domain/entities/file_sort.dart';
import '../../domain/entities/file_tree_node.dart';
import '../../domain/entities/folder_manage_mode.dart';
import '../../domain/entities/system_tag.dart';
import '../../domain/entities/tag_definition.dart';
import '../../domain/entities/view_mode.dart';
import '../../domain/entities/workspace_view_settings.dart';
import '../../domain/entities/file_node.dart';
import '../../domain/repositories/view_settings_repository.dart';
import '../../domain/usecases/build_grouped_tree.dart';
import '../../domain/usecases/folder_index_scope.dart';
import '../../domain/usecases/query_files.dart';
import '../../domain/usecases/tag_display_order.dart';
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
    ref.listen(tagDefinitionsProvider, (_, next) => _reconcileWith(next));
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
    _reconcileWith(ref.read(tagDefinitionsProvider));
  }

  /// 정의 목록이 **다 실린 뒤에만** 정리한다.
  ///
  /// 아직 실리는 중이면 그 자리엔 직전 워크스페이스의(또는 폴더를 열기 전의 빈)
  /// 목록이 남아 있다. 그걸 기준으로 정리하면 멀쩡한 조건이 "없는 태그"로 몰려
  /// 지워지고, 지운 결과가 그대로 저장돼 버린다.
  void _reconcileWith(AsyncValue<List<TagDefinition>> defs) {
    if (defs.isLoading || defs.hasError) return;
    final value = defs.valueOrNull;
    if (value != null) _reconcile(value);
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
    final order = state.tagDisplayOrder;
    final groupKeys = state.grouping.keys;
    final keptConditions = conditions
        .where((c) => validIds.contains(c.tagDefinitionId))
        .toList();
    final keptKeys = keys
        .where((k) => validIds.contains(k.tagDefinitionId))
        .toList();
    final keptOrder = order.where(validIds.contains).toList();
    // 폴더 계층 키는 실제 태그가 아니라 늘 유효하다 — 태그 키만 삭제 여부를 본다.
    final keptGroupKeys = groupKeys
        .where(
          (k) => k is FolderHierarchyGroupKey || validIds.contains(groupKeyId(k)),
        )
        .toList();
    if (keptConditions.length == conditions.length &&
        keptKeys.length == keys.length &&
        keptOrder.length == order.length &&
        keptGroupKeys.length == groupKeys.length) {
      return; // 사라진 참조 없음 — 그대로 둔다(불필요한 저장 방지).
    }
    _set(
      state.copyWith(
        filter: FileFilter(conditions: keptConditions),
        sort: FileSortOrder(keys: keptKeys),
        tagDisplayOrder: keptOrder,
        grouping: FileGrouping(keys: keptGroupKeys),
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

  /// 사용자 태그 [id]를 목록·프리뷰 칩으로 표시할지 토글·저장한다(시스템 태그와 반대로
  /// 기본은 표시라 감춤 집합에서 더하고 뺀다). 값 계산·필터·정렬·그룹은 늘 동작.
  void updateUserTagVisibility(int id, bool visible) {
    final next = {...state.hiddenTagIds};
    if (visible) {
      next.remove(id);
    } else {
      next.add(id);
    }
    _set(state.copyWith(hiddenTagIds: next));
  }

  /// 태그 칩의 표시 순서(정의 id 나열)를 갱신·저장한다. 여기 없는 태그는 뒤에
  /// 붙으므로 부분 목록이어도 된다.
  void updateTagDisplayOrder(List<int> order) =>
      _set(state.copyWith(tagDisplayOrder: order));

  /// 그룹 트리에서 폴더 [path]의 펼침/접힘을 뒤집고 저장한다(세션을 넘겨 유지).
  void toggleExpandedFolder(String path) {
    final next = {...state.expandedFolders};
    if (!next.remove(path)) next.add(path);
    _set(state.copyWith(expandedFolders: next));
  }

  /// 그룹 단계를 통째로 갈아끼우고 저장한다(그룹 줄 편집이 호출).
  void updateGrouping(FileGrouping grouping) =>
      _set(state.copyWith(grouping: grouping));

  /// 파일 목록의 보기 모드(목록/아이콘/자세히)를 갈아끼우고 저장한다.
  void updateViewMode(ViewMode mode) => _set(state.copyWith(viewMode: mode));

  /// 보기 모드 [mode]의 크기 배율을 [scale]로 바꾸고 저장한다(허용 범위로 가둔다).
  /// 배율이 그대로면 저장하지 않아 휠 끝(범위 한계)에서 헛저장을 막는다.
  void updateViewScale(ViewMode mode, double scale) {
    final clamped = scale.clamp(kViewScaleMin, kViewScaleMax);
    if (state.scaleFor(mode) == clamped) return;
    _set(
      state.copyWith(viewScales: {...state.viewScales, mode: clamped}),
    );
  }

  /// 자세히 테이블 전용 정렬을 갈아끼우고 저장한다(전역 정렬과 별개).
  void updateDetailSort(FileSortOrder sort) =>
      _set(state.copyWith(detailSort: sort));

  /// 자세히 컬럼 [id]의 폭을 [width]로 바꾸고 저장한다(허용 범위로 가둔다).
  void updateDetailColumnWidth(int id, double width) {
    final clamped = width.clamp(kDetailColumnWidthMin, kDetailColumnWidthMax);
    _set(
      state.copyWith(
        detailColumnWidths: {...state.detailColumnWidths, id: clamped},
      ),
    );
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

/// 태그 칩의 표시 순서(정의 id 나열). 쓰기는 [viewSettingsProvider]를 통한다.
final tagDisplayOrderProvider = Provider<List<int>>(
  (ref) => ref.watch(viewSettingsProvider).tagDisplayOrder,
);

/// 그룹 트리에서 펼쳐 놓은 폴더 경로들. 쓰기는 [viewSettingsProvider]를 통한다.
final expandedFoldersProvider = Provider<Set<String>>(
  (ref) => ref.watch(viewSettingsProvider).expandedFolders,
);

/// 현재 그룹 단계. 쓰기는 [viewSettingsProvider]를 통한다.
final groupingProvider = Provider<FileGrouping>(
  (ref) => ref.watch(viewSettingsProvider).grouping,
);

/// 현재 파일 목록 보기 모드. 쓰기는 [viewSettingsProvider]를 통한다.
final viewModeProvider = Provider<ViewMode>(
  (ref) => ref.watch(viewSettingsProvider).viewMode,
);

/// 현재 보기 모드의 크기 배율(Ctrl/⌘+휠 zoom). 모드가 바뀌면 그 모드의 배율로
/// 갈린다. 배율만 바뀌면 목록만 다시 그려지도록 좁은 값으로 노출한다.
final currentViewScaleProvider = Provider<double>((ref) {
  final settings = ref.watch(viewSettingsProvider);
  return settings.scaleFor(settings.viewMode);
});

/// 자세히 테이블 전용 정렬. 쓰기는 [viewSettingsProvider]를 통한다.
final detailSortProvider = Provider<FileSortOrder>(
  (ref) => ref.watch(viewSettingsProvider).detailSort,
);

/// 자세히 컬럼 폭(태그 id → 폭). 쓰기는 [viewSettingsProvider]를 통한다.
final detailColumnWidthsProvider = Provider<Map<int, double>>(
  (ref) => ref.watch(viewSettingsProvider).detailColumnWidths,
);

/// 자세히 테이블의 태그 컬럼(고정 '이름' 컬럼 제외). 모든 태그(사용자+시스템)를
/// 대상으로 하되, 이름은 고정 컬럼이 맡으므로 파일 이름 시스템 태그는 뺀다. 좌우
/// 순서는 목록·프리뷰와 공유하는 [effectiveTagDisplayOrderProvider]를 따른다.
final detailTagColumnsProvider = Provider<List<TagDefinition>>((ref) {
  final defs = ref.watch(pickableTagDefinitionsProvider);
  final order = ref.watch(effectiveTagDisplayOrderProvider);
  final columns = [
    for (final d in defs)
      if (d.id != SystemTag.fileName.id) d,
  ];
  return orderTagDefinitions(columns, order);
});

/// 자세히 테이블의 행: 그룹화를 무시하고 필터만 적용해 파일·폴더를 평면 나열하되
/// 자세히 전용 정렬로 정렬한다(전역 정렬·그룹과 별개). 정렬 비교기는 목록과 같은
/// [QueryFiles]를 재사용하고 정렬 키 출처만 [detailSortProvider]로 바꾼다.
final detailRowsProvider = Provider<AsyncValue<List<FileNode>>>((ref) {
  final nodes = ref.watch(fileNodesProvider);
  final assignments = ref.watch(effectiveAssignmentsByFileProvider);
  final defsById = ref.watch(definitionsByIdProvider);
  final filter = ref.watch(fileFilterProvider);
  final sort = ref.watch(detailSortProvider);
  return nodes.whenData(
    (files) => const QueryFiles()(
      files: files,
      assignmentsByFile: assignments,
      filter: filter,
      sort: sort,
      definitionsById: defsById,
    ),
  );
});

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

/// 필터를 적용한 뒤 그룹 단계로 묶은 표시용 트리. 형제끼리 정렬하고, 폴더 계층
/// 그룹이면 매치된 노드와 그 조상만 남긴다. 로딩/에러 상태는 그대로 전달한다.
///
/// 그룹이 비면 계층 없이 평면 리프 목록이고(옛 "폴더 그룹화 끔"), 폴더 계층 한
/// 단계면 옛 폴더 트리, 태그 키가 있으면 값별 [GroupHeaderNode] 버킷으로 묶인다.
final fileTreeProvider = Provider<AsyncValue<List<TreeItem>>>((ref) {
  final nodes = ref.watch(fileNodesProvider);
  final assignments = ref.watch(effectiveAssignmentsByFileProvider);
  final definitionsById = ref.watch(definitionsByIdProvider);
  final filter = ref.watch(fileFilterProvider);
  final sort = ref.watch(fileSortProvider);
  final grouping = ref.watch(groupingProvider);

  return nodes.whenData(
    (files) => const BuildGroupedTree()(
      files: files,
      assignmentsByFile: assignments,
      filter: filter,
      grouping: grouping,
      sort: sort,
      definitionsById: definitionsById,
    ),
  );
});
