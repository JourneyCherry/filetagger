import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/assigned_tag.dart';
import '../../domain/entities/file_node.dart';
import '../../domain/entities/file_sort.dart';
import '../../domain/entities/system_tag.dart';
import '../../domain/entities/tag_definition.dart';
import '../../domain/entities/tag_value_type.dart';
import '../../domain/entities/workspace_view_settings.dart';
import '../../domain/usecases/cell_value_edit.dart';
import '../providers/file_node_provider.dart';
import '../providers/file_view_provider.dart';
import '../widgets/link_target_picker.dart';
import '../providers/system_tag_provider.dart';
import '../providers/tag_provider.dart';
import '../tag_visuals.dart';
import '../theme.dart';
import '../widgets/file_thumbnail.dart';
import '../widgets/tag_assign_dialog.dart';
import 'focus_reveal.dart';
import 'navigation_cursor.dart';
import 'selection_controller.dart';

/// 배율 1.0일 때 이름 셀 썸네일 한 변. zoom 배율을 곱한다(Ctrl/⌘+휠).
const double _baseThumb = 20;

/// 컬럼 폭 조절 손잡이가 차지하는 폭(오른쪽 가장자리에 겹쳐 둔다).
const double _resizeHandleWidth = 10;

double _persistedWidth(Map<int, double> widths, int key) =>
    (widths[key] ?? kDefaultDetailColumnWidth).clamp(
      kDetailColumnWidthMin,
      kDetailColumnWidthMax,
    );

/// 자세히 표에서 행 커서 이동이 선택을 어떻게 함께 바꾸는지.
enum _DetailMove { single, range, cursorOnly }

/// 자세히 테이블의 한 컬럼 서술자(이름 컬럼 또는 태그 컬럼).
class _Col {
  _Col({
    required this.widthKey,
    required this.sortId,
    required this.label,
    required this.valueType,
    this.definition,
    this.reorderable = true,
    this.isName = false,
  });

  /// 컬럼 폭을 저장·조회할 키(태그 id, 이름 컬럼은 [kDetailNameColumnId]).
  final int widthKey;

  /// 정렬·값 조회에 쓰는 태그 id(이름 컬럼은 파일 이름 시스템 태그).
  final int sortId;
  final String label;
  final TagValueType valueType;

  /// 이 컬럼의 태그 정의(이름 컬럼은 null). 인라인 편집이 다중 부여 허용·시스템
  /// 여부를 여기서 읽는다.
  final TagDefinition? definition;

  /// 셀을 인라인 편집할 수 있는지: 사용자 태그 컬럼만 편집 대상이다(이름 컬럼과
  /// 파생값인 시스템 태그 컬럼은 제외).
  bool get editable => definition != null && !definition!.isSystem;

  /// 드래그로 순서를 바꿀 수 있는지(이름 컬럼은 고정이라 false).
  final bool reorderable;
  final bool isName;
}

/// 태그를 컬럼으로 펼친 자세히 테이블, 셸에 독립적인 보기.
///
/// **그룹화는 무시**하고 필터만 적용해 파일·폴더를 평면 나열한다. 컬럼은 고정 '이름'
/// 컬럼과 모든 태그(사용자+시스템) 컬럼이며, 좌우 순서는 목록·프리뷰와 공유하는
/// 태그 표시 순서를 따른다. 정렬은 이 뷰 전용이다: 헤더를 클릭하면 그 컬럼이 정렬에
/// 더해지고(클릭 순서 = 우선순위), 다시 클릭하면 방향만 뒤집는다. 컬럼 경계를 끌어
/// 폭을 바꾸고, 헤더를 끌어 컬럼 순서를 바꾼다.
///
/// 선택·프리뷰는 목록 뷰와 같은 계약을 쓴다([onTapNode]·[onActivateFile]).
class FileDetailView extends ConsumerStatefulWidget {
  const FileDetailView({
    super.key,
    required this.onTapNode,
    required this.onActivateFile,
    this.onLongPressNode,
    this.onSecondaryTapNode,
    this.padding = EdgeInsets.zero,
  });

  final void Function(List<FileNode> items, int index) onTapNode;
  final ValueChanged<FileNode> onActivateFile;
  final void Function(List<FileNode> items, int index)? onLongPressNode;
  final void Function(List<FileNode> items, int index, Offset globalPosition)?
  onSecondaryTapNode;
  final EdgeInsetsGeometry padding;

