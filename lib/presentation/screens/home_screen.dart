import 'dart:io' show FileSystemException;
import 'dart:math' as math;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/file_types.dart';
import '../../data/fs/node_renamer.dart';
import '../../domain/entities/assigned_tag.dart';
import '../../domain/entities/file_node.dart';
import '../../domain/entities/file_tree_node.dart';
import '../../domain/entities/folder_manage_mode.dart';
import '../../domain/entities/system_tag.dart';
import '../../domain/entities/workspace_view_settings.dart';
import '../../domain/usecases/folder_index_scope.dart';
import '../providers/database_provider.dart';
import '../providers/file_node_provider.dart';
import '../providers/file_view_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/system_tag_provider.dart';
import '../providers/tag_provider.dart';
import '../providers/workspace_provider.dart';
import '../widgets/file_thumbnail.dart';
import '../widgets/file_toolbar.dart';
import '../widgets/preview_pane.dart';
import '../widgets/reconnect_dialog.dart';
import '../widgets/tag_assign_dialog.dart';
import '../widgets/tag_chip.dart';
import '../widgets/tag_value_prompt.dart';
import 'tag_management_screen.dart';

/// 폴더 타일의 관리 방식 메뉴 선택지.
enum _ManageAction { opaque, managed, toggleRecursive }

/// 트리를 편 뒤의 한 표시 행(노드 + 깊이 + 펼침 상태).
class _TreeRow {
  const _TreeRow({
    required this.node,
    required this.depth,
    required this.expandable,
    required this.expanded,
  });

