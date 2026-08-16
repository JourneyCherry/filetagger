import 'tag_value_type.dart';

/// 정렬·비교를 위해 태그값을 유형에 맞게 **미리 해석해 둔 것**.
///
/// 순서 규칙(number=숫자, date=시간순, 그 외=사전순)의 단일 출처다. 같은 값을 여러
/// 번 견주는 자리 — 정렬은 한 노드를 log n 번 비교하고, 필터는 한 피연산자를 노드마다
/// 다시 견준다 — 에서 파싱과 소문자화를 비교마다 되풀이하지 않도록, 값마다 한 번
/// 만들어 두고 [compareTo]로 견준다.
///
/// 숫자·날짜로 읽히지 않는 값은 사전순으로 안전하게 되돌아가되, 읽힌 값보다 뒤에
/// 놓인다. 값 없음(null/빈 문자열)의 "항상 뒤로" 처리와 정렬 방향(오름/내림)은
/// 호출부가 다룬다.
class TagValueKey implements Comparable<TagValueKey> {
  TagValueKey(this.type, this.value)
    : _number = type == TagValueType.number ? num.tryParse(value) : null,
      _date = type == TagValueType.date ? DateTime.tryParse(value) : null;

  final TagValueType type;

  /// 해석 전 원본 값.
  final String value;

  final num? _number;
  final DateTime? _date;

  /// 사전순 비교에 쓰는 소문자 값. 숫자·날짜로 읽힌 값끼리는 쓰이지 않으므로
  /// 필요해질 때만 만든다.
  late final String lowerValue = value.toLowerCase();

  /// 같은 유형의 다른 값과의 순서. 유형이 다른 키끼리 견주지 않는다.
  @override
  int compareTo(TagValueKey other) {
    switch (type) {
      case TagValueType.number:
        return _compareParsed<num>(_number, other._number, other);
      case TagValueType.date:
        return _compareParsed<DateTime>(_date, other._date, other);
      case TagValueType.text:
      case TagValueType.label:
      // link은 비교 시 대표값이 이미 대상 이름으로 해석돼 넘어온다(소비 계층이 주입).
      case TagValueType.link:
      // image는 존재 여부만 정렬해(대표값이 label처럼 빈 문자열/없음으로 접힘) 값끼리
      // 견주는 이 경로를 사실상 타지 않지만, 스위치 완결성을 위해 사전순으로 둔다.
      case TagValueType.image:
        return lowerValue.compareTo(other.lowerValue);
    }
  }

  /// 유형에 맞게 읽힌 값끼리의 비교. 한쪽만 읽히지 않았으면 그쪽을 뒤로 밀고,
  /// 둘 다 읽히지 않았으면 사전순으로 되돌아간다.
  int _compareParsed<C extends Comparable<C>>(C? a, C? b, TagValueKey other) {
    if (a == null && b == null) return lowerValue.compareTo(other.lowerValue);
    if (a == null) return 1; // 파싱 불가 값은 뒤로.
    if (b == null) return -1;
    return a.compareTo(b);
  }
}

/// 무작위 정렬에서 값 하나가 갖는 자리.
///
/// 씨앗과 값에서만 나오는 **순수 함수**다. 그래서 (1) 같은 씨앗이면 목록을 다시
/// 세워도 같은 순서가 나오고 — 값을 만나는 차례에 따라 자리를 나눠 주면 재스캔·태그
/// 수정 때마다 화면이 흐트러진다 —, (2) 같은 값이면 자리도 같아 무작위 단계에서도
/// 동률이 성립한다(그래서 다음 정렬 단계로 넘어간다).
///
/// 사전순 비교와 같은 [TagValueKey.lowerValue]에서 뽑아, 대소문자만 다른 값이
/// 오름차순에서 동률이던 것이 여기서도 동률로 남는다.
int randomOrderRank(int seed, TagValueKey key) =>
    Object.hash(seed, key.lowerValue);

/// 태그값 두 개를 유형에 맞게 비교한다([TagValueKey]의 규칙 그대로).
///
/// 두 값 모두 존재(비어있지 않음)한다고 가정한다. 한 값을 여러 번 견주는 자리라면
/// [TagValueKey]를 직접 만들어 재사용하는 편이 낫다(파싱이 한 번으로 준다).
int compareTagValues(TagValueType type, String a, String b) =>
    TagValueKey(type, a).compareTo(TagValueKey(type, b));
