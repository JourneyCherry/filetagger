import 'package:filetagger/domain/entities/assigned_tag.dart';
import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/node_kind.dart';
import 'package:filetagger/domain/entities/system_tag.dart';
import 'package:filetagger/domain/entities/tag_assignment.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:flutter_test/flutter_test.dart';

FileNode _file({
  int? id = 1,
  String path = 'a/photo.png',
  int? size = 100,
  DateTime? modifiedAt,
  int? imageWidth,
  int? imageHeight,
  DateTime? missingSince,
}) => FileNode(
  id: id,
  path: path,
  kind: NodeKind.file,
  size: size,
  modifiedAt: modifiedAt ?? DateTime(2024, 1, 2, 3, 4, 5),
  imageWidth: imageWidth,
  imageHeight: imageHeight,
  missingSince: missingSince,
);

/// 표시용 정의는 화면 계층이 짓는다(이름이 표시 언어를 타기 때문). 이 테스트는 값
/// 계산과 id·유형만 보므로 이름 자리에 열거 이름을 넣어 한 벌 만들어 쓴다.
final _defs = {
  for (final t in SystemTag.values)
    t: TagDefinition(
      id: t.id,
      name: t.name,
      valueType: t.valueType,
      isSystem: true,
    ),
};

List<AssignedTag> _systemTags(
  FileNode node, {
  List<AssignedTag> assignments = const [],
}) => systemAssignmentsFor(node, definitions: _defs, assignments: assignments);

