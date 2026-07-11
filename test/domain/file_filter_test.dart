import 'package:filetagger/domain/entities/assigned_tag.dart';
import 'package:filetagger/domain/entities/file_filter.dart';
import 'package:filetagger/domain/entities/tag_assignment.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:flutter_test/flutter_test.dart';

AssignedTag _tag(int defId, TagValueType type, String? value) => AssignedTag(
  assignment: TagAssignment(
    fileNodeId: 1,
    tagDefinitionId: defId,
    value: value,
  ),
  definition: TagDefinition(id: defId, name: 't$defId', valueType: type),
);

void main() {
  group('FilterCondition', () {
    test('exists는 값과 무관하게 태그 존재 여부만 본다', () {
      const c = FilterCondition(tagDefinitionId: 1);
      expect(c.matches([_tag(1, TagValueType.label, null)]), isTrue);
      expect(c.matches(const []), isFalse);
    });

    test('number 비교 연산은 숫자 크기로 판정', () {
      const gt = FilterCondition(
        tagDefinitionId: 1,
        operator: FilterOperator.greaterThan,
        operand: '5',
      );
      expect(gt.matches([_tag(1, TagValueType.number, '10')]), isTrue);
      expect(gt.matches([_tag(1, TagValueType.number, '3')]), isFalse);
    });

    test('text contains는 부분 문자열(대소문자 무시)', () {
      const c = FilterCondition(
        tagDefinitionId: 1,
        operator: FilterOperator.contains,
        operand: 'ap',
      );
      expect(c.matches([_tag(1, TagValueType.text, 'Apple')]), isTrue);
      expect(c.matches([_tag(1, TagValueType.text, 'banana')]), isFalse);
    });

    test('text notContains는 부분 문자열이 없어야 통과', () {
      const c = FilterCondition(
        tagDefinitionId: 1,
        operator: FilterOperator.notContains,
        operand: 'ap',
      );
      expect(c.matches([_tag(1, TagValueType.text, 'banana')]), isTrue);
      expect(c.matches([_tag(1, TagValueType.text, 'Apple')]), isFalse);
    });

    test('부정 연산은 태그가 붙어 있어야 만족할 수 있다', () {
      // 제외 조건과 갈리는 지점: 값 비교는 태그가 없으면 판정 대상이 아니다.
      const c = FilterCondition(
        tagDefinitionId: 1,
        operator: FilterOperator.notContains,
        operand: 'ap',
      );
      expect(c.matches(const []), isFalse);
    });

    test('다중 값 중 하나라도 만족하면 통과', () {
      const c = FilterCondition(
        tagDefinitionId: 1,
        operator: FilterOperator.equals,
        operand: '2',
      );
      expect(
        c.matches([
          _tag(1, TagValueType.number, '1'),
          _tag(1, TagValueType.number, '2'),
        ]),
        isTrue,
      );
    });
  });

  group('FileFilter', () {
    test('표시 조건은 모두 만족해야 통과(AND)', () {
      const filter = FileFilter(
        conditions: [
          FilterCondition(tagDefinitionId: 1),
          FilterCondition(tagDefinitionId: 2),
        ],
      );
      expect(
        filter.matches([
          _tag(1, TagValueType.label, null),
          _tag(2, TagValueType.label, null),
        ]),
        isTrue,
      );
      expect(filter.matches([_tag(1, TagValueType.label, null)]), isFalse);
    });

    test('제외 조건은 만족하면 무조건 숨김', () {
      const filter = FileFilter(
        conditions: [
          FilterCondition(tagDefinitionId: 1),
          FilterCondition(tagDefinitionId: 9, exclude: true),
        ],
      );
      // 표시 조건 만족해도 제외 조건에 걸리면 탈락.
      expect(
        filter.matches([
          _tag(1, TagValueType.label, null),
          _tag(9, TagValueType.label, null),
        ]),
        isFalse,
      );
      expect(filter.matches([_tag(1, TagValueType.label, null)]), isTrue);
    });

    test('부정 연산 표시 조건과 제외 조건은 태그 없는 노드에서 갈린다', () {
      // "메모가 있고 그게 ap를 안 품은 것만" — 메모 없는 노드는 떨어진다.
      const notContains = FileFilter(
        conditions: [
          FilterCondition(
            tagDefinitionId: 1,
            operator: FilterOperator.notContains,
            operand: 'ap',
          ),
        ],
      );
      // "ap를 품은 메모만 빼고 다" — 메모 없는 노드는 남는다.
      const excluded = FileFilter(
        conditions: [
          FilterCondition(
            tagDefinitionId: 1,
            operator: FilterOperator.contains,
            operand: 'ap',
            exclude: true,
          ),
        ],
      );
      expect(notContains.matches(const []), isFalse);
      expect(excluded.matches(const []), isTrue);

      // 태그가 붙어 있을 땐 둘이 같은 답을 낸다.
      final apple = [_tag(1, TagValueType.text, 'Apple')];
      final banana = [_tag(1, TagValueType.text, 'banana')];
      expect(notContains.matches(apple), isFalse);
      expect(excluded.matches(apple), isFalse);
      expect(notContains.matches(banana), isTrue);
      expect(excluded.matches(banana), isTrue);
    });

    test('exists + 제외가 곧 미존재다(별도 notExists 연산이 필요 없는 이유)', () {
      // 값 비교와 달리 exists는 판정 대상이 "태그가 붙었는가" 자체다. 그래서
      // 제외 접두사가 정확히 부정이 되고, 태그 없는 노드에서도 어긋나지 않는다.
      const notExists = FileFilter(
        conditions: [FilterCondition(tagDefinitionId: 1, exclude: true)],
      );
      expect(notExists.matches(const []), isTrue);
      expect(notExists.matches([_tag(1, TagValueType.label, null)]), isFalse);
      // 다른 태그만 붙어 있어도 이 태그의 미존재는 성립한다.
      expect(notExists.matches([_tag(2, TagValueType.label, null)]), isTrue);
    });

    test('빈 필터는 모두 통과', () {
      const filter = FileFilter();
      expect(filter.isEmpty, isTrue);
      expect(filter.matches(const []), isTrue);
    });

    test('add/removeAt/replaceAt/reorder는 불변 목록을 만든다', () {
      const a = FilterCondition(tagDefinitionId: 1);
      const b = FilterCondition(tagDefinitionId: 2);
      var f = const FileFilter().add(a).add(b);
      expect(f.conditions.map((c) => c.tagDefinitionId), [1, 2]);

      f = f.reorder(0, 1);
      expect(f.conditions.map((c) => c.tagDefinitionId), [2, 1]);

      f = f.removeAt(0);
      expect(f.conditions.map((c) => c.tagDefinitionId), [1]);

      f = f.replaceAt(
        0,
        const FilterCondition(tagDefinitionId: 1, exclude: true),
      );
      expect(f.conditions.single.exclude, isTrue);
    });
  });

  test('operatorsForType은 유형별로 가능한 연산만 준다', () {
    expect(operatorsForType(TagValueType.label), [FilterOperator.exists]);
    expect(
      operatorsForType(TagValueType.text),
      contains(FilterOperator.contains),
    );
    expect(
      operatorsForType(TagValueType.number),
      contains(FilterOperator.greaterThan),
    );
    expect(
      operatorsForType(TagValueType.text),
      isNot(contains(FilterOperator.lessThan)),
    );
  });
}
