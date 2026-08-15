import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/assigned_tag.dart';
import '../../domain/entities/file_node.dart';
import '../../domain/entities/file_tree_node.dart';
import '../../domain/entities/folder_manage_mode.dart';
import '../../domain/entities/system_tag.dart';
import '../../domain/entities/tag_definition.dart';
import '../../domain/usecases/tag_display_order.dart';
import '../providers/file_view_provider.dart';
import '../providers/system_tag_provider.dart';
import '../theme.dart';
import '../widgets/file_thumbnail.dart';
import '../widgets/tag_capsule.dart';
import '../widgets/tag_chip.dart';
import 'flat_tree.dart';
import 'focus_reveal.dart';
import 'navigation_cursor.dart';
import 'selection_controller.dart';

/// 들여쓰기로 표현하는 최대 계층 단계. 더 깊은 노드는 이 단계로 함께 눌러 파일명
/// 자리가 화면 밖으로 밀려나지 않게 한다(계층 자체는 가이드 라인·캐럿이 드러낸다).
const int kMaxIndentDepth = 6;

/// 트리 깊이를 실제로 들여쓸 단계로 가둔다.
int visualIndentDepth(int depth) => depth.clamp(0, kMaxIndentDepth);

/// 한 노드의 부여 태그를 **행에 보이는 순서**로 낸다: 표시 순서로 정렬한 뒤 표시
/// 술어를 통과한 칩만. 목록 행 렌더와 키보드 태그 내비게이션이 같은 목록을 쓰도록
/// 순수 함수로 둔다(둘의 태그 순서·개수가 어긋나면 좌우 이동이 엉킨다).
List<AssignedTag> visibleOrderedTags(
  List<AssignedTag> assignments,
  List<int> displayOrder,
  bool Function(int) isTagVisible,
) => [
  for (final a in orderAssignedTags(assignments, displayOrder))
    if (isTagVisible(a.tagDefinitionId)) a,
];

/// 파일 트리를 평면 목록으로 렌더하는, 셸에 독립적인 목록 뷰.
///
/// 필터·정렬·태그 표시 순서·선택 상태·펼침 상태는 provider에서 직접 읽고, 입력
/// 해석(보조키 vs 선택 모드)과 행 끝 위젯(체크박스 등)만 셸이 주입한다.
class FileListView extends ConsumerStatefulWidget {
  const FileListView({
    super.key,
    required this.onTapNode,
    required this.onOpenNode,
    required this.onEditAssignment,
    this.onLongPressNode,
    this.onSecondaryTapNode,
    this.trailingBuilder,
    this.tileWrapper,
    this.padding = EdgeInsets.zero,
    this.inlineEdit = false,
    this.onRemoveAssignment,
    this.onAddTag,
  });

  /// 행을 탭했을 때. 표시 순서의 노드 목록과 그 안의 인덱스를 함께 넘겨
  /// 셸이 범위 선택 등을 해석할 수 있게 한다.
  final void Function(List<FileNode> items, int index) onTapNode;

  /// 행을 더블클릭(활성)했을 때. **펼칠 수 있는 행은 여기로 오지 않는다** — 그룹
  /// 헤더와, 폴더 계층으로 묶인 폴더는 열리는 대신 이 뷰가 여닫기로 처리한다
  /// (그룹화가 노드 종류보다 앞선다 — 아이콘 뷰의 활성과 같은 규칙).
  final ValueChanged<FileNode> onOpenNode;

  /// 값 태그 칩을 눌렀을 때 그 부여 기록을 편집하는 콜백.
  final ValueChanged<AssignedTag> onEditAssignment;

  /// 행을 길게 눌렀을 때(모바일 선택 모드 진입). 지정하지 않으면 무시한다.
  final void Function(List<FileNode> items, int index)? onLongPressNode;

  /// 행을 우클릭했을 때(데스크톱 컨텍스트 메뉴). 메뉴를 띄울 화면 좌표를 함께
  /// 넘긴다. 지정하지 않으면 우클릭을 무시한다.
  final void Function(List<FileNode> items, int index, Offset globalPosition)?
  onSecondaryTapNode;

  /// 행 오른쪽 끝 위젯을 만드는 콜백. [resolvedMode]는 실제 폴더면 상속까지 반영한
  /// 관리 모드, 파일·보존 노드면 null이다. 지정하지 않으면 행 끝이 비어 있다.
  final Widget? Function(FileNode node, FolderManageMode? resolvedMode)?
  trailingBuilder;

