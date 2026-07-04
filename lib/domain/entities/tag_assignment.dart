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
  });

  /// 저장소가 부여한 식별자. 아직 저장 전이면 null.
  final int? id;

  final int fileNodeId;

  final int tagDefinitionId;

  /// 부여된 값. label 등 값이 없으면 null.
  final String? value;
}
