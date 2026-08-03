/// 한 파일 노드에 태그를 부여한 기록(N:M).
///
/// [value]는 대상 태그 정의의 valueType에 따라 해석되는 문자열이며, label
/// 유형처럼 값이 없으면 null이다. 순수 도메인 표현이다.
class TagAssignment {
  const TagAssignment({
    this.id,
    required this.fileNodeId,
    required this.tagDefinitionId,
    this.value,
    this.valueUnresolved = false,
  });

  /// 저장소가 부여한 식별자. 아직 저장 전이면 null.
  final int? id;

  final int fileNodeId;

  final int tagDefinitionId;

  /// 부여된 값. label 등 값이 없으면 null.
  final String? value;

  /// 링크 값이 **대상 노드를 가리키지 못하는 상태**(미해결 링크). 참이면 [value]는
  /// 노드 id가 아니라 외부에서 받은 **원래 문자열**(상대 경로·키워드 이름)이다.
  ///
  /// 값 안에 표식을 섞지 않고 플래그로 가르는 이유는, 링크 값이 필터·정렬·그룹에서
  /// text로 비교되는 자리가 많아 표식이 그 결과로 새어 나가기 때문이다. 플래그가
  /// 따로 있으면 원문을 그대로 두고도 "이건 아직 id가 아니다"를 알 수 있어, 이름이
  /// 숫자인 키워드가 우연히 남의 노드 id로 읽히는 사고도 함께 막힌다.
  ///
  /// 쓰는 것은 가져오기(큐) 한 곳뿐이다. 사용자가 값을 고치면 늘 실제 대상을 고른
  /// 것이므로 저장소가 이 플래그를 내린다. **대상이 지워져 id가 떠 버린 경우**는
  /// 저장된 플래그가 아니라 해석 시점에 드러나므로, 읽는 쪽은
  /// [resolveLinkAssignments]가 얹어 주는 같은 플래그로 두 경우를 함께 받는다.
  final bool valueUnresolved;
}
