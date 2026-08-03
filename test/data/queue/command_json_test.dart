import 'dart:convert';

import 'package:filetagger/data/queue/command_json.dart';
import 'package:filetagger/domain/entities/external_tag_command.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// 항목 하나짜리 파일을 읽어 그 항목만 돌려준다(대부분의 테스트가 쓰는 모양).
ExternalCommandRecord only(String text) => decodeCommandFile(text).items.single;

/// 항목 하나에 실패 표식을 얹어 파일 내용으로 되쓴다(저장소가 하는 일과 같다).
String rewriteWithFailure(
  ExternalCommandRecord record,
  CommandFailure failure,
) => encodeCommandObjects([record.toJson(failure: failure)], asArray: false);

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

      expect(record, isA<PendingCommand>());
      expect((record as PendingCommand).command, command);
    });

    test('조작·없는 태그 처리를 적지 않으면 부여·실패가 기본이다', () {
      final record = only(jsonEncode({'path': 'a.png', 'tag': '읽음'}));

      final command = (record as PendingCommand).command;
      expect(command.operation, ExternalCommandOperation.add);
      expect(command.missingTag, MissingTagPolicy.fail);
      expect(command.value, isNull);
      expect(command.createValueType, isNull);
      // 판별을 적지 않은 예전 요청 파일은 그대로 경로로 읽힌다.
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

      expect((record as PendingCommand).command, command);
    });

    test('다중 부여 허용과 색상을 그대로 다시 읽는다', () {
      // 받지 않으면 다중값 태그를 내보내 되받을 때 값이 하나로 조용히 접힌다.
      const command = ExternalTagCommand(
        targetPath: 'a.png',
        tagName: '장르',
        value: '판타지',
        missingTag: MissingTagPolicy.create,
        createValueType: TagValueType.text,
        createAllowMultiple: true,
        createColor: 123456,
      );

      final record = only(encodeCommandFile(command));

      expect((record as PendingCommand).command, command);
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

      final command = (record as PendingCommand).command;
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

      expect((number as PendingCommand).command.value, '5');
      expect((flag as PendingCommand).command.value, 'true');
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

      expect(file.isArray, isTrue);
      expect(file.items, hasLength(2));
      expect(
        [for (final r in file.items) (r as PendingCommand).command.targetPath],
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

      expect(file.items[0], isA<PendingCommand>());
      expect(file.items[1], isA<UnreadableCommand>());
      expect(file.items[2], isA<UnreadableCommand>());
    });

    test('배열로 되쓰면 배열로, 객체 하나면 객체로 남는다', () {
      final objects = [
        commandToJson(
          const ExternalTagCommand(targetPath: 'a.png', tagName: '읽음'),
        ),
      ];

      expect(
        decodeCommandFile(encodeCommandObjects(objects, asArray: true)).isArray,
        isTrue,
      );
      expect(
        decodeCommandFile(
          encodeCommandObjects(objects, asArray: false),
        ).isArray,
        isFalse,
      );
    });

    test('빈 배열은 형식 오류로 본다', () {
      // 할 일이 없는데 지울 근거도 없어 큐에 영영 남는 것을 막는다.
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

  group('실패 표식', () {
    final failure = CommandFailure(
      reason: CommandFailureReason.targetMissing,
      at: DateTime(2026, 7, 4, 13, 30),
      message: '없는 파일입니다.',
    );

    test('표식이 있으면 명령을 읽지 않고 건너뛸 항목이 된다', () {
      // 명령 필드가 깨져 있어도 표식이 먼저다(같은 실패를 되풀이하지 않는다).
      final record = only(
        jsonEncode({
          'tag': '읽음',
          'failure': {
            'reason': 'malformed',
            'at': DateTime(2026, 7, 4).toIso8601String(),
          },
        }),
      );

      expect(record, isA<MarkedCommand>());
      expect(
        (record as MarkedCommand).failure.reason,
        CommandFailureReason.malformed,
      );
    });

    test('표식을 얹어 되써도 원본과 사유가 보존된다', () {
      const command = ExternalTagCommand(targetPath: 'a.png', tagName: '작가');
      final record = only(encodeCommandFile(command));

      final marked = only(rewriteWithFailure(record, failure));

      expect(marked, isA<MarkedCommand>());
      expect((marked as MarkedCommand).failure, failure);
      // 원본 명령 필드는 그대로 남아, 외부 앱이 자기가 무엇을 요청했는지 볼 수 있다.
      expect(marked.source['path'], 'a.png');
      expect(marked.source['tag'], '작가');
    });

    test('앱이 해석하지 않는 키도 되쓸 때 남는다', () {
      final record = only(
        jsonEncode({'path': 'a.png', 'tag': '작가', 'requestId': 'abc'}),
      );

      final marked = only(rewriteWithFailure(record, failure));

      expect((marked as MarkedCommand).source['requestId'], 'abc');
    });

    test('JSON이 아니던 항목은 원문을 남긴 채 표식이 붙는다', () {
      const text = '{반쯤 쓰다 만';
      final record = only(text) as UnreadableCommand;

      final marked = only(
        rewriteWithFailure(record, record.toFailure(DateTime(2026, 7))),
      );

      expect(marked, isA<MarkedCommand>());
      expect(
        (marked as MarkedCommand).failure.reason,
        CommandFailureReason.malformed,
      );
      expect(marked.source['raw'], text);
    });

    test('읽을 수 없는 표식은 한 번 갈아 쓰면 그 뒤로 읽힌다', () {
      // 시각이 없으면 보존 정리가 나이를 셀 수 없어, 제대로 된 표식으로 바꿔 둔다.
      final broken = jsonEncode({
        'path': 'a.png',
        'tag': '작가',
        'failure': {'reason': 'targetMissing'},
      });

      final record = only(broken) as UnreadableCommand;
      final marked = only(
        rewriteWithFailure(record, record.toFailure(DateTime(2026, 7))),
      );

      expect(marked, isA<MarkedCommand>());
      expect((marked as MarkedCommand).source['path'], 'a.png');
    });
  });
}
