import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/node_kind.dart';
import 'package:filetagger/domain/entities/file_tree_node.dart';
import 'package:filetagger/presentation/common/file_icon_view.dart';
import 'package:flutter_test/flutter_test.dart';

/// 파일 노드(비디렉토리) 하나짜리 트리 리프.
FileTreeNode _file(String path, {int? id}) =>
    FileTreeNode(FileNode(id: id, path: path, kind: NodeKind.file), const []);

/// 자식을 갖는 폴더 노드.
FileTreeNode _dir(String path, List<TreeItem> children, {int? id}) =>
    FileTreeNode(
      FileNode(id: id, path: path, kind: NodeKind.directory),
      children,
    );

/// 태그값 버킷 헤더(항목 수는 이 테스트가 보지 않아 자식 수로 채운다).
GroupHeaderNode _group(int tagId, String? value, List<TreeItem> children) =>
    GroupHeaderNode(
      tagDefinitionId: tagId,
      value: value,
      itemCount: children.length,
      children: children,
    );

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
      final r = descendTreeByKeys(roots, [
        iconItemKey(roots[0]),
        'p:a/b',
      ], iconItemKey);
      expect(r.items, hasLength(1));
      expect((r.items.single as FileTreeNode).node.path, 'a/b/y.txt');
      expect(r.trail.map((t) => (t as FileTreeNode).node.path), ['a', 'a/b']);
    });

    test('어긋난 키에서 멈춰 유효한 데까지만 내려간다', () {
      final r = descendTreeByKeys(roots, [
        iconItemKey(roots[0]),
        'p:a/does-not-exist',
      ], iconItemKey);
      // 'a'까지만 유효 — 그 자식 계층을 돌려주고 낡은 키는 버린다.
      expect(r.trail.map((t) => (t as FileTreeNode).node.path), ['a']);
      expect(r.items.map((t) => (t as FileTreeNode).node.path), [
        'a/x.txt',
        'a/b',
      ]);
    });

    test('첫 키부터 어긋나면 루트에 머문다', () {
      final r = descendTreeByKeys(roots, const ['p:nope'], iconItemKey);
      expect(r.items, roots);
      expect(r.trail, isEmpty);
    });
  });

  group('iconPathToNode', () {
    test('루트 계층의 노드는 파고들 것 없이 그 자리를 준다', () {
      final roots = [
        _dir('a', [_file('a/x.txt', id: 1)], id: 2),
        _file('c.txt', id: 3),
      ];
      final found = iconPathToNode(roots, 3, iconItemKey);
      expect(found?.path, isEmpty);
      expect(found?.index, 1);
    });

    test('깊은 노드는 그 자리까지의 조상 키 경로를 준다', () {
      final roots = [
        _dir('a', [
          _file('a/x.txt', id: 1),
          _dir('a/b', [_file('a/b/y.txt', id: 4)], id: 5),
        ], id: 2),
      ];
      final found = iconPathToNode(roots, 4, iconItemKey);
      // 그 경로를 그대로 따라 내려가면 그 계층이 나온다(드릴인과 같은 키).
      expect(found?.path, ['p:a', 'p:a/b']);
      final level = descendTreeByKeys(roots, found!.path, iconItemKey).items;
      expect((level[found.index] as FileTreeNode).node.id, 4);
    });

    test('그룹 헤더 아래 노드도 헤더 키로 찾아간다', () {
      // 폴더가 아니라 태그값 버킷이 조상인 경우 — 경로 문자열로는 열 수 없는 자리다.
      final roots = [
        _group(9, '초안', [_file('c.txt', id: 3)]),
      ];
      final found = iconPathToNode(roots, 3, iconItemKey);
      expect(found?.path, hasLength(1));
      final level = descendTreeByKeys(roots, found!.path, iconItemKey).items;
      expect((level[found.index] as FileTreeNode).node.id, 3);
    });

    test('여러 버킷에 걸친 노드는 얕은 자리를 고른다', () {
      // 다중값 그룹은 같은 노드를 여러 버킷에 넣는다 — 파고들 걸음이 적은 쪽이 낫다.
      final shared = _file('c.txt', id: 3);
      final roots = [
        _group(9, '초안', [
          _group(9, '보류', [shared]),
        ]),
        shared,
      ];
      final found = iconPathToNode(roots, 3, iconItemKey);
      expect(found?.path, isEmpty);
      expect(found?.index, 1);
    });

    test('없는 노드면 null', () {
      final roots = [_file('c.txt', id: 3)];
      expect(iconPathToNode(roots, 99, iconItemKey), isNull);
    });
  });
}
