import 'tag_assignment.dart';
import 'tag_definition.dart';

/// 부여 기록과 그 태그 정의를 함께 묶은 조회용 값 객체.
///
/// 목록의 태그 칩, 부여/편집 다이얼로그처럼 "어떤 태그가 어떤 값으로 붙어
/// 있는지"를 한 번에 표시할 때 쓴다. 저장소가 조인해 만들어 돌려준다.
class AssignedTag {
  const AssignedTag({required this.assignment, required this.definition});

  final TagAssignment assignment;
  final TagDefinition definition;

  int get fileNodeId => assignment.fileNodeId;
  int get tagDefinitionId => assignment.tagDefinitionId;
  String? get value => assignment.value;
}
