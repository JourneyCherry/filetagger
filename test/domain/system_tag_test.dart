import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/system_tag.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:flutter_test/flutter_test.dart';

FileNode _file({
  int? id = 1,
  String path = 'a/photo.png',
  int? size = 100,
  DateTime? modifiedAt,
  String? imageDimensions,
  DateTime? missingSince,
}) => FileNode(
  id: id,
  path: path,
  isDirectory: false,
  size: size,
  modifiedAt: modifiedAt ?? DateTime(2024, 1, 2, 3, 4, 5),
  imageDimensions: imageDimensions,
  missingSince: missingSince,
);

void main() {
  test('시스템 태그 id는 안정적인 음수이며 서로 겹치지 않는다', () {
    final ids = SystemTag.values.map((t) => t.id).toList();
    expect(ids.every(isSystemTagId), isTrue);
    expect(ids.toSet(), hasLength(ids.length));
    // 저장·직렬화에 쓰이므로 특정 값이 바뀌지 않아야 한다.
    expect(SystemTag.fileSize.id, -1);
    expect(SystemTag.fileName.id, -5);
    expect(SystemTag.folder.id, -6);
    expect(systemTagById(-5), SystemTag.fileName);
    expect(systemTagById(999), isNull);
  });

  test('valueFor: 파일의 크기·수정시각·확장자·이미지크기·이름을 계산한다', () {
    final node = _file(
      path: 'a/photo.PNG',
      size: 100,
      modifiedAt: DateTime(2024, 5, 6, 7, 8, 9),
      imageDimensions: '4x2',
    );
    expect(SystemTag.fileSize.valueFor(node), '100');
    expect(
      SystemTag.modifiedTime.valueFor(node),
      DateTime(2024, 5, 6, 7, 8, 9).toIso8601String(),
    );
    expect(SystemTag.extension.valueFor(node), 'png'); // 소문자로 정규화
    expect(SystemTag.imageDimensions.valueFor(node), '4x2');
    expect(SystemTag.fileName.valueFor(node), 'photo.PNG');
    expect(SystemTag.folder.valueFor(node), isNull); // 파일은 폴더 표식 없음
  });

  test('valueFor: 확장자 없는 이름·선두 점 이름은 확장자가 없다', () {
    expect(SystemTag.extension.valueFor(_file(path: 'README')), isNull);
    expect(SystemTag.extension.valueFor(_file(path: '.gitignore')), isNull);
  });

  test('valueFor: 폴더는 크기·확장자·이미지크기가 없고 수정시각·이름만 갖는다', () {
    final dir = FileNode(
      id: 2,
      path: 'a/sub',
      isDirectory: true,
      modifiedAt: DateTime(2024, 1, 1),
    );
    expect(SystemTag.fileSize.valueFor(dir), isNull);
    expect(SystemTag.extension.valueFor(dir), isNull);
    expect(SystemTag.imageDimensions.valueFor(dir), isNull);
    expect(SystemTag.modifiedTime.valueFor(dir), isNotNull);
    expect(SystemTag.fileName.valueFor(dir), 'sub');
    expect(SystemTag.folder.valueFor(dir), isNotNull); // 폴더 표식이 붙는다
  });

  test('systemAssignmentsFor: 폴더는 폴더 표식이 붙고 파일은 안 붙는다', () {
    final dir = FileNode(
      id: 3,
      path: 'a/sub',
      isDirectory: true,
      modifiedAt: DateTime(2024, 1, 1),
    );
    final dirTags = systemAssignmentsFor(dir).map((t) => t.tagDefinitionId);
    expect(dirTags, contains(SystemTag.folder.id));
    final fileTags = systemAssignmentsFor(
      _file(path: 'a/README'),
    ).map((t) => t.tagDefinitionId);
    expect(fileTags, isNot(contains(SystemTag.folder.id)));
  });

  test('systemAssignmentsFor: 값 있는 시스템 태그만 부여로 묶고 null은 건너뛴다', () {
    final node = _file(
      path: 'a/photo.png',
      imageDimensions: '4x2',
    ); // 이미지 파일 → 폴더 표식만 빼고 전부
    final tags = systemAssignmentsFor(node);
    expect(tags.map((t) => t.tagDefinitionId).toSet(), {
      for (final t in SystemTag.values)
        if (t != SystemTag.folder) t.id,
    });
    // 합성 부여이므로 assignment.id는 없다.
    expect(tags.every((t) => t.assignment.id == null), isTrue);
    expect(tags.every((t) => t.definition.isSystem), isTrue);

    // 이미지가 아니고 확장자도 없는 파일 → 크기·수정시각·이름만.
    final plain = systemAssignmentsFor(_file(path: 'a/README'));
    expect(plain.map((t) => t.tagDefinitionId).toSet(), {
      SystemTag.fileSize.id,
      SystemTag.modifiedTime.id,
      SystemTag.fileName.id,
    });
  });

  test('systemAssignmentsFor: 미싱 노드와 저장 전(id 없음) 노드는 제외', () {
    expect(systemAssignmentsFor(_file(missingSince: DateTime(2024))), isEmpty);
    expect(systemAssignmentsFor(_file(id: null)), isEmpty);
  });

  test('isEditableAssignment: 파일 이름만 편집 가능, 나머지 시스템 태그는 불가', () {
    final tags = {
      for (final t in systemAssignmentsFor(_file(imageDimensions: '4x2')))
        t.tagDefinitionId: t,
    };
    expect(isEditableAssignment(tags[SystemTag.fileName.id]!), isTrue);
    expect(isEditableAssignment(tags[SystemTag.fileSize.id]!), isFalse);
    expect(isEditableAssignment(tags[SystemTag.imageDimensions.id]!), isFalse);
  });

  test('시스템 태그 정의는 회색용(isSystem)·색 미지정이다', () {
    for (final t in SystemTag.values) {
      expect(t.definition.isSystem, isTrue);
      expect(t.definition.color, isNull);
      expect(t.definition.id, t.id);
    }
    expect(SystemTag.fileSize.valueType, TagValueType.number);
    expect(SystemTag.modifiedTime.valueType, TagValueType.date);
  });
}
