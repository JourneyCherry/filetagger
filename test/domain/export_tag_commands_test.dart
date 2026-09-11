import 'package:filetagger/data/commands/command_json.dart';
import 'package:filetagger/domain/entities/assigned_tag.dart';
import 'package:filetagger/domain/entities/external_tag_command.dart';
import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/node_kind.dart';
import 'package:filetagger/domain/entities/system_tag.dart';
import 'package:filetagger/domain/entities/tag_assignment.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/domain/usecases/export_tag_commands.dart';
import 'package:flutter_test/flutter_test.dart';

const _file = FileNode(id: 1, path: '신작/01.png', kind: NodeKind.file);
const _artist = FileNode(id: 2, path: '홍길동', kind: NodeKind.keyword);
const _folder = FileNode(id: 3, path: '신작', kind: NodeKind.directory);

TagDefinition _def(
  int id,
  String name,
  TagValueType type, {
  bool allowMultiple = false,
  int? color,
}) => TagDefinition(
  id: id,
  name: name,
  valueType: type,
  allowMultiple: allowMultiple,
  color: color,
);

AssignedTag _tag(
  FileNode node,
  TagDefinition def,
  String? value, {
  bool unresolved = false,
}) => AssignedTag(
  assignment: TagAssignment(
    fileNodeId: node.id!,
    tagDefinitionId: def.id!,
    value: value,
    valueUnresolved: unresolved,
  ),
  definition: def,
);

/// 링크 값의 판별만 기본값으로 되돌린 같은 명령. 형식이 그 필드를 내지 않으므로
/// 되받은 명령과 견줄 때 이만큼을 덜어 낸다.
ExternalTagCommand _withoutValueKind(ExternalTagCommand c) =>
    ExternalTagCommand(
      targetPath: c.targetPath,
      tagName: c.tagName,
      operation: c.operation,
      value: c.value,
      missingTag: c.missingTag,
      createValueType: c.createValueType,
      targetKind: c.targetKind,
      missingKeyword: c.missingKeyword,
      missingLink: c.missingLink,
      createAllowMultiple: c.createAllowMultiple,
      createColor: c.createColor,
    );

ExportedCommands _build({
  required List<FileNode> nodes,
  required Map<int, List<AssignedTag>> assignments,
  Set<int>? tagIds,
  bool includeValues = true,
  bool includeImages = true,
}) => buildExportCommands(
  nodes: nodes,
  assignmentsByFile: assignments,
  nodesById: const {1: _file, 2: _artist, 3: _folder},
  tagIds:
      tagIds ?? exportableTagIds(nodes: nodes, assignmentsByFile: assignments),
  includeValues: includeValues,
  includeImages: includeImages,
);