  @override
  ConsumerState<FileDetailView> createState() => _FileDetailViewState();
}

class _FileDetailViewState extends ConsumerState<FileDetailView> {
  final ScrollController _horizontal = ScrollController();

  /// 조절 중인 컬럼의 임시 폭(놓는 순간 저장하고 지운다).
  final Map<int, double> _resizing = {};

  /// 이번 build의 저장된 컬럼 폭(손잡이 콜백이 참조).
  Map<int, double> _persisted = const {};

  /// 인라인 편집 중인 셀(파일·컬럼)과 그 입력 상태. null이면 편집 중이 아니다.
  FileNode? _editNode;
  _Col? _editCol;
  final TextEditingController _editController = TextEditingController();
  final FocusNode _editFocus = FocusNode();

  /// 키보드 커서(행=파일 id, 열=0 이름·1.. 태그 컬럼). 선택과 별개다.
  int? _cursorNodeId;
  int _cursorCol = 0;

  /// 방향키를 받는 이 뷰의 포커스. 모드 진입 시·셀 탭 시 포커스를 가져온다. 셀을
  /// 편집할 땐 [_editFocus]가 포커스를 쥐어 방향키가 입력창의 캐럿 이동이 된다.
  final FocusNode _navFocus = FocusNode(debugLabel: 'FileDetailView');

  @override
  void initState() {
    super.initState();
    // 포커스를 잃으면(다른 곳을 누름·스크롤로 사라짐) 편집을 확정한다.
    _editFocus.addListener(() {
      if (!_editFocus.hasFocus && _editNode != null) _commitEdit();
    });
    // 이 보기로 전환하면 곧바로 방향키가 먹도록 포커스를 잡는다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _navFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _horizontal.dispose();
    _editController.dispose();
    _editFocus.dispose();
    _navFocus.dispose();
    super.dispose();
  }

  double _widthOf(int key) => _resizing[key] ?? _persistedWidth(_persisted, key);

