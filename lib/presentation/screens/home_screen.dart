import 'dart:io' show FileSystemException;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/platform.dart';
import '../../data/db/schema_probe.dart';
import '../../data/fs/node_renamer.dart';
import '../../data/fs/reveal_in_file_manager.dart';
import '../../domain/entities/assigned_tag.dart';
import '../../domain/entities/file_node.dart';
import '../../domain/entities/folder_manage_mode.dart';
import '../../domain/entities/nested_merge_resolution.dart';
import '../../domain/entities/system_tag.dart';
import '../../domain/usecases/folder_index_scope.dart';
import '../commands/app_commands.dart';
import '../commands/command_scope.dart';
import '../common/file_list_view.dart';
import '../common/pointer_presence.dart';
import '../common/preview_split.dart';
import '../common/selection_controller.dart';
import '../providers/database_provider.dart';
import '../providers/file_node_provider.dart';
import '../providers/file_view_provider.dart';
import '../providers/nested_workspace_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/tag_provider.dart';
import '../providers/workspace_provider.dart';
import '../shells/command_context_menu.dart';
import '../shells/desktop_shell.dart';
import '../shells/mobile_sheets.dart';
import '../shells/mobile_shell.dart';
import '../widgets/folder_manage_menu.dart';
import '../widgets/preview_pane.dart';
import '../widgets/reconnect_dialog.dart';
import '../widgets/tag_assign_dialog.dart';
import '../widgets/tag_manage_dialog.dart';
import '../widgets/tag_order_dialog.dart';
import '../widgets/tag_value_prompt.dart';
import 'tag_management_screen.dart';

