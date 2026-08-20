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
/// [id]는 저장·직렬화(필터·정렬 참조)에 쓰이므로 값을 바꾸지 않는다. **없앤 태그의
/// id도 다시 쓰지 않는다** — 저장된 필터·정렬·프리셋이 그 id를 여전히 가리킬 수 있어,
/// 재사용하면 옛 참조가 엉뚱한 태그로 되살아난다. 사라진 id를 가리키는 참조는 불러올
/// 때 걸러진다.
///
/// 쓰였다가 없앤 id: -4(이미지 크기 — 가로·세로를 한 문자열에 합쳐 담던 태그로,
/// [imageWidth]·[imageHeight]로 갈라졌다).
enum SystemTag {
  /// 파일 크기(바이트). 폴더는 값 없음.
  fileSize(id: -1, displayName: '크기', valueType: TagValueType.number),

  /// 마지막 수정 시각.
  modifiedTime(id: -2, displayName: '수정 시각', valueType: TagValueType.date),

  /// 파일 확장자(점 제외, 소문자). 폴더·확장자 없는 파일은 값 없음.
  extension(id: -3, displayName: '확장자', valueType: TagValueType.text),

  /// 이미지의 가로 픽셀 수. 이미지가 아니거나 크기를 못 읽으면 값 없음.
  ///
  /// [imageHeight]와 **따로 서는 것이 요점**이다 — 합쳐 두면 글자로 비교되어 크기순
  /// 정렬도, "너비가 얼마 이상" 같은 조건도 설 수 없다.
  imageWidth(id: -9, displayName: '이미지 너비', valueType: TagValueType.number),

  /// 이미지의 세로 픽셀 수. 붙는 조건은 [imageWidth]와 같다(둘은 늘 함께 붙거나
  /// 함께 없다).
  imageHeight(id: -10, displayName: '이미지 높이', valueType: TagValueType.number),

  /// 노드 이름. **수정 가능** — 디스크 노드는 값 편집 시 실제 rename되고, 키워드는
  /// 디스크에 실체가 없어 저장된 이름만 바뀐다.
  fileName(
    id: -5,
    displayName: '파일 이름',
    valueType: TagValueType.text,
    editable: true,
  ),

  /// 폴더가 직속으로 담은 파일 수. **폴더에만 붙으므로 디렉토리 표식을 겸한다** —
  /// 파일·키워드는 값 없음이라 '있음'으로 폴더만, '제외'로 파일만 걸러낼 수 있다.
  /// 빈 폴더도 0을 값으로 가져(값 없음이 아니다) 그 갈래가 수량과 무관하게 선다.
  childFileCount(
    id: -6,
    displayName: '내부 파일 수량',
    valueType: TagValueType.number,
  ),

  /// 키워드 표식(label). 디스크에 실체가 없는 노드에만 붙는다. [childFileCount]가
  /// 폴더에 대해 그러하듯 노드 종류를 가르는 층위이며, '제외'로 키워드를 목록에서
  /// 감추는 것이 이 태그의 주 용도다.
  keyword(id: -7, displayName: '키워드', valueType: TagValueType.label),

  /// 미해결 링크 표식(label). 대상을 가리키지 못하는 링크 태그를 **하나라도** 가진
  /// 노드에 붙는다. 다른 시스템 태그와 달리 노드 자신이 아니라 그 노드의 **부여
  /// 목록**에서 나오며, 사라진 대상을 찾아 재연결하거나 지우는 자리를 찾는 수단이다.
  unresolvedLink(id: -8, displayName: '미해결 링크', valueType: TagValueType.label);

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

  /// 이 시스템 태그의 표시용 정의(항상 회색·시스템 소유). 노드마다 되풀이해 묻는
  /// 자리라([systemAssignmentsFor]) 태그당 한 벌만 만들어 나눠 쓴다.
  TagDefinition get definition => _definitionsByTag[this]!;

