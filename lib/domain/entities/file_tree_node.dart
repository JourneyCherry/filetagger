import 'file_node.dart';

/// 계층(그룹) 표시용 트리 노드. 파일/폴더 [node]와 그 아래 표시할 자식들.
///
/// 필터·정렬이 적용된 뒤의 표시 트리다: 자식은 정렬된 순서이고, 필터가 걸리면
/// 매치되지 않는 가지는 이미 걷어내진 상태다(매치된 노드와 그 조상만 남는다).
class FileTreeNode {
  const FileTreeNode(this.node, this.children);

  final FileNode node;
  final List<FileTreeNode> children;

  bool get hasChildren => children.isNotEmpty;
}