/// 관리 폴더를 열어 스캔한 파일/폴더 목록을 보여주는 메인 화면.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _scanning = false;
  bool _picking = false;

  /// watcher가 트리거한 백그라운드 재스캔이 진행 중인지. 전면 스피너를 띄우지
  /// 않으며(_scanning과 별개), 재스캔 중복 실행을 막는 데 쓴다.
  bool _backgroundScanning = false;

  /// 프리뷰 창을 목록 옆(또는 위)에 표시할지. 보기 토글로 전환한다.
  bool _previewVisible = true;

  /// 도구모음의 필터·정렬 조건 줄을 보일지(데스크톱 '보기' 메뉴 토글). 숨겨도
  /// 조건 자체는 그대로 적용된다 — 자리만 접는다.
  bool _filterBarVisible = true;
  bool _sortBarVisible = true;

  /// 목록 행에서 태그를 프리뷰처럼 바로 고칠 수 있게 할지(데스크톱 '보기' 메뉴 토글).
  bool _listEditEnabled = false;

  /// 모바일 선택 모드(롱프레스로 진입, 선택이 비면 빠져나온다). 이 동안 탭은
  /// 프리뷰 대신 선택 토글이 되고 행 끝에 체크박스가 붙는다. 데스크톱은 보조키로
  /// 다중 선택하므로 늘 false다.
  bool _selectionMode = false;

  /// 폴더 열기·스캔 등 앱을 잠가야 하는 작업이 진행 중인지. 이 동안에는 폴더
  /// 열기·재스캔·최근 폴더 탭을 막아 네이티브 다이얼로그가 모달처럼 동작하게 한다.
  bool get _busy => _scanning || _picking;

  Future<void> _openFolder() async {
    if (_busy) return;
    // 피커가 닫힐 때까지 트리거를 비활성화해 재진입(중복 다이얼로그)을 막는다.
    setState(() => _picking = true);
    String? path;
    try {
      path = await getDirectoryPath();
    } finally {
      if (mounted) setState(() => _picking = false);
    }
    if (path == null) return;
    await _openWorkspace(path);
  }

  /// 폴더를 현재 워크스페이스로 열고, 최근 목록을 갱신한 뒤 스캔한다.
  Future<void> _openWorkspace(String path) async {
    _clearSelection();
    ref.read(workspaceRootProvider.notifier).state = path;
    await ref.read(recentFoldersProvider.notifier).touch(path);
    await _scan();
  }

  /// 현재 열린 폴더를 닫고 최근 폴더 목록(메인)으로 돌아간다. 워크스페이스 루트를
  /// 비우면 DB·목록·보기 설정(펼침 상태 포함) provider가 자동으로 해제·초기화된다.
  /// 화면 로컬 상태(선택)는 여기서 함께 비운다. 스캔 중에는 무시한다.
  void _closeWorkspace() {
    if (_busy) return;
    _clearSelection();
    ref.read(workspaceRootProvider.notifier).state = null;
  }

  Future<void> _scan() async {
    final usecase = ref.read(scanWorkspaceProvider);
    final root = ref.read(workspaceRootProvider);
    if (usecase == null || root == null) return;

    final rootMode = ref.read(rootManageModeProvider);
    setState(() => _scanning = true);
    try {
      final result = await usecase(root, rootManageMode: rootMode);
      if (!mounted) return;
      await _reconcileNestedDecisions(result.nestedFiletaggerDirs);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('스캔에 실패했습니다: $e')));
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  /// watcher가 감지한 디스크 변화에 맞춰 조용히 재스캔한다. 전면 스피너를 띄우지
  /// 않고(목록은 Drift 스트림으로 갱신됨), 병합 프롬프트도 반복하지 않는다.
  /// 다른 스캔이 진행 중이면 건너뛴다(다음 변화 신호가 다시 트리거한다).
  Future<void> _backgroundScan() async {
    if (_scanning || _backgroundScanning) return;
    final usecase = ref.read(scanWorkspaceProvider);
    final root = ref.read(workspaceRootProvider);
    if (usecase == null || root == null) return;

    final rootMode = ref.read(rootManageModeProvider);
    _backgroundScanning = true;
    try {
      await usecase(root, rootManageMode: rootMode);
    } catch (_) {
      // 백그라운드 재스캔 실패는 조용히 무시한다(다음 변화 때 재시도).
    } finally {
      _backgroundScanning = false;
    }
  }

  void _clearSelection() {
    ref.read(selectionControllerProvider.notifier).clear();
    _exitSelectionMode();
  }

  void _exitSelectionMode() {
    if (_selectionMode && mounted) setState(() => _selectionMode = false);
  }

  /// 선택을 개별 토글한다(체크박스·롱프레스·Ctrl 클릭). 마지막 선택이 풀리면
  /// 모바일 선택 모드에서 함께 빠져나온다.
  void _toggleNode(int id) {
    ref.read(selectionControllerProvider.notifier).toggle(id);
    if (ref.read(selectionControllerProvider).isEmpty) _exitSelectionMode();
  }

  /// 폴더 펼침/접힘을 뒤집는다(워크스페이스 보기 설정에 저장된다).
  void _toggleExpand(String path) =>
      ref.read(viewSettingsProvider.notifier).toggleExpandedFolder(path);

  /// 표시 중인(펼쳐진) 모든 행을 선택한다. 표시 순서는 목록 렌더와 같은
  /// [flattenTree]로 구해 Shift 범위 선택과 어긋나지 않게 한다.
  void _selectAll() {
    final roots = ref.read(fileTreeProvider).valueOrNull;
    if (roots == null) return;
    final rows = flattenTree(
      roots,
      expandedFolders: ref.read(expandedFoldersProvider),
      expandAll: !ref.read(fileFilterProvider).isEmpty,
    );
    final ids = [
      for (final r in rows)
        if (r.node.id != null) r.node.id!,
    ];
    ref.read(selectionControllerProvider.notifier).selectAll(ids);
    if (ids.isEmpty) {
      _exitSelectionMode();
    } else if (!isDesktopPlatform && !_selectionMode) {
      setState(() => _selectionMode = true);
    }
  }

  /// 선택한 단일 항목을 활성화한다(Enter·컨텍스트 메뉴). 폴더는 펼침/접힘을
  /// 토글하고, 파일은 프리뷰를 띄운다(이미 보이면 그대로 둔다).
  void _activateSelected() {
    final node = _singleSelectedNode;
    if (node == null) return;
    if (node.isDirectory && !node.isMissing) {
      _toggleExpand(node.path);
    } else {
      _showPreview(node);
    }
  }

  /// [node]의 프리뷰를 드러낸다. 분할이 가능한 폭이면 분할 창을 켜고, 좁으면
  /// 바텀시트로 띄운다.
  void _showPreview(FileNode node) {
    if (_splitAllowed) {
      if (!_previewVisible) setState(() => _previewVisible = true);
      return;
    }
    _showPreviewSheet(node);
  }

  Future<void> _showPreviewSheet(FileNode node) {
    return showPreviewSheet(
      context,
      preview: PreviewPane(
        node: node,
        selectedCount: 1,
        onEditAssignment: _editAssignmentFromList,
        onRemoveAssignment: _removeAssignment,
        onAddTag: () => _addTagToNode(node),
      ),
    );
  }

  /// 프리뷰를 목록 옆에 나란히 둘 만한 폭인지. 데스크톱은 창을 줄여도 분할을
  /// 유지한다(분할선을 끌어 프리뷰를 접을 수 있으므로).
  bool get _splitAllowed =>
      isDesktopPlatform || prefersSplitPane(MediaQuery.sizeOf(context).width);

  /// 분할 프리뷰가 지금 화면에 떠 있는지(좁은 폭에서는 시트가 대신한다).
  bool get _splitVisible => _previewVisible && _splitAllowed;

  /// '프리뷰 보기' 명령. 분할을 쓸 수 없는 폭에서는 단일 선택의 프리뷰 시트를 연다.
  void _togglePreview() {
    if (!_splitAllowed) {
      final node = _singleSelectedNode;
      if (node != null) _showPreviewSheet(node);
      return;
    }
    setState(() => _previewVisible = !_previewVisible);
  }

  /// 도구모음의 조건 줄을 접었다 편다. 조건은 그대로 적용된 채 자리만 감춘다.
  void _toggleFilterBar() =>
      setState(() => _filterBarVisible = !_filterBarVisible);

  void _toggleSortBar() => setState(() => _sortBarVisible = !_sortBarVisible);

  /// 목록 행의 태그를 프리뷰처럼 바로 고칠 수 있게 켜고 끈다.
  void _toggleListEdit() =>
      setState(() => _listEditEnabled = !_listEditEnabled);

  /// 목록의 폴더 묶기(계층 그룹화)를 켜고 끈다. 워크스페이스 설정에 저장된다.
  void _toggleGrouping() =>
      ref.read(viewSettingsProvider.notifier).toggleGroupByFolder();

  /// 행 탭/클릭 해석. 보조키가 눌려 있으면 플랫폼과 무관하게 탐색기식으로 읽는다
  /// (Shift=범위, Ctrl/Cmd=개별 토글) — 모바일에 하드웨어 키보드를 붙인 경우의
  /// 입력 적응이다. 보조키가 없으면 데스크톱은 단일 선택, 모바일은 선택 모드일 때만
  /// 토글하고 아니면 단일 선택 후 프리뷰를 연다. 선택 상태 변경은
  /// [SelectionController]에 위임한다.
  void _onTapNode(List<FileNode> items, int index) {
    final node = items[index];
    final id = node.id;
    if (id == null) return;
    final keys = HardwareKeyboard.instance;
    final controller = ref.read(selectionControllerProvider.notifier);

    if (keys.isShiftPressed) {
      controller.selectRange(_orderedIdsOf(items), id);
      return;
    }
    if (keys.isControlPressed || keys.isMetaPressed) {
      _toggleNode(id);
      return;
    }
    if (_selectionMode) {
      _toggleNode(id);
      return;
    }
    controller.selectSingle(id);
    if (!isDesktopPlatform && !node.isDirectory) _showPreview(node);
  }

  /// 행 롱프레스: 선택 모드로 들어가며 그 행을 선택에 넣는다(모바일 전용).
  void _onLongPressNode(List<FileNode> items, int index) {
    final id = items[index].id;
    if (id == null) return;
    if (!_selectionMode) setState(() => _selectionMode = true);
    _toggleNode(id);
  }

  List<int> _orderedIdsOf(List<FileNode> items) => [
    for (final n in items)
      if (n.id != null) n.id!,
  ];

  /// 행 우클릭: 선택 밖의 행이면 그 행만 선택한 뒤(탐색기와 같은 관용) 새 선택
  /// 기준으로 명령 활성 상태를 다시 구해 컨텍스트 메뉴를 띄운다. 우클릭한 행이
  /// 폴더면 관리 방식 항목을 메뉴 끝에 이어 붙인다(체크 = 상속 반영 모드).
  Future<void> _onSecondaryTapNode(
    List<FileNode> items,
    int index,
    Offset globalPosition,
  ) async {
    final node = items[index];
    final id = node.id;
    if (id == null) return;
    final controller = ref.read(selectionControllerProvider.notifier);
    if (!ref.read(selectionControllerProvider).contains(id)) {
      controller.selectSingle(id);
    }

    final handlers = _handlers(
      ref.read(selectionControllerProvider),
      ref.read(workspaceRootProvider) != null,
    );
    final missing = _singleMissingSelected != null;
    final resolved = _resolvedModeOf(node);
    if (!mounted) return;
    await showCommandContextMenu(
      context: context,
      globalPosition: globalPosition,
      handlers: handlers,
      items: [
        AppCommandId.activateNode,
        null,
        // 연결 끊긴 노드 하나면 태그 부여 대신 원본 찾기로 안내한다.
        if (missing) AppCommandId.reconnect else AppCommandId.assignTags,
        AppCommandId.revealInFileManager,
        null,
        AppCommandId.selectAll,
        AppCommandId.clearSelection,
      ],
      extraItems: resolved == null
          ? const []
          : [
              const PopupMenuDivider(),
              ...folderManageMenuItems<AppCommandId>(
                resolved: resolved,
                onSelected: (action) => _onFolderManage(node, resolved, action),
              ),
            ],
    );
  }

  /// 선택이 정확히 하나면 그 노드. 아니면 null.
  FileNode? get _singleSelectedNode {
    final single = ref.read(selectionControllerProvider).singleOrNull;
    if (single == null) return null;
    final items = ref.read(fileNodesProvider).valueOrNull ?? const [];
    final matches = items.where((n) => n.id == single);
    return matches.isEmpty ? null : matches.first;
  }

  /// 선택이 정확히 연결 끊긴(보존) 노드 하나면 그 노드를 반환한다. 이때
  /// '태그 부여' 자리가 '원본 파일 찾기'로 바뀐다.
  FileNode? get _singleMissingSelected {
    final node = _singleSelectedNode;
    return node != null && node.isMissing ? node : null;
  }

  /// 선택이 정확히 디스크에 실재하는 노드 하나면 그 노드. 탐색기에서 열기처럼
  /// 실제 파일을 필요로 하는 명령의 활성 조건이다.
  FileNode? get _singleExistingSelected {
    final node = _singleSelectedNode;
    return node != null && !node.isMissing ? node : null;
  }

  /// 선택한 항목의 위치를 OS 파일 관리자에서 연다(Windows 탐색기는 항목을 고른 채).
  Future<void> _revealSelected() async {
    final node = _singleExistingSelected;
    final root = ref.read(workspaceRootProvider);
    if (node == null || root == null) return;
    try {
      await const FileManagerRevealer().reveal(
        workspaceRoot: root,
        relPath: node.path,
      );
    } catch (e) {
      _showSnack('탐색기에서 열지 못했습니다: $e');
    }
  }

  /// 보존 노드의 원본 파일을 사용자가 골라 태그를 수동 재연결한다. 후보는
  /// 태그가 하나도 없는 실제(연결 안 끊긴) 노드다.
  Future<void> _reconnectSelected() async {
    final missing = _singleMissingSelected;
    if (missing == null || missing.id == null) return;

    final items = ref.read(fileNodesProvider).valueOrNull ?? const [];
    final assignmentsByFile =
        ref.read(assignmentsByFileProvider).valueOrNull ?? const {};
    final candidates = items
        .where(
          (n) =>
              !n.isMissing &&
              n.id != null &&
              (assignmentsByFile[n.id] ?? const []).isEmpty,
        )
        .toList();

    final action = await showReconnectDialog(
      context,
      missing: missing,
      candidates: candidates,
    );
    final repo = ref.read(fileNodeRepositoryProvider);
    if (repo == null) return;
    switch (action) {
      case null:
        return;
      case ReconnectToTarget(:final target):
        if (target.id == null) return;
        await repo.reconnectNode(
          missingNodeId: missing.id!,
          targetNodeId: target.id!,
        );
      case ReconnectRemove():
        await repo.removeNode(missing.id!);
    }
    if (mounted) _clearSelection();
  }

  Future<void> _assignToSelection() async {
    final selection = ref.read(selectionControllerProvider);
    if (selection.isEmpty) return;
    final ids = selection.selectedIds.toList();
    final items = ref.read(fileNodesProvider).valueOrNull ?? const [];
    String title;
    if (ids.length == 1) {
      final matches = items.where((n) => n.id == ids.first);
      title = matches.isEmpty ? '파일 1개' : matches.first.name;
    } else {
      title = '${ids.length}개 파일';
    }
    await showTagAssignDialog(context, fileNodeIds: ids, title: title);
  }

  /// 목록의 태그 칩을 눌러 그 부여 기록의 값을 바로 수정한다(다이얼로그 없이).
  /// 시스템 태그면 사용자 태그 편집 경로로 가지 않고, 수정 가능한 '파일 이름'만
  /// rename 흐름으로 넘긴다(읽기전용 시스템 태그는 애초에 눌러지지 않는다).
  Future<void> _editAssignmentFromList(AssignedTag a) async {
    if (isSystemTagId(a.tagDefinitionId)) {
      if (systemTagById(a.tagDefinitionId) == SystemTag.fileName) {
        await _renameNodeById(a.assignment.fileNodeId);
      }
      return;
    }
    final result = await promptTagValue(
      context,
      a.definition,
      initial: a.value,
    );
    if (result == null) return;
    final assignmentId = a.assignment.id;
    if (assignmentId == null) return;
    await ref
        .read(tagRepositoryProvider)
        ?.updateAssignmentValue(
          assignmentId: assignmentId,
          value: result.value,
        );
  }

  /// '파일 이름' 시스템 태그 편집: 새 이름을 받아 디스크에서 rename하고 인덱스
  /// 경로를 맞춘다. fs 실패(권한·중복 이름 등)는 스낵바로 알린다.
  Future<void> _renameNodeById(int nodeId) async {
    final items = ref.read(fileNodesProvider).valueOrNull ?? const [];
    final matches = items.where((n) => n.id == nodeId);
    if (matches.isEmpty) return;
    final node = matches.first;
    final root = ref.read(workspaceRootProvider);
    final repo = ref.read(fileNodeRepositoryProvider);
    if (root == null || repo == null) return;

    final newName = await _promptRename(node.name);
    if (newName == null) return;
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == node.name) return;
    if (trimmed.contains('/') || trimmed.contains(r'\')) {
      _showSnack('이름에 경로 구분자(/ \\)는 쓸 수 없습니다.');
      return;
    }

    final newPath = siblingPath(node.path, trimmed);
    try {
      await const NodeRenamer().rename(
        workspaceRoot: root,
        oldRelPath: node.path,
        newRelPath: newPath,
        isDirectory: node.isDirectory,
      );
    } on FileSystemException catch (e) {
      _showSnack('이름을 바꾸지 못했습니다: ${e.message}');
      return;
    }
    await repo.renameNode(oldPath: node.path, newPath: newPath);
  }

  /// 새 이름 입력 다이얼로그. 취소하면 null.
  Future<String?> _promptRename(String initial) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('이름 변경'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '새 이름',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// 프리뷰 창에서 태그 칩의 x 버튼으로 그 부여 기록을 해제한다.
  Future<void> _removeAssignment(AssignedTag a) async {
    final assignmentId = a.assignment.id;
    if (assignmentId == null) return;
    await ref.read(tagRepositoryProvider)?.unassign(assignmentId);
  }

  /// 프리뷰 창의 '+' 버튼으로 이 노드에 태그를 새로 부여한다(부여 다이얼로그).
  Future<void> _addTagToNode(FileNode node) async {
    if (node.id == null) return;
    await showTagAssignDialog(
      context,
      fileNodeIds: [node.id!],
      title: node.name,
    );
  }

  /// 데스크톱 컨텍스트 메뉴에서 폴더 관리 방식을 골랐을 때. 바뀔 게 없는 선택
  /// (이미 그 모드)이면 아무 것도 하지 않는다.
  void _onFolderManage(
    FileNode node,
    FolderManageMode resolved,
    FolderManageAction action,
  ) {
    final next = nextManageMode(resolved, action);
    if (next != null) _applyFolderMode(node, next);
  }

  /// 폴더 노드면 상속까지 반영한 관리 모드, 아니면(파일·보존 노드) null.
  FolderManageMode? _resolvedModeOf(FileNode node) =>
      node.isDirectory && !node.isMissing
      ? (ref.read(folderResolvedModesProvider)[node.path] ??
            FolderManageMode.managed)
      : null;

  /// 모바일: 폴더 관리 방식을 바텀시트에서 고른다(데스크톱 컨텍스트 메뉴에 대응).
  Future<void> _openFolderManageSheet(
    FileNode node,
    FolderManageMode resolved,
  ) async {
    final mode = await showFolderManageSheet(
      context,
      folderName: node.name,
      resolved: resolved,
    );
    if (mode == null || mode == resolved) return;
    await _applyFolderMode(node, mode);
  }

  /// 폴더의 관리 방식 override를 [newMode]로 바꾼다. 범위가 줄어 사라질 하위(태그
  /// 포함)가 있으면 경고 후 확인받고, 확정되면 override를 저장한 뒤 재스캔한다
  /// (재스캔이 확대 시 새 하위 인덱싱, 축소 시 사라진 하위 정리를 함께 처리).
  Future<void> _applyFolderMode(FileNode node, FolderManageMode newMode) async {
    final repo = ref.read(fileNodeRepositoryProvider);
    if (repo == null || node.id == null) return;

    final dropped = _droppedByOverride(node.path, newMode);
    final taggedCount = _countTaggedIn(dropped);
    if (taggedCount > 0) {
      final ok = await _confirmScopeReduction(node.name, taggedCount);
      if (ok != true) return;
    }
    await repo.setManageMode(nodeId: node.id!, mode: newMode);
    await _backgroundScan();
  }

  /// 루트 폴더의 관리 방식(재귀 여부)을 바꾼다. 루트는 불투명이 없어 두 갈래다.
  Future<void> _setRootRecursive(bool recursive) async {
    final current = ref.read(rootManageModeProvider);
    final newMode = recursive
        ? FolderManageMode.managedRecursive
        : FolderManageMode.managed;
    if (newMode == current) return;

    final dropped = _droppedByRootMode(newMode);
    final taggedCount = _countTaggedIn(dropped);
    if (taggedCount > 0) {
      final ok = await _confirmScopeReduction('루트 폴더', taggedCount);
      if (ok != true) return;
    }
    // 저장만 하면 rootManageMode 리스너가 재스캔을 트리거한다.
    ref.read(viewSettingsProvider.notifier).updateRootManageMode(newMode);
  }

  /// 폴더 [changedPath]의 override를 [newMode]로 바꿀 때 더 이상 인덱싱되지 않을
  /// 노드 경로들.
  Set<String> _droppedByOverride(String changedPath, FolderManageMode newMode) {
    final nodes = ref.read(fileNodesProvider).valueOrNull ?? const [];
    final rootMode = ref.read(rootManageModeProvider);
    final overrides = <String, FolderManageMode?>{
      for (final n in nodes)
        if (n.isDirectory) n.path: n.manageMode,
    };
    overrides[changedPath] = newMode;
    return droppedNodePaths(nodes, rootMode, overrides);
  }

  /// 루트 모드를 [newRootMode]로 바꿀 때 더 이상 인덱싱되지 않을 노드 경로들.
  Set<String> _droppedByRootMode(FolderManageMode newRootMode) {
    final nodes = ref.read(fileNodesProvider).valueOrNull ?? const [];
    final overrides = <String, FolderManageMode?>{
      for (final n in nodes)
        if (n.isDirectory) n.path: n.manageMode,
    };
    return droppedNodePaths(nodes, newRootMode, overrides);
  }

  /// [paths] 중 태그가 하나라도 부여된 노드 수(범위 축소 경고용).
  int _countTaggedIn(Set<String> paths) {
    if (paths.isEmpty) return 0;
    final nodes = ref.read(fileNodesProvider).valueOrNull ?? const [];
    final assignmentsByFile =
        ref.read(assignmentsByFileProvider).valueOrNull ?? const {};
    var count = 0;
    for (final n in nodes) {
      final id = n.id;
      if (id == null || !paths.contains(n.path)) continue;
      if ((assignmentsByFile[id] ?? const []).isNotEmpty) count++;
    }
    return count;
  }

  /// 관리 범위를 줄여 하위 태그가 함께 제거됨을 경고한다(태그 삭제와 같은 패턴).
  Future<bool?> _confirmScopeReduction(String targetName, int taggedCount) {
    final scheme = Theme.of(context).colorScheme;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: scheme.error),
        title: const Text('관리 범위 축소'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('‘$targetName’의 관리 범위를 줄입니다.'),
            const SizedBox(height: 12),
            Text(
              '범위 밖이 되는 $taggedCount개 하위 항목의 태그가 함께 제거되며, '
              '되돌릴 수 없습니다.',
              style: TextStyle(color: scheme.error),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('범위 축소'),
          ),
        ],
      ),
    );
  }

  /// 스캔이 관측한 중첩 태거 목록([detectedDirs])을 확정 기록과 맞춘다.
  ///
  /// - 기록에는 있으나 이번에 관측되지 않은(제거·이동된) 태거의 확정 기록은 지운다
  ///   — 같은 위치에 다시 생기면 사용자에게 다시 묻도록.
  /// - 아직 처리하지 않은(새로 발견된) 태거만 병합 프롬프트를 띄운다.
  Future<void> _reconcileNestedDecisions(List<String> detectedDirs) async {
    final repo = ref.read(nestedWorkspaceRepositoryProvider);
    if (repo == null) return;

    final decided = await repo.decidedPaths();
    final detected = detectedDirs.toSet();

    for (final path in decided) {
      if (!detected.contains(path)) await repo.remove(path);
    }

    final undecided = detectedDirs.where((d) => !decided.contains(d)).toList();
    if (undecided.isNotEmpty && mounted) {
      await _promptMerge(undecided);
    }
  }

  /// 중첩된 `.filetagger/`를 발견했을 때, 폴더별로 처리 방식(흡수/독립/무시)을
  /// 묻고 적용한다. 흡수는 하위 버전이 현재보다 높으면(해석 불가) 비활성화된다.
  /// '나중에'로 넘긴 폴더는 확정 기록을 남기지 않아 다음 스캔에서 다시 묻는다.
  Future<void> _promptMerge(List<String> nestedDirs) async {
    final root = ref.read(workspaceRootProvider);
    final resolver = ref.read(resolveNestedWorkspaceProvider);
    if (root == null || resolver == null) return;
    final parentVersion = ref.read(databaseProvider)?.schemaVersion;

    var appliedAny = false;
    for (final dir in nestedDirs) {
      if (!mounted) break;
      final childAbs = p.joinAll([root, ...dir.split('/')]);
      final childVersion = await readWorkspaceSchemaVersion(childAbs);
      // 하위 버전이 현재보다 높으면 스키마를 해석할 수 없어 흡수를 막는다(내부 DB를
      // 읽지 않는 독립/무시는 계속 허용).
      final canAbsorb =
          parentVersion != null &&
          childVersion != null &&
          childVersion <= parentVersion;
      if (!mounted) break;

      final resolution = await showDialog<NestedMergeResolution>(
        context: context,
        builder: (_) => _NestedMergeDialog(
          childRelPath: dir,
          canAbsorb: canAbsorb,
          childVersion: childVersion,
          parentVersion: parentVersion,
        ),
      );
      if (resolution == null) continue; // 나중에.
      await resolver(parentRoot: root, resolution: resolution);
      appliedAny = true;
    }

    // 관리 방식 변경·흡수 결과를 반영해 프롬프트 없이 한 번 재스캔한다.
    if (appliedAny) {
      final usecase = ref.read(scanWorkspaceProvider);
      final rootMode = ref.read(rootManageModeProvider);
      if (usecase != null) {
        try {
          await usecase(root, rootManageMode: rootMode);
        } catch (_) {
          // 재조정 스캔 실패는 조용히 둔다(다음 변화 때 다시 반영).
        }
      }
    }
  }

  /// 지금 상태에서 실행할 수 있는 명령들의 핸들러. 실행할 수 없는 명령은 null로
  /// 두어 단축키·메뉴·버튼이 함께 비활성화된다.
  CommandHandlers _handlers(SelectionState selection, bool hasWorkspace) {
    return CommandHandlers(
      openFolder: _busy ? null : _openFolder,
      closeFolder: (!hasWorkspace || _busy) ? null : _closeWorkspace,
      rescan: (!hasWorkspace || _busy) ? null : _scan,
      selectAll: hasWorkspace ? _selectAll : null,
      clearSelection: selection.isEmpty ? null : _clearSelection,
      activateNode: selection.singleOrNull == null ? null : _activateSelected,
      assignTags: selection.isEmpty ? null : _assignToSelection,
      reconnect: _singleMissingSelected == null ? null : _reconnectSelected,
      revealInFileManager: _singleExistingSelected == null
          ? null
          : _revealSelected,
      manageTags: hasWorkspace ? _openTagManagement : null,
      // 데스크톱은 표시 순서를 태그 관리 다이얼로그가 함께 다룬다.
      tagDisplayOrder: (hasWorkspace && !isDesktopPlatform)
          ? () => showTagOrderDialog(context)
          : null,
      // 도구모음·목록 수정 토글은 데스크톱 셸의 크롬에만 있다.
      toggleFilterBar: (hasWorkspace && isDesktopPlatform)
          ? _toggleFilterBar
          : null,
      toggleSortBar: (hasWorkspace && isDesktopPlatform)
          ? _toggleSortBar
          : null,
      toggleListEdit: (hasWorkspace && isDesktopPlatform)
          ? _toggleListEdit
          : null,
      // 폴더 묶기는 크롬이 아니라 실제 보기 설정이라 두 셸 모두에서 켤 수 있다.
      toggleGrouping: hasWorkspace ? _toggleGrouping : null,
      togglePreview: hasWorkspace ? _togglePreview : null,
    );
  }

  /// 태그 관리를 연다. 데스크톱은 화면 전환 없이 다이얼로그로(생성·편집·삭제·표시
  /// 순서를 한 자리에서), 모바일은 전용 화면으로 간다.
  void _openTagManagement() {
    if (isDesktopPlatform) {
      showTagManageDialog(context);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TagManagementScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workspaceRoot = ref.watch(workspaceRootProvider);
    // DB는 폴더가 열릴 때 생성/연결된다. 여기서 watch해 생명주기를 활성화한다.
    ref.watch(databaseProvider);
    // 선택이 바뀌면 목록 하이라이트·프리뷰·명령 활성 상태가 함께 갱신된다.
    final selection = ref.watch(selectionControllerProvider);
    final handlers = _handlers(selection, workspaceRoot != null);

    // 디스크 변화(watcher, 디바운스됨)를 구독해 백그라운드 재스캔을 트리거한다.
    ref.listen(workspaceChangesProvider, (_, next) {
      next.whenData((_) => _backgroundScan());
    });

    // 루트 관리 방식이 바뀌면(사용자 토글, 또는 폴더 열 때 뷰 설정 비동기 로드
    // 완료로 기본값→저장값) 새 범위를 반영해 재스캔한다.
    ref.listen(rootManageModeProvider, (prev, next) {
      if (prev != null && prev != next) _backgroundScan();
    });

    final body = workspaceRoot != null
        ? _buildContentArea(selection)
        : _buildRecentFolders(handlers, ref.watch(recentFoldersProvider));

    if (!isDesktopPlatform) {
      return MobileShell(
        handlers: handlers,
        workspaceRoot: workspaceRoot,
        selectionCount: selection.length,
        scanning: _scanning,
        onOpenFilterSheet: () => showFilterSortSheet(context),
        // 빈 상태(최근 폴더)만 여백을 준다. 목록은 화면 끝까지 채운다.
        body: workspaceRoot != null
            ? body
            : Padding(padding: const EdgeInsets.all(16), child: body),
      );
    }

    return DesktopShell(
      handlers: handlers,
      workspaceRoot: workspaceRoot,
      onOpenRecent: _busy ? null : _openWorkspace,
      onSetRootRecursive: workspaceRoot == null ? null : _setRootRecursive,
      scanning: _scanning,
      previewVisible: _previewVisible,
      filterBarVisible: _filterBarVisible,
      sortBarVisible: _sortBarVisible,
      listEditEnabled: _listEditEnabled,
      grouped: ref.watch(groupByFolderProvider),
      body: body,
    );
  }

  /// 목록과, 분할로 켜져 있으면 프리뷰 창을 함께 배치한다. 좁은 폭에서는 분할
  /// 대신 프리뷰를 시트로 띄우므로 여기서는 목록만 그린다.
  Widget _buildContentArea(SelectionState selection) {
    final list = _buildFileList(selection);
    if (!_splitVisible) return list;
    return PreviewSplitView(list: list, preview: _buildPreviewPane());
  }

  /// 선택이 정확히 하나일 때 그 노드를 미리본다. 없거나 여럿이면 노드는 null이고
  /// 프리뷰 창이 안내(빈 상태/"N개 선택됨")를 대신 보인다.
  Widget _buildPreviewPane() {
    final items = ref.watch(fileNodesProvider).valueOrNull ?? const [];
    final selection = ref.read(selectionControllerProvider);
    FileNode? node;
    final single = selection.singleOrNull;
    if (single != null) {
      final matches = items.where((n) => n.id == single);
      if (matches.isNotEmpty) node = matches.first;
    }
    final target = node;
    return PreviewPane(
      node: target,
      selectedCount: selection.length,
      onEditAssignment: _editAssignmentFromList,
      onRemoveAssignment: _removeAssignment,
      onAddTag: target == null ? () {} : () => _addTagToNode(target),
    );
  }

  Widget _buildFileList(SelectionState selection) {
    final desktop = isDesktopPlatform;
    final content = _scanning
        ? const Center(child: CircularProgressIndicator())
        : FileListView(
            onTapNode: _onTapNode,
            onLongPressNode: desktop ? null : _onLongPressNode,
            // 우클릭은 정밀 포인터가 있을 때만 연다(마우스를 붙인 모바일도 포함).
            onSecondaryTapNode: ref.watch(pointerPresenceProvider)
                ? _onSecondaryTapNode
                : null,
            onEditAssignment: _editAssignmentFromList,
            // '목록에서 수정'을 켜면 행의 태그 칩이 프리뷰 창처럼 해제·추가까지 받는다.
            inlineEdit: desktop && _listEditEnabled,
            onRemoveAssignment: _removeAssignment,
            onAddTag: _addTagToNode,
            // 데스크톱은 폴더 관리 방식을 우클릭 컨텍스트 메뉴로 옮겨 행 끝을 비운다.
            trailingBuilder: desktop
                ? null
                : (node, mode) => _mobileTrailing(selection, node, mode),
            tileWrapper: desktop ? null : _swipeActions,
            // FAB에 마지막 행이 가리지 않도록 아래를 비워 둔다.
            padding: desktop
                ? EdgeInsets.zero
                : const EdgeInsets.only(bottom: 88),
          );
    if (desktop) return content;
    // 당겨서 재스캔(모바일에는 상시 '다시 스캔' 버튼이 없다). 스캔이 시작되면
    // 목록이 스피너로 바뀌므로 RefreshIndicator를 그 바깥에 두어 살려 둔다.
    return RefreshIndicator(onRefresh: _scan, child: content);
  }

  /// 모바일 행 끝: 선택 모드면 체크박스, 아니면 폴더의 관리 방식 시트 버튼.
  Widget? _mobileTrailing(
    SelectionState selection,
    FileNode node,
    FolderManageMode? resolvedMode,
  ) {
    final id = node.id;
    if (_selectionMode) {
      return Checkbox(
        value: id != null && selection.contains(id),
        onChanged: id == null ? null : (_) => _toggleNode(id),
      );
    }
    if (resolvedMode == null) return null;
    return IconButton(
      icon: const Icon(Icons.more_vert),
      tooltip: '폴더 관리 방식',
      onPressed: () => _openFolderManageSheet(node, resolvedMode),
    );
  }

  /// 모바일 스와이프 액션: 오른쪽으로 밀면 태그 부여. 행을 지우는 제스처가 아니므로
  /// 액션을 실행한 뒤 늘 제자리로 되돌린다. 선택 모드에서는 체크 조작과 겹치지
  /// 않도록 스와이프를 끈다.
  Widget _swipeActions(FileNode node, Widget tile) {
    final id = node.id;
    if (_selectionMode || id == null) return tile;
    return Dismissible(
      key: ValueKey(id),
      direction: DismissDirection.startToEnd,
      background: _swipeBackground(AppCommandId.assignTags),
      confirmDismiss: (_) async {
        await _addTagToNode(node);
        return false;
      },
      child: tile,
    );
  }

  Widget _swipeBackground(AppCommandId id) {
    final command = commandOf(id);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.secondaryContainer,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(command.icon, color: scheme.onSecondaryContainer),
    );
  }

  /// 열린 폴더가 없을 때의 빈 상태: 폴더 열기 버튼 + 최근 폴더 목록.
  Widget _buildRecentFolders(
    CommandHandlers handlers,
    AsyncValue<List<String>> recentFolders,
  ) {
    final openFolder = commandOf(AppCommandId.openFolder);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilledButton.icon(
          onPressed: handlers.openFolder,
          icon: Icon(openFolder.icon),
          label: Text(openFolder.label),
        ),
        const SizedBox(height: 24),
        Text('최근 폴더', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Expanded(
          child: recentFolders.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('설정을 불러오지 못했습니다: $e'),
            data: (folders) => folders.isEmpty
                ? const Text('아직 연 폴더가 없습니다.')
                : ListView.builder(
                    itemCount: folders.length,
                    itemBuilder: (context, index) {
                      final folder = folders[index];
                      return ListTile(
                        leading: const Icon(Icons.folder),
                        title: Text(folder),
                        onTap: _busy ? null : () => _openWorkspace(folder),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => ref
                              .read(recentFoldersProvider.notifier)
                              .remove(folder),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

/// 중첩된 하위 태거 하나에 대해 처리 방식(흡수/독립/무시)을 고르는 다이얼로그.
/// '적용'이면 [NestedMergeResolution], '나중에'면 null을 돌려준다.
class _NestedMergeDialog extends StatefulWidget {
  const _NestedMergeDialog({
    required this.childRelPath,
    required this.canAbsorb,
    required this.childVersion,
    required this.parentVersion,
  });

  final String childRelPath;

  /// 하위 버전이 현재 버전 이하라 흡수(내부 DB 해석)가 가능한지.
  final bool canAbsorb;

  final int? childVersion;
  final int? parentVersion;

  @override
  State<_NestedMergeDialog> createState() => _NestedMergeDialogState();
}

class _NestedMergeDialogState extends State<_NestedMergeDialog> {
  // 데이터를 옮기지 않는 비파괴 기본값(독립)으로 시작한다.
  NestedMergeAction _action = NestedMergeAction.independent;

  // 흡수 후 원본 제거는 되돌릴 수 없어, 기본은 하위 태거를 남기는 쪽(무시 전환)이다.
  bool _removeSource = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: const Text('중첩된 태그 폴더 발견'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('하위 폴더가 자체 태그 데이터를 가지고 있습니다. 어떻게 처리할지 선택하세요.'),
            const SizedBox(height: 8),
            Text(
              widget.childRelPath,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            RadioGroup<NestedMergeAction>(
              groupValue: _action,
              onChanged: (v) => setState(() {
                if (v != null) _action = v;
              }),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<NestedMergeAction>(
                    value: NestedMergeAction.absorb,
                    enabled: widget.canAbsorb,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('흡수'),
                    subtitle: Text(
                      widget.canAbsorb
                          ? '태그와 목록을 현재 워크스페이스로 가져와 관리합니다.'
                          : '하위 태거가 더 높은 버전이라 흡수할 수 없습니다.',
                    ),
                  ),
                  RadioListTile<NestedMergeAction>(
                    value: NestedMergeAction.independent,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('독립'),
                    subtitle: const Text(
                      '내부를 열지 않는 단일 노드로 두고, 하위 태거는 건드리지 않습니다.',
                    ),
                  ),
                  RadioListTile<NestedMergeAction>(
                    value: NestedMergeAction.ignore,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('무시'),
                    subtitle: const Text('하위 태거를 무시하고 내부 파일을 현재 규칙으로 인덱싱합니다.'),
                  ),
                ],
              ),
            ),
            if (_action == NestedMergeAction.absorb && widget.canAbsorb) ...[
              const Divider(),
              CheckboxListTile(
                value: _removeSource,
                onChanged: (v) => setState(() => _removeSource = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('흡수 후 하위 태그 폴더 제거'),
                subtitle: Text(
                  _removeSource
                      ? '하위 .filetagger 폴더를 삭제합니다(되돌릴 수 없음).'
                      : '하위 태거를 남기고 이후 ‘무시’로 처리합니다.',
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('나중에'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            NestedMergeResolution(
              childRelPath: widget.childRelPath,
              action: _action,
              removeSource:
                  _action == NestedMergeAction.absorb && _removeSource,
            ),
          ),
          child: const Text('적용'),
        ),
      ],
    );
  }
}