  /// 행 위젯을 감싸 셸 고유의 제스처(모바일 스와이프 액션 등)를 입히는 콜백.
  /// 지정하지 않으면 행을 그대로 그린다.
  final Widget Function(FileNode node, Widget tile)? tileWrapper;

  /// 목록 바깥 여백(겹쳐 뜨는 바 등에 마지막 항목이 가리지 않도록 확보).
  final EdgeInsetsGeometry padding;

  /// 행에서 태그를 프리뷰처럼 바로 고칠 수 있게 할지(해제·추가 버튼이 붙는다).
  /// 켜려면 [onRemoveAssignment]·[onAddTag]를 함께 준다.
  final bool inlineEdit;

  /// 태그 칩의 x 버튼으로 그 부여 기록을 해제하는 콜백([inlineEdit] 전용).
  final ValueChanged<AssignedTag>? onRemoveAssignment;

  /// 행 끝 '+' 버튼으로 그 노드에 태그를 새로 부여하는 콜백([inlineEdit] 전용).
  final ValueChanged<FileNode>? onAddTag;

  @override
  ConsumerState<FileListView> createState() => _FileListViewState();
}

class _FileListViewState extends ConsumerState<FileListView> {
  /// 키보드 커서를 화면 밖 행으로 옮겼을 때 스크롤을 끌어오기 위한 컨트롤러.
  /// 실체화된 행은 [EnsureVisibleOnFocus]가 스스로 드러내지만, 화면·캐시 밖 행은
  /// 위젯이 없어 그 방법이 안 먹으므로 여기서 대략 위치로 먼저 점프해 실체화시킨다.
  final ScrollController _scroll = ScrollController();

  /// 이번 build의 표시 행(커서 대상 행 인덱스를 찾을 때 쓴다).
  List<TreeRow> _rows = const [];

  /// 마지막으로 반응한 커서 자리(같은 자리에 반복 반영하지 않기 위함). 노드 행이면
  /// 노드 id, 그룹 헤더 행이면 그 행의 펼침 키다.
  Object? _lastCursorAnchor;

  /// 마지막 탭의 시각·대상. 아이콘 뷰와 같이 더블탭을 손수 판정한다 —
  /// `GestureDetector`의 더블탭을 쓰면 단일 탭이 판정 시간만큼 늦어져 선택이 굼떠진다.
  DateTime? _lastTapAt;
  String? _lastTapKey;

  /// 이번 탭이 같은 행에 대한 더블탭의 **두 번째**인지. 판정과 동시에 상태를 갱신한다.
  bool _isSecondTap(String rowKey) {
    final now = DateTime.now();
    final isDouble =
        _lastTapKey == rowKey &&
        _lastTapAt != null &&
        now.difference(_lastTapAt!) < kDoubleTapTimeout;
    _lastTapAt = isDouble ? null : now;
    _lastTapKey = isDouble ? null : rowKey;
    return isDouble;
  }

  void _toggleExpandKey(String key) =>
      ref.read(viewSettingsProvider.notifier).toggleExpandedFolder(key);

