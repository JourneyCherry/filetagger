import 'package:filetagger/cli/cli_output.dart';
import 'package:filetagger/data/commands/command_json.dart';
import 'package:filetagger/domain/entities/external_tag_command.dart';
import 'package:filetagger/domain/usecases/apply_external_commands.dart';
import 'package:filetagger/l10n/console_strings.dart';
import 'package:flutter_test/flutter_test.dart';

final ConsoleStrings _ko = consoleStringsFor('ko');
final ConsoleStrings _en = consoleStringsFor('en');

ExternalTagCommand _command({String? value}) =>
    ExternalTagCommand(targetPath: 'photos/a.jpg', tagName: '작가', value: value);

void main() {
  group('종료 코드', () {
    test('모두 적용됐으면 성공이다', () {
      final code = exitCodeFor([
        CommandApplied(_command()),
        CommandApplied(_command()),
      ]);

      expect(code, exitOk);
    });

    test('보류가 섞이면 보류를 낸다', () {
      final code = exitCodeFor([
        CommandApplied(_command()),
        CommandHeld(_command()),
      ]);

      // 스캔한 뒤 다시 넣으면 서는 것이라, 스크립트가 재시도로 받아야 한다.
      expect(code, exitHeld);
    });

    test('거부가 하나라도 있으면 보류를 이긴다', () {
      final code = exitCodeFor([
        CommandHeld(_command()),
        CommandRejected(_command(), CommandFailureReason.tagMissing),
      ]);

      // 다시 넣어도 같은 자리에서 걸리는 것을 재시도로 감추면 안 된다.
      expect(code, exitRejected);
    });

    test('아무것도 없으면 성공이다', () {
      expect(exitCodeFor(const []), exitOk);
    });
  });

  group('기계용 표현', () {
    test('명령 필드 위에 결과만 얹는다', () {
      final json = resultToJson(CommandApplied(_command(value: '김')));

      // 거부된 항목을 고쳐 그대로 다시 먹일 수 있어야 하므로 명령 모양이 그대로 남는다.
      expect(json['path'], 'photos/a.jpg');
      expect(json['tag'], '작가');
      expect(json['value'], '김');
      expect(json[kResult], resultApplied);
      expect(json.containsKey(kFailure), isFalse);
    });

    test('거부는 사유와 세부 갈래를 함께 싣는다', () {
      final json = resultToJson(
        CommandRejected(
          _command(),
          CommandFailureReason.malformed,
          CommandFailureDetail.keywordNameInvalid,
          'separator',
        ),
      );

      expect(json[kResult], resultRejected);
      final failure = json[kFailure] as Map<String, dynamic>;
      // 기계가 분기하는 것은 갈래의 **이름**이다 — 콘솔이 고른 언어를 타지 않는다.
      expect(failure[kReason], CommandFailureReason.malformed.name);
      expect(failure[kDetail], CommandFailureDetail.keywordNameInvalid.name);
      expect(failure[kSubject], 'separator');
    });

    test('사유가 이미 말한 실패에는 세부가 없다', () {
      final json = resultToJson(
        CommandRejected(_command(), CommandFailureReason.systemTag),
      );

      final failure = json[kFailure] as Map<String, dynamic>;
      expect(failure[kReason], CommandFailureReason.systemTag.name);
      // 사유를 되풀이하는 세부는 짚어 주는 것이 없다.
      expect(failure.containsKey(kDetail), isFalse);
    });

    test('보류에는 실패 자리가 없다', () {
      final json = resultToJson(CommandHeld(_command()));

      expect(json[kResult], resultHeld);
      expect(json.containsKey(kFailure), isFalse);
    });
  });

  group('사람용 표현', () {
    test('값이 있으면 태그 뒤에 붙인다', () {
      expect(
        resultLine(CommandApplied(_command(value: '김')), _ko),
        contains('작가=김'),
      );
    });

    test('값이 없으면 태그 이름만 낸다', () {
      expect(resultLine(CommandApplied(_command()), _ko), endsWith('작가'));
    });

    test('거부는 사유와 세부의 이름을 낸다', () {
      final line = resultLine(
        CommandRejected(
          _command(),
          CommandFailureReason.invalidValue,
          CommandFailureDetail.notNumber,
        ),
        _ko,
      );

      expect(line, contains(CommandFailureReason.invalidValue.name));
      expect(line, contains(CommandFailureDetail.notNumber.name));
    });

    test('읽어 내지 못한 항목도 갈래 이름으로 낸다', () {
      final line = unreadableLine(
        const UnreadableCommand(
          CommandReadError.unknownOperation,
          'frobnicate',
        ),
        _ko,
      );

      expect(line, contains(CommandReadError.unknownOperation.name));
      expect(line, contains('frobnicate'));
    });

    test('맺음 줄은 갈래별 수를 센다', () {
      final line = summaryLine(
        [
          CommandApplied(_command()),
          CommandApplied(_command()),
          CommandHeld(_command()),
        ],
        _ko,
        unreadable: 1,
      );

      expect(line, contains('2'));
      expect(line, contains('1'));
    });

    test('표식은 고른 언어를 따르고 갈래 이름은 따르지 않는다', () {
      final rejected = CommandRejected(
        _command(),
        CommandFailureReason.invalidValue,
        CommandFailureDetail.notNumber,
      );

      expect(resultLine(rejected, _ko), contains(_ko.markRejected));
      expect(resultLine(rejected, _en), contains(_en.markRejected));
      // 갈래는 기계가 분기하는 값이라 어느 언어에서도 같은 글자다.
      for (final strings in [_ko, _en]) {
        expect(
          resultLine(rejected, strings),
          contains(CommandFailureDetail.notNumber.name),
        );
      }
    });
  });
}
