/// `import` — 내보낸 명령 파일을 먹는다.
///
/// 요청함이 하던 일의 자리다. 다른 점은 **언제 먹을지를 부르는 쪽이 정한다**는 것 —
/// 폴더에 떨어뜨려 두면 앱이 알아서 집어 가던 것을, 이제는 이 명령이 집는다.
///
/// 상대 이미지 경로는 **명령 파일이 놓인 폴더**를 기준으로 푼다. 내보내기가 이미지를
/// 파일 옆에 캐시 키 이름 그대로 놓기 때문이다.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import '../data/commands/command_json.dart';
import '../domain/entities/external_tag_command.dart';
import 'cli_command.dart';
import 'cli_output.dart';

class ImportCommand extends CliCommand {
  ImportCommand(super.strings) {
    addAutoScanOption(argParser, strings);
  }

  @override
  String get name => 'import';

  @override
  String get description => strings.importDescription;

  @override
  String get invocation => '$executableName $name <${strings.tokenFile}>';

  @override
  Future<int> run() async {
    if (rest.length != 1) usageException(strings.needCommandFile);
    final file = File(p.absolute(rest.first));
    final String text;
    try {
      text = await file.readAsString();
    } catch (_) {
      return fail(
        exitIoError,
        ConsoleFailure.fileUnreadable,
        strings.fileUnreadable(file.path),
        subject: file.path,
      );
    }

    // 읽기는 예외를 던지지 않는다 — 형식 오류도 항목 하나의 판정일 뿐이라 나머지
    // 항목의 처리를 막지 않는다.
    final records = decodeCommandFile(text);
    final commands = <ExternalTagCommand>[
      for (final record in records)
        if (record case ParsedCommand(:final command)) command,
    ];
    final unreadable = <UnreadableCommand>[
      for (final record in records)
        if (record is UnreadableCommand) record,
    ];

    return withWorkspace((root, db) async {
      final results = await applyCommandsScanningIfHeld(
        root,
        db,
        commands,
        imageBaseDir: file.parent.path,
      );
      return report(results, unreadable: unreadable);
    });
  }
}
