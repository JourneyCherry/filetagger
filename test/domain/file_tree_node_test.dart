import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/node_kind.dart';
import 'package:filetagger/domain/entities/file_tree_node.dart';
import 'package:flutter_test/flutter_test.dart';

FileNode _node(String path) => FileNode(path: path, kind: NodeKind.file);

FileTreeNode _leaf(String path) => FileTreeNode(_node(path), const []);

void main() {
  group('countTreeNodes', () {
    test('빈 트리는 0', () {
      expect(countTreeNodes(const []), 0);
    });

    test('중첩된 자손까지 모두 센다(펼침 상태와 무관)', () {
      final tree = [
        FileTreeNode(_node('a'), [
          _leaf('a/1'),
          FileTreeNode(_node('a/b'), [_leaf('a/b/2')]),
        ]),
        _leaf('c'),
      ];
      expect(countTreeNodes(tree), 5);
    });
  });

  group('treeNodesInOrder', () {
    test('낸 차례 그대로 편다 — 그룹 머리글은 빠지고 그 안은 내려간다', () {
      final tree = [
        GroupHeaderNode(
          tagDefinitionId: 7,
          value: '고양이',
          itemCount: 2,
          children: [
            _leaf('a/1'),
            FileTreeNode(_node('a'), [_leaf('a/2')]),
          ],
        ),
        _leaf('c'),
      ];

      expect(treeNodesInOrder(tree).map((n) => n.path), [
        'a/1',
        'a',
        'a/2',
        'c',
      ]);
    });

    test('세는 것과 같은 목록이다', () {
      final tree = [
        FileTreeNode(_node('a'), [_leaf('a/1')]),
        _leaf('c'),
      ];

      expect(treeNodesInOrder(tree).length, countTreeNodes(tree));
    });

    test('다중값 그룹의 중복 소속은 그대로 여러 번 나온다', () {
      // 고르는 쪽이 거를 수 있도록 **접지 않고** 낸다 — 세는 자리는 중복을 세야
      // 버킷별 수가 맞는다.
      final shared = _leaf('a/1');
      final tree = [
        GroupHeaderNode(
          tagDefinitionId: 7,
          value: '고양이',
          itemCount: 1,
          children: [shared],
        ),
        GroupHeaderNode(
          tagDefinitionId: 7,
          value: '개',
          itemCount: 1,
          children: [shared],
        ),
      ];

      expect(treeNodesInOrder(tree).map((n) => n.path), ['a/1', 'a/1']);
    });
  });
}