  /// [node]에 대한 이 시스템 태그의 값. 해당 노드에 의미가 없으면(폴더의 크기 등)
  /// null을 돌려 "그 노드엔 이 시스템 태그가 없음"을 나타낸다.
  ///
  /// [assignments]는 그 노드에 붙은 부여 목록으로, **노드만 봐서는 알 수 없는**
  /// 시스템 태그([unresolvedLink])가 쓴다. 링크 해석이 끝난 목록을 넘겨야 한다
  /// ([resolveLinkAssignments]) — 떠 버린 id는 해석 시점에야 드러나기 때문이다.
  String? valueFor(FileNode node, {List<AssignedTag> assignments = const []}) {
    switch (this) {
      case SystemTag.fileSize:
        final size = node.size;
        return (!node.isFile || size == null) ? null : size.toString();
      case SystemTag.modifiedTime:
        return node.modifiedAt?.toIso8601String();
      case SystemTag.extension:
        // 파일 이름에서만 뽑는다. 키워드 이름이 확장자처럼 끝나도(예: 그림.png)
        // 파일이 아니므로 확장자를 갖지 않는다.
        return node.isFile ? _extensionOf(node.name) : null;
      case SystemTag.imageWidth:
        return node.imageWidth?.toString();
      case SystemTag.imageHeight:
        return node.imageHeight?.toString();
      case SystemTag.fileName:
        return node.name;
      case SystemTag.childFileCount:
        if (!node.isDirectory) return null;
        // 스캔 전(컬럼 신설 직후 등)이라 수량을 모르는 폴더도 값을 비우지 않는다 —
        // 비우면 '있음'으로 폴더만 거르던 필터에서 그 폴더들만 조용히 빠진다.
        // 다음 스캔이 실제 수량으로 덮는다.
        return (node.childFileCount ?? 0).toString();
      case SystemTag.keyword:
        return node.isKeyword ? '' : null;
      case SystemTag.unresolvedLink:
        return assignments.any((a) => a.valueUnresolved) ? '' : null;
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

/// 시스템 태그 → 그 표시용 정의. [SystemTag.definition]이 나눠 쓴다.
final Map<SystemTag, TagDefinition> _definitionsByTag = {
  for (final t in SystemTag.values)
    t: TagDefinition(
      id: t.id,
      name: t.displayName,
      valueType: t.valueType,
      isSystem: true,
    ),
};

/// 식별자 → 시스템 태그. [systemTagById]가 나눠 쓴다.
final Map<int, SystemTag> _tagsById = {
  for (final t in SystemTag.values) t.id: t,
};

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
SystemTag? systemTagById(int id) => _tagsById[id];

/// 모든 시스템 태그의 표시용 정의 목록(선택기·정의맵 병합용).
final List<TagDefinition> systemTagDefinitions = [
  for (final t in SystemTag.values) t.definition,
];

/// [node]가 가지는 시스템 태그의 부여 기록(값 있는 것만). 실제 존재하는 저장된
/// 노드에만 붙인다 — 연결 끊김(미싱) 노드와 아직 저장 전(id 없음) 노드는 제외한다.
/// 합성 부여이므로 [TagAssignment.id]는 null이다.
///
/// [assignments]는 그 노드의 **사용자 태그 부여 목록**이다. 시스템 태그 대부분은
/// 노드 하나만 보고 계산되지만 [SystemTag.unresolvedLink]는 부여를 봐야 알 수 있어,
/// 계산 경로가 여기까지 넓다. 넘기지 않으면 그런 태그는 붙지 않는다.
List<AssignedTag> systemAssignmentsFor(
  FileNode node, {
  List<AssignedTag> assignments = const [],
}) {
  final nodeId = node.id;
  if (nodeId == null || node.isMissing) return const [];
  final result = <AssignedTag>[];
  for (final t in SystemTag.values) {
    final value = t.valueFor(node, assignments: assignments);
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
