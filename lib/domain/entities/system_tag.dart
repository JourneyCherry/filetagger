import 'assigned_tag.dart';
import 'file_node.dart';
import 'tag_assignment.dart';
import 'tag_definition.dart';
import 'tag_value_type.dart';

/// OS/파일 자체에서 파생되는 자동 태그의 카탈로그.
///
/// 사용자 정의 태그와 달리 DB에 저장되지 않고 [FileNode]에서 **계산**으로만
/// 존재한다. 값은 항상 계산되어 필터/정렬에 참여하고, 표시 여부만 워크스페이스
/// 보기 설정으로 토글한다. 태그 시스템 전체가 `int` 식별자와 [AssignedTag]로
/// 태그를 소비하므로, 시스템 태그는 **안정적인 음수 id**를 가진 합성 태그로 만들어
/// 필터/정렬/표시에 그대로 녹아들게 한다.
///
/// [id]는 저장·직렬화(필터·정렬 참조)에 쓰이므로 값을 바꾸지 않는다.
enum SystemTag {
  /// 파일 크기(바이트). 폴더는 값 없음.
  fileSize(id: -1, displayName: '크기', valueType: TagValueType.number),

  /// 마지막 수정 시각.
  modifiedTime(id: -2, displayName: '수정 시각', valueType: TagValueType.date),

  /// 파일 확장자(점 제외, 소문자). 폴더·확장자 없는 파일은 값 없음.
  extension(id: -3, displayName: '확장자', valueType: TagValueType.text),

  /// 이미지 픽셀 크기("가로x세로"). 이미지가 아니면 값 없음.
  imageDimensions(id: -4, displayName: '이미지 크기', valueType: TagValueType.text),

  /// 파일/폴더 이름. **수정 가능** — 값 편집 시 디스크에서 실제 rename된다.
  fileName(
    id: -5,
    displayName: '파일 이름',
    valueType: TagValueType.text,
    editable: true,
  );

  const SystemTag({
    required this.id,
    required this.displayName,
    required this.valueType,
    this.editable = false,
  });

  /// 안정적 음수 식별자(저장·직렬화용).
  final int id;

  /// 사용자에게 보이는 태그 이름.
  final String displayName;

  final TagValueType valueType;

  /// 값 편집이 원본(파일명 등)에 반영되어 실제로 바뀌는지. false면 읽기 전용.
  final bool editable;

  /// 이 시스템 태그의 표시용 정의(항상 회색·시스템 소유).
  TagDefinition get definition => TagDefinition(
    id: id,
    name: displayName,
    valueType: valueType,
    isSystem: true,
  );

  /// [node]에 대한 이 시스템 태그의 값. 해당 노드에 의미가 없으면(폴더의 크기 등)
  /// null을 돌려 "그 노드엔 이 시스템 태그가 없음"을 나타낸다.
  String? valueFor(FileNode node) {
    switch (this) {
      case SystemTag.fileSize:
        final size = node.size;
        return (node.isDirectory || size == null) ? null : size.toString();
      case SystemTag.modifiedTime:
        return node.modifiedAt?.toIso8601String();
      case SystemTag.extension:
        return node.isDirectory ? null : _extensionOf(node.name);
      case SystemTag.imageDimensions:
        return node.imageDimensions;
      case SystemTag.fileName:
        return node.name;
    }
  }
}

/// 파일 이름에서 확장자(점 제외, 소문자)를 뽑는다. 점이 없거나 끝이 점이면 null.
/// 선두 점만 있는 이름(예: `.gitignore`)은 확장자로 보지 않는다.
String? _extensionOf(String name) {
  final dot = name.lastIndexOf('.');
  if (dot <= 0 || dot == name.length - 1) return null;
  return name.substring(dot + 1).toLowerCase();
}

/// 식별자가 시스템 태그의 것(음수)인지.
bool isSystemTagId(int id) => id < 0;

/// 이 부여를 칩에서 눌러 값을 편집할 수 있는지. 시스템 태그는 수정 가능한 것
/// (파일 이름)만, 사용자 태그는 값을 갖는 것만 편집 가능하다.
bool isEditableAssignment(AssignedTag tag) {
  if (isSystemTagId(tag.tagDefinitionId)) {
    return systemTagById(tag.tagDefinitionId)?.editable ?? false;
  }
  return tag.definition.hasValue;
}

/// 식별자로 시스템 태그를 찾는다. 없으면 null.
SystemTag? systemTagById(int id) {
  for (final t in SystemTag.values) {
    if (t.id == id) return t;
  }
  return null;
}

/// 모든 시스템 태그의 표시용 정의 목록(선택기·정의맵 병합용).
final List<TagDefinition> systemTagDefinitions = [
  for (final t in SystemTag.values) t.definition,
];

/// [node]가 가지는 시스템 태그의 부여 기록(값 있는 것만). 실제 존재하는 저장된
/// 노드에만 붙인다 — 연결 끊김(미싱) 노드와 아직 저장 전(id 없음) 노드는 제외한다.
/// 합성 부여이므로 [TagAssignment.id]는 null이다.
List<AssignedTag> systemAssignmentsFor(FileNode node) {
  final nodeId = node.id;
  if (nodeId == null || node.isMissing) return const [];
  final result = <AssignedTag>[];
  for (final t in SystemTag.values) {
    final value = t.valueFor(node);
    if (value == null) continue;
    result.add(
      AssignedTag(
        assignment: TagAssignment(
          fileNodeId: nodeId,
          tagDefinitionId: t.id,
          value: value,
        ),
        definition: t.definition,
      ),
    );
  }
  return result;
}
