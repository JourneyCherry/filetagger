/// 태그 표시에 쓰는 시각 요소의 단일 출처(색 팔레트·유형 라벨).
///
/// 색상값 자체는 여기 상수로만 두고(컨벤션 2), 화면들은 이 헬퍼를 통해서만
/// 색·라벨을 얻는다.
library;

import 'package:flutter/material.dart';

import '../domain/entities/assigned_tag.dart';
import '../domain/entities/file_filter.dart';
import '../domain/entities/tag_value_type.dart';

// 저장 형식은 domain이 단일 출처다. 표시 헬퍼와 함께 쓰이므로 여기서 다시 내보낸다.
export '../domain/entities/tag_value_format.dart' show dateToStoredValue;

/// 도구모음의 조건 줄(프리셋·필터·정렬·그룹)이 비었을 때 그 자리에 두는 문구.
///
/// 빈 자리마다 다른 말로 무슨 뜻인지 설명하지 않고 한 낱말로 통일한다 — 네 줄이 나란히
/// 놓여 있어, 설명이 저마다 다르면 무엇이 없는지보다 문구가 먼저 읽힌다. 칩 줄과 텍스트
/// 입력의 빈 자리, 프리셋 저장 미리보기가 모두 이 값을 쓴다.
const String kEmptyQueryLabel = '없음';

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

/// 시스템 태그(자동 파생)의 고정 배경색(회색). 사용자 색과 구분해 늘 이 색으로
/// 칠한다. 값의 단일 출처로 두어 칩이 이 상수만 참조한다.
const int kSystemTagColor = 0xFF9E9E9E;

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

/// 포인터를 올렸을 때 '누를 수 있음'을 알리는 배경색. 그 칩의 대비색(글자색)을
/// 옅게 덧칠해 밝은 태그는 어둡게, 어두운 태그는 밝게 옮긴다 — 태그 색이 무엇이든
/// 변화가 눈에 들어오게 하기 위함이다.
Color hoverOn(Color background) => Color.alphaBlend(
  foregroundOn(background).withValues(alpha: _hoverOverlayAlpha),
  background,
);

/// 호버 덧칠의 세기. 색이 바뀐 것은 알아채되 태그 색을 잃지 않을 만큼만.
const double _hoverOverlayAlpha = 0.2;

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
    case TagValueType.link:
      return '링크';
    case TagValueType.image:
      return '이미지';
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
    case FilterOperator.notContains:
      return '미포함';
  }
}

/// 필터 연산자의 설명이 붙은 라벨(연산 선택 목록·자동완성 목록용).
String filterOperatorMenuLabel(FilterOperator op) {
  switch (op) {
    case FilterOperator.exists:
      return '있음 (존재)';
    case FilterOperator.equals:
      return '= 같음';
    case FilterOperator.notEquals:
      return '≠ 다름';
    case FilterOperator.lessThan:
      return '< 미만';
    case FilterOperator.lessOrEqual:
      return '≤ 이하';
    case FilterOperator.greaterThan:
      return '> 초과';
    case FilterOperator.greaterOrEqual:
      return '≥ 이상';
    case FilterOperator.contains:
      return '포함';
    case FilterOperator.notContains:
      return '미포함';
  }
}

/// 부여된 값의 표시 문자열. label은 값이 없고, date는 날짜만 보기 좋게 자른다.
/// 표시할 값이 없으면 null을 돌려 칩이 값 부분을 생략하게 한다.
/// 이 값 유형이 **글자를 낼 수 있는가**. label은 값이 없고, image는 값이 불투명한
/// 캐시 키라 칩에도 이름 칸에도 글자로 보이지 않는다.
///
/// [formatTagValue]가 이 판정을 그대로 쓰고, 이름 태그를 고르는 자리도 같은 것으로
/// 후보를 거른다 — 두 곳이 갈라지면 "골랐는데 아무 일도 일어나지 않는" 태그가 생긴다.
bool canNameSourceShowText(TagValueType type) =>
    type != TagValueType.label && type != TagValueType.image;

String? formatTagValue(TagValueType type, String? value) {
  if (!canNameSourceShowText(type)) return null;
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

/// 노드 id → **이름 칸에 보일 문자열**. 이름 태그가 글자를 내지 못한 노드는 키가
/// 아예 없어, 소비 측이 노드 이름(파일 이름)으로 폴백한다.
///
/// [nameSources]는 앞이 높은 우선순위다. 한 노드는 이 순서로 훑어 **처음으로 글자를
/// 낸 태그**의 값을 쓴다 — 노드마다 가진 태그가 달라도 각자 맞는 출처가 뽑히고, 둘 다
/// 가지면 앞선 것이 이긴다. 썸네일 출처와 같은 얼개다([resolveThumbnailRelPaths]).
///
/// 값을 글자로 보일 수 없는 태그(label·image)를 골라 두어도 **기본과 같게 동작**하는
/// 것은 [formatTagValue]가 그런 유형에 null을 돌려주기 때문이다 — 그 규칙을 여기서
/// 다시 적지 않아 두 자리가 갈라지지 않는다.
///
/// [assignmentsByFile]은 **링크 해석이 끝난** 부여 맵이어야 한다(링크는 저장값이 노드
/// id라 그대로 보이면 뜻이 없다). 다중값 태그는 처음 값 하나만 쓴다 — 이름은 한 줄에
/// 놓이는 자리라 여럿을 이어 붙이면 되레 읽히지 않는다.
Map<int, String> buildDisplayNameIndex({
  required Map<int, List<AssignedTag>> assignmentsByFile,
  required List<int> nameSources,
}) {
  if (nameSources.isEmpty) return const {};
  final result = <int, String>{};
  for (final entry in assignmentsByFile.entries) {
    for (final tagId in nameSources) {
      String? found;
      for (final a in entry.value) {
        if (a.tagDefinitionId != tagId) continue;
        found = formatTagValue(a.definition.valueType, a.value);
        if (found != null) break;
      }
      if (found != null) {
        result[entry.key] = found;
        break;
      }
    }
  }
  return result;
}