  /// 행 활성(더블클릭). **그룹화가 노드 종류보다 앞선다** — 펼칠 수 있는 행이면
  /// (그룹 헤더와, 폴더 계층으로 묶였을 때의 폴더) 여닫기 토글이고, 아니면 셸에
  /// 열기를 위임한다. 아이콘 뷰의 활성·목록 보기의 Enter와 같은 규칙이다.
  /// [node]는 그룹 헤더 행이면 null(열 것이 없다).
  void _activateRow(TreeRow row, FileNode? node) {
    if (row.expandable) {
      _toggleExpandKey(row.expandKey);
      return;
    }
    if (node != null) widget.onOpenNode(node);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// 커서 행이 화면·캐시 밖(실체화 전)이면 대략 위치로 점프해 실체화시킨다
  /// ([jumpToRowIfOffscreen]). 여기서는 커서가 가리키는 행이 몇 번째인지만 찾는다.
  void _ensureCursorVisible(Object anchor) {
    if (!mounted) return;
    final rows = _rows;
    final idx = rows.indexWhere((r) {
      if (anchor is String) {
        return r.nodeIndex == null && r.expandKey == anchor;
      }
      final it = r.item;
      return it is FileTreeNode && it.node.id == anchor;
    });
    jumpToRowIfOffscreen(_scroll, idx, rows.length);
  }

  @override
  Widget build(BuildContext context) {
    // 트리를 펴는 일은 프로바이더가 한 번만 한다(셸의 범위 선택·커서 이동과 공유).
    final tree = ref.watch(flatTreeProvider);
    final assignmentsByFile = ref.watch(effectiveAssignmentsByFileProvider);
    final displayNames = ref.watch(displayNameByIdProvider);
    final isTagVisible = ref.watch(tagChipVisibleProvider);
    final tagDisplayOrder = ref.watch(effectiveTagDisplayOrderProvider);
    final resolvedModes = ref.watch(folderResolvedModesProvider);
    final definitionsById = ref.watch(definitionsByIdProvider);
    final filterActive = !ref.watch(fileFilterProvider).isEmpty;
    final selection = ref.watch(selectionControllerProvider);
    final cursor = ref.watch(navigationCursorProvider);
    final scale = ref.watch(currentViewScaleProvider);

    return tree.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('목록을 불러오지 못했습니다: $e'),
      data: (flat) {
        final rows = flat.rows;
        _rows = rows;
        // 커서가 새 노드로 바뀌면(특히 화면 밖 먼 항목으로 점프한 경우) 스크롤을
        // 끌어와 드러낸다. 실체화된 근처 이동은 EnsureVisibleOnFocus가 알아서 한다.
        final Object? anchor = cursor.headerKey ?? cursor.nodeId;
        if (anchor != _lastCursorAnchor) {
          _lastCursorAnchor = anchor;
          if (anchor != null) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _ensureCursorVisible(anchor),
            );
          }
        }
        if (rows.isEmpty) {
          return Text(
            filterActive ? '필터 조건에 맞는 파일이 없습니다.' : '이 폴더에는 표시할 파일이 없습니다.',
          );
        }
        // 범위 선택(shift)이 표시 순서로 동작하도록 편 노드 목록을 넘긴다(헤더 제외).
        final items = flat.nodes;
        // 글자는 목록 전체를 감싼 textScaler로, 썸네일·캐럿은 타일이 배율을 곱해
        // 함께 키운다(둘 다 같은 zoom 배율을 쓴다).
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(scale)),
          child: ListView.builder(
            controller: _scroll,
            padding: widget.padding,
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final row = rows[index];
              final item = row.item;
              if (item is GroupHeaderNode) {
                final cursored = cursor.headerKey == row.expandKey;
                return EnsureVisibleOnFocus(
                  active: cursored,
                  child: _GroupHeaderTile(
                    header: item,
                    depth: row.depth,
                    expandable: row.expandable,
                    expanded: row.expanded,
                    cursored: cursored,
                    scale: scale,
                    definition: definitionsById[item.tagDefinitionId],
                    onToggleExpand: row.expandable
                        ? () => _toggleExpandKey(row.expandKey)
                        : null,
                    // 노드 행과 같은 결: 단일 탭은 커서를 그 행으로 옮기고(헤더는
                    // 선택 대상이 아니라 커서가 "지금 이 행"을 대신한다), 두 번째
                    // 탭이면 활성까지 잇는다. 선택 상태는 건드리지 않는다.
                    onTapRow: () {
                      ref
                          .read(navigationCursorProvider.notifier)
                          .moveToHeader(row.expandKey);
                      if (_isSecondTap(row.expandKey)) {
                        _activateRow(row, null);
                      }
                    },
                  ),
                );
              }
              final node = (item as FileTreeNode).node;
              final nodeIndex = row.nodeIndex!;
              // 실제 폴더만 상속 반영 모드를 갖는다. 파일·보존 노드는 null.
              final resolved = node.isDirectory && !node.isMissing
                  ? (resolvedModes[node.path] ?? FolderManageMode.managed)
                  : null;
              // 커서가 이 노드에 있으면 행 링을 두르고, 태그 칸이면 그 칩에 링을 준다.
              final cursored = node.id != null && cursor.nodeId == node.id;
              final tile = FileNodeTile(
                node: node,
                displayName: displayNames[node.id],
                depth: row.depth,
                expandable: row.expandable,
                expanded: row.expanded,
                onToggleExpand: row.expandable
                    ? () => _toggleExpandKey(node.path)
                    : null,
                selected: node.id != null && selection.contains(node.id!),
                cursored: cursored,
                focusedTagColumn: cursored ? cursor.tagColumn : null,
                assignments: orderAssignedTags(
                  assignmentsByFile[node.id] ?? const [],
                  tagDisplayOrder,
                ),
                isTagVisible: isTagVisible,
                // 선택은 매 탭 반영하고, 같은 행의 두 번째 탭이면 활성까지 잇는다.
                onTap: () {
                  widget.onTapNode(items, nodeIndex);
                  if (_isSecondTap(row.expandKey)) _activateRow(row, node);
                },
                onLongPress: widget.onLongPressNode == null
                    ? null
                    : () => widget.onLongPressNode!(items, nodeIndex),
                onSecondaryTap: widget.onSecondaryTapNode == null
                    ? null
                    : (position) => widget.onSecondaryTapNode!(
                        items,
                        nodeIndex,
                        position,
                      ),
                onEditAssignment: widget.onEditAssignment,
                inlineEdit: widget.inlineEdit,
                onRemoveAssignment: widget.onRemoveAssignment,
                onAddTag: widget.onAddTag == null
                    ? null
                    : () => widget.onAddTag!(node),
                folderMode: resolved,
                trailing: widget.trailingBuilder?.call(node, resolved),
                scale: scale,
              );
              final wrapped = widget.tileWrapper?.call(node, tile) ?? tile;
              // 커서가 이 행으로 오면 스크롤이 따라와 화면에 드러낸다(자기 자신을
              // 뷰포트로 끌어온다). 한 칸씩 이동이라 대상은 대개 캐시 범위 안에 있다.
              return EnsureVisibleOnFocus(active: cursored, child: wrapped);
            },
          ),
        );
      },
    );
  }
}

