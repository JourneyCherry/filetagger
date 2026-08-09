/// 날짜 태그값의 **저장 표현 ↔ 표시 표현** 단일 출처(순수 변환).
///
/// 저장은 시간대에 매이지 않는 고정 값이어야 하고(같은 DB를 다른 시간대에서 열어도
/// 같은 날짜여야 한다), 표시는 그 값을 사람이 읽는 형식으로 되돌린 것이다.
///
/// 두 방향을 한자리에 두는 이유는 **읽는 쪽이 둘**이기 때문이다 — 칩·셀에 보이는
/// 글자(presentation)와 인라인 편집창의 초기 내용(domain 유즈케이스)이 같아야 하는데,
/// 각자 만들면 조용히 갈라진다. 저장 형식도 파서와 입력 위젯이 함께 써야 해 여기 있다.
library;

import 'package:intl/intl.dart';

/// 표시용 날짜 형식. 자리를 고정한 숫자 표기라 로케일에 흔들리지 않아야 하므로
/// 로케일 데이터가 필요 없는 고정 패턴을 쓴다.
final DateFormat _displayDate = DateFormat('yyyy-MM-dd');

/// 날짜 값을 저장용 ISO 문자열로(날짜만, 시각 제거).
String dateToStoredValue(DateTime date) =>
    DateTime(date.year, date.month, date.day).toIso8601String();

/// 저장된 날짜 값을 사람이 읽는 형식으로. 읽을 수 없는 값이면 null을 돌려,
/// 부르는 쪽이 저장값 원문을 그대로 보이게 한다.
String? storedDateToDisplay(String value) {
  final parsed = DateTime.tryParse(value);
  return parsed == null ? null : _displayDate.format(parsed);
}
