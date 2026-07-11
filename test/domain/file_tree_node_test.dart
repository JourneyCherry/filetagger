import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/file_tree_node.dart';
import 'package:flutter_test/flutter_test.dart';

FileNode _node(String path) => FileNode(path: path, isDirectory: false);

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
}
