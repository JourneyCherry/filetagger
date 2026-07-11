import 'package:filetagger/domain/entities/assigned_tag.dart';
import 'package:filetagger/domain/entities/tag_assignment.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/domain/usecases/tag_display_order.dart';
import 'package:flutter_test/flutter_test.dart';

TagDefinition _def(int id, {bool allowMultiple = false}) => TagDefinition(
  id: id,
  name: 't$id',
  valueType: TagValueType.text,
  allowMultiple: allowMultiple,
);

/// 부여 기록 하나. [assignmentId]가 부여된 순서를 나타낸다(시스템 태그는 null).
AssignedTag _tag(int defId, {int? assignmentId, String? value}) => AssignedTag(
  assignment: TagAssignment(
    id: assignmentId,
    fileNodeId: 1,
    tagDefinitionId: defId,
    value: value,
  ),
  definition: _def(defId),
);

List<int> _defIds(List<AssignedTag> tags) => [
  for (final t in tags) t.tagDefinitionId,
];

void main() {
  group('orderAssignedTags', () {
    test('표시 순서대로 정렬한다', () {
      final tags = [
        _tag(1, assignmentId: 1),
        _tag(2, assignmentId: 2),
        _tag(3, assignmentId: 3),
      ];
      expect(_defIds(orderAssignedTags(tags, [3, 1, 2])), [3, 1, 2]);
    });

    test('표시 순서에 없는 태그는 원래 순서를 지킨 채 뒤에 붙는다', () {
      final tags = [
        _tag(1, assignmentId: 1),
        _tag(2, assignmentId: 2),
        _tag(3, assignmentId: 3),
      ];
      // 태그 3만 순서에 실려 있다 → 3이 먼저, 나머지는 원래 순서(1, 2).
      expect(_defIds(orderAssignedTags(tags, [3])), [3, 1, 2]);
    });

    test('빈 표시 순서면 원래 순서를 그대로 둔다', () {
      final tags = [_tag(2, assignmentId: 1), _tag(1, assignmentId: 2)];
      expect(_defIds(orderAssignedTags(tags, const [])), [2, 1]);
    });

    test('다중 값 태그는 개별 칩으로 흩되 부여된 순서를 지킨다', () {
      final tags = [
        _tag(1, assignmentId: 30, value: 'c'),
        _tag(2, assignmentId: 10, value: 'x'),
        _tag(1, assignmentId: 10, value: 'a'),
        _tag(1, assignmentId: 20, value: 'b'),
      ];
      final ordered = orderAssignedTags(tags, [1, 2]);
      expect(_defIds(ordered), [1, 1, 1, 2]);
      expect([for (final t in ordered) t.value], ['a', 'b', 'c', 'x']);
    });

    test('시스템 태그(음수 id)도 순서 목록에 실리면 사용자 태그 위로 옮겨진다', () {
      // 순서 목록은 무리 구분 없이 자리를 그대로 정한다(자유 이동).
      final tags = [_tag(1, assignmentId: 1), _tag(-1), _tag(-2)];
      expect(_defIds(orderAssignedTags(tags, [-2, 1, -1])), [-2, 1, -1]);
    });

    test('부여 기록 id가 없는(합성) 같은 태그는 원래 순서를 지킨다', () {
      final tags = [_tag(-1, value: 'b'), _tag(-1, value: 'a')];
      final ordered = orderAssignedTags(tags, [-1]);
      expect([for (final t in ordered) t.value], ['b', 'a']);
    });
  });

  group('orderTagDefinitions', () {
    test('표시 순서대로 정렬하고 없는 정의는 뒤에 원래 순서로 붙인다', () {
      final defs = [_def(1), _def(2), _def(3), _def(4)];
      final ordered = orderTagDefinitions(defs, [3, 1]);
      expect([for (final d in ordered) d.id], [3, 1, 2, 4]);
    });

    test('빈 표시 순서면 원래 순서를 그대로 둔다', () {
      final defs = [_def(2), _def(1)];
      expect(
        [for (final d in orderTagDefinitions(defs, const [])) d.id],
        [2, 1],
      );
    });

    test('완전한 순서를 주면 시스템 태그도 그 자리를 그대로 지킨다', () {
      final defs = [_def(1), _def(-1), _def(2)];
      // 사용자 사이에 시스템 태그를 끼워 저장한 순서도 그대로 반영된다(자유 이동).
      expect(
        [
          for (final d in orderTagDefinitions(defs, [1, -1, 2])) d.id,
        ],
        [1, -1, 2],
      );
    });
  });

  group('normalizeTagOrder', () {
    test('순서에 빠진 시스템 태그는 뒤에, 빠진 사용자 태그는 앞에 붙인다', () {
      // 실제로 저장돼 있던 형태(시스템 태그만 나열) → 사용자 태그가 앞으로 온다.
      expect(normalizeTagOrder([1, 2, -1, -2], [-1, -2]), [1, 2, -1, -2]);
    });

    test('저장된 순서에 실린 태그는 자리를 그대로 지킨다', () {
      // 사용자가 시스템 태그를 위로 끌어 저장한 순서는 보존된다.
      expect(normalizeTagOrder([1, 2, -1], [-1, 1, 2]), [-1, 1, 2]);
    });

    test('빈 순서면 사용자 태그가 앞, 시스템 태그가 뒤(기본값)', () {
      expect(normalizeTagOrder([-1, 1, -2, 2], const []), [1, 2, -1, -2]);
    });

    test('더 이상 없는 태그 id는 걷어낸다', () {
      expect(normalizeTagOrder([1, -1], [9, 1, -1]), [1, -1]);
    });
  });
}
