import 'package:filetagger/domain/entities/assigned_tag.dart';
import 'package:filetagger/domain/entities/tag_assignment.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/presentation/tag_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('foregroundOn (접근성 대비색)', () {
    test('어두운 배경에는 흰색 글자를 고른다', () {
      expect(foregroundOn(const Color(0xFF000000)), Colors.white);
      expect(foregroundOn(const Color(0xFF303030)), Colors.white);
    });

    test('밝은 배경에는 검은색 글자를 고른다', () {
      expect(foregroundOn(const Color(0xFFFFFFFF)), Colors.black);
      expect(foregroundOn(const Color(0xFFFFD54F)), Colors.black);
    });
  });

  group('hoverOn (호버 배경색)', () {
    test('밝은 태그는 어둡게, 어두운 태그는 밝게 옮긴다', () {
      const light = Color(0xFFFFD54F);
      const dark = Color(0xFF303030);
      expect(
        hoverOn(light).computeLuminance(),
        lessThan(light.computeLuminance()),
      );
      expect(
        hoverOn(dark).computeLuminance(),
        greaterThan(dark.computeLuminance()),
      );
    });

    test('배경색은 옮기되 불투명하게 유지한다', () {
      const background = Color(0xFF64B5F6);
      final hovered = hoverOn(background);
      expect(hovered, isNot(background));
      expect(hovered.a, 1.0);
    });
  });

  test('canNameSourceShowText는 값이 없거나 불투명한 유형만 걸러 낸다', () {
    // 이름 태그 후보 거르기와 formatTagValue가 이 하나를 함께 쓴다.
    expect(canNameSourceShowText(TagValueType.label), isFalse);
    expect(canNameSourceShowText(TagValueType.image), isFalse);
    for (final t in [
      TagValueType.text,
      TagValueType.number,
      TagValueType.date,
      TagValueType.link,
    ]) {
      expect(canNameSourceShowText(t), isTrue, reason: '$t');
    }
  });

  group('formatTagValue', () {
    test('label은 값을 표시하지 않는다', () {
      expect(formatTagValue(TagValueType.label, 'anything'), isNull);
    });

    test('값이 없거나 비면 null', () {
      expect(formatTagValue(TagValueType.text, null), isNull);
      expect(formatTagValue(TagValueType.text, ''), isNull);
    });

    test('text/number는 값을 그대로 보여준다', () {
      expect(formatTagValue(TagValueType.text, '메모'), '메모');
      expect(formatTagValue(TagValueType.number, '42'), '42');
    });

    test('date는 날짜만 잘라 보여준다', () {
      final iso = DateTime(2026, 7, 4, 13, 30).toIso8601String();
      expect(formatTagValue(TagValueType.date, iso), '2026-07-04');
    });

    test('date가 파싱 불가면 원값을 보여준다', () {
      expect(formatTagValue(TagValueType.date, 'not-a-date'), 'not-a-date');
    });
  });

  test('dateToStoredValue는 시각을 제거한 자정으로 저장한다', () {
    final stored = dateToStoredValue(DateTime(2026, 7, 4, 13, 30));
    final parsed = DateTime.parse(stored);
    expect(parsed, DateTime(2026, 7, 4));
  });

  group('buildDisplayNameIndex (이름 태그)', () {
    AssignedTag tag(int defId, TagValueType type, String? value) => AssignedTag(
      assignment: TagAssignment(
        fileNodeId: 1,
        tagDefinitionId: defId,
        value: value,
      ),
      definition: TagDefinition(id: defId, name: 'T$defId', valueType: type),
    );

    Map<int, String> build(
      Map<int, List<AssignedTag>> byFile,
      List<int> sources,
    ) => buildTagTextIndex(assignmentsByFile: byFile, sources: sources);

    test('출처가 없으면 아무 노드도 갈아끼우지 않는다', () {
      expect(
        build({
          1: [tag(5, TagValueType.text, '제목')],
        }, const []),
        isEmpty,
      );
    });

    test('우선순위 순으로 훑어 처음 글자를 낸 태그를 쓴다', () {
      final index = build(
        {
          1: [tag(5, TagValueType.text, '뒤'), tag(6, TagValueType.text, '앞')],
        },
        [6, 5],
      );
      expect(index[1], '앞');
    });

    test('앞선 출처가 없는 노드는 다음 출처로 내려간다', () {
      // 노드마다 가진 태그가 달라도 각자 맞는 출처가 뽑힌다.
      final index = build(
        {
          1: [tag(6, TagValueType.text, '앞')],
          2: [tag(5, TagValueType.text, '뒤')],
        },
        [6, 5],
      );
      expect(index[1], '앞');
      expect(index[2], '뒤');
    });

    test('글자로 못 내는 태그(label·image)는 이름 자리를 갈아끼우지 않는다', () {
      // 고르는 자리가 이런 태그를 후보에서 빼지만, 목록에 오른 뒤 값 유형이 바뀔 수
      // 있으므로 해석도 스스로 폴백한다 — 키가 아예 없으면 소비 측이 노드 이름을 쓴다.
      final index = build(
        {
          1: [tag(5, TagValueType.label, null)],
          2: [tag(6, TagValueType.image, 'cafe01.png')],
        },
        [5, 6],
      );
      expect(index, isEmpty);
    });

    test('빈 값도 못 낸 것으로 보고 다음 출처로 넘어간다', () {
      final index = build(
        {
          1: [tag(5, TagValueType.text, ''), tag(6, TagValueType.text, '있음')],
        },
        [5, 6],
      );
      expect(index[1], '있음');
    });

    test('날짜는 칩과 같은 규칙으로 다듬어 보인다', () {
      final index = build(
        {
          1: [
            tag(5, TagValueType.date, DateTime(2026, 7, 4).toIso8601String()),
          ],
        },
        [5],
      );
      expect(index[1], '2026-07-04');
    });

    test('다중값 태그는 처음 값 하나만 쓴다', () {
      // 이름은 한 줄에 놓이는 자리라 여럿을 이어 붙이면 되레 읽히지 않는다.
      final index = build(
        {
          1: [tag(5, TagValueType.text, '첫째'), tag(5, TagValueType.text, '둘째')],
        },
        [5],
      );
      expect(index[1], '첫째');
    });
  });
}
