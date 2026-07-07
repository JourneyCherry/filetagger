import '../entities/tag_definition.dart';

/// 두 태그 정의를 하나로 합칠 수 있는지 판정한다.
///
/// 값을 같은 방식으로 해석하고(값 유형 일치) 같은 부여 규칙을 따라야(다중 부여
/// 허용 일치) 옮긴 부여 기록이 대상 태그에서 그대로 유효하다. 시스템 태그는
/// 사용자 CRUD 대상이 아니라 합칠 수 없다. 같은 정의(자기 자신)끼리는 대상이
/// 아니다. 실제 이관·정리는 저장소가 수행하고, 이 판정은 후보를 거르는 게이트다.
bool canMergeTags(TagDefinition source, TagDefinition target) {
  if (source.id == null || target.id == null) return false;
  if (source.id == target.id) return false;
  if (source.isSystem || target.isSystem) return false;
  return source.valueType == target.valueType &&
      source.allowMultiple == target.allowMultiple;
}

/// [source]를 합칠 수 있는 대상 후보만 골라 돌려준다(이름순 유지).
List<TagDefinition> mergeTargetsFor(
  TagDefinition source,
  List<TagDefinition> all,
) {
  return [
    for (final d in all)
      if (canMergeTags(source, d)) d,
  ];
}
