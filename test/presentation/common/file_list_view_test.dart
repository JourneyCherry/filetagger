import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/file_tree_node.dart';
import 'package:filetagger/presentation/common/file_list_view.dart';
import 'package:flutter_test/flutter_test.dart';

FileTreeNode _dir(String path, List<FileTreeNode> children) =>
    FileTreeNode(FileNode(path: path, isDirectory: true), children);

FileTreeNode _file(String path) =>
    FileTreeNode(FileNode(path: path, isDirectory: false), const []);

/// a/
///   a/b/
///     a/b/deep.txt
///   a/leaf.txt
/// top.txt
List<FileTreeNode> _sample() => [
  _dir('a', [
    _dir('a/b', [_file('a/b/deep.txt')]),
    _file('a/leaf.txt'),
  ]),
  _file('top.txt'),
];

GroupHeaderNode _group(int tagId, String? value, List<TreeItem> children) =>
    GroupHeaderNode(
      tagDefinitionId: tagId,
      value: value,
      fileCount: countFileLeaves(children),
      children: children,
    );

List<String> _paths(List<TreeRow> rows) =>
    [for (final r in rows) (r.item as FileTreeNode).node.path];

void main() {
  test('접힌 폴더의 자식은 행으로 펴지 않는다', () {
    final rows = flattenTree(
      _sample(),
      expandedFolders: const {},
      expandAll: false,
    ).rows;
    expect(_paths(rows), ['a', 'top.txt']);
    expect(rows.first.expandable, isTrue);
    expect(rows.first.expanded, isFalse);
  });

  test('펼친 폴더만 한 단계씩 열린다', () {
    final rows = flattenTree(
      _sample(),
      expandedFolders: const {'a'},
      expandAll: false,
    ).rows;
    // 'a'는 열렸지만 'a/b'는 접힌 채라 그 자식은 나오지 않는다.
    expect(_paths(rows), ['a', 'a/b', 'a/leaf.txt', 'top.txt']);
    expect(rows[1].expanded, isFalse);
  });

  test('expandAll이면 접힘 상태와 무관하게 전부 편다', () {
    final rows = flattenTree(
      _sample(),
      expandedFolders: const {},
      expandAll: true,
    ).rows;
    expect(_paths(rows), ['a', 'a/b', 'a/b/deep.txt', 'a/leaf.txt', 'top.txt']);
  });

  test('깊이는 계층 단계를 그대로 따른다', () {
    final rows = flattenTree(
      _sample(),
      expandedFolders: const {},
      expandAll: true,
    ).rows;
    expect([for (final r in rows) r.depth], [0, 1, 2, 1, 0]);
  });

  test('자식 없는 폴더는 펼칠 수 없다', () {
    final rows = flattenTree(
      [_dir('empty', const [])],
      expandedFolders: const {'empty'},
      expandAll: false,
    ).rows;
    expect(rows.single.expandable, isFalse);
  });

  test('그룹 헤더도 접었다 펼 수 있는 행이 되고, 기본은 접힘', () {
    final tree = <TreeItem>[
      _group(1, 'red', <TreeItem>[_file('x.txt'), _file('y.txt')]),
      _group(1, null, <TreeItem>[_file('z.txt')]),
    ];
    // 접힘 기본: 헤더 두 줄만 나오고 그 안의 파일은 감춘다.
    final collapsed = flattenTree(
      tree,
      expandedFolders: const {},
      expandAll: false,
    );
    expect(collapsed.rows, hasLength(2));
    expect(collapsed.rows.every((r) => r.item is GroupHeaderNode), isTrue);
    expect(collapsed.rows.first.expandable, isTrue);
    expect(collapsed.rows.first.expanded, isFalse);
    // 헤더는 선택 대상이 아니라 노드 목록이 비어 있다.
    expect(collapsed.nodes, isEmpty);
  });

  test('expandAll이면 헤더 안 파일까지 펴고, nodeIndex는 파일 행만 가리킨다', () {
    final tree = <TreeItem>[
      _group(1, 'red', <TreeItem>[_file('x.txt'), _file('y.txt')]),
      _group(1, null, <TreeItem>[_file('z.txt')]),
    ];
    final flat = flattenTree(
      tree,
      expandedFolders: const {},
      expandAll: true,
    );
    // 헤더 → 파일 → 파일 → 헤더 → 파일.
    expect([for (final r in flat.rows) r.item.runtimeType.toString()], [
      'GroupHeaderNode',
      'FileTreeNode',
      'FileTreeNode',
      'GroupHeaderNode',
      'FileTreeNode',
    ]);
    // 헤더 행은 nodeIndex가 없고, 파일 행은 노드 목록을 순서대로 가리킨다.
    expect([for (final r in flat.rows) r.nodeIndex], [null, 0, 1, null, 2]);
    expect([for (final n in flat.nodes) n.name], ['x.txt', 'y.txt', 'z.txt']);
  });

  test('얕은 깊이는 그대로 들여쓰고, 한계를 넘으면 같은 단계로 눌린다', () {
    expect(visualIndentDepth(0), 0);
    expect(visualIndentDepth(kMaxIndentDepth), kMaxIndentDepth);
    expect(visualIndentDepth(kMaxIndentDepth + 5), kMaxIndentDepth);
  });
}
