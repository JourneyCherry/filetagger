import 'package:filetagger/cli/tag_commands.dart';
import 'package:filetagger/domain/entities/tag_color_format.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/l10n/console_strings.dart';
import 'package:flutter_test/flutter_test.dart';

final ConsoleStrings _strings = consoleStringsFor(consoleTemplateLanguageCode);

TagDefinition _definition({
  int? id = 1,
  String name = '작가',
  TagValueType valueType = TagValueType.text,
  int? color,
  bool allowMultiple = false,
}) => TagDefinition(
  id: id,
  name: name,
  valueType: valueType,
  color: color,
  allowMultiple: allowMultiple,
);

/// 열 이름으로 한 줄에서 그 칸을 집는다 — 열이 늘어도 테스트가 자리를 세지 않는다.
String _column(String line, String column) =>
    line.split('\t')[definitionColumns(_strings).indexOf(column)];

void main() {
  group('사람용 한 줄', () {
    test('없는 성질도 자리를 비우지 않는다', () {
      final line = definitionLine(_definition(), const {}, _strings);
      final columns = line.split('\t');

      // 열이 밀리면 cut·awk로 집어 쓸 수 없다.
      expect(columns.length, definitionColumns(_strings).length);
      expect(columns.every((c) => c.isNotEmpty), isTrue);
    });

    test('색은 16진 표기로 낸다', () {
      final color = parseTagColorHex('#3366CC')!;

      final line = definitionLine(
        _definition(color: color),
        const {},
        _strings,
      );

      // 저장은 정수지만 사람이 읽고 다시 치는 것은 16진 표기다.
      expect(line, contains(tagColorToHex(color)));
    });

    test('부여 수는 그 태그의 것만 센다', () {
      final line = definitionLine(_definition(id: 7), const {
        7: 3,
        8: 99,
      }, _strings);

      expect(_column(line, _strings.columnAssignments), '3');
    });

    test('아직 저장 전인 정의는 부여가 없다', () {
      // 만든 직후를 그대로 내는 자리가 있어, id가 없는 정의도 지나간다.
      final line = definitionLine(_definition(id: null), const {
        1: 5,
      }, _strings);

      expect(_column(line, _strings.columnAssignments), '0');
      expect(_column(line, _strings.columnId), _strings.labelNone);
    });

    test('id를 맨 뒤에 붙여 앞자리를 밀지 않는다', () {
      final line = definitionLine(_definition(id: 7), const {}, _strings);

      expect(line.split('\t').first, _definition().name);
      expect(line.split('\t').last, '7');
    });
  });

  group('기계용 표현', () {
    test('성질을 이름으로 낸다', () {
      final json = definitionToJson(
        _definition(valueType: TagValueType.link, allowMultiple: true),
        const {1: 2},
      );

      // 값 순서가 바뀌어도 흔들리지 않도록 열거는 이름으로 나간다.
      expect(json['valueType'], TagValueType.link.name);
      expect(json['allowMultiple'], isTrue);
      expect(json['assignments'], 2);
    });

    test('색이 없으면 키를 두지 않는다', () {
      final json = definitionToJson(_definition(), const {});

      expect(json.containsKey('color'), isFalse);
    });
  });
}
