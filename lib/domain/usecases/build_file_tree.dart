import '../entities/assigned_tag.dart';
import '../entities/file_filter.dart';
import '../entities/file_node.dart';
import '../entities/file_sort.dart';
import '../entities/file_tree_node.dart';
import '../entities/tag_definition.dart';
import 'folder_index_scope.dart' show parentDirPath;
import 'query_files.dart';

/// 평면 노드 목록을 경로 기준 계층 트리로 묶고, 필터·정렬을 계층에 맞게 적용하는
/// 순수 유즈케이스(그룹 UI용).
///
/// - **정렬**: 형제(같은 부모의 자식)끼리 [QueryFiles]와 같은 다단계 규칙으로 정렬.
/// - **필터**: 노드는 자신이 매치되거나 **매치되는 자손이 있을 때만** 남긴다(매치된
///   노드와 그 조상 체인 보존, 매치 안 된 가지는 접지 않고 아예 제외). 필터가 비면
///   전부 매치라 전체 트리가 그대로 나온다.
class BuildFileTree {
  const BuildFileTree();

  List<FileTreeNode> call({
    required List<FileNode> files,
    required Map<int, List<AssignedTag>> assignmentsByFile,
    required FileFilter filter,
    required FileSortOrder sort,
    required Map<int, TagDefinition> definitionsById,
  }) {
    final childrenByParent = <String, List<FileNode>>{};
    for (final f in files) {
      childrenByParent.putIfAbsent(parentDirPath(f.path), () => []).add(f);
    }

    final cmp = const QueryFiles().comparator(
      assignmentsByFile: assignmentsByFile,
      sort: sort,
      definitionsById: definitionsById,
    );

    bool matches(FileNode f) => filter.matches(_tagsOf(f, assignmentsByFile));

    List<FileTreeNode> build(String parentPath) {
      final kids = [...?childrenByParent[parentPath]]..sort(cmp);
      final result = <FileTreeNode>[];
      for (final k in kids) {
        final children = build(k.path);
        if (matches(k) || children.isNotEmpty) {
          result.add(FileTreeNode(k, children));
        }
      }
      return result;
    }

    // 루트('') 직속부터 재귀로 트리를 세운다.
    return build('');
  }

  List<AssignedTag> _tagsOf(
    FileNode file,
    Map<int, List<AssignedTag>> assignmentsByFile,
  ) {
    final id = file.id;
    if (id == null) return const [];
    return assignmentsByFile[id] ?? const [];
  }
}