  final FileNode node;
  final int depth;
  final bool expandable;
  final bool expanded;
}

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

  /// 겹쳐 뜨는 선택 바가 차지하는 높이만큼 목록 하단에 확보하는 여백.
  static const double _selectionBarReserve = 64;

  /// 선택된 파일 노드 id들과 범위 선택(shift)의 기준점.
  final Set<int> _selectedIds = {};
  int? _anchorId;

  /// 펼쳐 놓은 폴더 경로들(그룹 트리). 기본은 접힘이라 여기 없으면 접힌 상태다.
  /// 필터가 걸리면 이 상태와 무관하게 전부 펼쳐 매치를 드러낸다.
  final Set<String> _expandedFolders = {};

  /// 프리뷰 창을 목록 옆(또는 위)에 표시할지. 앱바 토글로 전환한다.
  bool _previewVisible = true;

  /// 분할선을 드래그하는 동안의 임시 비율. 드래그가 끝나면 보기 설정에 저장하고
  /// null로 되돌린다(그 뒤엔 저장된 값을 쓴다).
  double? _previewRatioDrag;

  /// 폴더 열기·스캔 등 앱을 잠가야 하는 작업이 진행 중인지. 이 동안에는 폴더
  /// 열기·재스캔·최근 폴더 탭을 막아 네이티브 다이얼로그가 모달처럼 동작하게 한다.
  bool get _busy => _scanning || _picking;

  /// 보조키(ESC 등)를 쓸 수 있는 데스크톱인지. 선택 해제 UI를 이에 맞춰 바꾼다.
  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

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

  Future<void> _scan() async {
    final usecase = ref.read(scanWorkspaceProvider);
    final root = ref.read(workspaceRootProvider);
    if (usecase == null || root == null) return;

    final rootMode = ref.read(rootManageModeProvider);
    setState(() => _scanning = true);
    try {
      final result = await usecase(root, rootManageMode: rootMode);
      if (!mounted) return;
      if (result.nestedFiletaggerDirs.isNotEmpty) {
        await _promptMerge(result.nestedFiletaggerDirs);
      }
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
    _selectedIds.clear();
    _anchorId = null;
  }

  void _toggleExpand(String path) {
    setState(() {
      if (!_expandedFolders.remove(path)) _expandedFolders.add(path);
    });
  }

  /// 필터·정렬된 트리를 표시 순서의 평면 행으로 편다. 접힌 폴더의 자식은 건너뛴다.
  /// [expandAll]이면(필터 활성 등) 접힘 상태를 무시하고 전부 편다.
  List<_TreeRow> _flattenTree(
    List<FileTreeNode> roots, {
    required bool expandAll,
  }) {
    final rows = <_TreeRow>[];
    void walk(List<FileTreeNode> nodes, int depth) {
      for (final n in nodes) {
        final expandable = n.hasChildren;
        final expanded = expandAll || _expandedFolders.contains(n.node.path);
        rows.add(
          _TreeRow(
            node: n.node,
            depth: depth,
            expandable: expandable,
            expanded: expanded,
          ),
        );
        if (expandable && expanded) walk(n.children, depth + 1);
      }
    }

    walk(roots, 0);
    return rows;
  }

  /// 탐색기식 클릭 선택. 클릭=단일, Shift=범위, Ctrl/Cmd=개별 토글.
  ///
  /// TODO(select): 보조키가 없는 모바일/태블릿에서는 선택 모드 토글+체크박스로
  /// 동작하도록 플랫폼 분기가 필요하다(백로그).
  void _onTapNode(List<FileNode> items, int index) {
    final id = items[index].id;
    if (id == null) return;
    final keys = HardwareKeyboard.instance;

    setState(() {
      if (keys.isShiftPressed && _anchorId != null) {
        final anchorIndex = items.indexWhere((n) => n.id == _anchorId);
        if (anchorIndex == -1) {
          _selectedIds
            ..clear()
            ..add(id);
          _anchorId = id;
        } else {
          final lo = math.min(anchorIndex, index);
          final hi = math.max(anchorIndex, index);
          _selectedIds.clear();
          for (var i = lo; i <= hi; i++) {
            final nid = items[i].id;
            if (nid != null) _selectedIds.add(nid);
          }
        }
      } else if (keys.isControlPressed || keys.isMetaPressed) {
        if (!_selectedIds.remove(id)) _selectedIds.add(id);
        _anchorId = id;
      } else {
        _selectedIds
          ..clear()
          ..add(id);
        _anchorId = id;
      }
    });
  }

  /// 선택이 정확히 연결 끊긴(보존) 노드 하나면 그 노드를 반환한다. 이때
  /// 액션 바 버튼이 '태그 부여' 대신 '원본 파일 찾기'로 바뀐다.
  FileNode? get _singleMissingSelected {
    if (_selectedIds.length != 1) return null;
    final items = ref.read(fileNodesProvider).valueOrNull ?? const [];
    final matches = items.where((n) => n.id == _selectedIds.first);
    if (matches.isEmpty) return null;
    final node = matches.first;
    return node.isMissing ? node : null;
  }

  /// 겹쳐 뜨는 선택 바(선택 수·ESC 안내·태그 부여/원본 찾기 버튼)가 필요한지.
  ///
  /// 단일 선택은 프리뷰 창에서 칩으로 바로 추가·해제하므로 바가 불필요하다.
  /// 여러 개를 선택했거나(일괄 부여), 프리뷰가 꺼져 있거나(추가 경로가 없음),
  /// 연결 끊긴 노드 하나를 골라 원본 찾기가 필요할 때만 바를 띄운다.
  bool get _needsSelectionBar {
    if (_selectedIds.isEmpty) return false;
    if (_singleMissingSelected != null) return true;
    if (_selectedIds.length > 1) return true;
    return !_previewVisible;
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
    if (mounted) setState(_clearSelection);
  }

  Future<void> _assignToSelection() async {
    if (_selectedIds.isEmpty) return;
    final ids = _selectedIds.toList();
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

  /// 폴더 타일의 관리 방식 메뉴. `폴더만 관리`(내부 감춤) / `내부 관리` 중 하나와,
  /// 내부 관리일 때만 켤 수 있는 `재귀적으로 관리` 토글을 보인다. [resolved]는
  /// 상속까지 반영한 이 폴더의 실제(effective) 모드다.
  Widget _folderManageMenu(FileNode node, FolderManageMode resolved) {
    final managedFamily = resolved != FolderManageMode.opaque;
    return PopupMenuButton<_ManageAction>(
      tooltip: '폴더 관리 방식',
      onSelected: (action) => _onFolderManage(node, resolved, action),
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: _ManageAction.opaque,
          checked: resolved == FolderManageMode.opaque,
          child: const Text('폴더만 관리 (내부 감춤)'),
        ),
        CheckedPopupMenuItem(
          value: _ManageAction.managed,
          checked: managedFamily,
          child: const Text('내부 관리'),
        ),
        const PopupMenuDivider(),
        CheckedPopupMenuItem(
          value: _ManageAction.toggleRecursive,
          checked: resolved == FolderManageMode.managedRecursive,
          // 폴더만 관리(불투명)일 땐 재귀가 의미 없어 체크 불가.
          enabled: managedFamily,
          child: const Text('재귀적으로 관리'),
        ),
      ],
    );
  }

  Future<void> _onFolderManage(
    FileNode node,
    FolderManageMode resolved,
    _ManageAction action,
  ) async {
    switch (action) {
      case _ManageAction.opaque:
        if (resolved == FolderManageMode.opaque) return;
        await _applyFolderMode(node, FolderManageMode.opaque);
      case _ManageAction.managed:
        // 이미 관리 계열이면 라디오는 무시(재귀 여부는 토글로 바꾼다).
        if (resolved != FolderManageMode.opaque) return;
        await _applyFolderMode(node, FolderManageMode.managed);
      case _ManageAction.toggleRecursive:
        if (resolved == FolderManageMode.opaque) return;
        final next = resolved == FolderManageMode.managedRecursive
            ? FolderManageMode.managed
            : FolderManageMode.managedRecursive;
        await _applyFolderMode(node, next);
    }
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

  /// 루트 폴더의 관리 방식 메뉴(관리/재귀 관리 토글). 루트는 불투명이 없다.
  Widget _rootManageMenu(FolderManageMode rootMode) {
    return PopupMenuButton<bool>(
      tooltip: '루트 폴더 관리 방식',
      icon: const Icon(Icons.account_tree_outlined),
      onSelected: _setRootRecursive,
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: false,
          checked: rootMode != FolderManageMode.managedRecursive,
          child: const Text('직속 항목만 관리'),
        ),
        CheckedPopupMenuItem(
          value: true,
          checked: rootMode == FolderManageMode.managedRecursive,
          child: const Text('전체 재귀 관리'),
        ),
      ],
    );
  }

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

  /// 중첩된 `.filetagger/`를 발견했을 때 병합 여부를 묻는다.
  ///
  /// TODO(merge): 실제 병합(하위 태그 DB를 현재 워크스페이스로 통합)은 아직
  /// 미구현이다. 지금은 발견 사실을 알리고 선택만 받는 자리표시 다이얼로그다.
  Future<void> _promptMerge(List<String> nestedDirs) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('중첩된 태그 폴더 발견'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '아래 하위 폴더가 자체 태그 데이터를 가지고 있습니다. '
              '현재 워크스페이스로 병합하시겠습니까?',
            ),
            const SizedBox(height: 12),
            for (final dir in nestedDirs) Text('• $dir'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('나중에'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('병합 기능은 아직 준비 중입니다.')),
              );
            },
            child: const Text('병합'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workspaceRoot = ref.watch(workspaceRootProvider);
    // DB는 폴더가 열릴 때 생성/연결된다. 여기서 watch해 생명주기를 활성화한다.
    final database = ref.watch(databaseProvider);
    final recentFolders = ref.watch(recentFoldersProvider);

    // 디스크 변화(watcher, 디바운스됨)를 구독해 백그라운드 재스캔을 트리거한다.
    ref.listen(workspaceChangesProvider, (_, next) {
      next.whenData((_) => _backgroundScan());
    });

    // 루트 관리 방식이 바뀌면(사용자 토글, 또는 폴더 열 때 뷰 설정 비동기 로드
    // 완료로 기본값→저장값) 새 범위를 반영해 재스캔한다.
    ref.listen(rootManageModeProvider, (prev, next) {
      if (prev != null && prev != next) _backgroundScan();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('File Tagger'),
        actions: [
          if (workspaceRoot != null) ...[
            IconButton(
              tooltip: _previewVisible ? '프리뷰 숨기기' : '프리뷰 보기',
              onPressed: () =>
                  setState(() => _previewVisible = !_previewVisible),
              icon: Icon(
                _previewVisible
                    ? Icons.view_sidebar
                    : Icons.view_sidebar_outlined,
              ),
            ),
            IconButton(
              tooltip: '태그 관리',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TagManagementScreen(),
                ),
              ),
              icon: const Icon(Icons.sell_outlined),
            ),
            IconButton(
              tooltip: '다시 스캔',
              onPressed: _busy ? null : _scan,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ],
      ),
      body: _wrapWithEscToClear(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FilledButton.icon(
                onPressed: _busy ? null : _openFolder,
                icon: const Icon(Icons.folder_open),
                label: const Text('폴더 열기'),
              ),
              const SizedBox(height: 16),
              if (workspaceRoot != null) ...[
                Row(
                  children: [
                    Text(
                      '현재 폴더',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    _rootManageMenu(ref.watch(rootManageModeProvider)),
                  ],
                ),
                Text(workspaceRoot),
                const SizedBox(height: 4),
                Text(
                  database != null ? 'DB 연결됨 (.filetagger)' : 'DB 미연결',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Divider(height: 32),
                const FileToolbar(),
                const SizedBox(height: 12),
                Expanded(child: _buildContentArea()),
              ] else
                Expanded(child: _buildRecentFolders(recentFolders)),
            ],
          ),
        ),
      ),
    );
  }

  /// 데스크톱에서 ESC로 선택을 취소하도록 감싼다. 모바일은 선택 해제 버튼을 쓴다.
  Widget _wrapWithEscToClear(Widget child) {
    if (!_isDesktop) return child;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_selectedIds.isNotEmpty) setState(_clearSelection);
        },
      },
      child: Focus(autofocus: true, child: child),
    );
  }

  /// 목록(+겹친 선택 바)과, 켜져 있으면 프리뷰 창을 반응형으로 배치한다.
  /// 창이 가로로 넓으면 프리뷰를 왼쪽에, 세로로 길면 위쪽에 둔다.
  Widget _buildContentArea() {
    // 선택 정보 바는 목록을 밀어내지 않고 위에 반투명하게 겹쳐 띄운다.
    final listStack = Stack(
      children: [
        Positioned.fill(child: _buildFileList()),
        Positioned(left: 0, right: 0, bottom: 0, child: _buildSelectionBar()),
      ],
    );
    if (!_previewVisible) return listStack;

    // 드래그 중이면 임시 비율, 아니면 저장된 비율을 쓴다.
    final ratio =
        _previewRatioDrag ?? ref.watch(viewSettingsProvider).previewRatio;

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = preferHorizontalPreview(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        final total = horizontal ? constraints.maxWidth : constraints.maxHeight;
        final paneExtent = total * ratio;
        final pane = _buildPreviewPane();
        final handle = _buildDragHandle(horizontal: horizontal, total: total);
        if (horizontal) {
          return Row(
            children: [
              SizedBox(width: paneExtent, child: pane),
              handle,
              Expanded(child: listStack),
            ],
          );
        }
        return Column(
          children: [
            SizedBox(height: paneExtent, child: pane),
            handle,
            Expanded(child: listStack),
          ],
        );
      },
    );
  }

  /// 프리뷰와 목록 사이의 분할선. 드래그하면 비율이 바뀌고, 놓으면 저장한다.
  /// 커서를 리사이즈 모양으로 바꿔 잡을 수 있음을 알린다.
  Widget _buildDragHandle({required bool horizontal, required double total}) {
    return MouseRegion(
      cursor: horizontal
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanUpdate: (details) {
          if (total <= 0) return;
          final delta = horizontal ? details.delta.dx : details.delta.dy;
          final base =
              _previewRatioDrag ?? ref.read(viewSettingsProvider).previewRatio;
          setState(() {
            _previewRatioDrag = (base + delta / total).clamp(
              kPreviewRatioMin,
              kPreviewRatioMax,
            );
          });
        },
        onPanEnd: (_) {
          final ratio = _previewRatioDrag;
          if (ratio != null) {
            ref.read(viewSettingsProvider.notifier).updatePreviewRatio(ratio);
          }
          setState(() => _previewRatioDrag = null);
        },
        child: horizontal
            ? const VerticalDivider(width: 10, thickness: 1)
            : const Divider(height: 10, thickness: 1),
      ),
    );
  }

  /// 선택이 정확히 하나일 때 그 노드를 미리본다. 없거나 여럿이면 노드는 null이고
  /// 프리뷰 창이 안내(빈 상태/"N개 선택됨")를 대신 보인다.
  Widget _buildPreviewPane() {
    final items = ref.watch(fileNodesProvider).valueOrNull ?? const [];
    FileNode? node;
    if (_selectedIds.length == 1) {
      final matches = items.where((n) => n.id == _selectedIds.first);
      if (matches.isNotEmpty) node = matches.first;
    }
    final target = node;
    return PreviewPane(
      node: target,
      selectedCount: _selectedIds.length,
      onEditAssignment: _editAssignmentFromList,
      onRemoveAssignment: _removeAssignment,
      onAddTag: target == null ? () {} : () => _addTagToNode(target),
    );
  }

  Widget _buildFileList() {
    if (_scanning) {
      return const Center(child: CircularProgressIndicator());
    }
    final tree = ref.watch(fileTreeProvider);
    final assignmentsByFile = ref.watch(effectiveAssignmentsByFileProvider);
    final visibleSystemTagIds = ref.watch(visibleSystemTagIdsProvider);
    final resolvedModes = ref.watch(folderResolvedModesProvider);
    final filterActive = !ref.watch(fileFilterProvider).isEmpty;

    return tree.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('목록을 불러오지 못했습니다: $e'),
      data: (roots) {
        // 필터가 걸리면 매치를 드러내기 위해 접힘 상태와 무관하게 전부 편다.
        final rows = _flattenTree(roots, expandAll: filterActive);
        if (rows.isEmpty) return Text(_emptyMessage(filterActive));
        // 범위 선택(shift)이 표시 순서로 동작하도록 편 노드 목록을 넘긴다.
        final items = [for (final r in rows) r.node];
        return ListView.builder(
          // 겹쳐 뜬 선택 바에 마지막 항목이 영구히 가리지 않도록 여백을 둔다.
          padding: EdgeInsets.only(
            bottom: _needsSelectionBar ? _selectionBarReserve : 0,
          ),
          itemCount: rows.length,
          itemBuilder: (context, index) => _treeTile(
            rows,
            items,
            index,
            assignmentsByFile,
            visibleSystemTagIds,
            resolvedModes,
          ),
        );
      },
    );
  }

  String _emptyMessage(bool filterActive) =>
      filterActive ? '필터 조건에 맞는 파일이 없습니다.' : '이 폴더에는 표시할 파일이 없습니다.';

  Widget _treeTile(
    List<_TreeRow> rows,
    List<FileNode> items,
    int index,
    Map<int, List<AssignedTag>> assignmentsByFile,
    Set<int> visibleSystemTagIds,
    Map<String, FolderManageMode> resolvedModes,
  ) {
    final row = rows[index];
    final node = row.node;
    // 실제 폴더의 effective 관리 모드(상속 반영). 파일·보존 노드는 메뉴 없음.
    final showManage = node.isDirectory && !node.isMissing;
    final resolved = resolvedModes[node.path] ?? FolderManageMode.managed;
    return _FileNodeTile(
      node: node,
      depth: row.depth,
      expandable: row.expandable,
      expanded: row.expanded,
      onToggleExpand: row.expandable ? () => _toggleExpand(node.path) : null,
      selected: node.id != null && _selectedIds.contains(node.id),
      assignments: assignmentsByFile[node.id] ?? const [],
      visibleSystemTagIds: visibleSystemTagIds,
      onTap: () => _onTapNode(items, index),
      onEditAssignment: _editAssignmentFromList,
      folderMode: showManage ? resolved : null,
      trailing: showManage ? _folderManageMenu(node, resolved) : null,
    );
  }

  Widget _buildSelectionBar() {
    if (!_needsSelectionBar) return const SizedBox.shrink();
    // 연결 끊긴 노드 하나만 선택되면 '태그 부여' 대신 '원본 파일 찾기'를 보인다.
    final missing = _singleMissingSelected;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        // 목록을 완전히 가리지 않도록 반투명 배경으로 겹쳐 띄운다.
        color: scheme.surface.withValues(alpha: 0.85),
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          Text('${_selectedIds.length}개 선택'),
          if (_isDesktop) ...[
            const SizedBox(width: 8),
            Text('ESC로 선택 해제', style: Theme.of(context).textTheme.bodySmall),
          ],
          const Spacer(),
          // 데스크톱은 ESC로 해제하므로 버튼을 숨긴다(모바일에서만 노출).
          if (!_isDesktop) ...[
            TextButton(
              onPressed: () => setState(_clearSelection),
              child: const Text('선택 해제'),
            ),
            const SizedBox(width: 8),
          ],
          if (missing != null)
            FilledButton.icon(
              onPressed: _reconnectSelected,
              icon: const Icon(Icons.link),
              label: const Text('원본 파일 찾기'),
            )
          else
            FilledButton.icon(
              onPressed: _assignToSelection,
              icon: const Icon(Icons.sell_outlined),
              label: const Text('태그 부여'),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentFolders(AsyncValue<List<String>> recentFolders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

class _FileNodeTile extends StatelessWidget {
  const _FileNodeTile({
    required this.node,
    required this.selected,
    required this.assignments,
    required this.visibleSystemTagIds,
    required this.onTap,
    required this.onEditAssignment,
    this.depth = 0,
    this.expandable = false,
    this.expanded = false,
    this.onToggleExpand,
    this.folderMode,
    this.trailing,
  });

  /// 계층 한 단계당 들여쓰기 폭.
  static const double _indentUnit = 16;

  final FileNode node;
  final bool selected;
  final List<AssignedTag> assignments;

  /// 칩으로 표시할 시스템 태그 id 집합. 여기 없는 시스템 태그 칩은 렌더하지 않는다
  /// (값은 필터·정렬에 여전히 참여). 사용자 태그 칩은 이 집합과 무관하게 항상 표시.
  final Set<int> visibleSystemTagIds;
  final VoidCallback onTap;

  /// 값 태그 칩을 눌렀을 때 그 부여 기록의 값을 바로 수정하는 콜백.
  final ValueChanged<AssignedTag> onEditAssignment;

  /// 트리 깊이(0=최상위). 들여쓰기에 쓴다.
  final int depth;

  /// 펼칠 수 있는(자식 있는) 폴더인지. 펼침/접힘 캐럿을 보인다.
  final bool expandable;

  /// 현재 펼쳐져 있는지. 캐럿 모양을 정한다.
  final bool expanded;

  /// 캐럿을 눌러 펼침/접힘을 토글하는 콜백. 펼칠 수 없으면 null.
  final VoidCallback? onToggleExpand;

  /// 폴더일 때 상속까지 반영한 effective 관리 모드. 파일·보존 노드면 null.
  final FolderManageMode? folderMode;

  /// 타일 오른쪽 끝 위젯(폴더 관리 방식 메뉴 등). 없으면 null.
  final Widget? trailing;

  /// 렌더할 태그 칩: 사용자 태그는 모두, 시스템 태그는 표시로 켠 것만.
  List<AssignedTag> get _visibleTags => [
    for (final a in assignments)
      if (!isSystemTagId(a.tagDefinitionId) ||
          visibleSystemTagIds.contains(a.tagDefinitionId))
        a,
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final missing = node.isMissing;
    return Padding(
      // 선택 배경이 행 끝까지 번지지 않도록 좌우 여백을 둔다. 계층 깊이만큼 왼쪽을
      // 더 들여써 그룹 구조를 드러낸다.
      padding: EdgeInsets.only(
        left: 4 + depth * _indentUnit,
        right: 4,
        top: 1,
        bottom: 1,
      ),
      // 선택 배경을 타일 자체 Material에 칠해 스크롤 뷰포트에 함께 잘리게 한다
      // (상위 Material에 그려져 목록 밖 정렬·필터 영역까지 번지는 것을 막는다).
      // 모서리를 둥글게 잘라 파일명·태그와 같은 안쪽 영역에만 칠해지게 한다.
      child: Material(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          dense: true,
          selected: selected,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          // 선택 시 글자·아이콘 색만 대비색으로 바꾼다(배경은 위 Material이 칠함).
          selectedColor: scheme.onPrimaryContainer,
          onTap: onTap,
          // 펼침 캐럿(폴더) + 썸네일. 캐럿 자리는 자식 없는 노드도 비워 정렬을 맞춘다.
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                child: expandable
                    ? IconButton(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        iconSize: 20,
                        tooltip: expanded ? '접기' : '펼치기',
                        icon: Icon(
                          expanded ? Icons.expand_more : Icons.chevron_right,
                        ),
                        onPressed: onToggleExpand,
                      )
                    : null,
              ),
              // 목록 썸네일은 원본 비율을 유지해 잘리지 않게 담는다(crop 없음).
              FileThumbnail(node: node, dimension: 40, fit: BoxFit.contain),
            ],
          ),
          trailing: trailing,
          title: Text(
            node.name,
            style: missing ? TextStyle(color: scheme.error) : null,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(node.path),
              if (missing)
                Text(
                  '연결 끊김 — 원본 파일을 찾아 태그를 재연결하세요',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: scheme.error),
                ),
              if (folderMode == FolderManageMode.opaque)
                Text(
                  '내부 감춤 — 메뉴에서 ‘내부 관리’로 펼치기',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              if (_visibleTags.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final a in _visibleTags)
                      TagChip(
                        definition: a.definition,
                        value: a.value,
                        // 값 태그만 눌러 편집 가능(호버 피드백으로 구분). 시스템 태그는
                        // 수정 가능한 '파일 이름'만 눌러 rename, 나머지는 표시 전용.
                        onPressed: isEditableAssignment(a)
                            ? () => onEditAssignment(a)
                            : null,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