/// 파일/폴더 한 행. 썸네일·이름·경로·태그 칩과, 폴더면 펼침 캐럿을 보인다.
class FileNodeTile extends StatelessWidget {
  const FileNodeTile({
    super.key,
    required this.node,
    required this.selected,
    this.displayName,
    this.cursored = false,
    this.focusedTagColumn,
    required this.assignments,
    required this.isTagVisible,
    required this.onTap,
    required this.onEditAssignment,
    this.inlineEdit = false,
    this.onRemoveAssignment,
    this.onAddTag,
    this.onLongPress,
    this.onSecondaryTap,
    this.depth = 0,
    this.expandable = false,
    this.expanded = false,
    this.onToggleExpand,
    this.folderMode,
    this.trailing,
    this.scale = 1.0,
  });

  /// 계층 한 단계당 들여쓰기 폭.
  static const double _indentUnit = 16;

  /// 목록 좌우 여백(들여쓰기의 기준점이자 가이드 라인의 시작 x).
  static const double _rowInset = 4;

  /// 크기 배율 1.0일 때의 기준 치수(펼침 캐럿 자리 폭·캐럿 아이콘·썸네일 한 변).
  /// zoom 배율을 곱해 쓰며, 그룹 헤더 타일도 캐럿 자리를 맞추려 같은 값을 참조한다.
  static const double _caretSlot = 28;
  static const double _caretIcon = 20;
  static const double _thumbSize = 40;

  final FileNode node;
  final bool selected;

  /// 이름 칸에 노드 이름 대신 보일 문자열(이름 태그가 정한 값). null이면 노드 이름.
  final String? displayName;

  /// 키보드 커서가 이 행에 놓여 있는지(선택과 별개의 포커스 링).
  final bool cursored;

  /// 커서 행일 때 포커스된 태그 칸: null=행 레벨 · 0..n-1=보이는 태그 · n='+' 추가
  /// 슬롯. [cursored]가 false면 무시한다.
  final int? focusedTagColumn;

  /// 이미 표시 순서로 정렬된 부여 태그 목록.
  final List<AssignedTag> assignments;

  /// 태그 부여를 칩으로 표시할지 판정하는 술어. 통과하지 못한 칩은 렌더하지 않는다
  /// (값은 필터·정렬·그룹에 여전히 참여). 시스템 태그는 표시로 켠 것만, 사용자 태그는
  /// 감춤으로 끄지 않은 것만 통과한다([tagChipVisibleProvider]).
  final bool Function(int) isTagVisible;
  final VoidCallback onTap;

