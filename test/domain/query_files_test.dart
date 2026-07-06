import 'package:filetagger/domain/entities/assigned_tag.dart';
import 'package:filetagger/domain/entities/file_filter.dart';
import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/file_sort.dart';
import 'package:filetagger/domain/entities/tag_assignment.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/domain/usecases/query_files.dart';
import 'package:flutter_test/flutter_test.dart';

FileNode _file(int id, String path, {bool dir = false}) =>
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

const _priority = TagDefinition(
  id: 7,
  name: 'priority',
  valueType: TagValueType.number,
);
const _stage = TagDefinition(
  id: 8,
  name: 'stage',
  valueType: TagValueType.text,
);

void main() {
  const query = QueryFiles();

  test('필터가 표시 조건 없는 파일을 제거한다', () {
    final files = [_file(1, 'a.txt'), _file(2, 'b.txt')];
    final assignments = {
      1: [_assign(1, 7, TagValueType.number, '1')],
    };
    final result = query(
      files: files,
      assignmentsByFile: assignments,
      filter: const FileFilter(
        conditions: [FilterCondition(tagDefinitionId: 7)],
      ),
      sort: const FileSortOrder(),
      definitionsById: const {7: _priority},
    );
    expect(result.map((f) => f.id), [1]);
  });

  test('정렬 단계가 없으면 폴더 우선 이름순', () {
    final files = [
      _file(1, 'zeta.txt'),
      _file(2, 'alpha.txt'),
      _file(3, 'dir', dir: true),
    ];
    final result = query(
      files: files,
      assignmentsByFile: const {},
      filter: const FileFilter(),
      sort: const FileSortOrder(),
      definitionsById: const {},
    );
    expect(result.map((f) => f.id), [3, 2, 1]);
  });

  test('숫자 태그 정렬은 값 크기순, 값 없는 파일은 방향과 무관하게 뒤', () {
    final files = [_file(1, 'a'), _file(2, 'b'), _file(3, 'c')];
    final assignments = {
      1: [_assign(1, 7, TagValueType.number, '10')],
      2: [_assign(2, 7, TagValueType.number, '2')],
    };
    final asc = query(
      files: files,
      assignmentsByFile: assignments,
      filter: const FileFilter(),
      sort: const FileSortOrder(keys: [SortKey(tagDefinitionId: 7)]),
      definitionsById: const {7: _priority},
    );
    expect(asc.map((f) => f.id), [2, 1, 3]);

    final desc = query(
      files: files,
      assignmentsByFile: assignments,
      filter: const FileFilter(),
      sort: const FileSortOrder(
        keys: [
          SortKey(tagDefinitionId: 7, direction: SortDirection.descending),
        ],
      ),
      definitionsById: const {7: _priority},
    );
    expect(desc.map((f) => f.id), [1, 2, 3]);
  });

  test('다단계 정렬: 앞 단계 동률일 때 다음 단계로 넘어간다', () {
    final files = [_file(1, 'a'), _file(2, 'b'), _file(3, 'c')];
    final assignments = {
      // stage(8): 1,2는 'x'로 동률, 3은 'y'
      1: [
        _assign(1, 8, TagValueType.text, 'x'),
        _assign(1, 7, TagValueType.number, '9'),
      ],
      2: [
        _assign(2, 8, TagValueType.text, 'x'),
        _assign(2, 7, TagValueType.number, '1'),
      ],
      3: [_assign(3, 8, TagValueType.text, 'y')],
    };
    final result = query(
      files: files,
      assignmentsByFile: assignments,
      filter: const FileFilter(),
      // 1순위 stage(오름), 2순위 priority(오름).
      sort: const FileSortOrder(
        keys: [SortKey(tagDefinitionId: 8), SortKey(tagDefinitionId: 7)],
      ),
      definitionsById: const {7: _priority, 8: _stage},
    );
    // stage x끼리는 priority로 2<9 → 2,1 순, 그 뒤 stage y인 3.
    expect(result.map((f) => f.id), [2, 1, 3]);
  });

  test('label 정렬은 방향과 무관하게 부여된 요소를 위로, 없는 요소는 뒤로', () {
    const fav = TagDefinition(
      id: 9,
      name: 'fav',
      valueType: TagValueType.label,
    );
    final files = [_file(1, 'a'), _file(2, 'b'), _file(3, 'c')];
    final assignments = {
      1: [_assign(1, 9, TagValueType.label, null)],
      3: [_assign(3, 9, TagValueType.label, null)],
      // 2는 미부여
    };
    for (final dir in SortDirection.values) {
      final result = query(
        files: files,
        assignmentsByFile: assignments,
        filter: const FileFilter(),
        sort: FileSortOrder(
          keys: [SortKey(tagDefinitionId: 9, direction: dir)],
        ),
        definitionsById: const {9: fav},
      );
      // 부여된 1,3이 앞(그 안에서 이름순), 미부여 2는 방향과 무관하게 뒤.
      expect(result.map((f) => f.id), [1, 3, 2], reason: '$dir');
    }
  });

  test('다중 값은 방향에 맞는 대표값으로 정렬(오름=최소)', () {
    final files = [_file(1, 'a'), _file(2, 'b')];
    final assignments = {
      1: [
        _assign(1, 7, TagValueType.number, '5'),
        _assign(1, 7, TagValueType.number, '1'),
      ],
      2: [_assign(2, 7, TagValueType.number, '3')],
    };
    final asc = query(
      files: files,
      assignmentsByFile: assignments,
      filter: const FileFilter(),
      sort: const FileSortOrder(keys: [SortKey(tagDefinitionId: 7)]),
      definitionsById: const {7: _priority},
    );
    // 파일1의 대표값은 최소인 1 → 3보다 앞.
    expect(asc.map((f) => f.id), [1, 2]);
  });
}
