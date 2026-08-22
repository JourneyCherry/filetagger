import 'package:filetagger/domain/entities/tag_color_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('16진 표기', () {
    test('저장 정수를 앞에 우물정을 붙인 대문자 여섯 자리로 낸다', () {
      expect(tagColorToHex(0xFF64B5F6), '#64B5F6');
    });

    test('앞자리가 비는 색도 여섯 자리를 채운다', () {
      expect(tagColorToHex(0xFF000000), '#000000');
      expect(tagColorToHex(0xFF0A0B0C), '#0A0B0C');
    });

    test('우물정·공백·소문자를 가리지 않고 읽는다', () {
      const expected = 0xFF64B5F6;
      expect(parseTagColorHex('#64B5F6'), expected);
      expect(parseTagColorHex('64b5f6'), expected);
      expect(parseTagColorHex('  #64b5F6  '), expected);
    });

    test('축약형은 각 자리를 두 번 쓴 것으로 편다', () {
      expect(parseTagColorHex('#FA0'), 0xFFFFAA00);
    });

    test('읽을 수 없는 글자는 null을 돌려준다', () {
      // 빈 칸·자릿수 미달·초과·16진이 아닌 글자.
      expect(parseTagColorHex(''), isNull);
      expect(parseTagColorHex('#'), isNull);
      expect(parseTagColorHex('#12'), isNull);
      expect(parseTagColorHex('#1234'), isNull);
      expect(parseTagColorHex('#12345678'), isNull);
      expect(parseTagColorHex('#GGGGGG'), isNull);
      expect(parseTagColorHex('파랑'), isNull);
    });

    test('읽어 낸 색은 늘 불투명이다', () {
      // 칩 배경이 뒤와 섞이면 대비 보장이 깨진다.
      expect(parseTagColorHex('#64B5F6')! & 0xFF000000, opaqueTagColorBits);
    });

    test('내고 다시 읽으면 같은 색으로 돌아온다', () {
      for (final argb in [0xFFE57373, 0xFF4DD0E1, 0xFF000000, 0xFFFFFFFF]) {
        expect(parseTagColorHex(tagColorToHex(argb)), argb);
      }
    });
  });
}
