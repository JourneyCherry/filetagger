import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/file_tree_node.dart';
import 'package:filetagger/presentation/common/file_icon_view.dart';
import 'package:flutter_test/flutter_test.dart';

/// 파일 노드(비디렉토리) 하나짜리 트리 리프.
FileTreeNode _file(String path) => FileTreeNode(
  FileNode(path: path, isDirectory: false),
  const [],
);

/// 자식을 갖는 폴더 노드.
FileTreeNode _dir(String path, List<TreeItem> children) =>
    FileTreeNode(FileNode(path: path, isDirectory: true), children);

void main() {
  group('descendTreeByKeys', () {
    final roots = [
      _dir('a', [
        _file('a/x.txt'),
        _dir('a/b', [_file('a/b/y.txt')]),
      ]),
      _file('c.txt'),
    ];

    test('빈 경로는 루트 계층을 그대로 준다', () {
      final r = descendTreeByKeys(roots, const [], iconItemKey);
      expect(r.items, roots);
      expect(r.trail, isEmpty);
    });

    test('경로를 따라 내려가 자식 계층과 지나온 항목을 준다', () {
      final r = descendTreeByKeys(
        roots,
        [iconItemKey(roots[0]), 'p:a/b'],
        iconItemKey,
      );
      expect(r.items, hasLength(1));
      expect((r.items.single as FileTreeNode).node.path, 'a/b/y.txt');
      expect(r.trail.map((t) => (t as FileTreeNode).node.path), ['a', 'a/b']);
    });

    test('어긋난 키에서 멈춰 유효한 데까지만 내려간다', () {
      final r = descendTreeByKeys(
        roots,
        [iconItemKey(roots[0]), 'p:a/does-not-exist'],
        iconItemKey,
      );
      // 'a'까지만 유효 — 그 자식 계층을 돌려주고 낡은 키는 버린다.
      expect(r.trail.map((t) => (t as FileTreeNode).node.path), ['a']);
      expect(
        r.items.map((t) => (t as FileTreeNode).node.path),
        ['a/x.txt', 'a/b'],
      );
    });

    test('첫 키부터 어긋나면 루트에 머문다', () {
      final r = descendTreeByKeys(roots, const ['p:nope'], iconItemKey);
      expect(r.items, roots);
      expect(r.trail, isEmpty);
    });
  });
}
