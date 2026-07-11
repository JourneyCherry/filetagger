/// 태그값의 저장 표현을 만드는 순수 변환. 표시용 포맷(사람이 읽는 문자열)은
/// presentation의 `tag_visuals`가 담당하고, 여기엔 **저장 형식의 단일 출처**만 둔다.
///
/// domain(파서·유즈케이스)과 presentation(입력 위젯)이 같은 저장 형식을 써야 하므로
/// domain에 두고 presentation이 다시 내보낸다.
library;

/// 날짜 값을 저장용 ISO 문자열로(날짜만, 시각 제거).
String dateToStoredValue(DateTime date) =>
    DateTime(date.year, date.month, date.day).toIso8601String();
