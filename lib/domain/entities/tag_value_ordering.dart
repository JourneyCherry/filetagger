import 'tag_value_type.dart';

/// 태그값 두 개를 유형에 맞게 비교한다(number=숫자, date=시간순, 그 외=사전순).
///
/// 두 값 모두 존재(비어있지 않음)한다고 가정한다. 값 없음(null/빈 문자열)의
/// "항상 뒤로" 처리와 정렬 방향(오름/내림)은 호출부에서 다룬다. 숫자·날짜로
/// 파싱되지 않는 값은 사전순으로 안전하게 되돌아간다.
int compareTagValues(TagValueType type, String a, String b) {
  switch (type) {
    case TagValueType.number:
      final an = num.tryParse(a);
      final bn = num.tryParse(b);
      if (an == null && bn == null) return _lexical(a, b);
      if (an == null) return 1; // 파싱 불가 값은 뒤로.
      if (bn == null) return -1;
      return an.compareTo(bn);
    case TagValueType.date:
      final ad = DateTime.tryParse(a);
      final bd = DateTime.tryParse(b);
      if (ad == null && bd == null) return _lexical(a, b);
      if (ad == null) return 1;
      if (bd == null) return -1;
      return ad.compareTo(bd);
    case TagValueType.text:
    case TagValueType.label:
    // link은 비교 시 대표값이 이미 대상 이름으로 해석돼 넘어온다(소비 계층이 주입).
    case TagValueType.link:
    // image는 존재 여부만 정렬해(대표값이 label처럼 빈 문자열/없음으로 접힘) 값끼리
    // 견주는 이 경로를 사실상 타지 않지만, 스위치 완결성을 위해 사전순으로 둔다.
    case TagValueType.image:
      return _lexical(a, b);
  }
}

int _lexical(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());
