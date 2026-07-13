import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/domain/usecases/cell_value_edit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatCellEditText', () {
    test('단일 텍스트는 인용 없이 그 값만', () {
      expect(
        formatCellEditText(TagValueType.text, false, ['a b c']),
        'a b c',
      );
    });

    test('다중 텍스트는 값마다 쌍따옴표로 감싸 콤마로 잇는다', () {
      expect(
        formatCellEditText(TagValueType.text, true, ['foo bar', 'baz']),
        '"foo bar", "baz"',
      );
    });

    test('텍스트 안의 쌍따옴표는 겹쳐 표기한다', () {
      expect(
        formatCellEditText(TagValueType.text, true, ['say "hi"']),
        '"say ""hi"""',
      );
    });

    test('다중 숫자는 인용 없이 콤마로만 잇는다', () {
      expect(
        formatCellEditText(TagValueType.number, true, ['1', '2.5']),
        '1, 2.5',
      );
    });

    test('날짜는 사람이 읽는 형식으로 자른다', () {
      expect(
        formatCellEditText(
          TagValueType.date,
          false,
          ['2026-07-13T00:00:00.000'],
        ),
        '2026-07-13',
      );
    });

    test('값이 없으면 빈 문자열', () {
      expect(formatCellEditText(TagValueType.text, true, []), '');
    });
  });

  group('parseCellEditText', () {
    test('단일 텍스트는 콤마도 값의 일부로 통째로 받는다', () {
      expect(
        parseCellEditText(TagValueType.text, false, 'a, b'),
        ['a, b'],
      );
    });

    test('다중 텍스트는 인용된 콤마 구분을 나눠 인용을 푼다', () {
      expect(
        parseCellEditText(TagValueType.text, true, '"foo bar", "baz"'),
        ['foo bar', 'baz'],
      );
    });

    test('인용 안 한 조각도 콤마로 나눠 받는다', () {
      expect(
        parseCellEditText(TagValueType.text, true, 'foo, bar'),
        ['foo', 'bar'],
      );
    });

    test('겹친 쌍따옴표는 한 개로 되돌린다', () {
      expect(
        parseCellEditText(TagValueType.text, true, '"say ""hi"""'),
        ['say "hi"'],
      );
    });

    test('빈 조각은 버린다(빈 입력은 태그 제거)', () {
      expect(parseCellEditText(TagValueType.text, true, ''), isEmpty);
      expect(
        parseCellEditText(TagValueType.text, true, '"a", , "b"'),
        ['a', 'b'],
      );
    });

    test('숫자가 아닌 조각은 버린다', () {
      expect(
        parseCellEditText(TagValueType.number, true, '1, x, 3'),
        ['1', '3'],
      );
    });

    test('날짜는 저장 형식(시각 제거)으로 바꾸고 못 읽으면 버린다', () {
      expect(
        parseCellEditText(TagValueType.date, true, '2026-07-13, nope'),
        ['2026-07-13T00:00:00.000'],
      );
    });

    test('편집 텍스트를 파싱하면 다시 같은 텍스트로 되돌아온다(왕복)', () {
      const values = ['foo, bar', 'baz "q"'];
      final text = formatCellEditText(TagValueType.text, true, values);
      expect(parseCellEditText(TagValueType.text, true, text), values);
    });
  });
}
