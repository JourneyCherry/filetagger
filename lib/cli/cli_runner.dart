/// 콘솔 명령 표면 전체를 세운다.
///
/// **명사와 동사로 갈라 둔다** — `tag`는 태그 **정의**를, `list`는 파일에 붙은 **부여**를
/// 다루고, 각자 `add`·`modify`·`delete`·`show`를 갖는다. 정의와 부여를 한 명령에 겹쳐
/// 두면 "없으면 만들어라"가 부여 명령마다 정의의 성질을 끌고 다니게 되고, 같은 태그가
/// 부르는 자리마다 다른 성질로 태어난다.
///
/// 나머지는 홀로 서는 동사·명사들이다 — `scan`(전체 스캔이 도는 **유일한** 자리),
/// `import`(명령 파일 먹기), `image`(바깥 이미지를 캐시 키로), `status`(요약),
/// `systemtags`(파생 태그의 카탈로그), `config`(콘솔 자신의 설정). 뒤의 둘은 관리
/// 폴더를 열지 않고도 답한다.
///
/// **문구는 표면을 세우기 전에 정해진다.** 명령 설명과 옵션 도움말은 파서에 박히는
/// 값이라, 언어가 파싱 뒤에 정해지면 이미 늦다([resolveConsoleLanguage]).
library;

import 'dart:io';

import 'package:args/command_runner.dart';

import '../l10n/console_strings.dart';
import 'cli_command.dart';
import 'cli_output.dart';
import 'config_command.dart';
import 'console_locale.dart';
import 'image_command.dart';
import 'import_command.dart';
import 'list_commands.dart';
import 'scan_command.dart';
import 'status_command.dart';
import 'system_tags_command.dart';
import 'tag_commands.dart';

/// 명령 표면 전체. 세우는 것과 돌리는 것을 가른 이유는 **표면 자체를 볼 수 있게**
/// 하려는 것이다 — 무엇이 있는지 묻는 데 DB도 폴더도 필요하지 않아야 한다.
CommandRunner<int> buildCliRunner([ConsoleStrings? strings]) {
  final s = strings ?? consoleStringsFor(consoleTemplateLanguageCode);
  final runner = CommandRunner<int>(executableName, s.runnerDescription)
    ..addCommand(TagCommand(s))
    ..addCommand(ListCommand(s))
    ..addCommand(ScanCommand(s))
    ..addCommand(ImportCommand(s))
    ..addCommand(ImageCommand(s))
    ..addCommand(StatusCommand(s))
    ..addCommand(SystemTagsCommand(s))
    ..addCommand(ConfigCommand(s));
  // 하위 명령 앞에도 적을 수 있게 러너에도 붙인다. 잎 명령마다 이미 갖고 있으므로
  // 어느 자리에 적어도 파서가 거절하지 않는다.
  addLanguageOption(runner.argParser, s);
  return runner;
}

/// 인자를 받아 명령을 돌리고 종료 코드를 돌려준다.
Future<int> runCli(List<String> args) async {
  // 표면을 세우기 전에 언어부터 정한다. `--lang`은 파서가 아니라 인자를 미리 훑어
  // 읽는데, 파싱 결과를 기다리면 이미 문구가 박힌 뒤이기 때문이다.
  final option = languageOptionIn(args);
  final language = resolveConsoleLanguage(option: option);
  final strings = language.strings;

  // 적어 준 언어를 낼 문구가 없으면 조용히 눕지 않는다 — 직접 적은 것이 무시되면
  // 왜 그대로인지 알 길이 없다(설정에 적힌 값은 `config set`이 이미 막는다).
  if (option != null && language.fellBack) {
    stderr.writeln(strings.unknownLanguage(option, consoleStringLanguages));
    return exitUsage;
  }

  final runner = buildCliRunner(strings);
  try {
    return await runner.run(args) ?? exitOk;
  } on UsageException catch (e) {
    // 잘못 쓴 것은 결과가 아니므로 표준 출력에 섞지 않는다.
    stderr.writeln(e);
    return exitUsage;
  }
}
