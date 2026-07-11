/// 태그 표시 순서(태그 정의 id의 나열)를 적용하는 순수 로직.
///
/// 순서 목록은 태그 자리를 자유롭게 정한다 — 사용자 태그와 시스템 태그를 섞어
/// 놓을 수 있다. 순서를 정하지 않았을 때의 **기본값**만 자동 파생인 시스템 태그를
/// 사용자 태그 뒤에 둔다([normalizeTagOrder]). 그 기본 순서가 저장되면 이후에는
/// 저장된 순서가 그대로 자리를 정하므로, 시스템 태그도 위로 끌어올릴 수 있다.
///
/// 순서 목록은 **부분 목록**이어도 된다 — 목록에 없는 태그는 원래 순서를 지킨 채
/// 뒤에 붙는다. 새로 만든 태그가 순서 목록에 없어도 사라지지 않게 하기 위함이다.
///
/// 한 태그를 여러 값으로 부여한 경우(다중 부여)는 칩을 묶지 않고 개별로 흩되,
/// 그 태그 안에서는 부여된 순서(부여 기록 id 오름차순)를 지킨다. 라벨 태그는
/// 따로 모으지 않고 값 태그와 똑같이 정의별 순서에 참여한다.
library;

import '../entities/assigned_tag.dart';
import '../entities/system_tag.dart';
import '../entities/tag_definition.dart';

Map<int, int> _rankOf(List<int> displayOrder) => {
  for (var i = 0; i < displayOrder.length; i++) displayOrder[i]: i,
};

/// 저장된(부분·불완전할 수 있는) 순서를 [allIds] 전체를 덮는 **완전한** 순서로
/// 보정한다. 순서에 빠진 태그는 자기 자리를 기본값으로 얻는다 — 사용자 태그는
/// 저장된 순서의 앞에, 시스템 태그는 뒤에 붙인다. 저장된 순서에 실린 태그는
/// 자리를 그대로 지키므로(섞어 놓은 것 포함), 한 번 완전해진 뒤에는 자유롭게
/// 옮길 수 있다.
///
/// 이는 "시스템 태그만 담긴 순서가 저장돼 사용자 태그가 뒤로 밀리는" 초기 저장
/// 사고를, 규칙으로 막지 않고 기본 자리로 되돌리는 방식이다.
List<int> normalizeTagOrder(List<int> allIds, List<int> stored) {
  final present = allIds.toSet();
  final kept = [
    for (final id in stored)
      if (present.contains(id)) id,
  ];
  final keptSet = kept.toSet();
  final missingUser = <int>[];
  final missingSystem = <int>[];
  for (final id in allIds) {
    if (keptSet.contains(id)) continue;
    (isSystemTagId(id) ? missingSystem : missingUser).add(id);
  }
  return [...missingUser, ...kept, ...missingSystem];
}

/// 한 파일의 부여 태그들을 표시 순서대로 정렬한다(원본은 건드리지 않는다).
List<AssignedTag> orderAssignedTags(
  List<AssignedTag> tags,
  List<int> displayOrder,
) {
  if (tags.length < 2) return tags;
  final rank = _rankOf(displayOrder);
  final unranked = displayOrder.length;
  // 순서가 같을 때 원래 자리를 지키도록(안정 정렬) 원본 인덱스를 함께 들고 비교한다.
  final indexed = [
    for (var i = 0; i < tags.length; i++) (index: i, tag: tags[i]),
  ];
  indexed.sort((a, b) {
    final ra = rank[a.tag.tagDefinitionId] ?? unranked;
    final rb = rank[b.tag.tagDefinitionId] ?? unranked;
    if (ra != rb) return ra.compareTo(rb);
    if (a.tag.tagDefinitionId == b.tag.tagDefinitionId) {
      // 같은 태그의 여러 값: 부여된 순서. 시스템 태그(합성 부여)는 id가 없어
      // 원본 순서로 떨어진다.
      final ia = a.tag.assignment.id;
      final ib = b.tag.assignment.id;
      if (ia != null && ib != null && ia != ib) return ia.compareTo(ib);
    }
    return a.index.compareTo(b.index);
  });
  return [for (final e in indexed) e.tag];
}

/// 태그 정의 목록을 표시 순서대로 정렬한다(순서 편집 UI가 현재 순서를 보일 때 쓴다).
List<TagDefinition> orderTagDefinitions(
  List<TagDefinition> definitions,
  List<int> displayOrder,
) {
  if (definitions.length < 2) return definitions;
  final rank = _rankOf(displayOrder);
  final unranked = displayOrder.length;
  final indexed = [
    for (var i = 0; i < definitions.length; i++)
      (index: i, definition: definitions[i]),
  ];
  indexed.sort((a, b) {
    final ra = rank[a.definition.id] ?? unranked;
    final rb = rank[b.definition.id] ?? unranked;
    if (ra != rb) return ra.compareTo(rb);
    return a.index.compareTo(b.index);
  });
  return [for (final e in indexed) e.definition];
}
