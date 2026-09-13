import 'package:filetagger/cli/list_commands.dart';
import 'package:filetagger/domain/entities/assigned_tag.dart';
import 'package:filetagger/domain/entities/external_tag_command.dart';
import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/node_kind.dart';
import 'package:filetagger/domain/entities/tag_assignment.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/l10n/console_strings.dart';
import 'package:flutter_test/flutter_test.dart';

final ConsoleStrings _strings = consoleStringsFor(consoleTemplateLanguageCode);

const FileNode _file = FileNode(id: 1, path: '신작/01.png', kind: NodeKind.file);
const FileNode _artist = FileNode(id: 2, path: '홍길동', kind: NodeKind.keyword);

/// 부여 하나. [id]가 없으면 계산으로만 서는 시스템 태그다.
AssignedTag _tag(
  int tagId,
  String name,
  TagValueType type, {
  String? value,
  int? id,
  bool system = false,
}) => AssignedTag(
  assignment: TagAssignment(
    id: id,
    fileNodeId: 1,
    tagDefinitionId: tagId,
    value: value,
  ),
  definition: TagDefinition(
    id: tagId,
    name: name,
    valueType: type,
    isSystem: system,
  ),
);

/// 사람용 한 줄에서 값 칸. 열 이름을 세는 대신 낸 차례를 그대로 딛는다.
String _valueColumn(TagRow row) => row.line(_strings).split('\t')[1];

ExternalTagCommand _command(String tag, String? value) => ExternalTagCommand(
  targetPath: '신작/01.png',
  tagName: tag,
  value: value,
  createValueType: TagValueType.image,
);

void main() {
  group('TagRow', () {
    test('대상의 종류를 기계용에 싣는다', () {
      // path 칸이 키워드 이름을 담기도 해, 이것이 없으면 객체만 받은 쪽이 파일을 받은
      // 것인지 키워드를 받은 것인지 가릴 수 없다.
      final row = TagRow(
        _artist,
        _tag(7, 'Country', TagValueType.text, value: '한국', id: 3),
        system: false,
      );

      expect(row.toJson()['kind'], NodeKind.keyword.name);
      expect(row.toJson()['path'], _artist.path);
    });

    test('label은 사용자·시스템 어느 쪽이든 값 칸을 두지 않는다', () {
      // 시스템 label은 "붙어 있다"는 표식으로 빈 글자를 들고 온다 — 그대로 내면 같은
      // 값 유형이 한 배열 안에서 두 모양으로 나온다.
      final user = TagRow(
        _file,
        _tag(11, '읽음', TagValueType.label, id: 4),
        system: false,
      );
      final derived = TagRow(
        _file,
        _tag(-7, '키워드', TagValueType.label, value: '', system: true),
        system: true,
      );

      expect(user.toJson().containsKey('value'), isFalse);
      expect(derived.toJson().containsKey('value'), isFalse);
      // 사람용도 마찬가지다 — 한쪽만 빈 칸이면 열이 비어 보이는 이유가 갈린다.
      expect(_valueColumn(user), _strings.labelNone);
      expect(_valueColumn(derived), _strings.labelNone);
    });

    test('값을 갖는 태그의 빈 글자는 값 그대로 낸다', () {
      // 눕히는 것은 label뿐이다 — 글자 태그의 빈 값은 사용자가 적어 넣은 값이다.
      final row = TagRow(
        _file,
        _tag(12, '메모', TagValueType.text, value: '', id: 5),
        system: false,
      );

      expect(row.toJson()['value'], '');
    });
  });

  group('referencedImageKeys', () {
    test('남은 명령이 가리키는 것만 추린다', () {
      // 낼 것을 자른 뒤에 쓰는 함수다 — 잘려 나간 명령의 이미지까지 옮기면 받는
      // 폴더에 아무도 가리키지 않는 파일이 남는다.
      final keys = {'cafe01.png', 'beef02.png'};

      expect(referencedImageKeys(keys, [_command('표지', 'cafe01.png')]), {
        'cafe01.png',
      });
    });

    test('값이 없는 명령은 아무것도 가리키지 않는다', () {
      expect(
        referencedImageKeys({'cafe01.png'}, [_command('읽음', null)]),
        isEmpty,
      );
    });

    test('모아 둔 적 없는 값은 키로 새어 들지 않는다', () {
      // 값 유형을 다시 따지지 않고 맞대는 방식이라, 글자 값이 키 행세를 하지 못하는
      // 것은 **모아 둔 키 쪽이 기준**이기 때문이다.
      expect(
        referencedImageKeys({'cafe01.png'}, [_command('메모', '아무 글자')]),
        isEmpty,
      );
    });
  });
}
