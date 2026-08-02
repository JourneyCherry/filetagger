import 'dart:convert';

import 'package:filetagger/data/queue/command_json.dart';
import 'package:filetagger/domain/entities/external_tag_command.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:flutter_test/flutter_test.dart';

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

      final record = decodeCommandFile(encodeCommandFile(command));

      expect(record, isA<PendingCommand>());
      expect((record as PendingCommand).command, command);
    });

    test('조작·없는 태그 처리를 적지 않으면 부여·실패가 기본이다', () {
      final record = decodeCommandFile(
        jsonEncode({'path': 'a.png', 'tag': '읽음'}),
      );

      final command = (record as PendingCommand).command;
      expect(command.operation, ExternalCommandOperation.add);
      expect(command.missingTag, MissingTagPolicy.fail);
      expect(command.value, isNull);
      expect(command.createValueType, isNull);
    });

    test('값이 숫자·불리언이어도 문자열로 받아 적는다', () {
      final number = decodeCommandFile(
        jsonEncode({'path': 'a.png', 'tag': '점수', 'value': 5}),
      );
      final flag = decodeCommandFile(
        jsonEncode({'path': 'a.png', 'tag': '완결', 'value': true}),
      );

      expect((number as PendingCommand).command.value, '5');
      expect((flag as PendingCommand).command.value, 'true');
    });
  });

  group('깨진 입력은 예외 대신 결과로 돌아온다', () {
    test('JSON이 아니거나 객체가 아니면 읽지 못한 것으로 본다', () {
      expect(decodeCommandFile('{반쯤 쓰다 만'), isA<UnreadableCommand>());
      expect(decodeCommandFile('[]'), isA<UnreadableCommand>());
    });

    test('필수 필드가 없으면 읽지 못한 것으로 본다', () {
      expect(
        decodeCommandFile(jsonEncode({'tag': '읽음'})),
        isA<UnreadableCommand>(),
      );
      expect(
        decodeCommandFile(jsonEncode({'path': 'a.png'})),
        isA<UnreadableCommand>(),
      );
      expect(
        decodeCommandFile(jsonEncode({'path': '', 'tag': '읽음'})),
        isA<UnreadableCommand>(),
      );
    });

    test('모르는 이름은 기본값으로 눕히지 않고 읽지 못한 것으로 본다', () {
      // 오타 난 조작을 부여로 눕히면 제거하려던 명령이 조용히 태그를 붙인다.
      for (final broken in [
        {'path': 'a.png', 'tag': '읽음', 'op': 'delete'},
        {'path': 'a.png', 'tag': '읽음', 'missing': 'auto'},
        {'path': 'a.png', 'tag': '읽음', 'valueType': 'boolean'},
      ]) {
        expect(decodeCommandFile(jsonEncode(broken)), isA<UnreadableCommand>());
      }
    });

    test('값이 문자열로 옮길 수 없는 형태면 읽지 못한 것으로 본다', () {
      expect(
        decodeCommandFile(
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
      final record = decodeCommandFile(
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
      final record = decodeCommandFile(encodeCommandFile(command));

      final marked = decodeCommandFile(record.withFailure(failure));

      expect(marked, isA<MarkedCommand>());
      expect((marked as MarkedCommand).failure, failure);
      // 원본 명령 필드는 그대로 남아, 외부 앱이 자기가 무엇을 요청했는지 볼 수 있다.
      expect(marked.source['path'], 'a.png');
      expect(marked.source['tag'], '작가');
    });

    test('앱이 해석하지 않는 키도 되쓸 때 남는다', () {
      final record = decodeCommandFile(
        jsonEncode({'path': 'a.png', 'tag': '작가', 'requestId': 'abc'}),
      );

      final marked = decodeCommandFile(record.withFailure(failure));

      expect((marked as MarkedCommand).source['requestId'], 'abc');
    });

    test('JSON이 아니던 항목은 원문을 남긴 채 표식이 붙는다', () {
      const text = '{반쯤 쓰다 만';
      final record = decodeCommandFile(text) as UnreadableCommand;

      final rewritten = record.withFailure(record.toFailure(DateTime(2026, 7)));
      final marked = decodeCommandFile(rewritten);

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

      final record = decodeCommandFile(broken) as UnreadableCommand;
      final marked = decodeCommandFile(
        record.withFailure(record.toFailure(DateTime(2026, 7))),
      );

      expect(marked, isA<MarkedCommand>());
      expect((marked as MarkedCommand).source['path'], 'a.png');
    });
  });
}
