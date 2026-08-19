import '../entities/assigned_tag.dart';
import '../entities/file_filter.dart';
import '../entities/file_grouping.dart';
import '../entities/file_node.dart';
import '../entities/file_sort.dart';
import '../entities/file_tree_node.dart';
import '../entities/tag_definition.dart';
import '../entities/tag_value_ordering.dart';
import '../entities/tag_value_type.dart';
import 'folder_index_scope.dart' show parentDirPath;
import 'query_files.dart';

/// 필터를 통과한 노드를 그룹 단계에 맞춰 표시 트리로 묶는 순수 유즈케이스.
///
/// 그룹은 **남은 키를 들고 가는 재귀**다([FileGrouping]). 태그 키는 값별
/// [GroupHeaderNode] 버킷을 만들고(값 없는 항목은 "(미분류)" 버킷으로, 다중값은
/// 여러 버킷에 중복 소속), 폴더 계층 키는 substrate를 경로 계층으로 바꾼다.
///
/// - **폴더 키 앞의 값 키**: 먼저 값으로 버킷을 나눈 뒤, 각 버킷 안에서 폴더 계층을
///   세운다(폴더 계층은 "노드∈버킷" 술어로 매치와 그 조상 체인만 보존한다).
/// - **폴더 키 뒤의 값 키**: 각 폴더의 **직속 파일**을 그 키들로 다시 그룹화한다
///   (하위 폴더는 계층 그대로, 값 헤더는 그 폴더의 자식으로 함께 놓인다).
/// - **그룹이 비면** 계층 없이 정렬된 평면 리프 목록이다(옛 평면 보기와 같다).
///
/// 정렬은 형제(같은 버킷·같은 폴더의 자식)끼리 [QueryFiles]와 같은 규칙으로 한다.
/// 버킷 자체의 순서는 값의 유형별 오름차순이고 "(미분류)"는 늘 맨 뒤다.
class BuildGroupedTree {
  const BuildGroupedTree();

