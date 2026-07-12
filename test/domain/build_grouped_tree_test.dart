import 'package:filetagger/domain/entities/assigned_tag.dart';
import 'package:filetagger/domain/entities/file_filter.dart';
import 'package:filetagger/domain/entities/file_grouping.dart';
import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/file_sort.dart';
import 'package:filetagger/domain/entities/file_tree_node.dart';
import 'package:filetagger/domain/entities/tag_assignment.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/domain/usecases/build_grouped_tree.dart';
import 'package:flutter_test/flutter_test.dart';

// 태그 정의: 2=평점(number), 3=색상(text), 4=숨김(label).
const _rating = TagDefinition(id: 2, name: '평점', valueType: TagValueType.number);
const _color = TagDefinition(id: 3, name: '색상', valueType: TagValueType.text);
const _label = TagDefinition(id: 4, name: '숨김', valueType: TagValueType.label);
final _defsById = <int, TagDefinition>{
  for (final d in [_rating, _color, _label]) d.id!: d,
};

FileNode _node(int id, String path, {bool dir = false}) =>
    FileNode(id: id, path: path, isDirectory: dir);

AssignedTag _assign(int fileId, TagDefinition def, String? value) => AssignedTag(
  assignment: TagAssignment(
    fileNodeId: fileId,
    tagDefinitionId: def.id!,
    value: value,
  ),
  definition: def,
);

const _build = BuildGroupedTree();

List<TreeItem> _run(
  List<FileNode> files,
  Map<int, List<AssignedTag>> assignments,
  FileGrouping grouping, {
  FileFilter filter = const FileFilter(),
  FileSortOrder sort = const FileSortOrder(),
}) => _build(
  files: files,
  assignmentsByFile: assignments,
  filter: filter,
  grouping: grouping,
  sort: sort,
  definitionsById: _defsById,
);

/// 헤더의 값 라벨(미분류는 '·미분류')을 순서대로.
List<String> _headerLabels(List<TreeItem> items) => [
  for (final i in items)
    if (i is GroupHeaderNode) (i.value ?? '·미분류'),
];

List<String> _filePaths(List<TreeItem> items) => [
  for (final i in items)
    if (i is FileTreeNode) i.node.path,
];

