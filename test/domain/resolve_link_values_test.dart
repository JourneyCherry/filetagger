import 'package:filetagger/domain/entities/assigned_tag.dart';
import 'package:filetagger/domain/entities/tag_assignment.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/domain/usecases/resolve_link_values.dart';
import 'package:flutter_test/flutter_test.dart';

AssignedTag tag(
  int defId,
  TagValueType type,
  String? value, {
  bool unresolved = false,
}) => AssignedTag(
  assignment: TagAssignment(
    fileNodeId: 1,
    tagDefinitionId: defId,
    value: value,
    valueUnresolved: unresolved,
  ),
  definition: TagDefinition(id: defId, name: 'T$defId', valueType: type),
);

void main() {
  group('resolveLinkAssignments', () {
    String? nameOf(String raw) => const {'10': '표지.png', '20': '다음화.png'}[raw];

    test('링크 값(대상 id)을 대상 이름으로 바꾼다', () {
      final resolved = resolveLinkAssignments({
        1: [tag(5, TagValueType.link, '10')],
      }, nameOf);
      expect(resolved[1]!.single.value, '표지.png');
    });

    test('링크 아닌 부여는 그대로 둔다', () {
      final input = {
        1: [
          tag(5, TagValueType.text, 'hello'),
          tag(6, TagValueType.number, '3'),
        ],
      };
      final resolved = resolveLinkAssignments(input, nameOf);
      // 변경이 없으면 같은 리스트 인스턴스를 그대로 돌려준다.
      expect(identical(resolved[1], input[1]), isTrue);
    });

    test('대상이 떠 버린 링크는 미해결로 표시하고 뜻 없는 id는 감춘다', () {
      // 값을 비우기만 하면 "값 없음"과 구분되지 않아, 대상이 지워진 링크가 조용히
      // 사라진 것처럼 보인다.
      final resolved = resolveLinkAssignments({
        1: [tag(5, TagValueType.link, '999')],
      }, nameOf);
      expect(resolved[1]!.single.valueUnresolved, isTrue);
      expect(resolved[1]!.single.value, isNull);
    });

    test('가져온 미해결 링크는 원문을 그대로 들고 간다', () {
      // 사람이 읽을 수 있는 원문(경로·키워드 이름)이라 표시에도 필터에도 쓰인다.
      final resolved = resolveLinkAssignments({
        1: [tag(5, TagValueType.link, '작가/홍길동', unresolved: true)],
      }, nameOf);
      expect(resolved[1]!.single.value, '작가/홍길동');
      expect(resolved[1]!.single.valueUnresolved, isTrue);
    });

    test('빈/누락 링크 값은 미해결이 아니라 값 없음이다', () {
      final resolved = resolveLinkAssignments({
        1: [tag(5, TagValueType.link, null), tag(5, TagValueType.link, '')],
      }, nameOf);
      expect(resolved[1]!.every((t) => t.value == null), isTrue);
      expect(resolved[1]!.every((t) => !t.valueUnresolved), isTrue);
    });
  });
}
