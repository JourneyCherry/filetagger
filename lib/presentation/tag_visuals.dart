/// 태그 표시에 쓰는 시각 요소의 단일 출처(색 팔레트·유형 라벨).
///
/// 색상값 자체는 여기 상수로만 두고(컨벤션 2), 화면들은 이 헬퍼를 통해서만
/// 색·라벨을 얻는다.
library;

import 'package:flutter/material.dart';

import '../domain/entities/file_filter.dart';
import '../domain/entities/tag_value_type.dart';

/// 태그 정의 색으로 고를 수 있는 프리셋 팔레트(ARGB).
const List<int> tagColorPalette = <int>[
  0xFFE57373, // red
  0xFFF06292, // pink
  0xFFBA68C8, // purple
  0xFF9575CD, // deep purple
  0xFF7986CB, // indigo
  0xFF64B5F6, // blue
  0xFF4DD0E1, // cyan
  0xFF4DB6AC, // teal
  0xFF81C784, // green
  0xFFDCE775, // lime
  0xFFFFD54F, // amber
  0xFFFFB74D, // orange
  0xFFA1887F, // brown
  0xFF90A4AE, // blue grey
];

/// 저장된 색 정수를 [Color]로. 미지정이면 테마 기본색을 쓴다.
Color tagColorOf(int? argb, BuildContext context) {
  if (argb == null) return Theme.of(context).colorScheme.secondaryContainer;
  return Color(argb);
}

/// 배경색 위에 얹을 글자색을 WCAG 대비비가 큰 쪽(검정/흰색)으로 고른다.
///
/// 대비비 = (밝은쪽+오프셋)/(어두운쪽+오프셋)을 흑·백 각각 계산해 더 잘 읽히는
/// 쪽을 반환한다. 어두운 태그색에서도 글자 가독성을 접근성 기준으로 보장한다.
Color foregroundOn(Color background) {
  const offset = 0.05; // WCAG 상대휘도 대비 공식의 고정 오프셋.
  final luminance = background.computeLuminance();
  final contrastWithWhite = (1.0 + offset) / (luminance + offset);
  final contrastWithBlack = (luminance + offset) / offset;
  return contrastWithWhite >= contrastWithBlack ? Colors.white : Colors.black;
}

/// 값 유형의 사용자 표시 라벨.
String tagValueTypeLabel(TagValueType type) {
  switch (type) {
    case TagValueType.label:
      return '라벨';
    case TagValueType.text:
      return '텍스트';
    case TagValueType.number:
      return '숫자';
    case TagValueType.date:
      return '날짜';
  }
}

/// 필터 연산자의 짧은 표시 라벨(칩·드롭다운용).
String filterOperatorLabel(FilterOperator op) {
  switch (op) {
    case FilterOperator.exists:
      return '있음';
    case FilterOperator.equals:
      return '=';
    case FilterOperator.notEquals:
      return '≠';
    case FilterOperator.lessThan:
      return '<';
    case FilterOperator.lessOrEqual:
      return '≤';
    case FilterOperator.greaterThan:
      return '>';
    case FilterOperator.greaterOrEqual:
      return '≥';
    case FilterOperator.contains:
      return '포함';
  }
}

/// 부여된 값의 표시 문자열. label은 값이 없고, date는 날짜만 보기 좋게 자른다.
/// 표시할 값이 없으면 null을 돌려 칩이 값 부분을 생략하게 한다.
String? formatTagValue(TagValueType type, String? value) {
  if (type == TagValueType.label) return null;
  if (value == null || value.isEmpty) return null;
  if (type == TagValueType.date) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      final m = parsed.month.toString().padLeft(2, '0');
      final d = parsed.day.toString().padLeft(2, '0');
      return '${parsed.year}-$m-$d';
    }
  }
  return value;
}

/// 날짜 값을 저장용 ISO 문자열로(날짜만, 시각 제거).
String dateToStoredValue(DateTime date) =>
    DateTime(date.year, date.month, date.day).toIso8601String();
