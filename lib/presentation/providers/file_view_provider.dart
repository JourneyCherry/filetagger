import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings/view_settings_store.dart';
import '../../domain/entities/file_filter.dart';
import '../../domain/entities/file_grouping.dart';
import '../../domain/entities/file_sort.dart';
import '../../domain/entities/file_tree_node.dart';
import '../../domain/entities/folder_manage_mode.dart';
import '../../domain/entities/query_preset.dart';
import '../../domain/entities/system_tag.dart';
import '../../domain/entities/tag_definition.dart';
import '../../domain/entities/view_mode.dart';
import '../../domain/entities/workspace_view_settings.dart';
import '../../domain/entities/file_node.dart';
import '../../domain/repositories/view_settings_repository.dart';
import '../../domain/usecases/apply_query_preset.dart';
import '../../domain/usecases/build_grouped_tree.dart';
import '../../domain/usecases/folder_index_scope.dart';
import '../../domain/usecases/query_files.dart';
import '../../domain/usecases/tag_display_order.dart';
import '../common/flat_tree.dart';
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
    final validIds = _validIdsOf(defs);
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
          (k) =>
              k is FolderHierarchyGroupKey || validIds.contains(groupKeyId(k)),
        )
        .toList();
    // 썸네일 출처 우선순위에서 지워진 태그를 걷어낸다(기본 항목은 태그가 아니라 늘
    // 유효). 사라진 태그를 계속 가리키지 않도록.
    final sources = state.thumbnailSources;
    final keptSources = sources
        .where((s) => s == kDefaultThumbnailSourceId || validIds.contains(s))
        .toList();
    // 이름·부제 출처도 같은 이유로 정리한다(기본=노드 이름·경로는 태그가 아니라
    // 목록에 없다).
    final names = state.nameSources;
    final keptNames = names.where(validIds.contains).toList();
    final subtitles = state.subtitleSources;
    final keptSubtitles = subtitles.where(validIds.contains).toList();
    if (keptConditions.length == conditions.length &&
        keptKeys.length == keys.length &&
        keptOrder.length == order.length &&
        keptGroupKeys.length == groupKeys.length &&
        keptSources.length == sources.length &&
        keptNames.length == names.length &&
        keptSubtitles.length == subtitles.length) {
      return; // 사라진 참조 없음 — 그대로 둔다(불필요한 저장 방지).
    }
    _set(
      state.copyWith(
        filter: FileFilter(conditions: keptConditions),
        sort: FileSortOrder(keys: keptKeys),
        tagDisplayOrder: keptOrder,
        grouping: FileGrouping(keys: keptGroupKeys),
        thumbnailSources: keptSources,
        nameSources: keptNames,
        subtitleSources: keptSubtitles,
      ),
    );
  }

  /// 참조해도 되는 태그 정의 id 집합. 시스템 태그(계산 태그)는 항상 유효하다 — 그
  /// 참조 필터·정렬을 정리로 지우지 않는다(표시 여부 토글과 무관하게 필터·정렬은
  /// 계속 동작).
  Set<int> _validIdsOf(List<TagDefinition> defs) => {
    for (final t in SystemTag.values) t.id,
    for (final d in defs)
      if (d.id != null) d.id!,
  };

  /// 프리셋 한 벌을 통째로 건다 — **지금 걸린 필터·정렬·그룹과 이름·부제·썸네일 출처는
  /// 모두 지워지고** 프리셋의 것으로 대체된다(부분 병합 없음).
  ///
  /// 저장한 뒤 태그가 지워졌다면 그 조각은 걸 수 없어 빠지며, 그 수를 돌려준다(호출부가
  /// 사용자에게 알린다). 정의 목록이 아직 실리는 중이면 걸러 내지 않고 그대로 건다 —
  /// 빈 목록을 기준으로 걸렀다간 멀쩡한 조건이 몽땅 사라지기 때문이다(뒤늦게 정의가
  /// 실리면 [_reconcile]이 그때 정리한다).
  int applyPreset(QueryPreset preset) {
    final defs = ref.read(tagDefinitionsProvider);
    final resolved = defs.isLoading || defs.hasError
        ? QueryPresetApplication(
            filter: preset.filter,
            sort: preset.sort,
            grouping: preset.grouping,
            nameSources: preset.nameSources,
            subtitleSources: preset.subtitleSources,
            thumbnailSources: preset.thumbnailSources,
            droppedCount: 0,
          )
        : resolvePresetApplication(
            preset,
            _validIdsOf(defs.valueOrNull ?? const []),
          );
    _set(
      state.copyWith(
        filter: resolved.filter,
        sort: resolved.sort,
        grouping: resolved.grouping,
        nameSources: resolved.nameSources,
        subtitleSources: resolved.subtitleSources,
        thumbnailSources: resolved.thumbnailSources,
      ),
    );
    return resolved.droppedCount;
  }

  /// 노드 썸네일의 출처 우선순위를 통째로 갈아끼우고 저장한다(썸네일 태그 다이얼로그가
  /// 호출). 태그 id와 기본 항목([kDefaultThumbnailSourceId])을 앞이 높은 우선순위로 담는다.
  void updateThumbnailSources(List<int> sources) =>
      _set(state.copyWith(thumbnailSources: sources));

  /// 이름 칸에 보일 값의 출처 우선순위를 통째로 갈아끼우고 저장한다(이름 태그
  /// 다이얼로그가 호출). 어느 태그도 글자를 못 내면 노드 이름으로 폴백한다.
  void updateNameSources(List<int> sources) =>
      _set(state.copyWith(nameSources: sources));

  /// 부제 줄에 보일 값의 출처 우선순위를 통째로 갈아끼우고 저장한다(부제 태그
  /// 다이얼로그가 호출). 어느 태그도 글자를 못 내면 경로로 폴백한다.
  void updateSubtitleSources(List<int> sources) =>
      _set(state.copyWith(subtitleSources: sources));

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

  /// [keys]의 자리들을 한꺼번에 펼치고 저장한다(이미 펼쳐진 것은 그대로). 숨어 있는
  /// 노드를 드러내는 쪽(빠른 탐색·링크 이동)이 조상 사슬을 통째로 넘긴다 — 하나씩
  /// 토글하면 사슬 길이만큼 저장이 되풀이되고, 뒤집기라 이미 펼쳐진 자리를 도로 접는다.
  void expandFolders(Iterable<String> keys) {
    final next = {...state.expandedFolders};
    final before = next.length;
    next.addAll(keys);
    if (next.length == before) return; // 이미 다 펼쳐져 있어 저장할 것이 없다
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
    _set(state.copyWith(viewScales: {...state.viewScales, mode: clamped}));
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

/// 이름 칸에 보일 값의 출처 우선순위(보기 설정 파생, 앞이 높음). 비면 파일 이름.
final nameSourcesProvider = Provider<List<int>>(
  (ref) => ref.watch(viewSettingsProvider).nameSources,
);

/// 부제 줄에 보일 값의 출처 우선순위(보기 설정 파생, 앞이 높음). 비면 경로.
final subtitleSourcesProvider = Provider<List<int>>(
  (ref) => ref.watch(viewSettingsProvider).subtitleSources,
);

/// 썸네일 출처 우선순위(태그 id + 기본 항목, 앞이 높음).
final thumbnailSourcesProvider = Provider<List<int>>(
  (ref) => ref.watch(viewSettingsProvider).thumbnailSources,
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
  // 링크는 대상 이름 기준으로 정렬·필터되므로 이름 해석을 적용한 맵을 쓴다.
  final assignments = ref.watch(resolvedAssignmentsByFileProvider);
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
    for (final d in ref.watch(systemTagDefinitionsProvider)) d.id!: d,
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
  // 링크는 대상 이름 기준으로 필터·정렬·그룹되므로 이름 해석을 적용한 맵을 쓴다.
  final assignments = ref.watch(resolvedAssignmentsByFileProvider);
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

/// [fileTreeProvider]를 화면에 놓이는 순서의 평면 행으로 편 것.
///
/// 목록 렌더와 셸의 조작(범위·전체 선택, 키보드 커서 이동)이 **같은 결과**를 나눠
/// 쓴다 — 각자 펴면 키를 누를 때마다 트리를 다시 펴게 되고, 두 순서가 어긋날 여지도
/// 생긴다.
///
/// **필터는 펼침에 관여하지 않는다.** 접고 펴는 것은 사용자가 쥔 상태이고, 필터는
/// 목록을 줄일 뿐이다 — 조건을 걸었다고 전부 펴 버리면 접어 둔 그룹이 통째로 쏟아질
/// 뿐 아니라, 그 상태에서는 헤더를 눌러도 닫히지 않는다(강제 펼침이 저장된 상태를
/// 단락시킨다).
final flatTreeProvider = Provider<AsyncValue<FlatTree>>((ref) {
  final tree = ref.watch(fileTreeProvider);
  final expanded = ref.watch(expandedFoldersProvider);
  return tree.whenData(
    (roots) => flattenTree(roots, expandedFolders: expanded, expandAll: false),
  );
});

/// 표시 중인 트리에 남은 실제 노드 수(상태표시줄). 선택이 바뀔 때마다 트리를 다시
/// 세지 않도록 트리에서만 파생시킨다.
final visibleNodeCountProvider = Provider<int?>((ref) {
  final tree = ref.watch(fileTreeProvider).valueOrNull;
  return tree == null ? null : countTreeNodes(tree);
});

/// 인덱스에 실린 노드 수(필터·그룹을 거치기 **전**).
///
/// [visibleNodeCountProvider]와 갈라 두는 이유는 **"아직 보여 줄 것이 없다"와
/// "조건에 맞는 것이 없다"가 다른 상태**이기 때문이다. 스캔 표시를 띄울지는 앞의
/// 것으로만 갈라야 한다 — 뒤의 것으로 가르면 인덱스가 이미 차 있어도 지금 걸린
/// 조건이 아무것도 못 내는 순간(태그값 그룹은 폴더를 값 버킷에 담지 않아 폴더만
/// 있는 동안 그렇다) 목록이 스캔 표시에 가려진다. 조건이 아무것도 못 내는 것은
/// 목록이 제자리에서 알릴 일이다.
///
/// 스트림이 잠깐 다시 실리는 동안에도 직전 목록을 그대로 센다(`valueOrNull`은
/// 이전 값을 물려받는다) — 그 순간 목록이 통째로 사라지지 않게 하기 위함이다.
final indexedNodeCountProvider = Provider<int>((ref) {
  return ref.watch(fileNodesProvider).valueOrNull?.length ?? 0;
});
