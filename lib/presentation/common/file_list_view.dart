import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/assigned_tag.dart';
import '../../domain/entities/file_node.dart';
import '../../domain/entities/file_tree_node.dart';
import '../../domain/entities/folder_manage_mode.dart';
import '../../domain/entities/system_tag.dart';
import '../../domain/usecases/tag_display_order.dart';
import '../providers/file_view_provider.dart';
import '../providers/system_tag_provider.dart';
import '../theme.dart';
import '../widgets/file_thumbnail.dart';
import '../widgets/tag_capsule.dart';
import '../widgets/tag_chip.dart';
import 'selection_controller.dart';

/// 트리를 편 뒤의 한 표시 행(노드 + 깊이 + 펼침 상태).
class TreeRow {
  const TreeRow({
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

/// 필터·정렬된 트리를 표시 순서의 평면 행으로 편다. 접힌 폴더의 자식은 건너뛴다.
/// [expandAll]이면(필터 활성 등) 접힘 상태를 무시하고 전부 편다.
///
/// 셸(데스크톱/모바일)이 표시 순서를 알아야 하는 조작(범위 선택·전체 선택)에서도
/// 같은 결과를 쓰도록 순수 함수로 둔다.
List<TreeRow> flattenTree(
  List<FileTreeNode> roots, {
  required Set<String> expandedFolders,
  required bool expandAll,
}) {
  final rows = <TreeRow>[];
  void walk(List<FileTreeNode> nodes, int depth) {
    for (final n in nodes) {
      final expandable = n.hasChildren;
      final expanded = expandAll || expandedFolders.contains(n.node.path);
      rows.add(
        TreeRow(
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

/// 들여쓰기로 표현하는 최대 계층 단계. 더 깊은 노드는 이 단계로 함께 눌러 파일명
/// 자리가 화면 밖으로 밀려나지 않게 한다(계층 자체는 가이드 라인·캐럿이 드러낸다).
const int kMaxIndentDepth = 6;

/// 트리 깊이를 실제로 들여쓸 단계로 가둔다.
int visualIndentDepth(int depth) => depth.clamp(0, kMaxIndentDepth);

/// 파일 트리를 평면 목록으로 렌더하는, 셸에 독립적인 목록 뷰.
///
/// 필터·정렬·태그 표시 순서·선택 상태·펼침 상태는 provider에서 직접 읽고, 입력
/// 해석(보조키 vs 선택 모드)과 행 끝 위젯(체크박스 등)만 셸이 주입한다.
class FileListView extends ConsumerWidget {
  const FileListView({
    super.key,
    required this.onTapNode,
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
  Widget build(BuildContext context, WidgetRef ref) {
    final tree = ref.watch(fileTreeProvider);
    final assignmentsByFile = ref.watch(effectiveAssignmentsByFileProvider);
    final visibleSystemTagIds = ref.watch(visibleSystemTagIdsProvider);
    final tagDisplayOrder = ref.watch(effectiveTagDisplayOrderProvider);
    final resolvedModes = ref.watch(folderResolvedModesProvider);
    final filterActive = !ref.watch(fileFilterProvider).isEmpty;
    final selection = ref.watch(selectionControllerProvider);
    final expandedFolders = ref.watch(expandedFoldersProvider);

    return tree.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('목록을 불러오지 못했습니다: $e'),
      data: (roots) {
        // 필터가 걸리면 매치를 드러내기 위해 접힘 상태와 무관하게 전부 편다.
        final rows = flattenTree(
          roots,
          expandedFolders: expandedFolders,
          expandAll: filterActive,
        );
        if (rows.isEmpty) {
          return Text(
            filterActive ? '필터 조건에 맞는 파일이 없습니다.' : '이 폴더에는 표시할 파일이 없습니다.',
          );
        }
        // 범위 선택(shift)이 표시 순서로 동작하도록 편 노드 목록을 넘긴다.
        final items = [for (final r in rows) r.node];
        return ListView.builder(
          padding: padding,
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final row = rows[index];
            final node = row.node;
            // 실제 폴더만 상속 반영 모드를 갖는다. 파일·보존 노드는 null.
            final resolved = node.isDirectory && !node.isMissing
                ? (resolvedModes[node.path] ?? FolderManageMode.managed)
                : null;
            final tile = FileNodeTile(
              node: node,
              depth: row.depth,
              expandable: row.expandable,
              expanded: row.expanded,
              onToggleExpand: row.expandable
                  ? () => ref
                        .read(viewSettingsProvider.notifier)
                        .toggleExpandedFolder(node.path)
                  : null,
              selected: node.id != null && selection.contains(node.id!),
              assignments: orderAssignedTags(
                assignmentsByFile[node.id] ?? const [],
                tagDisplayOrder,
              ),
              visibleSystemTagIds: visibleSystemTagIds,
              onTap: () => onTapNode(items, index),
              onLongPress: onLongPressNode == null
                  ? null
                  : () => onLongPressNode!(items, index),
              onSecondaryTap: onSecondaryTapNode == null
                  ? null
                  : (position) => onSecondaryTapNode!(items, index, position),
              onEditAssignment: onEditAssignment,
              inlineEdit: inlineEdit,
              onRemoveAssignment: onRemoveAssignment,
              onAddTag: onAddTag == null ? null : () => onAddTag!(node),
              folderMode: resolved,
              trailing: trailingBuilder?.call(node, resolved),
            );
            return tileWrapper?.call(node, tile) ?? tile;
          },
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
    required this.assignments,
    required this.visibleSystemTagIds,
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
  });

  /// 계층 한 단계당 들여쓰기 폭.
  static const double _indentUnit = 16;

  /// 목록 좌우 여백(들여쓰기의 기준점이자 가이드 라인의 시작 x).
  static const double _rowInset = 4;

  final FileNode node;
  final bool selected;

  /// 이미 표시 순서로 정렬된 부여 태그 목록.
  final List<AssignedTag> assignments;

  /// 칩으로 표시할 시스템 태그 id 집합. 여기 없는 시스템 태그 칩은 렌더하지 않는다
  /// (값은 필터·정렬에 여전히 참여). 사용자 태그 칩은 이 집합과 무관하게 항상 표시.
  final Set<int> visibleSystemTagIds;
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
    final indent = visualIndentDepth(depth);
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
                    width: 28,
                    child: expandable
                        ? IconButton(
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            iconSize: 20,
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
                  if (inlineEdit) ...[
                    const SizedBox(height: 4),
                    _inlineTagRow(),
                  ] else if (_visibleTags.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final a in _visibleTags)
                          TagChip(
                            definition: a.definition,
                            value: a.value,
                            // 값 태그만 눌러 편집 가능. 시스템 태그는 수정 가능한
                            // '파일 이름'만 눌러 rename, 나머지는 표시 전용.
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
        ),
      ),
    );
  }

  /// 목록 수정 모드의 태그 줄. 프리뷰 창처럼 칩을 눌러 값을 고치고 x로 해제한다.
  /// 칩이 많으면 줄바꿈 대신 가로로 스크롤해 행 높이를 지키고, '+' 버튼은 스크롤
  /// 바깥 고정 자리에 두어 칩 수와 무관하게 늘 닿을 수 있게 한다.
  Widget _inlineTagRow() {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final a in _visibleTags)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: TagChip(
                      definition: a.definition,
                      value: a.value,
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
              ],
            ),
          ),
        ),
        CapsuleAddButton(tooltip: '태그 추가', onPressed: onAddTag),
      ],
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
