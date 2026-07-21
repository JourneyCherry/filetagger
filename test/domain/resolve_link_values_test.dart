import 'package:filetagger/domain/entities/assigned_tag.dart';
import 'package:filetagger/domain/entities/tag_assignment.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/domain/usecases/resolve_link_values.dart';
import 'package:flutter_test/flutter_test.dart';

AssignedTag tag(int defId, TagValueType type, String? value) => AssignedTag(
  assignment: TagAssignment(fileNodeId: 1, tagDefinitionId: defId, value: value),
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

    test('대상을 찾지 못한 링크는 값이 비워진다(값 없음처럼)', () {
      final resolved = resolveLinkAssignments({
        1: [tag(5, TagValueType.link, '999')],
      }, nameOf);
      expect(resolved[1]!.single.value, isNull);
    });

    test('빈/누락 링크 값도 안전하게 null', () {
      final resolved = resolveLinkAssignments({
        1: [tag(5, TagValueType.link, null), tag(5, TagValueType.link, '')],
      }, nameOf);
      expect(resolved[1]!.every((t) => t.value == null), isTrue);
    });
  });
}
