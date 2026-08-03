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
/// **대상을 찾지 못한 링크는 버리지 않고 미해결로 표시한다**
/// ([TagAssignment.valueUnresolved]). 값을 비워 "값 없음"처럼 다루면 대상이 지워진
/// 링크가 조용히 사라진 것처럼 보여, 사용자가 재연결할지 지울지 정할 기회를 잃는다.
/// 방침은 노드의 연결 끊김과 같다 — 버리지 않고, 눈에 띄게 두고, 사용자가 정한다.
///
/// 미해결에는 두 갈래가 있고 여기서 하나로 합쳐 내보낸다:
/// - **가져온 값**(부여에 표식이 이미 붙어 있음): 값은 외부 앱이 적어 보낸 원문
///   (상대 경로·키워드 이름)이라 그대로 두어 사람이 읽고 필터에도 걸린다.
/// - **떠 버린 id**(대상이 지워짐): 값은 사람에게 뜻이 없는 노드 id라 비운다 —
///   날 id를 UI에 내보이지 않는다는 원칙 그대로다.
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
      final String? value;
      final bool unresolved;
      if (a.valueUnresolved) {
        // 이미 미해결로 들어온 값 — 원문을 그대로 들고 간다.
        value = raw;
        unresolved = true;
      } else if (raw == null || raw.isEmpty) {
        // 값이 아예 없는 부여다(미해결이 아니라 "값 없음").
        value = null;
        unresolved = false;
      } else {
        final name = nameOf(raw);
        value = name;
        unresolved = name == null;
      }
      resolved.add(
        AssignedTag(
          assignment: TagAssignment(
            id: a.assignment.id,
            fileNodeId: a.assignment.fileNodeId,
            tagDefinitionId: a.assignment.tagDefinitionId,
            value: value,
            valueUnresolved: unresolved,
          ),
          definition: a.definition,
        ),
      );
    }
    result[entry.key] = changed ? resolved : entry.value;
  }
  return result;
}
