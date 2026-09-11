import 'dart:convert';

import 'package:filetagger/data/commands/command_json.dart';
import 'package:filetagger/domain/entities/external_tag_command.dart';
import 'package:filetagger/domain/entities/tag_color_format.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// 항목 하나짜리 파일을 읽어 그 항목만 돌려준다(대부분의 테스트가 쓰는 모양).
CommandRecord only(String text) => decodeCommandFile(text).single;

void main() {
  group('읽기·쓰기 대칭', () {
    test('쓴 명령을 그대로 다시 읽는다', () {
      const command = ExternalTagCommand(
        targetPath: '만화/신작/01.png',
        tagName: '작가',
        operation: ExternalCommandOperation.replace,
        value: '홍길동',
        missingTag: MissingTagPolicy.create,
        createValueType: TagValueType.text,
      );

      final record = only(encodeCommandFile(command));

      expect(record, isA<ParsedCommand>());
      expect((record as ParsedCommand).command, command);
    });

    test('조작·없는 태그 처리를 적지 않으면 부여·실패가 기본이다', () {
      final record = only(jsonEncode({'path': 'a.png', 'tag': '읽음'}));

      final command = (record as ParsedCommand).command;
      expect(command.operation, ExternalCommandOperation.add);
      expect(command.missingTag, MissingTagPolicy.fail);
      expect(command.value, isNull);
      expect(command.createValueType, isNull);
      // 판별을 적지 않은 예전 명령 파일은 그대로 경로로 읽힌다.
      expect(command.targetKind, ExternalNodeKind.file);
      expect(command.valueKind, ExternalNodeKind.file);
      expect(command.missingKeyword, MissingKeywordPolicy.fail);
      // 다중 부여·색상도 적지 않으면 비어 있다(생성 시 좁은 기본값이 쓰인다).
      expect(command.createAllowMultiple, isNull);
      expect(command.createColor, isNull);
    });

    test('키워드 판별과 생성 정책을 그대로 다시 읽는다', () {
      const command = ExternalTagCommand(
        targetPath: '작가 A',
        targetKind: ExternalNodeKind.keyword,
        tagName: '국적',
        value: '일본',
        missingKeyword: MissingKeywordPolicy.create,
      );

      final record = only(encodeCommandFile(command));

      expect((record as ParsedCommand).command, command);
    });

    test('다중 부여 허용과 색상을 그대로 다시 읽는다', () {
      // 받지 않으면 다중값 태그를 내보내 되받을 때 값이 하나로 조용히 접힌다.
      final command = ExternalTagCommand(
        targetPath: 'a.png',
        tagName: '장르',
        value: '판타지',
        missingTag: MissingTagPolicy.create,
        createValueType: TagValueType.text,
        createAllowMultiple: true,
        createColor: parseTagColorHex('#3366CC'),
      );

      final record = only(encodeCommandFile(command));

      expect((record as ParsedCommand).command, command);
    });

    test('색은 16진 표기로 내되 저장 정수로 적힌 것도 읽는다', () {
      // 사람이 열어 고치는 파일이라 내는 것은 16진 표기 하나뿐이고, 정수만 내던
      // 시절의 파일이 밖에 있으므로 읽기는 둘 다 받는다.
      final color = parseTagColorHex('#3366CC')!;
      final written = ExternalTagCommand(
        targetPath: 'a.png',
        tagName: '장르',
        missingTag: MissingTagPolicy.create,
        createValueType: TagValueType.label,
        createColor: color,
      );

      expect(commandToJson(written)['color'], tagColorToHex(color));

      final asInt = only(
        jsonEncode({'path': 'a.png', 'tag': '장르', 'color': color}),
      );
      expect((asInt as ParsedCommand).command.createColor, color);
    });

    test('링크 값의 판별은 내지 않는다', () {
      // 링크가 아닌 태그에도 값만 있으면 붙어 잡음이 되던 필드다(사용자 결정).
      const command = ExternalTagCommand(
        targetPath: '신작/01.png',
        tagName: '작가',
        value: '작가 A',
        valueKind: ExternalNodeKind.keyword,
      );

      expect(commandToJson(command).containsKey('valueNodeType'), isFalse);
    });

    test('대상과 링크 값의 판별은 서로 독립이다', () {
      // 그림 파일에 작가 키워드를 거는 것이 이 조합의 주 용도다.
      final record = only(
        jsonEncode({
          'path': '신작/01.png',
          'tag': '작가',
          'value': '작가 A',
          'valueNodeType': 'keyword',
        }),
      );

      final command = (record as ParsedCommand).command;
      expect(command.targetKind, ExternalNodeKind.file);
      expect(command.valueKind, ExternalNodeKind.keyword);
    });

    test('값이 숫자·불리언이어도 문자열로 받아 적는다', () {
      final number = only(
        jsonEncode({'path': 'a.png', 'tag': '점수', 'value': 5}),
      );
      final flag = only(
        jsonEncode({'path': 'a.png', 'tag': '완결', 'value': true}),
      );

      expect((number as ParsedCommand).command.value, '5');
      expect((flag as ParsedCommand).command.value, 'true');
    });
  });

  group('최상위 배열', () {
    test('한 파일에 여러 요청을 담아 읽는다', () {
      final file = decodeCommandFile(
        jsonEncode([
          {'path': 'a.png', 'tag': '읽음'},
          {'path': 'b.png', 'tag': '작가', 'value': '홍길동'},
        ]),
      );

      expect(file, hasLength(2));
      expect(
        [for (final r in file) (r as ParsedCommand).command.targetPath],
        ['a.png', 'b.png'],
      );
    });

    test('한 항목이 깨져도 나머지는 그대로 읽힌다', () {
      final file = decodeCommandFile(
        jsonEncode([
          {'path': 'a.png', 'tag': '읽음'},
          {'tag': '경로 없음'},
          42,
        ]),
      );

      expect(file[0], isA<ParsedCommand>());
      expect(file[1], isA<UnreadableCommand>());
      expect(file[2], isA<UnreadableCommand>());
    });

    test('항목이 하나여도 배열로 쓸 수 있고, 어느 쪽이든 읽힌다', () {
      final objects = [
        commandToJson(
          const ExternalTagCommand(targetPath: 'a.png', tagName: '읽음'),
        ),
      ];

      final asArray = encodeCommandObjects(objects, asArray: true);
      final asObject = encodeCommandObjects(objects, asArray: false);

      expect(asArray.trimLeft(), startsWith('['));
      expect(asObject.trimLeft(), startsWith('{'));
      expect(decodeCommandFile(asArray).single, isA<ParsedCommand>());
      expect(decodeCommandFile(asObject).single, isA<ParsedCommand>());
    });

    test('빈 배열은 형식 오류로 본다', () {
      // 조용히 성공으로 치면 왜 아무것도 안 됐는지 알 길이 없다.
      expect(only(jsonEncode([])), isA<UnreadableCommand>());
    });
  });

  group('깨진 입력은 예외 대신 결과로 돌아온다', () {
    test('JSON이 아니면 읽지 못한 것으로 본다', () {
      expect(only('{반쯤 쓰다 만'), isA<UnreadableCommand>());
      expect(only(jsonEncode(42)), isA<UnreadableCommand>());
    });

    test('필수 필드가 없으면 읽지 못한 것으로 본다', () {
      expect(only(jsonEncode({'tag': '읽음'})), isA<UnreadableCommand>());
      expect(only(jsonEncode({'path': 'a.png'})), isA<UnreadableCommand>());
      expect(
        only(jsonEncode({'path': '', 'tag': '읽음'})),
        isA<UnreadableCommand>(),
      );
    });

    test('모르는 이름은 기본값으로 눕히지 않고 읽지 못한 것으로 본다', () {
      // 오타 난 조작을 부여로 눕히면 제거하려던 명령이 조용히 태그를 붙인다.
      for (final broken in [
        {'path': 'a.png', 'tag': '읽음', 'op': 'delete'},
        {'path': 'a.png', 'tag': '읽음', 'missing': 'auto'},
        {'path': 'a.png', 'tag': '읽음', 'valueType': 'boolean'},
        {'path': 'a.png', 'tag': '읽음', 'nodeType': 'note'},
        {'path': 'a.png', 'tag': '읽음', 'valueNodeType': 'note'},
        {'path': 'a.png', 'tag': '읽음', 'missingKeyword': 'auto'},
        {'path': 'a.png', 'tag': '읽음', 'allowMultiple': 'yes'},
        {'path': 'a.png', 'tag': '읽음', 'color': '빨강'},
      ]) {
        expect(only(jsonEncode(broken)), isA<UnreadableCommand>());
      }
    });

    test('값이 문자열로 옮길 수 없는 형태면 읽지 못한 것으로 본다', () {
      expect(
        only(
          jsonEncode({
            'path': 'a.png',
            'tag': '작가',
            'value': ['홍길동'],
          }),
        ),
        isA<UnreadableCommand>(),
      );
    });
  });
}
