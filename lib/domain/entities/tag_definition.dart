import 'tag_value_type.dart';

/// 태그의 종류. 이름·값 유형·표시색·다중 부여 허용 여부를 갖는다.
///
/// label은 값이 없는 분류용이고, text/number/date는 [valueType]에 따라 값을
/// 해석하는 키-값 태그다. 저장 계층(Drift row)과 독립된 순수 도메인 표현이다.
class TagDefinition {
  const TagDefinition({
    this.id,
    required this.name,
    required this.valueType,
    this.color,
    this.allowMultiple = false,
    this.isSystem = false,
  });

  /// 저장소가 부여한 식별자. 아직 저장 전이면 null.
  final int? id;

  /// 사용자에게 보이는 태그 이름(정의 간 중복 불가).
  final String name;

  final TagValueType valueType;

  /// 표시용 색상(ARGB). 미지정이면 null.
  final int? color;

  /// 한 파일에 이 태그를 여러 번 부여할 수 있는지.
  final bool allowMultiple;

  /// 시스템이 소유하는 태그(OS/파일에서 파생)인지. true면 사용자 CRUD 대상이
  /// 아니고 회색으로 고정 표시되며 제거할 수 없다. 사용자 정의 태그는 false.
  final bool isSystem;

  /// label은 부착 여부만 갖고 값 입력이 없다. 나머지는 값을 갖는다.
  bool get hasValue => valueType != TagValueType.label;

  TagDefinition copyWith({
    int? id,
    String? name,
    TagValueType? valueType,
    int? color,
    bool clearColor = false,
    bool? allowMultiple,
    bool? isSystem,
  }) {
    return TagDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      valueType: valueType ?? this.valueType,
      color: clearColor ? null : (color ?? this.color),
      allowMultiple: allowMultiple ?? this.allowMultiple,
      isSystem: isSystem ?? this.isSystem,
    );
  }
}