void main() {
  test('시스템 태그 id는 안정적인 음수이며 서로 겹치지 않는다', () {
    final ids = SystemTag.values.map((t) => t.id).toList();
    expect(ids.every(isSystemTagId), isTrue);
    expect(ids.toSet(), hasLength(ids.length));
    // 저장·직렬화에 쓰이므로 특정 값이 바뀌지 않아야 한다.
    expect(SystemTag.fileSize.id, -1);
    expect(SystemTag.fileName.id, -5);
    expect(SystemTag.childFileCount.id, -6);
    expect(systemTagById(-5), SystemTag.fileName);
    expect(systemTagById(999), isNull);
  });

  test('없앤 시스템 태그의 id는 되쓰이지 않는다', () {
    // 저장된 필터·정렬·프리셋이 옛 id를 여전히 가리킬 수 있어, 되쓰면 그 참조가
    // 엉뚱한 태그로 되살아난다(사라진 id를 가리키는 참조는 불러올 때 걸러진다).
    const retired = {-4}; // 합쳐 담던 '이미지 크기'
    expect(
      SystemTag.values.map((t) => t.id).toSet().intersection(retired),
      isEmpty,
    );
    for (final id in retired) {
      expect(systemTagById(id), isNull);
    }
  });

  test('valueFor: 파일의 크기·수정시각·확장자·이미지 너비·높이·이름을 계산한다', () {
    final node = _file(
      path: 'a/photo.PNG',
      size: 100,
      modifiedAt: DateTime(2024, 5, 6, 7, 8, 9),
      imageWidth: 4,
      imageHeight: 2,
    );
    expect(SystemTag.fileSize.valueFor(node), '100');
    expect(
      SystemTag.modifiedTime.valueFor(node),
      DateTime(2024, 5, 6, 7, 8, 9).toIso8601String(),
    );
    expect(SystemTag.extension.valueFor(node), 'png'); // 소문자로 정규화
    // 너비·높이가 서로 바뀌지 않도록 표본을 정사각형이 아닌 것으로 둔다.
    expect(SystemTag.imageWidth.valueFor(node), '4');
    expect(SystemTag.imageHeight.valueFor(node), '2');
    expect(SystemTag.fileName.valueFor(node), 'photo.PNG');
    expect(SystemTag.childFileCount.valueFor(node), isNull); // 파일은 폴더가 아니다
  });

  test('valueFor: 확장자 없는 이름·선두 점 이름은 확장자가 없다', () {
    expect(SystemTag.extension.valueFor(_file(path: 'README')), isNull);
    expect(SystemTag.extension.valueFor(_file(path: '.gitignore')), isNull);
  });

  test('valueFor: 폴더는 크기·확장자·이미지 크기가 없고 수정시각·이름·수량을 갖는다', () {
    final dir = FileNode(
      id: 2,
      path: 'a/sub',
      kind: NodeKind.directory,
      modifiedAt: DateTime(2024, 1, 1),
      childFileCount: 3,
    );
    expect(SystemTag.fileSize.valueFor(dir), isNull);
    expect(SystemTag.extension.valueFor(dir), isNull);
    expect(SystemTag.imageWidth.valueFor(dir), isNull);
    expect(SystemTag.imageHeight.valueFor(dir), isNull);
    expect(SystemTag.modifiedTime.valueFor(dir), isNotNull);
    expect(SystemTag.fileName.valueFor(dir), 'sub');
    expect(SystemTag.childFileCount.valueFor(dir), '3');
  });

  test('valueFor: 빈 폴더와 수량 모르는 폴더도 값이 비지 않는다(폴더 표식 겸용)', () {
    // 값이 비면 "있음"으로 폴더만 거르던 필터에서 그 폴더들만 조용히 빠진다.
    const empty = FileNode(
      id: 2,
      path: 'a/empty',
      kind: NodeKind.directory,
      childFileCount: 0,
    );
    const unscanned = FileNode(id: 3, path: 'a/old', kind: NodeKind.directory);
    expect(SystemTag.childFileCount.valueFor(empty), '0');
    expect(SystemTag.childFileCount.valueFor(unscanned), '0');
  });

  test('systemAssignmentsFor: 수량 태그는 폴더에만 붙어 파일과 구분된다', () {
    final dir = FileNode(
      id: 3,
      path: 'a/sub',
      kind: NodeKind.directory,
      modifiedAt: DateTime(2024, 1, 1),
    );
    final dirTags = _systemTags(dir).map((t) => t.tagDefinitionId);
    expect(dirTags, contains(SystemTag.childFileCount.id));
    final fileTags = _systemTags(
      _file(path: 'a/README'),
    ).map((t) => t.tagDefinitionId);
    expect(fileTags, isNot(contains(SystemTag.childFileCount.id)));
  });

  test('systemAssignmentsFor: 값 있는 시스템 태그만 부여로 묶고 null은 건너뛴다', () {
    final node = _file(
      path: 'a/photo.png',
      imageWidth: 4,
      imageHeight: 2,
    ); // 이미지 파일 → 폴더 전용 태그만 빼고 전부
    final tags = _systemTags(node);
    expect(tags.map((t) => t.tagDefinitionId).toSet(), {
      // 노드 종류를 가르는 태그(내부 파일 수량·키워드)는 파일에 붙지 않고, 미해결
      // 링크는 부여 목록에서 나오는 태그라 부여를 넘기지 않으면 붙지 않는다.
      for (final t in SystemTag.values)
        if (t != SystemTag.childFileCount &&
            t != SystemTag.keyword &&
            t != SystemTag.unresolvedLink)
          t.id,
    });
    // 합성 부여이므로 assignment.id는 없다.
    expect(tags.every((t) => t.assignment.id == null), isTrue);
    expect(tags.every((t) => t.definition.isSystem), isTrue);

    // 이미지가 아니고 확장자도 없는 파일 → 크기·수정시각·이름만.
    final plain = _systemTags(_file(path: 'a/README'));
    expect(plain.map((t) => t.tagDefinitionId).toSet(), {
      SystemTag.fileSize.id,
      SystemTag.modifiedTime.id,
      SystemTag.fileName.id,
    });
  });

  test('valueFor: 키워드는 키워드 표식과 이름만 갖고 파일 메타는 없다', () {
    // 이름이 확장자처럼 끝나도 파일이 아니므로 확장자를 갖지 않는다 —
    // "폴더가 아님"을 파일로 읽던 자리가 키워드를 파일로 오인하지 않게 하는 지점.
    const memo = FileNode(id: 4, path: '그림.png', kind: NodeKind.keyword);
    expect(SystemTag.keyword.valueFor(memo), isNotNull);
    expect(SystemTag.fileName.valueFor(memo), '그림.png');
    expect(SystemTag.extension.valueFor(memo), isNull);
    expect(SystemTag.fileSize.valueFor(memo), isNull);
    expect(SystemTag.imageWidth.valueFor(memo), isNull);
    expect(SystemTag.imageHeight.valueFor(memo), isNull);
    expect(SystemTag.modifiedTime.valueFor(memo), isNull);
    expect(SystemTag.childFileCount.valueFor(memo), isNull);
  });

  test('valueFor: 키워드 표식은 파일·폴더에 붙지 않는다', () {
    expect(SystemTag.keyword.valueFor(_file()), isNull);
    expect(
      SystemTag.keyword.valueFor(
        const FileNode(id: 5, path: 'a/sub', kind: NodeKind.directory),
      ),
      isNull,
    );
  });

  group('미해결 링크 표식', () {
    AssignedTag link(String? value, {bool unresolved = false}) => AssignedTag(
      assignment: TagAssignment(
        fileNodeId: 1,
        tagDefinitionId: 9,
        value: value,
        valueUnresolved: unresolved,
      ),
      definition: const TagDefinition(
        id: 9,
        name: '작가',
        valueType: TagValueType.link,
      ),
    );

    test('부여를 넘겨야 계산된다 — 노드만 봐서는 알 수 없다', () {
      // 다른 시스템 태그와 달리 노드가 아니라 부여 목록에서 나온다.
      expect(SystemTag.unresolvedLink.valueFor(_file()), isNull);
      expect(
        SystemTag.unresolvedLink.valueFor(
          _file(),
          assignments: [link('12', unresolved: true)],
        ),
        isNotNull,
      );
    });

    test('해결된 링크만 있으면 붙지 않는다', () {
      final tags = _systemTags(_file(), assignments: [link('12')]);
      expect(
        tags.map((t) => t.tagDefinitionId),
        isNot(contains(SystemTag.unresolvedLink.id)),
      );
    });

    test('미해결이 하나라도 있으면 노드에 붙는다', () {
      final tags = _systemTags(
        _file(),
        assignments: [link('12'), link('작가/홍길동', unresolved: true)],
      );
      expect(
        tags.map((t) => t.tagDefinitionId),
        contains(SystemTag.unresolvedLink.id),
      );
    });
  });

  test('systemAssignmentsFor: 미싱 노드와 저장 전(id 없음) 노드는 제외', () {
    expect(_systemTags(_file(missingSince: DateTime(2024))), isEmpty);
    expect(_systemTags(_file(id: null)), isEmpty);
  });

  test('isEditableAssignment: 파일 이름만 편집 가능, 나머지 시스템 태그는 불가', () {
    final tags = {
      for (final t in _systemTags(_file(imageWidth: 4, imageHeight: 2)))
        t.tagDefinitionId: t,
    };
    expect(isEditableAssignment(tags[SystemTag.fileName.id]!), isTrue);
    expect(isEditableAssignment(tags[SystemTag.fileSize.id]!), isFalse);
    expect(isEditableAssignment(tags[SystemTag.imageWidth.id]!), isFalse);
    expect(isEditableAssignment(tags[SystemTag.imageHeight.id]!), isFalse);
  });

  test('시스템 태그 정의는 회색용(isSystem)·색 미지정이다', () {
    for (final t in SystemTag.values) {
      expect(_defs[t]!.isSystem, isTrue);
      expect(_defs[t]!.color, isNull);
      expect(_defs[t]!.id, t.id);
    }
    expect(SystemTag.fileSize.valueType, TagValueType.number);
    expect(SystemTag.modifiedTime.valueType, TagValueType.date);
    // 숫자여야 대소 비교·크기순 정렬이 글자 비교로 무너지지 않는다.
    expect(SystemTag.imageWidth.valueType, TagValueType.number);
    expect(SystemTag.imageHeight.valueType, TagValueType.number);
  });
}