void main() {
  test('그룹이 비면 정렬된 평면 리프 목록이다', () {
    final files = [_node(1, 'b.txt'), _node(2, 'a.txt')];
    final tree = _run(files, const {}, const FileGrouping());
    expect(_filePaths(tree), ['a.txt', 'b.txt']);
    expect(tree.every((i) => i is FileTreeNode), isTrue);
  });

  group('태그값 그룹', () {
    test('값별 버킷을 만들고 값 없는 항목은 미분류로 모은다', () {
      final files = [_node(1, 'x'), _node(2, 'y'), _node(3, 'z')];
      final assignments = {
        1: [_assign(1, _rating, '5')],
        2: [_assign(2, _rating, '3')],
        // 3은 평점 없음 → 미분류.
      };
      final tree = _run(
        files,
        assignments,
        const FileGrouping(keys: [TagGroupKey(2)]),
      );
      // 숫자 오름차순: 3, 5, 그다음 미분류.
      expect(_headerLabels(tree), ['3', '5', '·미분류']);
      final b5 = tree[1] as GroupHeaderNode;
      expect(_filePaths(b5.children), ['x']);
      expect(b5.fileCount, 1);
    });

    test('다중값은 여러 버킷에 중복 소속되고 카운트 합이 늘 수 있다', () {
      final files = [_node(1, 'x'), _node(2, 'y')];
      final assignments = {
        1: [_assign(1, _color, '빨강'), _assign(1, _color, '파랑')],
        2: [_assign(2, _color, '빨강')],
      };
      final tree = _run(
        files,
        assignments,
        const FileGrouping(keys: [TagGroupKey(3)]),
      );
      // '빨강'에 x,y(2개), '파랑'에 x(1개) → 합 3 > 파일 2.
      expect(_headerLabels(tree), ['빨강', '파랑']);
      final total = tree
          .whereType<GroupHeaderNode>()
          .fold<int>(0, (s, h) => s + h.fileCount);
      expect(total, 3);
    });

    test('라벨 태그는 붙음/미분류 두 버킷으로 나뉜다', () {
      final files = [_node(1, 'x'), _node(2, 'y')];
      final assignments = {
        1: [_assign(1, _label, null)],
      };
      final tree = _run(
        files,
        assignments,
        const FileGrouping(keys: [TagGroupKey(4)]),
      );
      expect(_headerLabels(tree), ['', '·미분류']);
      expect((tree.first as GroupHeaderNode).isUnclassified, isFalse);
      expect(_filePaths((tree.first as GroupHeaderNode).children), ['x']);
    });

    test('중첩 값 그룹은 바깥→안쪽으로 접힌다', () {
      final files = [_node(1, 'x'), _node(2, 'y')];
      final assignments = {
        1: [_assign(1, _rating, '5'), _assign(1, _color, '빨강')],
        2: [_assign(2, _rating, '5'), _assign(2, _color, '파랑')],
      };
      final tree = _run(
        files,
        assignments,
        const FileGrouping(keys: [TagGroupKey(2), TagGroupKey(3)]),
      );
      expect(_headerLabels(tree), ['5']);
      final inner = (tree.first as GroupHeaderNode).children;
      expect(_headerLabels(inner), ['빨강', '파랑']);
    });
  });

  group('폴더 계층 그룹', () {
    test('폴더 키만이면 옛 폴더 트리와 같다', () {
      final files = [
        _node(1, 'a', dir: true),
        _node(2, 'a/z.txt'),
        _node(3, 'a/sub', dir: true),
        _node(4, 'a/sub/deep.txt'),
        _node(5, 'top.txt'),
      ];
      final tree = _run(
        files,
        const {},
        const FileGrouping(keys: [FolderHierarchyGroupKey()]),
      );
      expect(_filePaths(tree), ['a', 'top.txt']);
      final a = tree.first as FileTreeNode;
      expect(_filePaths(a.children), ['a/sub', 'a/z.txt']);
    });

    test('값 키 뒤 폴더 키: 각 값 버킷 안에서 폴더 계층으로 조상을 보존한다', () {
      final files = [
        _node(1, 'a', dir: true),
        _node(2, 'a/x.txt'),
        _node(3, 'a/y.txt'),
      ];
      final assignments = {
        2: [_assign(2, _rating, '5')],
        3: [_assign(3, _rating, '3')],
      };
      final tree = _run(
        files,
        assignments,
        const FileGrouping(
          keys: [TagGroupKey(2), FolderHierarchyGroupKey()],
        ),
      );
      // 값 버킷 3,5 각각 아래 폴더 a가 조상으로 보존되고 해당 파일만 리프로.
      expect(_headerLabels(tree), ['3', '5']);
      final b3 = tree.first as GroupHeaderNode;
      final a3 = b3.children.single as FileTreeNode;
      expect(a3.node.path, 'a');
      expect(_filePaths(a3.children), ['a/y.txt']);
      expect(b3.fileCount, 1);
    });

    test('폴더 키 뒤 값 키: 폴더 직속 파일을 값으로 재그룹한다', () {
      final files = [
        _node(1, 'a', dir: true),
        _node(2, 'a/x.txt'),
        _node(3, 'a/y.txt'),
        _node(4, 'a/sub', dir: true),
        _node(5, 'a/sub/deep.txt'),
      ];
      final assignments = {
        2: [_assign(2, _rating, '5')],
        3: [_assign(3, _rating, '5')],
        5: [_assign(5, _rating, '1')],
      };
      final tree = _run(
        files,
        assignments,
        const FileGrouping(
          keys: [FolderHierarchyGroupKey(), TagGroupKey(2)],
        ),
      );
      final a = tree.single as FileTreeNode;
      expect(a.node.path, 'a');
      // a의 자식: 하위 폴더 sub 먼저, 그다음 직속 파일의 값 버킷('5').
      final aChildren = a.children;
      expect(aChildren.first, isA<FileTreeNode>());
      expect((aChildren.first as FileTreeNode).node.path, 'a/sub');
      final valueBuckets = aChildren.whereType<GroupHeaderNode>().toList();
      expect(_headerLabels(valueBuckets), ['5']);
      expect(_filePaths((valueBuckets.single).children), [
        'a/x.txt',
        'a/y.txt',
      ]);
      // sub 폴더의 직속 파일도 값으로 재그룹된다('1').
      final sub = aChildren.first as FileTreeNode;
      expect(_headerLabels(sub.children), ['1']);
    });
  });

  test('필터가 먼저 걸린 뒤 남은 노드만 그룹화된다', () {
    final files = [_node(1, 'x'), _node(2, 'y')];
    final assignments = {
      1: [_assign(1, _rating, '5'), _assign(1, _label, null)],
      2: [_assign(2, _rating, '3')],
    };
    // 숨김(4) 태그가 있는 노드만 표시.
    final tree = _run(
      files,
      assignments,
      const FileGrouping(keys: [TagGroupKey(2)]),
      filter: const FileFilter(
        conditions: [FilterCondition(tagDefinitionId: 4)],
      ),
    );
    // y는 필터에서 빠지고 x만 '5' 버킷에.
    expect(_headerLabels(tree), ['5']);
    expect(_filePaths((tree.single as GroupHeaderNode).children), ['x']);
  });
}
