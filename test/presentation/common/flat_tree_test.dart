import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/node_kind.dart';
import 'package:filetagger/domain/entities/file_tree_node.dart';
import 'package:filetagger/presentation/common/flat_tree.dart';
import 'package:flutter_test/flutter_test.dart';

FileTreeNode _dir(String path, List<FileTreeNode> children) =>
    FileTreeNode(FileNode(path: path, kind: NodeKind.directory), children);

FileTreeNode _file(String path, {int? id}) =>
    FileTreeNode(FileNode(id: id, path: path, kind: NodeKind.file), const []);

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
      itemCount: countLeafItems(children),
      children: children,
    );

List<String> _paths(List<TreeRow> rows) => [
  for (final r in rows) (r.item as FileTreeNode).node.path,
];

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
    final flat = flattenTree(tree, expandedFolders: const {}, expandAll: true);
    // 헤더 → 파일 → 파일 → 헤더 → 파일.
    expect(
      [for (final r in flat.rows) r.item.runtimeType.toString()],
      [
        'GroupHeaderNode',
        'FileTreeNode',
        'FileTreeNode',
        'GroupHeaderNode',
        'FileTreeNode',
      ],
    );
    // 헤더 행은 nodeIndex가 없고, 파일 행은 노드 목록을 순서대로 가리킨다.
    expect([for (final r in flat.rows) r.nodeIndex], [null, 0, 1, null, 2]);
    expect([for (final n in flat.nodes) n.name], ['x.txt', 'y.txt', 'z.txt']);
    // 선택·커서가 쓰는 id 목록은 id 없는 노드를 빼고 표시 순서를 지킨다.
    expect(flat.nodeIds, isEmpty);
  });

  group('parentRowIndex', () {
    test('자기보다 얕은 가장 가까운 앞 행을 낸다', () {
      final rows = flattenTree(
        _sample(),
        expandedFolders: const {},
        expandAll: true,
      ).rows;
      // ['a', 'a/b', 'a/b/deep.txt', 'a/leaf.txt', 'top.txt']
      expect(parentRowIndex(rows, 1), 0); // a/b → a
      expect(parentRowIndex(rows, 2), 1); // deep.txt → a/b
      expect(parentRowIndex(rows, 3), 0); // leaf.txt → a (a/b를 건너뛴다)
    });

    test('최상위 행과 범위 밖은 -1', () {
      final rows = flattenTree(
        _sample(),
        expandedFolders: const {},
        expandAll: true,
      ).rows;
      expect(parentRowIndex(rows, 0), -1);
      expect(parentRowIndex(rows, 4), -1);
      expect(parentRowIndex(rows, -1), -1);
      expect(parentRowIndex(rows, rows.length), -1);
    });

    test('그룹 헤더도 부모가 된다', () {
      final flat = flattenTree(
        [
          _group(1, 'red', <TreeItem>[_file('x.txt')]),
        ],
        expandedFolders: const {},
        expandAll: true,
      );
      expect(parentRowIndex(flat.rows, 1), 0);
      expect(flat.rows[0].item, isA<GroupHeaderNode>());
    });
  });

  group('firstRowIndexOfAny', () {
    /// 헤더 두 개에 파일을 나눠 담은 트리(둘 다 펴 둔다).
    /// 헤더 → 1 → 2 → 헤더 → 3.
    FlatTree twoBuckets() => flattenTree(
      [
        _group(1, 'red', <TreeItem>[
          _file('x.txt', id: 1),
          _file('y.txt', id: 2),
        ]),
        _group(1, 'blue', <TreeItem>[_file('z.txt', id: 3)]),
      ],
      expandedFolders: const {},
      expandAll: true,
    );

    test('여러 그룹에 걸쳐 골라도 표시 순서의 첫 노드를 낸다', () {
      // 뒤 버킷의 노드를 먼저 적어도 순서는 집합이 아니라 표시 행이 정한다.
      expect(twoBuckets().firstRowIndexOfAny({3, 2}), 2);
    });

    test('고른 것이 하나면 그 행', () {
      expect(twoBuckets().firstRowIndexOfAny({3}), 4);
    });

    test('목록에 없는 id·빈 집합은 -1', () {
      expect(twoBuckets().firstRowIndexOfAny({99}), -1);
      expect(twoBuckets().firstRowIndexOfAny(const {}), -1);
    });

    test('첫 선택의 상위 행이 그 노드가 담긴 헤더다', () {
      final flat = twoBuckets();
      final first = flat.firstRowIndexOfAny({3, 2});
      expect(parentRowIndex(flat.rows, first), 0);
    });
  });

  group('ancestorExpandKeys', () {
    test('접혀 있어도 다 편 순서에서 조상 사슬을 바깥→안쪽으로 낸다', () {
      final rows = flattenTree(
        _sample(),
        expandedFolders: const {},
        expandAll: true,
      ).rows;
      // ['a', 'a/b', 'a/b/deep.txt', 'a/leaf.txt', 'top.txt']
      expect(ancestorExpandKeys(rows, 2), ['a', 'a/b']);
      expect(ancestorExpandKeys(rows, 3), ['a']);
    });

    test('최상위 행은 펼칠 조상이 없다', () {
      final rows = flattenTree(
        _sample(),
        expandedFolders: const {},
        expandAll: true,
      ).rows;
      expect(ancestorExpandKeys(rows, 0), isEmpty);
      expect(ancestorExpandKeys(rows, 4), isEmpty);
    });

    test('그룹 헤더도 조상으로 함께 낸다(폴더와 가리지 않는다)', () {
      final flat = flattenTree(
        [
          _group(1, 'red', <TreeItem>[
            _dir('a', [_file('a/x.txt')]),
          ]),
        ],
        expandedFolders: const {},
        expandAll: true,
      );
      // 헤더 → 폴더 → 파일.
      final keys = ancestorExpandKeys(flat.rows, 2);
      expect(keys, hasLength(2));
      expect(keys.first, flat.rows.first.expandKey); // 헤더가 바깥
      expect(keys.last, 'a');
    });

    test('범위 밖 인덱스는 빈 목록', () {
      final rows = flattenTree(
        _sample(),
        expandedFolders: const {},
        expandAll: true,
      ).rows;
      expect(ancestorExpandKeys(rows, -1), isEmpty);
      expect(ancestorExpandKeys(rows, rows.length), isEmpty);
    });
  });

  test('같은 값 버킷이라도 조상 맥락이 다르면 펼침 키가 갈린다', () {
    GroupHeaderNode bucket() => _group(1, 'red', <TreeItem>[_file('x.txt')]);
    final flat = flattenTree(
      [
        _group(2, 'a', <TreeItem>[bucket()]),
        _group(2, 'b', <TreeItem>[bucket()]),
      ],
      expandedFolders: const {},
      expandAll: true,
    );
    final keys = [
      for (final r in flat.rows)
        if (r.item is GroupHeaderNode) r.expandKey,
    ];
    expect(keys.toSet(), hasLength(keys.length));
    // 합성 키는 실제 폴더 경로와 겹치지 않는 제어문자로 시작한다.
    expect(keys.first.startsWith('\u0000'), isTrue);
  });
}