  List<TreeItem> call({
    required List<FileNode> files,
    required Map<int, List<AssignedTag>> assignmentsByFile,
    required FileFilter filter,
    required FileGrouping grouping,
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

    List<AssignedTag> tagsOf(FileNode f) {
      final id = f.id;
      if (id == null) return const [];
      return assignmentsByFile[id] ?? const [];
    }

    // 노드에 붙은 이 태그의 값들(비어있지 않고 중복 제거). label은 값이 없으므로
    // 부여 여부만 보아, 붙어 있으면 "붙음" 버킷(값 '')으로, 없으면 미분류로 간다.
    List<String> valuesOf(FileNode node, int tagId, TagValueType? type) {
      // label과 image는 값 대신 부여 여부만 본다(image 값은 불투명 캐시 키).
      if (type == TagValueType.label || type == TagValueType.image) {
        final present = tagsOf(node).any((t) => t.tagDefinitionId == tagId);
        return present ? const [''] : const [];
      }
      final seen = <String>{};
      final result = <String>[];
      for (final t in tagsOf(node)) {
        if (t.tagDefinitionId != tagId) continue;
        final v = t.value;
        if (v == null || v.isEmpty) continue;
        if (seen.add(v)) result.add(v);
      }
      return result;
    }

    // 폴더 계층 substrate. [memberNodes]만 리프로 남기고, 그 조상 폴더는 계층으로
    // 보존한다. [restKeys]가 남았으면 각 폴더의 직속 파일을 그 키로 다시 그룹화한다.
    List<TreeItem> buildFolderSubstrate(
      List<FileNode> memberNodes,
      List<GroupKey> restKeys,
      List<TreeItem> Function(List<FileNode>, List<GroupKey>) build,
    ) {
      final memberPaths = {for (final n in memberNodes) n.path};

      List<TreeItem> buildDir(String parentPath) {
        final kids = [...?childrenByParent[parentPath]]..sort(cmp);
        // 남은 키가 없으면 옛 폴더 트리 그대로 — 형제(폴더·파일)를 한 순서로 다룬다.
        if (restKeys.isEmpty) {
          final result = <TreeItem>[];
          for (final k in kids) {
            if (k.isDirectory) {
              final sub = buildDir(k.path);
              if (memberPaths.contains(k.path) || sub.isNotEmpty) {
                result.add(FileTreeNode(k, sub));
              }
            } else if (memberPaths.contains(k.path)) {
              result.add(FileTreeNode(k, const []));
            }
          }
          return result;
        }
        // 남은 값 키가 있으면 하위 폴더는 계층 그대로, 직속 파일은 값으로 재그룹.
        final dirItems = <TreeItem>[];
        final directFiles = <FileNode>[];
        for (final k in kids) {
          if (k.isDirectory) {
            final sub = buildDir(k.path);
            if (memberPaths.contains(k.path) || sub.isNotEmpty) {
              dirItems.add(FileTreeNode(k, sub));
            }
          } else if (memberPaths.contains(k.path)) {
            directFiles.add(k);
          }
        }
        return [...dirItems, ...build(directFiles, restKeys)];
      }

      return buildDir('');
    }

    late final List<TreeItem> Function(List<FileNode>, List<GroupKey>) build;

    // 태그값으로 버킷을 나눈 그룹 헤더들. 값 오름차순 + 미분류 맨 뒤.
    List<TreeItem> bucketByTag(
      List<FileNode> nodes,
      int tagId,
      List<GroupKey> rest,
    ) {
      final type = definitionsById[tagId]?.valueType ?? TagValueType.text;
      // 뒤에 폴더 계층 키가 남아 있으면 폴더는 그 키가 구조(조상)로 세우므로 값
      // 버킷의 멤버로 또 담지 않는다 — 담으면 같은 폴더가 자기 값 버킷과 조상
      // 자리에 겹쳐 나온다. 그런 키가 없으면 폴더도 파일과 똑같이 값으로 묶인다
      // (폴더에도 태그를 붙일 수 있고, 버리면 그룹을 거는 순간 사라진다).
      final foldersAreStructure = rest.any((k) => k is FolderHierarchyGroupKey);
      final byValue = <String, List<FileNode>>{};
      final unclassified = <FileNode>[];
      for (final n in nodes) {
        if (n.isDirectory && foldersAreStructure) continue;
        final vals = valuesOf(n, tagId, type);
        if (vals.isEmpty) {
          unclassified.add(n);
          continue;
        }
        for (final v in vals) {
          byValue.putIfAbsent(v, () => []).add(n);
        }
      }
      // 버킷 순서는 값 오름차순. 값마다 해석을 한 번만 하도록 비교 재료를 미리 뽑는다.
      final sortKeys = {for (final v in byValue.keys) v: TagValueKey(type, v)};
      final values = byValue.keys.toList()
        ..sort((a, b) => sortKeys[a]!.compareTo(sortKeys[b]!));

      GroupHeaderNode header(String? value, List<FileNode> members) {
        final children = build(members, rest);
        return GroupHeaderNode(
          tagDefinitionId: tagId,
          value: value,
          itemCount: countLeafItems(children),
          children: children,
        );
      }

      return [
        for (final v in values) header(v, byValue[v]!),
        if (unclassified.isNotEmpty) header(null, unclassified),
      ];
    }

    build = (List<FileNode> nodes, List<GroupKey> keys) {
      if (keys.isEmpty) {
        final sorted = [...nodes]..sort(cmp);
        return [for (final n in sorted) FileTreeNode(n, const [])];
      }
      final rest = keys.sublist(1);
      return switch (keys.first) {
        TagGroupKey(:final tagDefinitionId) => bucketByTag(
          nodes,
          tagDefinitionId,
          rest,
        ),
        FolderHierarchyGroupKey() => buildFolderSubstrate(nodes, rest, build),
      };
    };

    final visible = [
      for (final f in files)
        if (filter.matches(tagsOf(f))) f,
    ];
    return build(visible, grouping.keys);
  }
}
