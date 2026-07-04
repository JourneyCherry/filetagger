import '../entities/assigned_tag.dart';
import '../entities/tag_definition.dart';
import '../entities/tag_value_type.dart';

/// 태그 정의와 부여 기록의 저장소. 구현(Drift)은 data 계층에 격리한다.
///
/// 다중 부여 허용 여부는 태그 정의별 플래그라 DB 유니크 인덱스로 걸 수 없어,
/// 부여 시점에 이 저장소가 정의의 [TagDefinition.allowMultiple]를 보고
/// upsert(1회 제한)와 insert(다중 허용)를 가른다.
abstract interface class TagRepository {
  // ── 태그 정의 ──

  /// 전체 태그 정의를 이름순으로 스트림한다.
  Stream<List<TagDefinition>> watchDefinitions();

  /// 새 태그 정의를 만들고 식별자가 채워진 정의를 돌려준다.
  Future<TagDefinition> createDefinition({
    required String name,
    required TagValueType valueType,
    int? color,
    required bool allowMultiple,
  });

  /// 기존 태그 정의를 갱신한다(id 필수).
  Future<void> updateDefinition(TagDefinition definition);

  /// 태그 정의를 삭제한다. 관련 부여 기록은 FK cascade로 함께 정리된다.
  Future<void> deleteDefinition(int id);

  // ── 태그 부여 ──

  /// 전체 부여 기록을 정의와 조인해 스트림한다(목록 칩·다이얼로그 구독용).
  Stream<List<AssignedTag>> watchAssignments();

  /// 여러 파일에 한 태그를 일괄 부여한다. 정의가 다중 부여를 허용하지 않으면
  /// 파일별로 upsert(기존 값 갱신), 허용하면 새 기록을 추가한다.
  Future<void> assignToFiles({
    required List<int> fileNodeIds,
    required int tagDefinitionId,
    String? value,
  });

  /// 특정 부여 기록의 값을 수정한다.
  Future<void> updateAssignmentValue({
    required int assignmentId,
    String? value,
  });

  /// 특정 부여 기록 하나를 해제한다.
  Future<void> unassign(int assignmentId);

  /// 여러 파일에서 한 태그의 부여를 모두 해제한다.
  Future<void> unassignFromFiles({
    required List<int> fileNodeIds,
    required int tagDefinitionId,
  });
}
