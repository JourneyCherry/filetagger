import '../entities/assigned_tag.dart';
import '../entities/tag_assignment.dart';
import '../entities/tag_value_type.dart';

/// 링크 태그 부여의 **저장값(대상 노드 id 문자열)을 그 노드의 표시 이름으로 바꾼**
/// 부여 목록을 만든다.
///
/// 링크는 저장은 id로, 비교·필터·그룹·정렬·표시는 대상 **이름**으로 한다. 도메인
/// 질의 계층([QueryFiles]·[FileFilter]·[BuildGroupedTree])은 링크를 text처럼
/// 다루므로, 이름 해석만 여기서 미리 적용해 넘기면 그 계층을 손대지 않고 링크가
/// 이름 기준으로 동작한다. 이름 해석 함수는 소비 계층(파일 노드 인덱스를 아는
/// presentation)이 주입한다.
///
/// 대상을 찾지 못한 링크는 값을 비워(null) "값 없음"처럼 취급한다 — 사라지거나
/// 워크스페이스 밖을 가리키는 링크가 엉뚱한 버킷·조건에 걸리지 않게 한다.
Map<int, List<AssignedTag>> resolveLinkAssignments(
  Map<int, List<AssignedTag>> byFile,
  String? Function(String rawValue) nameOf,
) {
  final result = <int, List<AssignedTag>>{};
  for (final entry in byFile.entries) {
    var changed = false;
    final resolved = <AssignedTag>[];
    for (final a in entry.value) {
      if (a.definition.valueType != TagValueType.link) {
        resolved.add(a);
        continue;
      }
      changed = true;
      final raw = a.value;
      final name = (raw == null || raw.isEmpty) ? null : nameOf(raw);
      resolved.add(
        AssignedTag(
          assignment: TagAssignment(
            id: a.assignment.id,
            fileNodeId: a.assignment.fileNodeId,
            tagDefinitionId: a.assignment.tagDefinitionId,
            value: name,
          ),
          definition: a.definition,
        ),
      );
    }
    result[entry.key] = changed ? resolved : entry.value;
  }
  return result;
}
