import 'package:drift/drift.dart';

import '../../domain/entities/tag_value_type.dart';

/// 태그의 종류(이름·값 유형·색상). 라벨/키-값 태그를 [valueType] 하나로
/// 통합 표현한다.
///
/// 생성되는 row 클래스는 도메인 엔티티와 이름이 겹치지 않도록 `Row` 접미사를
/// 붙인다(도메인은 순수 엔티티 이름을 그대로 쓴다).
@DataClassName('TagDefinitionRow')
class TagDefinitions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 사용자에게 보이는 태그 이름. 중복 정의를 막는다.
  TextColumn get name => text().unique()();

  /// 값 해석 방식. 이름 기반으로 저장해 enum 순서 변경에 영향받지 않는다.
  TextColumn get valueType => textEnum<TagValueType>()();

  /// 표시용 색상(ARGB). 미지정 가능.
  IntColumn get color => integer().nullable()();

  /// 한 파일에 이 태그를 여러 번 부여할 수 있는지. 태그 생성 시 사용자가 정한다.
  /// 불가면 (파일,태그)당 1회로 재부여 시 값이 갱신되고, 허용이면 다중 부여를
  /// 허용한다. 유형에 따라 달라 DB 유니크 인덱스로 못 걸어 저장소가 강제한다.
  BoolColumn get allowMultiple => boolean().withDefault(const Constant(false))();
}

/// 스캔된 파일/폴더의 인덱스. 경로 외에 이동 추적용 메타(크기·수정시각·
/// 부분 해시)를 함께 보관한다.
@DataClassName('FileNodeRow')
class FileNodes extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 관리 폴더 루트 기준 경로. 같은 노드를 한 번만 인덱싱한다.
  TextColumn get path => text().unique()();

  BoolColumn get isDirectory => boolean()();

  /// 파일 크기. 폴더 등 의미 없는 경우 미지정.
  IntColumn get size => integer().nullable()();

  DateTimeColumn get modifiedAt => dateTime().nullable()();

  /// 이동 추적 시 동일 파일 후보를 가리기 위한 내용 부분 해시.
  TextColumn get contentHashPrefix => text().nullable()();

  /// 마지막 스캔에서 관측된 시각. 삭제 감지/정리에 쓰인다.
  DateTimeColumn get lastSeenAt => dateTime()();
}

/// 파일 노드에 태그를 부여한 기록(N:M). 값은 [TagDefinitions.valueType]에
/// 따라 해석되는 문자열로 저장한다.
@DataClassName('TagAssignmentRow')
class TagAssignments extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get fileNodeId =>
      integer().references(FileNodes, #id, onDelete: KeyAction.cascade)();

  IntColumn get tagDefinitionId =>
      integer().references(TagDefinitions, #id, onDelete: KeyAction.cascade)();

  /// 부여된 값. label 유형 등 값이 없으면 미지정.
  TextColumn get value => text().nullable()();
}
