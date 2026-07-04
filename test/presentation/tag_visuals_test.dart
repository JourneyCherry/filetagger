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
}
