import 'dart:math' as math;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/assigned_tag.dart';
import '../../domain/entities/file_node.dart';
import '../providers/database_provider.dart';
import '../providers/file_node_provider.dart';
import '../providers/file_view_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/tag_provider.dart';
import '../providers/workspace_provider.dart';
import '../widgets/file_toolbar.dart';
import '../widgets/reconnect_dialog.dart';
import '../widgets/tag_assign_dialog.dart';
import '../widgets/tag_chip.dart';
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

  /// 겹쳐 뜨는 선택 바가 차지하는 높이만큼 목록 하단에 확보하는 여백.
  static const double _selectionBarReserve = 64;

  /// 선택된 파일 노드 id들과 범위 선택(shift)의 기준점.
  final Set<int> _selectedIds = {};
  int? _anchorId;

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

    setState(() => _scanning = true);
    try {
      final result = await usecase(root);
      if (!mounted) return;
      if (result.nestedFiletaggerDirs.isNotEmpty) {
        await _promptMerge(result.nestedFiletaggerDirs);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('스캔에 실패했습니다: $e')));
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

    _backgroundScanning = true;
    try {
      await usecase(root);
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

  /// 보존 노드의 원본 파일을 사용자가 골라 태그를 수동 재연결한다. 후보는
  /// 태그가 하나도 없는 실제(연결 안 끊긴) 노드다.
  Future<void> _reconnectSelected() async {
    final missing = _singleMissingSelected;
    if (missing == null || missing.id == null) return;

    final items = ref.read(fileNodesProvider).valueOrNull ?? const [];
    final assignmentsByFile =
        ref.read(assignmentsByFileProvider).valueOrNull ?? const {};
    final candidates = items
        .where((n) =>
            !n.isMissing &&
            n.id != null &&
            (assignmentsByFile[n.id] ?? const []).isEmpty)
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
  Future<void> _editAssignmentFromList(AssignedTag a) async {
    final result =
        await promptTagValue(context, a.definition, initial: a.value);
    if (result == null) return;
    final assignmentId = a.assignment.id;
    if (assignmentId == null) return;
    await ref.read(tagRepositoryProvider)?.updateAssignmentValue(
          assignmentId: assignmentId,
          value: result.value,
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
            const Text('아래 하위 폴더가 자체 태그 데이터를 가지고 있습니다. '
                '현재 워크스페이스로 병합하시겠습니까?'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('File Tagger'),
        actions: [
          if (workspaceRoot != null) ...[
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
                Text('현재 폴더', style: Theme.of(context).textTheme.titleMedium),
                Text(workspaceRoot),
                const SizedBox(height: 4),
                Text(
                  database != null ? 'DB 연결됨 (.filetagger)' : 'DB 미연결',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Divider(height: 32),
                const FileToolbar(),
                const SizedBox(height: 12),
                // 선택 정보 바는 목록을 밀어내지 않고 위에 반투명하게 겹쳐 띄운다.
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: _buildFileList()),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _buildSelectionBar(),
                      ),
                    ],
                  ),
                ),
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

  Widget _buildFileList() {
    if (_scanning) {
      return const Center(child: CircularProgressIndicator());
    }
    final visible = ref.watch(visibleFileNodesProvider);
    final assignmentsByFile =
        ref.watch(assignmentsByFileProvider).valueOrNull ?? const {};
    final filterActive = !ref.watch(fileFilterProvider).isEmpty;

    return visible.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('목록을 불러오지 못했습니다: $e'),
      data: (items) {
        if (items.isEmpty) return Text(_emptyMessage(filterActive));
        return ListView.builder(
          // 겹쳐 뜬 선택 바에 마지막 항목이 영구히 가리지 않도록 여백을 둔다.
          padding: EdgeInsets.only(
            bottom: _selectedIds.isEmpty ? 0 : _selectionBarReserve,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) =>
              _fileTile(items, index, assignmentsByFile),
        );
      },
    );
  }

  String _emptyMessage(bool filterActive) => filterActive
      ? '필터 조건에 맞는 파일이 없습니다.'
      : '이 폴더에는 표시할 파일이 없습니다.';

  Widget _fileTile(
    List<FileNode> items,
    int index,
    Map<int, List<AssignedTag>> assignmentsByFile,
  ) {
    final node = items[index];
    return _FileNodeTile(
      node: node,
      selected: node.id != null && _selectedIds.contains(node.id),
      assignments: assignmentsByFile[node.id] ?? const [],
      onTap: () => _onTapNode(items, index),
      onEditAssignment: _editAssignmentFromList,
    );
  }

  Widget _buildSelectionBar() {
    if (_selectedIds.isEmpty) return const SizedBox.shrink();
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
            Text(
              'ESC로 선택 해제',
              style: Theme.of(context).textTheme.bodySmall,
            ),
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
    required this.onTap,
    required this.onEditAssignment,
  });

  final FileNode node;
  final bool selected;
  final List<AssignedTag> assignments;
  final VoidCallback onTap;

  /// 값 태그 칩을 눌렀을 때 그 부여 기록의 값을 바로 수정하는 콜백.
  final ValueChanged<AssignedTag> onEditAssignment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final missing = node.isMissing;
    return ListTile(
      dense: true,
      selected: selected,
      // 선택은 글자색이 아니라 행 영역 배경색으로 표시한다(가독성 확보).
      selectedTileColor: scheme.primaryContainer,
      selectedColor: scheme.onPrimaryContainer,
      onTap: onTap,
      leading: Icon(
        missing
            ? Icons.link_off
            : (node.isDirectory
                ? Icons.folder
                : Icons.insert_drive_file_outlined),
        color: missing ? scheme.error : null,
      ),
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
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.error),
            ),
          if (assignments.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final a in assignments)
                  TagChip(
                    definition: a.definition,
                    value: a.value,
                    // 값 태그만 눌러 편집 가능(호버 피드백으로 구분). label은 표시 전용.
                    onPressed: a.definition.hasValue
                        ? () => onEditAssignment(a)
                        : null,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