void main() {
  final rating = _def(10, '평점', TagValueType.number);
  final artistTag = _def(11, '작가', TagValueType.link);
  final cover = _def(12, '표지', TagValueType.image);
  final tags = _def(13, '태그', TagValueType.text, allowMultiple: true);

  test('태그 정의의 성질을 함께 실어 받는 쪽이 태그를 세울 수 있게 한다', () {
    final colored = _def(14, '읽음', TagValueType.label, color: 0xFF112233);
    final exported = _build(
      nodes: [_file],
      assignments: {
        1: [_tag(_file, colored, null)],
      },
    );

    final c = exported.commands.single;
    expect(c.missingTag, MissingTagPolicy.create);
    expect(c.createValueType, TagValueType.label);
    expect(c.createColor, 0xFF112233);
    // 다중 허용을 빠뜨리면 받는 쪽에서 값 여럿이 마지막 하나로 접힌다.
    expect(c.createAllowMultiple, isFalse);
  });

  test('다중값 태그는 값마다 명령 하나가 되고 조작은 add다', () {
    // replace는 받는 쪽에 이미 있던 값을 걷어낸다 — 내보내기는 "준다"이지
    // "이대로 맞춰라"가 아니다.
    final exported = _build(
      nodes: [_file],
      assignments: {
        1: [_tag(_file, tags, '만화'), _tag(_file, tags, 'SF')],
      },
    );

    expect(exported.commands, hasLength(2));
    expect(
      exported.commands.every(
        (c) => c.operation == ExternalCommandOperation.add,
      ),
      isTrue,
    );
    expect(exported.commands.map((c) => c.value), ['만화', 'SF']);
    expect(
      exported.commands.every((c) => c.createAllowMultiple == true),
      isTrue,
    );
  });

  test('시스템 태그는 후보에도 명령에도 들지 않는다', () {
    // 표시용 정의는 화면 계층이 짓는다 — 여기선 id·유형만 있으면 된다.
    final system = TagDefinition(
      id: SystemTag.fileName.id,
      name: SystemTag.fileName.name,
      valueType: SystemTag.fileName.valueType,
      isSystem: true,
    );
    final assignments = {
      1: [_tag(_file, system, '01.png'), _tag(_file, rating, '5')],
    };

    expect(exportableTagIds(nodes: [_file], assignmentsByFile: assignments), {
      rating.id,
    });
    // 후보를 무시하고 id를 통째로 넘겨도 새어 나가지 않는다.
    final exported = _build(
      nodes: [_file],
      assignments: assignments,
      tagIds: {system.id!, rating.id!},
    );
    expect(exported.commands.map((c) => c.tagName), ['평점']);
  });

  test('고르지 않은 태그는 빠진다', () {
    final exported = _build(
      nodes: [_file],
      assignments: {
        1: [_tag(_file, rating, '5'), _tag(_file, tags, '만화')],
      },
      tagIds: {rating.id!},
    );
    expect(exported.commands.map((c) => c.tagName), ['평점']);
  });

  test('태그값 미포함이면 태그만 붙고 값은 비어 간다', () {
    final exported = _build(
      nodes: [_file],
      assignments: {
        1: [_tag(_file, rating, '5')],
      },
      includeValues: false,
    );
    expect(exported.commands.single.value, isNull);
  });

  group('노드 종류', () {
    test('키워드는 이름으로, 폴더·파일은 경로로 지목한다', () {
      final exported = _build(
        nodes: [_file, _artist, _folder],
        assignments: {
          1: [_tag(_file, rating, '5')],
          2: [_tag(_artist, rating, '4')],
          3: [_tag(_folder, rating, '3')],
        },
      );
      expect(exported.commands.map((c) => (c.targetPath, c.targetKind)), [
        ('신작/01.png', ExternalNodeKind.file),
        ('홍길동', ExternalNodeKind.keyword),
        ('신작', ExternalNodeKind.directory),
      ]);
    });
  });

  group('링크 값', () {
    test('노드 id를 대상 경로·이름으로 풀고 미해결 보존을 켠다', () {
      // 대상이 선택 밖이어도 값을 빼지 않는다 — 받는 쪽이 미해결로 들고 있으면
      // 나중에 재연결할 수 있지만, 버리면 그 기회가 사라진다.
      final exported = _build(
        nodes: [_file],
        assignments: {
          1: [_tag(_file, artistTag, '2')],
        },
      );

      final c = exported.commands.single;
      expect(c.value, '홍길동');
      expect(c.valueKind, ExternalNodeKind.keyword);
      expect(c.missingLink, MissingLinkPolicy.keep);
    });

    test('이미 미해결인 값은 원문 그대로 나간다', () {
      final exported = _build(
        nodes: [_file],
        assignments: {
          1: [_tag(_file, artistTag, '없는 작가', unresolved: true)],
        },
      );
      expect(exported.commands.single.value, '없는 작가');
    });

    test('대상이 떠 버린 링크는 아예 담지 않는다', () {
      // 옛 id는 받는 쪽에서 뜻이 없어 미해결로도 쓸모가 없다.
      final exported = _build(
        nodes: [_file],
        assignments: {
          1: [_tag(_file, artistTag, '999'), _tag(_file, rating, '5')],
        },
      );
      expect(exported.commands.map((c) => c.tagName), ['평점']);
    });
  });

  group('이미지 값', () {
    test('캐시 키를 값으로 두고 동봉할 키를 모은다', () {
      // 파일을 명령 파일 옆에 같은 이름으로 놓으면, 받는 쪽이 상대 경로를 그 폴더
      // 기준으로 찾아 자기 캐시에 다시 등록한다.
      final exported = _build(
        nodes: [_file],
        assignments: {
          1: [_tag(_file, cover, 'cafe01.png')],
        },
      );
      expect(exported.commands.single.value, 'cafe01.png');
      expect(exported.imageKeys, {'cafe01.png'});
    });

    test('이미지 미포함이면 태그만 가고 파일은 모으지 않는다', () {
      final exported = _build(
        nodes: [_file],
        assignments: {
          1: [_tag(_file, cover, 'cafe01.png')],
        },
        includeImages: false,
      );
      expect(exported.commands.single.value, isNull);
      expect(exported.imageKeys, isEmpty);
    });
  });

  test('내보낸 명령은 가져오기가 그대로 읽는다(왕복)', () {
    // 내보내기가 채우는 필드를 코덱이 하나라도 흘리면 여기서 드러난다.
    // **링크 값의 판별만 예외다** — 형식이 그 필드를 더는 내지 않으므로(사용자 결정)
    // 키워드를 가리키던 링크가 되받을 때 경로로 읽힌다. 값 자체는 남는다.
    final exported = _build(
      nodes: [_file, _artist],
      assignments: {
        1: [
          _tag(_file, rating, '5'),
          _tag(_file, artistTag, '2'),
          _tag(_file, tags, '만화'),
        ],
        2: [_tag(_artist, tags, '한국')],
      },
    );

    final text = encodeCommandObjects([
      for (final c in exported.commands) commandToJson(c),
    ], asArray: true);
    final decoded = decodeCommandFile(text);

    expect(text.trimLeft(), startsWith('['));
    expect(
      decoded.map((i) => (i as ParsedCommand).command),
      exported.commands.map(_withoutValueKind),
    );
  });

  test('키워드를 가리키는 링크는 판별을 잃는다', () {
    // 잃는 것이 무엇인지 한자리에 못 박아 둔다 — 값은 이름 그대로 남고, 받는 쪽이
    // 경로로 찾다 놓치면 `missingLink: keep`이 미해결 링크로 앉힌다.
    final exported = _build(
      nodes: [_file],
      assignments: {
        1: [_tag(_file, artistTag, '2')],
      },
    );
    final command = exported.commands.single;
    expect(command.valueKind, ExternalNodeKind.keyword);

    final decoded = decodeCommandFile(encodeCommandFile(command)).single;

    final read = (decoded as ParsedCommand).command;
    expect(read.value, _artist.path);
    expect(read.valueKind, ExternalNodeKind.file);
    expect(read.missingLink, MissingLinkPolicy.keep);
  });
}