  /// 값 태그 칩을 눌렀을 때 그 부여 기록의 값을 바로 수정하는 콜백.
  final ValueChanged<AssignedTag> onEditAssignment;

  /// 태그 칩을 프리뷰처럼 그려 행에서 바로 고칠 수 있게 할지(해제 x·추가 + 버튼).
  final bool inlineEdit;

  /// 태그 칩의 x 버튼으로 그 부여 기록을 해제하는 콜백([inlineEdit] 전용).
  final ValueChanged<AssignedTag>? onRemoveAssignment;

  /// '+' 버튼으로 이 노드에 태그를 새로 부여하는 콜백([inlineEdit] 전용).
  final VoidCallback? onAddTag;

  /// 길게 눌렀을 때(모바일 선택 모드). 없으면 롱프레스를 무시한다.
  final VoidCallback? onLongPress;

  /// 우클릭했을 때 메뉴를 띄우는 콜백(화면 좌표). 없으면 우클릭을 무시한다.
  final ValueChanged<Offset>? onSecondaryTap;

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

  /// 크기 배율(Ctrl/⌘+휠 zoom). 캐럿 자리·썸네일에 곱한다. 글자는 목록 전체를 감싼
  /// [MediaQuery] textScaler가 함께 키운다.
  final double scale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final missing = node.isMissing;
    final indent = visualIndentDepth(depth);
    // 렌더할 태그 칩: 표시 술어를 통과한 것만(사용자 태그는 감추지 않은 것, 시스템
    // 태그는 표시로 켠 것). 한 행에서 여러 번 쓰이므로 한 번만 고른다.
    final visibleTags = <AssignedTag>[
      for (final a in assignments)
        if (isTagVisible(a.tagDefinitionId)) a,
    ];
    // 조상 단계마다 세로 가이드 라인을 행 뒤에 깔아 깊은 트리의 소속을 드러낸다.
    return CustomPaint(
      painter: indent == 0
          ? null
          : _IndentGuidePainter(indent: indent, color: scheme.outlineVariant),
      child: Padding(
        // 선택 배경이 행 끝까지 번지지 않도록 좌우 여백을 둔다. 계층 깊이만큼 왼쪽을
        // 더 들여써 그룹 구조를 드러낸다.
        padding: EdgeInsets.only(
          left: _rowInset + indent * _indentUnit,
          right: _rowInset,
          top: 1,
          bottom: 1,
        ),
        // 선택 배경을 타일 자체 Material에 칠해 스크롤 뷰포트에 함께 잘리게 한다
        // (상위 Material에 그려져 목록 밖 정렬·필터 영역까지 번지는 것을 막는다).
        // 모서리를 둥글게 잘라 파일명·태그와 같은 안쪽 영역에만 칠해지게 한다.
        //
        // 우클릭은 ListTile이 다루지 않으므로 바깥에서 가로챈다. 자식(칩·캐럿)이
        // 좌클릭을 먼저 받는 것은 그대로 두고, 빈 영역의 우클릭도 잡도록 translucent.
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onSecondaryTapDown: onSecondaryTap == null
              ? null
              : (details) => onSecondaryTap!(details.globalPosition),
          // 커서 링. 자리는 늘 같은 폭으로 비워 두어(투명 테두리) 커서가 오갈 때
          // 행 높이가 흔들리지 않는다.
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: cursored ? scheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Material(
              color: selected ? scheme.primaryContainer : Colors.transparent,
              // 데스크톱은 선택 배경을 서서히 채우지 않고 곧바로 바꾼다.
              animationDuration: stateChangeDuration,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                dense: true,
                selected: selected,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                // 선택 시 글자·아이콘 색만 대비색으로 바꾼다(배경은 위 Material이 칠함).
                selectedColor: scheme.onPrimaryContainer,
                // 행은 선택 대상이지 링크가 아니라 포인터 모양을 바꾸지 않는다
                // (버튼인 캐럿·태그 칩은 각자 기본 커서를 그대로 쓴다).
                mouseCursor: SystemMouseCursors.basic,
                // 포인터가 지나갈 때마다 행을 다시 칠하지 않는다(큰 목록의 렌더 비용).
                // 메뉴·버튼의 호버 색은 테마에 그대로 살아 있다.
                hoverColor: Colors.transparent,
                onTap: onTap,
                onLongPress: onLongPress,
                // 펼침 캐럿(폴더) + 썸네일. 캐럿 자리는 자식 없는 노드도 비워 정렬을 맞춘다.
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: _caretSlot * scale,
                      child: expandable
                          ? IconButton(
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              iconSize: _caretIcon * scale,
                              tooltip: expanded ? '접기' : '펼치기',
                              icon: Icon(
                                expanded
                                    ? Icons.expand_more
                                    : Icons.chevron_right,
                              ),
                              onPressed: onToggleExpand,
                            )
                          : null,
                    ),
                    // 목록 썸네일은 원본 비율을 유지해 잘리지 않게 담는다(crop 없음).
                    FileThumbnail(
                      node: node,
                      dimension: _thumbSize * scale,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
                trailing: trailing,
                title: Text(
                  displayName ?? node.name,
                  style: missing ? TextStyle(color: scheme.error) : null,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 키워드는 경로 계층에 속하지 않아 경로 자리에 이름이 그대로
                    // 들어간다 — 이름 칸과 같은 글자를 두 번 보이느니 종류를 알린다.
                    Text(node.isKeyword ? '키워드' : node.path),
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
                    if (inlineEdit) ...[
                      const SizedBox(height: 4),
                      _inlineTagRow(scheme.primary, visibleTags),
                    ] else if (visibleTags.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final (i, a) in visibleTags.indexed)
                            _maybeTagRing(
                              i,
                              scheme.primary,
                              AssignedTagChip(
                                tag: a,
                                // 값 태그만 눌러 편집 가능. 시스템 태그는 수정 가능한
                                // '파일 이름'만 눌러 rename, 나머지는 표시 전용.
                                onPressed: isEditableAssignment(a)
                                    ? () => onEditAssignment(a)
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 목록 수정 모드의 태그 줄. 프리뷰 창처럼 칩을 눌러 값을 고치고 x로 해제한다.
  /// 칩이 많으면 줄바꿈 대신 가로로 스크롤해 행 높이를 지키고, '+' 버튼은 스크롤
  /// 바깥 고정 자리에 두어 칩 수와 무관하게 늘 닿을 수 있게 한다.
  Widget _inlineTagRow(Color ringColor, List<AssignedTag> visibleTags) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (i, a) in visibleTags.indexed)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _maybeTagRing(
                      i,
                      ringColor,
                      AssignedTagChip(
                        tag: a,
                        onPressed: isEditableAssignment(a)
                            ? () => onEditAssignment(a)
                            : null,
                        // 시스템 태그는 제거할 수 없어 x 버튼을 달지 않는다.
                        onDeleted:
                            isSystemTagId(a.tagDefinitionId) ||
                                onRemoveAssignment == null
                            ? null
                            : () => onRemoveAssignment!(a),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // '+' 추가 슬롯. 커서가 이 자리(태그 수 == 칸 번호)면 링을 준다.
        _maybeTagRing(
          visibleTags.length,
          ringColor,
          CapsuleAddButton(tooltip: '태그 추가', onPressed: onAddTag),
        ),
      ],
    );
  }

  /// 태그 칸 [column]을 감싸는 포커스 링. 커서가 이 칸에 있을 때만 색이 보이고,
  /// 아니면 투명 테두리로 자리만 지켜 칩이 흔들리지 않는다. 이 행에 태그 커서가
  /// 없으면([focusedTagColumn]==null) 링 자리 없이 칩을 그대로 돌려준다.
  Widget _maybeTagRing(int column, Color color, Widget child) {
    if (focusedTagColumn == null) return child;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: ShapeDecoration(
        shape: StadiumBorder(
          side: BorderSide(
            color: column == focusedTagColumn ? color : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: child,
    );
  }
}

/// 태그값 버킷의 헤더 행. 폴더(뼈대)보다 종속돼 보이도록 썸네일 없이 연한 배경의
/// 얕은 행으로 그린다. 캐럿을 누르거나 행을 더블클릭해 버킷을 접었다 편다(행의 단일
/// 클릭은 노드 행과 같이 커서를 옮긴다). 파일 노드 타일과
/// 캐럿 자리 폭·들여쓰기·가이드 라인을 맞춰 같은 계층 눈금에 놓인다.
class _GroupHeaderTile extends StatelessWidget {
  const _GroupHeaderTile({
    required this.header,
    required this.depth,
    required this.expandable,
    required this.expanded,
    required this.definition,
    this.cursored = false,
    this.onToggleExpand,
    this.onTapRow,
    this.scale = 1.0,
  });

  final GroupHeaderNode header;
  final int depth;
  final bool expandable;
  final bool expanded;

  /// 키보드 커서가 이 행에 있는지(파일 타일과 같은 링을 두른다).
  final bool cursored;

  /// 이 버킷을 만든 태그 정의. 삭제 직후 등 참조가 아직 걷히기 전이면 null.
  final TagDefinition? definition;

  /// 캐럿(버튼)을 눌러 펼침/접힘을 토글하는 콜백. 자식이 없으면 null.
  final VoidCallback? onToggleExpand;

  /// 캐럿 버튼 밖의 행을 눌렀을 때. 커서 이동·활성 판정은 뷰가 한다.
  final VoidCallback? onTapRow;

  /// 크기 배율(Ctrl/⌘+휠 zoom). 파일 타일과 캐럿 자리를 맞추려 같은 값을 곱한다.
  final double scale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final indent = visualIndentDepth(depth);
    return CustomPaint(
      painter: indent == 0
          ? null
          : _IndentGuidePainter(indent: indent, color: scheme.outlineVariant),
      child: Padding(
        padding: EdgeInsets.only(
          left: FileNodeTile._rowInset + indent * FileNodeTile._indentUnit,
          right: FileNodeTile._rowInset,
          top: 1,
          bottom: 1,
        ),
        // 커서 링. 파일 타일과 같이 자리를 늘 비워 두어(투명 테두리) 커서가 오갈 때
        // 행 높이가 흔들리지 않는다.
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: cursored ? scheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Material(
            color: scheme.surfaceContainerHighest,
            animationDuration: stateChangeDuration,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTapRow,
              hoverColor: Colors.transparent,
              mouseCursor: SystemMouseCursors.basic,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    // 캐럿 자리는 자식 없는 헤더도 비워 파일 타일과 세로줄을 맞춘다.
                    SizedBox(
                      width: FileNodeTile._caretSlot * scale,
                      child: expandable
                          ? IconButton(
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              iconSize: FileNodeTile._caretIcon * scale,
                              tooltip: expanded ? '접기' : '펼치기',
                              icon: Icon(
                                expanded
                                    ? Icons.expand_more
                                    : Icons.chevron_right,
                              ),
                              onPressed: onToggleExpand,
                            )
                          : null,
                    ),
                    Flexible(child: _label(context, scheme)),
                    const SizedBox(width: 8),
                    // 버킷에 속한 파일(비디렉토리) 수. 다중값 중복 소속을 그대로 센다.
                    Text(
                      '${header.fileCount}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 헤더 라벨. 값 있는 버킷은 태그 칩(이름·값)으로, "(미분류)"는 태그 이름에
  /// 미분류 표시를 붙인 흐린 글자로 보인다. 정의를 못 찾으면 삭제된 태그로 표기.
  Widget _label(BuildContext context, ColorScheme scheme) {
    final def = definition;
    if (header.isUnclassified) {
      final name = def?.name ?? '(삭제된 태그)';
      return Text(
        '$name · (미분류)',
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: scheme.onSurfaceVariant),
      );
    }
    if (def == null) {
      return Text(
        '(삭제된 태그)',
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: scheme.onSurfaceVariant),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: TagChip(definition: def, value: header.value),
    );
  }
}

/// 행 뒤에 조상 단계마다 세로 가이드 라인을 그린다. 라인은 그 단계의 들여쓰기
/// 칸 가운데(자식 캐럿보다 왼쪽)에 놓여 어느 폴더에 속한 행인지 눈으로 잇는다.
class _IndentGuidePainter extends CustomPainter {
  const _IndentGuidePainter({required this.indent, required this.color});

  /// 그릴 라인 수(= 들여쓴 단계 수).
  final int indent;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var level = 0; level < indent; level++) {
      final x =
          FileNodeTile._rowInset +
          level * FileNodeTile._indentUnit +
          FileNodeTile._indentUnit / 2;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_IndentGuidePainter old) =>
      old.indent != indent || old.color != color;
}