  @override
  Widget build(BuildContext context) {
    final rows = ref.watch(detailRowsProvider);
    final tagCols = ref.watch(detailTagColumnsProvider);
    _persisted = ref.watch(detailColumnWidthsProvider);
    final sort = ref.watch(detailSortProvider);
    final byFile = ref.watch(effectiveAssignmentsByFileProvider);
    final selection = ref.watch(selectionControllerProvider);
    final scale = ref.watch(currentViewScaleProvider);

    final columns = _columnsFrom(tagCols);

    return rows.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('목록을 불러오지 못했습니다: $e'),
      data: (list) {
        final total = columns.fold<double>(
          0,
          (sum, c) => sum + _widthOf(c.widthKey),
        );
        // 커서 행이 목록에서 사라졌으면(필터·재스캔) 커서를 접는다.
        if (_cursorNodeId != null &&
            !list.any((n) => n.id == _cursorNodeId)) {
          _cursorNodeId = null;
        }
        _cursorCol = _cursorCol.clamp(0, columns.length - 1);
        final mq = MediaQuery.of(context);
        return CallbackShortcuts(
          bindings: _shortcuts(),
          child: Focus(
            focusNode: _navFocus,
            autofocus: true,
            child: MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(scale)),
          child: Scrollbar(
            controller: _horizontal,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontal,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: total,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _headerRow(context, columns, sort),
                    const Divider(height: 1),
                    Expanded(
                      child: list.isEmpty
                          ? _empty(context)
                          : ListView.builder(
                              padding: widget.padding,
                              itemCount: list.length,
                              itemBuilder: (context, index) => _dataRow(
                                context,
                                list,
                                index,
                                columns,
                                byFile,
                                selection,
                                scale,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ),
          ),
        );
      },
    );
  }

  /// 고정 '이름' 컬럼 + 태그 컬럼들의 서술자. build와 키보드 핸들러가 같은 컬럼
  /// 집합을 쓰도록 한곳에 둔다.
  List<_Col> _columnsFrom(List<TagDefinition> tagCols) => [
    _Col(
      widthKey: kDetailNameColumnId,
      sortId: SystemTag.fileName.id,
      label: '이름',
      valueType: TagValueType.text,
      reorderable: false,
      isName: true,
    ),
    for (final d in tagCols)
      _Col(
        widthKey: d.id!,
        sortId: d.id!,
        label: d.name,
        valueType: d.valueType,
        definition: d,
      ),
  ];

  // ── 키보드 내비게이션 ──

  /// 방향키·Enter·Delete를 이 뷰의 동작으로 잇는다(포커스가 이 뷰에 있을 때만 먹는다).
  /// 셀 편집 중엔 [_editFocus]가 안쪽에서 포커스를 쥐어 방향키·Enter·Delete가 입력창의
  /// 동작이 되고 이 바인딩엔 닿지 않는다.
  Map<ShortcutActivator, VoidCallback> _shortcuts() => {
    const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
        _moveRow(1, _DetailMove.single),
    const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
        _moveRow(-1, _DetailMove.single),
    const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): () =>
        _moveRow(1, _DetailMove.range),
    const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): () =>
        _moveRow(-1, _DetailMove.range),
    const SingleActivator(LogicalKeyboardKey.arrowDown, control: true): () =>
        _moveRow(1, _DetailMove.cursorOnly),
    const SingleActivator(LogicalKeyboardKey.arrowUp, control: true): () =>
        _moveRow(-1, _DetailMove.cursorOnly),
    const SingleActivator(LogicalKeyboardKey.arrowRight): () => _moveCol(1),
    const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _moveCol(-1),
    const SingleActivator(LogicalKeyboardKey.enter): _onEnter,
    const SingleActivator(LogicalKeyboardKey.enter, control: true):
        _toggleCursorSelection,
    const SingleActivator(LogicalKeyboardKey.delete): _clearCell,
  };

  /// Ctrl+Enter: 커서 행을 다중 선택에 넣거나 뺀다(이미 선택돼 있으면 해제).
  void _toggleCursorSelection() {
    _navFocus.requestFocus();
    final nodeId = _cursorNodeId;
    if (nodeId == null) return;
    ref.read(selectionControllerProvider.notifier).toggle(nodeId);
  }

  /// 행을 위/아래로 옮긴다. [mode]대로 선택을 함께 바꾼다(단일/범위/커서만). 열 커서는
  /// 유지한다.
  void _moveRow(int delta, _DetailMove mode) {
    _navFocus.requestFocus();
    final list = ref.read(detailRowsProvider).valueOrNull;
    if (list == null || list.isEmpty) return;
    final ids = [
      for (final n in list)
        if (n.id != null) n.id!,
    ];
    final current =
        _cursorNodeId ?? ref.read(selectionControllerProvider).singleOrNull;
    final next = stepNodeCursor(ids, current, delta);
    if (next == null) return;
    setState(() => _cursorNodeId = next);
    final ctl = ref.read(selectionControllerProvider.notifier);
    switch (mode) {
      case _DetailMove.single:
        ctl.selectSingle(next);
      case _DetailMove.range:
        ctl.selectRange(ids, next);
      case _DetailMove.cursorOnly:
        break;
    }
  }

  /// 셀(열) 커서를 좌우로 옮긴다. 행 선택은 그대로. 커서 행이 없으면 단일 선택 행에
  /// 커서를 세운다.
  void _moveCol(int delta) {
    _navFocus.requestFocus();
    final colCount = 1 + ref.read(detailTagColumnsProvider).length;
    final rowId =
        _cursorNodeId ?? ref.read(selectionControllerProvider).singleOrNull;
    if (rowId == null) return;
    setState(() {
      _cursorNodeId = rowId;
      _cursorCol = (_cursorCol + delta).clamp(0, colCount - 1);
    });
    _revealCol(_cursorCol);
  }

  /// Enter: 편집 가능한 태그 셀이면 그 셀의 인라인 편집을 시작한다(label 토글·link
  /// 선택기·값 입력, 기존 더블탭 편집과 같은 경로). 이름·시스템 셀이면 커서==단일선택일
  /// 때 파일 활성(프리뷰), 아니면 그 행을 선택으로 확정한다.
  void _onEnter() {
    final rowId = _cursorNodeId;
    if (rowId == null) return;
    final node = _nodeById(rowId);
    if (node == null) return;
    final columns = _columnsFrom(ref.read(detailTagColumnsProvider));
    final col = columns[_cursorCol.clamp(0, columns.length - 1)];
    if (col.editable) {
      final byFile = ref.read(effectiveAssignmentsByFileProvider);
      // 편집하는 셀의 파일을 선택해 프리뷰가 어긋나지 않게 한다(더블탭 편집과 같은 이유).
      ref.read(selectionControllerProvider.notifier).selectSingle(rowId);
      _onCellDoubleTap(node, col, byFile);
      return;
    }
    if (ref.read(selectionControllerProvider).singleOrNull == rowId) {
      if (!node.isDirectory) widget.onActivateFile(node);
    } else {
      ref.read(selectionControllerProvider.notifier).selectSingle(rowId);
    }
  }

  /// Delete: 편집 가능한 태그 셀이면 그 행에서 그 태그 부여를 통째로 제거한다(전 값
  /// 해제). 이름·시스템 셀은 무동작.
  Future<void> _clearCell() async {
    final rowId = _cursorNodeId;
    if (rowId == null) return;
    final columns = _columnsFrom(ref.read(detailTagColumnsProvider));
    final col = columns[_cursorCol.clamp(0, columns.length - 1)];
    if (!col.editable) return;
    await ref
        .read(tagRepositoryProvider)
        ?.unassignFromFiles(fileNodeIds: [rowId], tagDefinitionId: col.sortId);
  }

  FileNode? _nodeById(int id) {
    final list = ref.read(detailRowsProvider).valueOrNull ?? const [];
    for (final n in list) {
      if (n.id == id) return n;
    }
    return null;
  }

  /// 셀(열) 커서가 가로 스크롤 밖에 있으면 그 열이 보이도록 스크롤한다.
  void _revealCol(int colIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_horizontal.hasClients) return;
      final columns = _columnsFrom(ref.read(detailTagColumnsProvider));
      if (colIndex < 0 || colIndex >= columns.length) return;
      var before = 0.0;
      for (var i = 0; i < colIndex; i++) {
        before += _widthOf(columns[i].widthKey);
      }
      final width = _widthOf(columns[colIndex].widthKey);
      final viewport = _horizontal.position.viewportDimension;
      final start = _horizontal.offset;
      final end = start + viewport;
      double? target;
      if (before < start) {
        target = before;
      } else if (before + width > end) {
        target = before + width - viewport;
      }
      if (target == null) return;
      final to = target.clamp(0.0, _horizontal.position.maxScrollExtent);
      // 데스크톱은 stateChangeDuration이 0이라 animateTo가 단언(>0)에 걸린다 — 그땐
      // 곧바로 점프한다(애니메이션을 끄는 데스크톱 방침과도 맞다).
      if (stateChangeDuration == Duration.zero) {
        _horizontal.jumpTo(to);
      } else {
        _horizontal.animateTo(
          to,
          duration: stateChangeDuration,
          curve: Curves.linear,
        );
      }
    });
  }

  Widget _empty(BuildContext context) {
    final filterActive = !ref.watch(fileFilterProvider).isEmpty;
    return Center(
      child: Text(
        filterActive ? '필터 조건에 맞는 파일이 없습니다.' : '이 폴더에는 표시할 파일이 없습니다.',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }

  // ── 헤더 ──

  Widget _headerRow(BuildContext context, List<_Col> columns, FileSortOrder sort) {
    return Row(
      children: [for (final col in columns) _headerCell(context, col, sort)],
    );
  }

  Widget _headerCell(BuildContext context, _Col col, FileSortOrder sort) {
    final width = _widthOf(col.widthKey);
    Widget cell = _headerContent(context, col, sort);
    if (col.reorderable) {
      final scheme = Theme.of(context).colorScheme;
      cell = DragTarget<int>(
        onWillAcceptWithDetails: (d) => d.data != col.sortId,
        onAcceptWithDetails: (d) => _reorderColumn(d.data, col.sortId),
        builder: (context, candidate, rejected) => Draggable<int>(
          data: col.sortId,
          feedback: Material(
            elevation: 4,
            child: SizedBox(
              width: width,
              child: _headerContent(context, col, sort),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.4,
            child: _headerContent(context, col, sort),
          ),
          child: ColoredBox(
            color: candidate.isEmpty
                ? Colors.transparent
                : scheme.primaryContainer,
            child: _headerContent(context, col, sort),
          ),
        ),
      );
    }
    return SizedBox(
      width: width,
      child: Stack(
        children: [
          // 셀 내용은 non-positioned 자식으로 두어 Stack이 그 높이에 맞춰지게 한다
          // (모두 Positioned면 높이가 무한이 되어 제약 오류가 난다).
          cell,
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            child: _resizeHandle(col.widthKey),
          ),
        ],
      ),
    );
  }

  /// 헤더 라벨 + 정렬 방향 화살표. 탭하면 이 컬럼을 최상위 우선순위로 정렬에 올리거나
  /// (이미 최상위면) 방향을 뒤집는다.
  ///
  /// 화살표는 **현재 최상위 우선순위 컬럼에만** 보인다 — 다단계 정렬이라도 우선순위
  /// 숫자를 표기하지 않으므로, 방향 표식을 여럿 두면 어느 것이 먼저인지 헷갈린다.
  Widget _headerContent(BuildContext context, _Col col, FileSortOrder sort) {
    final top = sort.keys.isEmpty ? null : sort.keys.first;
    final sortKey = top?.tagDefinitionId == col.sortId ? top : null;
    return InkWell(
      onTap: () => _toggleSort(col.sortId),
      child: Padding(
        // 폭 조절 손잡이 자리를 오른쪽에 비워 라벨과 겹치지 않게 한다.
        padding: EdgeInsets.fromLTRB(8, 6, _resizeHandleWidth, 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                col.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            if (sortKey != null) _sortArrow(context, sortKey.direction),
          ],
        ),
      ),
    );
  }

  Widget _sortArrow(BuildContext context, SortDirection direction) {
    return Icon(
      direction == SortDirection.ascending
          ? Icons.arrow_upward
          : Icons.arrow_downward,
      size: 14,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _resizeHandle(int key) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (details) {
          setState(() {
            _resizing[key] = (_widthOf(key) + details.delta.dx).clamp(
              kDetailColumnWidthMin,
              kDetailColumnWidthMax,
            );
          });
        },
        onHorizontalDragEnd: (_) {
          final width = _resizing.remove(key);
          if (width != null) {
            ref
                .read(viewSettingsProvider.notifier)
                .updateDetailColumnWidth(key, width);
          }
          setState(() {});
        },
        child: const SizedBox(
          width: _resizeHandleWidth,
          child: VerticalDivider(width: _resizeHandleWidth, thickness: 1),
        ),
      ),
    );
  }

  // ── 데이터 행 ──

  Widget _dataRow(
    BuildContext context,
    List<FileNode> list,
    int index,
    List<_Col> columns,
    Map<int, List<AssignedTag>> byFile,
    SelectionState selection,
    double scale,
  ) {
    final node = list[index];
    final scheme = Theme.of(context).colorScheme;
    final selected = node.id != null && selection.contains(node.id!);
    final rowCursored = node.id != null && node.id == _cursorNodeId;
    // 선택(탭)·길게 누르기는 행 전체가 받고, 더블탭·우클릭은 셀마다 받아 그 셀의
    // 태그를 곧바로 고친다(엑셀식 인라인 편집). 편집 대상이 아닌 셀(이름·시스템
    // 태그)의 더블탭·우클릭은 행 동작(파일 열기·셸 메뉴)으로 넘긴다.
    return EnsureVisibleOnFocus(
      active: rowCursored,
      child: Material(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        animationDuration: stateChangeDuration,
        child: InkWell(
          onTap: () {
            _navFocus.requestFocus();
            if (node.id != null) setState(() => _cursorNodeId = node.id);
            widget.onTapNode(list, index);
          },
          onLongPress: widget.onLongPressNode == null
              ? null
              : () => widget.onLongPressNode!(list, index),
          hoverColor: Colors.transparent,
          // 인라인 편집이 행 안(TextField)에 키보드 포커스를 두는데, Enter·Esc로 편집을
          // 마치면 포커스 하이라이트 모드가 켜지며 포커스가 이 행으로 되돌아온다. 그때
          // 행마다 회색 포커스 덧칠이 남아 선택색(primaryContainer)과 뒤섞인다. 선택은
          // 오직 Material 배경색으로만 보이면 되므로, 행이 포커스를 쥐지도(회색 덧칠도
          // 나지) 않게 한다(다른 데스크톱 목록·버튼의 잉크 해제와 같은 취지).
          canRequestFocus: false,
          focusColor: Colors.transparent,
          mouseCursor: SystemMouseCursors.basic,
          // 세로 ListView 항목은 높이가 무한이라 stretch를 쓰면 셀 높이가 무한이 된다.
          // 셀은 내용 높이에 맡기고, 행 높이는 가장 큰 셀(썸네일 있는 이름 셀)로 정한다.
          child: Row(
            children: [
              for (final (colIndex, col) in columns.indexed)
                SizedBox(
                  width: _widthOf(col.widthKey),
                  child: _cellRing(
                    rowCursored && colIndex == _cursorCol,
                    scheme.primary,
                    _cellGestures(
                      context,
                      list,
                      index,
                      col,
                      byFile,
                      _cell(context, node, col, byFile, scale, selected),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 셀 커서 링. 커서가 이 셀에 있을 때만 색이 보이고, 아니면 투명 테두리로 자리만
  /// 지켜 셀 폭·높이가 흔들리지 않는다.
  Widget _cellRing(bool focused, Color color, Widget child) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: focused ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: child,
    );
  }

  /// 셀 하나에 더블탭·우클릭 손잡이를 얹는다. 편집 가능한 사용자 태그 셀이면
  /// 인라인 편집·셀 메뉴로, 아니면 행 동작(파일 열기·셸 컨텍스트 메뉴)으로 잇는다.
  Widget _cellGestures(
    BuildContext context,
    List<FileNode> list,
    int index,
    _Col col,
    Map<int, List<AssignedTag>> byFile,
    Widget child,
  ) {
    final node = list[index];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: col.editable
          // 셀을 고치면 그 파일도 선택한다 — 더블탭은 단일 선택 탭을 삼켜서, 선택
          // 없이 편집되면(프리뷰가 다른 파일을 가리킨 채) 헷갈린다.
          ? () {
              widget.onTapNode(list, index);
              _onCellDoubleTap(node, col, byFile);
            }
          : () => _onDoubleTap(node),
      onSecondaryTapDown: col.editable
          ? (d) => _showCellMenu(node, col, byFile, d.globalPosition)
          : widget.onSecondaryTapNode == null
          ? null
          : (d) => widget.onSecondaryTapNode!(list, index, d.globalPosition),
      child: child,
    );
  }

  Widget _cell(
    BuildContext context,
    FileNode node,
    _Col col,
    Map<int, List<AssignedTag>> byFile,
    double scale,
    bool selected,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: selected
          ? scheme.onPrimaryContainer
          : node.isMissing
          ? scheme.error
          : null,
    );
    if (col.isName) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            FileThumbnail(
              node: node,
              dimension: _baseThumb * scale,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                node.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          ],
        ),
      );
    }
    final editing =
        _editNode?.id == node.id && _editCol?.sortId == col.sortId;
    if (editing) return _editField(context, col, style);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          _cellText(node, col, byFile),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
    );
  }

  /// 한 셀의 표시 문자열. label 태그는 부여 여부 표식('✓'), 값 태그는 값(다중이면
  /// 쉼표로 이음)을 보인다.
  String _cellText(FileNode node, _Col col, Map<int, List<AssignedTag>> byFile) {
    final tags = byFile[node.id] ?? const <AssignedTag>[];
    if (col.valueType == TagValueType.label) {
      final present = tags.any((t) => t.tagDefinitionId == col.sortId);
      return present ? '✓' : '';
    }
    // 링크는 저장값(대상 노드 id)이 아니라 대상 이름을 보인다(찾지 못하면 없음 표식).
    if (col.valueType == TagValueType.link) {
      final byId = ref.read(fileNodesByIdProvider);
      final names = <String>[
        for (final t in tags)
          if (t.tagDefinitionId == col.sortId && t.value != null)
            byId[int.tryParse(t.value!)]?.name ?? '(없음)',
      ];
      return names.join(', ');
    }
    final values = <String>[];
    for (final t in tags) {
      if (t.tagDefinitionId != col.sortId) continue;
      final formatted = formatTagValue(col.valueType, t.value);
      if (formatted != null) values.add(formatted);
    }
    return values.join(', ');
  }

  // ── 인라인 편집 ──

  /// 편집 중인 셀에 뜨는 입력창. Enter·포커스 잃음이 확정, Esc가 취소다. 다중 부여
  /// 태그면 여러 값을 콤마로(텍스트는 쌍따옴표+콤마) 담는다. 숫자·날짜 셀은 그
  /// 유형에 쓰이는 글자만 받아(다중이면 구분용 콤마·공백 포함) 엉뚱한 문자를 막는다.
  Widget _editField(BuildContext context, _Col col, TextStyle? style) {
    final numeric =
        col.valueType == TagValueType.number ||
        col.valueType == TagValueType.date;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _cancelEdit,
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: TextField(
          controller: _editController,
          focusNode: _editFocus,
          autofocus: true,
          style: style,
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                )
              : TextInputType.text,
          inputFormatters: _editFormatters(col),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _commitEdit(),
        ),
      ),
    );
  }

  /// 유형별 허용 문자 필터. 텍스트는 제한이 없고, 숫자·날짜는 그 유형이 쓰는 글자만
  /// 받는다(다중 부여면 값을 가르는 콤마·공백을 함께 허용). 형식 자체의 유효성은
  /// 확정 시 [parseCellEditText]가 걸러 낸다.
  List<TextInputFormatter>? _editFormatters(_Col col) {
    final multi = col.definition?.allowMultiple ?? false;
    final sep = multi ? ', ' : '';
    switch (col.valueType) {
      case TagValueType.number:
        return [FilteringTextInputFormatter.allow(RegExp('[0-9.\\-$sep]'))];
      case TagValueType.date:
        return [FilteringTextInputFormatter.allow(RegExp('[0-9\\-$sep]'))];
      case TagValueType.text:
      case TagValueType.label:
      // link 셀은 인라인 텍스트 편집이 아니라 노드 선택기로 고치므로 이 경로를 타지
      // 않는다(제한 없음으로 둔다).
      case TagValueType.link:
        return null;
    }
  }

  /// 편집 대상 셀의 더블탭: label은 부여/해제를 바로 뒤집고, 값 태그는 인라인
  /// 입력창을 띄운다.
  void _onCellDoubleTap(
    FileNode node,
    _Col col,
    Map<int, List<AssignedTag>> byFile,
  ) {
    if (col.valueType == TagValueType.label) {
      _toggleLabel(node, col, byFile);
    } else if (col.valueType == TagValueType.link) {
      _editLinkCell(node, col, byFile);
    } else {
      _beginEdit(node, col, byFile);
    }
  }

  /// 링크 셀 편집: 인라인 텍스트 대신 노드 선택기를 띄워 대상을 다시 고르고, 이 파일의
  /// 그 링크 태그 부여를 고른 대상 하나로 교체한다.
  Future<void> _editLinkCell(
    FileNode node,
    _Col col,
    Map<int, List<AssignedTag>> byFile,
  ) async {
    final repo = ref.read(tagRepositoryProvider);
    final id = node.id;
    if (repo == null || id == null) return;
    final current = _storedValuesOf(node, col, byFile);
    final picked = await pickLinkTarget(
      context,
      initial: current.isEmpty ? null : current.first,
    );
    if (picked == null) return;
    await repo.unassignFromFiles(fileNodeIds: [id], tagDefinitionId: col.sortId);
    await repo.assignToFiles(
      fileNodeIds: [id],
      tagDefinitionId: col.sortId,
      value: picked,
    );
  }

  /// 이 파일에 붙은 [col] 태그의 저장값들(값 없는 부여는 뺀다).
  List<String> _storedValuesOf(
    FileNode node,
    _Col col,
    Map<int, List<AssignedTag>> byFile,
  ) => [
    for (final t in (byFile[node.id] ?? const <AssignedTag>[]))
      if (t.tagDefinitionId == col.sortId && t.value != null) t.value!,
  ];

  void _beginEdit(
    FileNode node,
    _Col col,
    Map<int, List<AssignedTag>> byFile,
  ) {
    // 다른 셀을 편집 중이었다면 먼저 확정한다(같은 포커스라 포커스 잃음이 안 온다).
    if (_editNode != null) _commitEdit();
    final allowMultiple = col.definition?.allowMultiple ?? false;
    _editController.text = formatCellEditText(
      col.valueType,
      allowMultiple,
      _storedValuesOf(node, col, byFile),
    );
    _editController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _editController.text.length,
    );
    setState(() {
      _editNode = node;
      _editCol = col;
    });
    _editFocus.requestFocus();
  }

  /// 편집 확정: 입력을 값 목록으로 해석해 이 파일의 [col] 부여를 통째로 교체한다
  /// (전부 해제 후 값마다 다시 부여). 빈 입력이면 태그가 사라진다.
  void _commitEdit() {
    final node = _editNode;
    final col = _editCol;
    if (node == null || col == null) return;
    final text = _editController.text;
    setState(() {
      _editNode = null;
      _editCol = null;
    });
    _applyCellEdit(node, col, text);
  }

  void _cancelEdit() {
    setState(() {
      _editNode = null;
      _editCol = null;
    });
  }

  Future<void> _applyCellEdit(FileNode node, _Col col, String text) async {
    final repo = ref.read(tagRepositoryProvider);
    final id = node.id;
    if (repo == null || id == null) return;
    final allowMultiple = col.definition?.allowMultiple ?? false;
    final values = parseCellEditText(col.valueType, allowMultiple, text);
    await repo.unassignFromFiles(
      fileNodeIds: [id],
      tagDefinitionId: col.sortId,
    );
    for (final value in values) {
      await repo.assignToFiles(
        fileNodeIds: [id],
        tagDefinitionId: col.sortId,
        value: value,
      );
    }
  }

  Future<void> _toggleLabel(
    FileNode node,
    _Col col,
    Map<int, List<AssignedTag>> byFile,
  ) async {
    final repo = ref.read(tagRepositoryProvider);
    final id = node.id;
    if (repo == null || id == null) return;
    final present = (byFile[id] ?? const <AssignedTag>[])
        .any((t) => t.tagDefinitionId == col.sortId);
    if (present) {
      await repo.unassignFromFiles(
        fileNodeIds: [id],
        tagDefinitionId: col.sortId,
      );
    } else {
      await repo.assignToFiles(fileNodeIds: [id], tagDefinitionId: col.sortId);
    }
  }

  /// 편집 대상 셀의 우클릭 메뉴: '추가'(그 태그를 미리 고른 부여 다이얼로그)와,
  /// 이미 붙어 있으면 '제거'(이 파일에서 그 태그 해제).
  Future<void> _showCellMenu(
    FileNode node,
    _Col col,
    Map<int, List<AssignedTag>> byFile,
    Offset globalPosition,
  ) async {
    final id = node.id;
    if (id == null) return;
    // 선택 밖의 셀을 우클릭하면 그 파일을 먼저 선택한다(탐색기와 같은 관용, 셸의
    // 행 우클릭 처리와 동일). 이미 선택에 든 파일이면 다중 선택을 흩뜨리지 않는다.
    if (!ref.read(selectionControllerProvider).contains(id)) {
      ref.read(selectionControllerProvider.notifier).selectSingle(id);
    }
    final present = (byFile[id] ?? const <AssignedTag>[])
        .any((t) => t.tagDefinitionId == col.sortId);
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        globalPosition & Size.zero,
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem(value: 'add', child: Text('추가…')),
        if (present)
          const PopupMenuItem(value: 'remove', child: Text('제거')),
      ],
    );
    if (!mounted) return;
    if (selected == 'add') {
      await showTagAssignDialog(
        context,
        fileNodeIds: [id],
        title: node.name,
        preselectTagId: col.sortId,
      );
    } else if (selected == 'remove') {
      await ref
          .read(tagRepositoryProvider)
          ?.unassignFromFiles(fileNodeIds: [id], tagDefinitionId: col.sortId);
    }
  }

  // ── 조작 ──

  /// 헤더 클릭: 방금 클릭한 컬럼이 늘 **최상위 우선순위**가 되도록 정렬 맨 앞으로
  /// 올린다(보편적인 표처럼 마지막 클릭이 1순위). 새 컬럼은 오름차순으로 올리고,
  /// 이미 정렬에 있던 컬럼은 방향을 뒤집으며 앞으로 올린다(해제는 없다).
  void _toggleSort(int sortId) {
    final keys = [...ref.read(detailSortProvider).keys];
    final index = keys.indexWhere((k) => k.tagDefinitionId == sortId);
    final key = index >= 0
        ? keys.removeAt(index).toggled()
        : SortKey(tagDefinitionId: sortId);
    keys.insert(0, key);
    ref
        .read(viewSettingsProvider.notifier)
        .updateDetailSort(FileSortOrder(keys: keys));
  }

  /// 컬럼 [draggedId]를 [targetId] 앞으로 끼워 넣어 좌우 순서를 바꾼다. 순서는
  /// 목록·프리뷰와 공유하는 태그 표시 순서에 저장된다.
  void _reorderColumn(int draggedId, int targetId) {
    final order = [for (final d in ref.read(detailTagColumnsProvider)) d.id!];
    order.remove(draggedId);
    var target = order.indexOf(targetId);
    if (target < 0) target = order.length;
    order.insert(target, draggedId);
    ref.read(viewSettingsProvider.notifier).updateTagDisplayOrder(order);
  }

  /// 더블클릭(활성): 파일이면 셸에 프리뷰를 위임한다. 폴더는 계층이 없는 평면
  /// 테이블이라 아무 것도 하지 않는다.
  void _onDoubleTap(FileNode node) {
    if (!node.isDirectory) widget.onActivateFile(node);
  }
}
