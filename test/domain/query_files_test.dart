import 'package:filetagger/domain/entities/assigned_tag.dart';
import 'package:filetagger/domain/entities/file_filter.dart';
import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/node_kind.dart';
import 'package:filetagger/domain/entities/file_sort.dart';
import 'package:filetagger/domain/entities/tag_assignment.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/domain/usecases/query_files.dart';
import 'package:flutter_test/flutter_test.dart';

FileNode _file(int id, String path, {bool dir = false}) => FileNode(
  id: id,
  path: path,
  kind: dir ? NodeKind.directory : NodeKind.file,
);

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

/// 다단계 정렬 검사용 고정 목록. stage(8)로 x/y가 갈리고 x 안에서 priority(7)가
/// 갈리되, 두 노드는 양쪽 값이 모두 같아 "동률로 남는 노드"가 함께 든다.
final _multiStepFiles = [
  _file(1, 'a'),
  _file(2, 'b'),
  _file(3, 'c'),
  _file(4, 'd'),
];

final _multiStepAssignments = <int, List<AssignedTag>>{
  1: [
    _assign(1, 8, TagValueType.text, 'x'),
    _assign(1, 7, TagValueType.number, '5'),
  ],
  2: [
    _assign(2, 8, TagValueType.text, 'x'),
    _assign(2, 7, TagValueType.number, '5'),
  ],
  3: [
    _assign(3, 8, TagValueType.text, 'x'),
    _assign(3, 7, TagValueType.number, '9'),
  ],
  4: [
    _assign(4, 8, TagValueType.text, 'y'),
    _assign(4, 7, TagValueType.number, '1'),
  ],
};

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

  group('무작위 정렬', () {
    // 무작위 단계는 값의 순서만 흩는다. 그래서 값이 같은 노드는 동률로 남고 뒤
    // 단계가 그들의 순서를 정한다 — 이 성질 덕에 다단계 정렬이 그대로 산다.
    List<int> orderOf(FileSortOrder sort, List<FileNode> files) => query(
      files: files,
      assignmentsByFile: _multiStepAssignments,
      filter: const FileFilter(),
      sort: sort,
      definitionsById: const {7: _priority, 8: _stage},
    ).map((f) => f.id!).toList();

    test('앞 단계가 정한 자리는 지키고, 값이 같은 노드는 다음 단계가 정한다', () {
      // 1순위 stage(오름) → 2순위 priority(무작위). stage가 같은 노드끼리만 섞이고
      // priority 값까지 같은 노드는 흐트러지지 않아 이름으로 안정화된다.
      final order = orderOf(
        FileSortOrder(
          keys: [
            const SortKey(tagDefinitionId: 8),
            SortKey.shuffled(tagDefinitionId: 7),
          ],
        ),
        _multiStepFiles,
      );
      // stage 'x'인 1·2·3이 앞(그 안에서 무작위), stage 'y'인 4는 늘 뒤.
      expect(order.last, 4);
      // priority가 같은 1·2는 무작위 자리도 같아 늘 이름순으로 붙어 있다.
      expect(order.indexOf(2) - order.indexOf(1), 1);
    });

    test('씨앗이 같으면 목록을 다시 세워도 같은 순서다', () {
      const sort = FileSortOrder(
        keys: [
          SortKey(tagDefinitionId: 8, direction: SortDirection.random, seed: 1),
        ],
      );
      // 스캔 결과의 순서가 달라져도(재스캔) 씨앗이 그대로면 화면은 그대로여야 한다.
      expect(
        orderOf(sort, _multiStepFiles.reversed.toList()),
        orderOf(sort, _multiStepFiles),
      );
    });

    test('씨앗이 다르면 순서가 갈린다', () {
      final orders = {
        for (var seed = 0; seed < 16; seed++)
          orderOf(
            FileSortOrder(
              keys: [
                SortKey(
                  tagDefinitionId: 7,
                  direction: SortDirection.random,
                  seed: seed,
                ),
              ],
            ),
            _multiStepFiles,
          ).join(','),
      };
      expect(orders, hasLength(greaterThan(1)));
    });

    test('값 없는 노드는 무작위에서도 뒤로 밀린다', () {
      final files = [_file(1, 'a'), _file(2, 'b'), _file(3, 'c')];
      final assignments = {
        1: [_assign(1, 7, TagValueType.number, '10')],
        3: [_assign(3, 7, TagValueType.number, '2')],
      };
      for (var seed = 0; seed < 16; seed++) {
        final result = query(
          files: files,
          assignmentsByFile: assignments,
          filter: const FileFilter(),
          sort: FileSortOrder(
            keys: [
              SortKey(
                tagDefinitionId: 7,
                direction: SortDirection.random,
                seed: seed,
              ),
            ],
          ),
          definitionsById: const {7: _priority},
        );
        expect(result.map((f) => f.id).last, 2, reason: '씨앗 $seed');
      }
    });
  });

  test('정의를 모르는 태그로 정렬하면 값 있는 노드만 앞으로 밀린다', () {
    // 방금 지워진 태그를 참조하는 정렬 단계. 값을 견줄 규칙이 없어 값끼리는
    // 동률이지만, 값이 있는 노드는 없는 노드보다 앞에 선다.
    final files = [_file(1, 'a'), _file(2, 'b'), _file(3, 'c')];
    final assignments = {
      2: [_assign(2, 99, TagValueType.text, 'zzz')],
      3: [_assign(3, 99, TagValueType.text, 'aaa')],
    };
    final result = query(
      files: files,
      assignmentsByFile: assignments,
      filter: const FileFilter(),
      sort: const FileSortOrder(keys: [SortKey(tagDefinitionId: 99)]),
      definitionsById: const {},
    );
    // 2·3은 동률이라 이름으로 안정화되고, 값 없는 1이 뒤로 밀린다.
    expect(result.map((f) => f.id), [2, 3, 1]);
  });
}
