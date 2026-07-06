import 'package:filetagger/domain/entities/assigned_tag.dart';
import 'package:filetagger/domain/entities/file_filter.dart';
import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/file_sort.dart';
import 'package:filetagger/domain/entities/file_tree_node.dart';
import 'package:filetagger/domain/entities/tag_assignment.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/domain/usecases/build_file_tree.dart';
import 'package:flutter_test/flutter_test.dart';

FileNode _node(int id, String path, {bool dir = false}) =>
    FileNode(id: id, path: path, isDirectory: dir);

AssignedTag _assign(int fileId, int defId, TagValueType type, String? value) =>
    AssignedTag(
      assignment: TagAssignment(
        fileNodeId: fileId,
        tagDefinitionId: defId,
        value: value,
      ),
      definition: TagDefinition(id: defId, name: 'tag$defId', valueType: type),
    );

/// 트리에서 경로로 노드를 찾는다(테스트 편의).
FileTreeNode? _find(List<FileTreeNode> tree, String path) {
  for (final n in tree) {
    if (n.node.path == path) return n;
    final inChild = _find(n.children, path);
    if (inChild != null) return inChild;
  }
  return null;
}

void main() {
  const build = BuildFileTree();

  test('경로 기준으로 계층 트리를 세운다(폴더 우선·이름순)', () {
    final files = [
      _node(1, 'a', dir: true),
      _node(2, 'a/z.txt'),
      _node(3, 'a/sub', dir: true),
      _node(4, 'a/sub/deep.txt'),
      _node(5, 'top.txt'),
    ];

    final tree = build(
      files: files,
      assignmentsByFile: const {},
      filter: const FileFilter(),
      sort: const FileSortOrder(),
      definitionsById: const {},
    );

    // 최상위: 폴더 a 먼저, 그다음 top.txt.
    expect(tree.map((n) => n.node.path), ['a', 'top.txt']);
    final a = tree.first;
    // a의 자식: 폴더 sub 먼저, 그다음 z.txt.
    expect(a.children.map((n) => n.node.path), ['a/sub', 'a/z.txt']);
    expect(_find(tree, 'a/sub')!.children.map((n) => n.node.path), [
      'a/sub/deep.txt',
    ]);
  });

  test('필터는 매치된 노드와 그 조상만 남기고 나머지 형제는 제외한다', () {
    final files = [
      _node(1, 'a', dir: true),
      _node(2, 'a/hit.txt'),
      _node(3, 'a/miss.txt'),
      _node(4, 'b', dir: true),
      _node(5, 'b/none.txt'),
    ];
    // 'hit.txt'에만 label 태그(7) 부여.
    final assignments = {
      2: [_assign(2, 7, TagValueType.label, null)],
    };

    final tree = build(
      files: files,
      assignmentsByFile: assignments,
      filter: const FileFilter(
        conditions: [FilterCondition(tagDefinitionId: 7)],
      ),
      sort: const FileSortOrder(),
      definitionsById: const {
        7: TagDefinition(id: 7, name: 'tag7', valueType: TagValueType.label),
      },
    );

    // a는 자손(hit)이 매치돼 조상으로 남고, b는 매치가 없어 통째로 빠진다.
    expect(tree.map((n) => n.node.path), ['a']);
    // a 아래엔 매치된 hit.txt만 남고 miss.txt는 빠진다.
    expect(tree.first.children.map((n) => n.node.path), ['a/hit.txt']);
  });

  test('형제 정렬은 태그값 기준으로 적용된다(숫자 오름차순)', () {
    final files = [
      _node(1, 'a', dir: true),
      _node(2, 'a/big.txt'),
      _node(3, 'a/small.txt'),
    ];
    final assignments = {
      2: [_assign(2, 9, TagValueType.number, '10')],
      3: [_assign(3, 9, TagValueType.number, '2')],
    };

    final tree = build(
      files: files,
      assignmentsByFile: assignments,
      filter: const FileFilter(),
      sort: const FileSortOrder(keys: [SortKey(tagDefinitionId: 9)]),
      definitionsById: const {
        9: TagDefinition(id: 9, name: 'tag9', valueType: TagValueType.number),
      },
    );

    // 숫자 오름차순이면 2(small) < 10(big).
    expect(tree.first.children.map((n) => n.node.path), [
      'a/small.txt',
      'a/big.txt',
    ]);
  });
}
