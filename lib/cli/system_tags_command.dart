/// `systemtags` — 쓸 수 있는 시스템 태그의 카탈로그.
///
/// **관리 폴더를 열지 않는다.** 시스템 태그는 파일에서 파생되는 고정 목록이라 어느
/// 폴더에도 저장되어 있지 않다 — 이름도 값 유형도 코드가 쥔 값이므로, 폴더 없이
/// 어디서든 물어볼 수 있다. 그래서 이 명령만 [CliCommand]가 아니다.
///
/// 사용자 정의 태그를 내는 `tag show`와 **가르는 것이 요점**이다. 한 목록에 섞으면
/// 부여 수 같은 열이 한쪽에서만 뜻을 갖고, 무엇을 고치고 지울 수 있는지가 흐려진다.
library;

import 'dart:io';

import 'package:args/command_runner.dart';

import '../domain/entities/system_tag.dart';
import '../l10n/console_strings.dart';
import '../l10n/system_tag_names.dart';
import 'cli_command.dart';
import 'cli_output.dart';
import 'output_window.dart';

class SystemTagsCommand extends Command<int> with CliOutput {
  SystemTagsCommand(this.strings) {
    argParser.addFlag(optJson, negatable: false, help: strings.optJsonHelp);
    addLanguageOption(argParser, strings);
    addWindowOptions(argParser, strings);
    addCountOption(argParser, strings);
  }

  /// 이 실행이 낼 문구. 폴더를 열지 않는 명령이라 [CliCommand]를 딛지 못해 직접 든다.
  @override
  final ConsoleStrings strings;

  @override
  String get name => 'systemtags';

  @override
  String get description => strings.systemTagsDescription;

  @override
  String get invocation => '$executableName $name';

  @override
  Future<int> run() async {
    if (argResults!.rest.isNotEmpty) {
      usageException(strings.takesNoArguments(name));
    }
    final window = resolveWindow(argResults!, strings);
    if (window case WindowUnreadable(:final message)) {
      return fail(exitUsage, ConsoleFailure.badWindow, message);
    }

    final names = systemTagNamesFor(strings.languageCode);
    final tags = (window as WindowResolved).window.apply(SystemTag.values);

    if (!writeCount(tags.length)) return exitOk;
    if (asJson) {
      writeJson([
        for (final tag in tags)
          {
            _kName: names[tag]!,
            _kValueType: tag.valueType.name,
            _kEditable: tag.editable,
            _kId: tag.id,
            // 조건은 어느 언어의 이름으로 적어도 읽으므로, 스크립트가 언어를 골라
            // 쓸 수 있도록 전부 싣는다.
            _kNames: {
              for (final code in systemTagNameLanguages)
                code: systemTagNamesFor(code)[tag]!,
            },
          },
      ]);
    } else {
      writeHeader([
        strings.columnName,
        strings.columnValueType,
        strings.columnEditable,
        strings.columnId,
      ]);
      for (final tag in tags) {
        stdout.writeln(
          [
            names[tag]!,
            tag.valueType.name,
            tag.editable ? strings.labelEditable : strings.labelReadOnly,
            '${tag.id}',
          ].join('\t'),
        );
      }
    }
    return exitOk;
  }
}

const String _kName = 'name';
const String _kValueType = 'valueType';
const String _kEditable = 'editable';
const String _kId = 'id';
const String _kNames = 'names';
