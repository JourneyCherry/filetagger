import 'file_node.dart';

/// 계층·그룹 표시용 트리의 한 항목. 실제 파일/폴더 노드([FileTreeNode])이거나,
/// 태그값으로 묶은 합성 그룹 헤더([GroupHeaderNode])다.
///
/// 필터·정렬·그룹이 적용된 뒤의 표시 트리다: 형제는 정렬된 순서이고, 필터가
/// 걸리면 매치되지 않는 가지는 이미 걷어내진 상태다. 폴더 계층 그룹은 실제 폴더를
/// [FileTreeNode]로 그대로 두고, 태그값 그룹만 [GroupHeaderNode]로 버킷을 만든다.
sealed class TreeItem {
  const TreeItem();

  /// 이 항목 아래 표시할 자식들(그룹 헤더의 버킷 내용, 폴더의 자식 등).
  List<TreeItem> get children;
}

/// 파일/폴더 [node]와 그 아래 표시할 자식들. 폴더 계층에서 폴더는 자식을 갖고,
/// 파일(리프)은 자식이 없다.
final class FileTreeNode extends TreeItem {
  const FileTreeNode(this.node, this.children);

  final FileNode node;

  @override
  final List<TreeItem> children;

  bool get hasChildren => children.isNotEmpty;
}

/// 한 태그값으로 묶은 그룹 버킷의 헤더(합성 노드). 값별 파일 수를 표기해
/// "태그값별 가짓수"를 드러낸다(다중값 중복 소속으로 합이 전체보다 클 수 있다).
final class GroupHeaderNode extends TreeItem {
  const GroupHeaderNode({
    required this.tagDefinitionId,
    required this.value,
    required this.fileCount,
    required this.children,
  });

  /// 이 버킷을 만든 그룹 단계의 태그 정의 id. 표시 이름·유형 해석에 쓴다.
  final int tagDefinitionId;

  /// 이 버킷의 태그값. 값 없는 항목을 모은 "(미분류)" 버킷이면 null.
  final String? value;

  /// 이 버킷에 속한 파일(비디렉토리) 수. 다중값 중복 소속을 그대로 센다.
  final int fileCount;

  @override
  final List<TreeItem> children;

  /// 값 없는 항목을 모은 버킷인지.
  bool get isUnclassified => value == null;
}

/// 트리에 남은 실제 파일/폴더 노드 수(그룹 헤더는 세지 않고, 그 안은 내려가 센다).
/// 필터를 통과한 항목 수를 세는 데 쓴다. 값 그룹이 걸리면 다중값 중복만큼 같은
/// 노드가 여러 버킷에 들어 합이 늘 수 있다.
int countTreeNodes(List<TreeItem> roots) {
  var count = 0;
  for (final item in roots) {
    if (item is FileTreeNode) count += 1;
    count += countTreeNodes(item.children);
  }
  return count;
}

/// 트리 아래 파일(비디렉토리) 리프 수. 그룹 헤더의 [GroupHeaderNode.fileCount]가
/// 이 값을 담는다(폴더 안에 중첩된 파일도 함께 센다).
int countFileLeaves(List<TreeItem> roots) {
  var count = 0;
  for (final item in roots) {
    if (item is FileTreeNode && !item.node.isDirectory) count += 1;
    count += countFileLeaves(item.children);
  }
  return count;
}
