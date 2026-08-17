/// 표시 트리를 화면에 놓이는 순서의 **평면 행**으로 펴는 순수 로직.
///
/// 목록 렌더뿐 아니라 셸(범위 선택·전체 선택·키보드 커서)도 같은 순서를 알아야 해서,
/// 위젯에서 떼어 여기에 둔다(프로바이더가 한 번 계산해 둘이 나눠 쓴다).
library;

import '../../domain/entities/file_node.dart';
import '../../domain/entities/file_tree_node.dart';

/// 트리를 편 뒤의 한 표시 행. 실제 파일/폴더 노드([FileTreeNode])이거나 태그값
/// 버킷의 그룹 헤더([GroupHeaderNode])다. 폴더·헤더는 접었다 펼 수 있고
/// ([expandable]), 헤더는 선택 대상이 아니다([nodeIndex]가 null).
class TreeRow {
  const TreeRow({
    required this.item,
    required this.depth,
    required this.expandable,
    required this.expanded,
    required this.expandKey,
    this.nodeIndex,
  });

  final TreeItem item;
  final int depth;
  final bool expandable;
  final bool expanded;

  /// 펼침 상태를 저장·조회할 키. 폴더는 실제 경로, 그룹 헤더는 조상 맥락을 실은
  /// 합성 키(경로엔 없는 제어문자로 시작해 폴더 경로와 겹치지 않는다)다.
  final String expandKey;

  /// 파일/폴더 노드 행이면 선택 가능한 노드 목록([FlatTree.nodes])에서의 위치.
  /// 그룹 헤더 행이면 null(선택 대상이 아니다).
  final int? nodeIndex;
}

/// [flattenTree]의 결과: 표시 행과, 그와 나란한 선택 가능한 노드 목록.
class FlatTree {
  const FlatTree({required this.rows, required this.nodes});

  static const FlatTree empty = FlatTree(rows: [], nodes: []);

  final List<TreeRow> rows;

  /// 표시 순서의 선택 가능한 노드(파일·폴더). 범위 선택·전체 선택이 이 순서를 쓴다.
  /// 다중값 그룹에선 같은 노드가 여러 버킷에 들어 여러 번 나올 수 있다.
  final List<FileNode> nodes;

  /// 표시 순서의 노드 id들(id 없는 노드는 빠진다). 커서 이동·범위 선택의 순서 기준.
  List<int> get nodeIds => [
    for (final n in nodes)
      if (n.id != null) n.id!,
  ];

  /// [ids] 중 표시 순서에서 **가장 먼저 나오는** 노드의 행 위치. 하나도 없으면 -1.
  ///
  /// 여럿을 골라 둔 채로 "그 선택이 속한 상위 행"을 물을 때의 기준이다 — 고른 것이
  /// 여러 그룹에 걸쳐 있으면 갈 곳이 여럿이라, 첫 노드 하나로 못박아야 답이 정해진다.
  /// 다중값 그룹에서 같은 노드가 여러 버킷에 나오는 것도 첫 등장으로 갈린다.
  int firstRowIndexOfAny(Set<int> ids) => rows.indexWhere((r) {
    final i = r.nodeIndex;
    return i != null && ids.contains(nodes[i].id);
  });
}

/// 필터·정렬·그룹된 트리를 표시 순서의 평면 행으로 편다. 접힌 폴더·헤더의 자식은
/// 건너뛴다. [expandAll]이면(필터 활성 등) 접힘 상태를 무시하고 전부 편다.
FlatTree flattenTree(
  List<TreeItem> roots, {
  required Set<String> expandedFolders,
  required bool expandAll,
}) {
  final rows = <TreeRow>[];
  final nodes = <FileNode>[];

  void walk(List<TreeItem> items, int depth, String keyPrefix) {
    for (final item in items) {
      switch (item) {
        case FileTreeNode(:final node, :final children):
          final expandable = children.isNotEmpty;
          final expanded = expandAll || expandedFolders.contains(node.path);
          rows.add(
            TreeRow(
              item: item,
              depth: depth,
              expandable: expandable,
              expanded: expanded,
              expandKey: node.path,
              nodeIndex: nodes.length,
            ),
          );
          nodes.add(node);
          if (expandable && expanded) walk(children, depth + 1, node.path);
        case GroupHeaderNode(:final children):
          final key = _headerKey(keyPrefix, item);
          final expandable = children.isNotEmpty;
          final expanded = expandAll || expandedFolders.contains(key);
          rows.add(
            TreeRow(
              item: item,
              depth: depth,
              expandable: expandable,
              expanded: expanded,
              expandKey: key,
            ),
          );
          if (expandable && expanded) walk(children, depth + 1, key);
      }
    }
  }

  walk(roots, 0, '');
  return FlatTree(rows: rows, nodes: nodes);
}

/// [rows]에서 [index] 행이 속한 **바로 위 행**의 위치(자기보다 얕은, 가장 가까운 앞
/// 행). 최상위 행이거나 범위 밖이면 -1.
///
/// 편 목록은 계층을 깊이로만 들고 있어(부모 포인터가 없다) 앞으로 훑어 찾는다. 폴더든
/// 그룹 헤더든 가리지 않는다 — 그 행을 담고 있는 구조가 곧 부모다.
int parentRowIndex(List<TreeRow> rows, int index) {
  if (index < 0 || index >= rows.length) return -1;
  final depth = rows[index].depth;
  if (depth == 0) return -1;
  for (var i = index - 1; i >= 0; i--) {
    if (rows[i].depth < depth) return i;
  }
  return -1;
}

/// [rows]의 [index] 행이 목록에 보이려면 펼쳐져 있어야 하는 **조상 행들의 펼침 키**
/// (바깥에서 안쪽 순서). 접힘을 무시하고 편 결과([flattenTree]의 `expandAll`)에서만
/// 뜻이 있다 — 거기서는 조상이 접혀 있어도 행이 있어 사슬을 끝까지 거슬러 오를 수 있다.
///
/// 폴더든 그룹 헤더든 가리지 않는다(둘 다 자기 펼침 키로 여닫힌다). 숨어 있는 노드를
/// 드러내는 쪽이 이 키들을 펼침 집합에 더한다.
List<String> ancestorExpandKeys(List<TreeRow> rows, int index) {
  final keys = <String>[];
  for (
    var i = parentRowIndex(rows, index);
    i >= 0;
    i = parentRowIndex(rows, i)
  ) {
    keys.add(rows[i].expandKey);
  }
  return keys.reversed.toList();
}

/// 헤더 펼침 키에서 각 조각을 시작하는 표식. 경로에 들어갈 수 없는 제어문자라 합성
/// 키가 실제 폴더 경로와 겹치지 않는다(소스에서도 보이도록 이스케이프로 적는다).
const String _headerKeyMark = '\u0000';

/// 그룹 헤더의 펼침 키. 조상 맥락([prefix])에 이 단계의 태그·값을 잇는다 — 같은 값
/// 버킷이 서로 다른 폴더 아래 놓여도 조상 경로가 달라 키가 갈린다.
String _headerKey(String prefix, GroupHeaderNode header) {
  final value = header.value == null
      ? '${_headerKeyMark}none'
      : '=${header.value}';
  return '$prefix$_headerKeyMark${header.tagDefinitionId}$value';
}
