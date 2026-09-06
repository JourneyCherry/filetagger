/// 콘솔 명령들이 공유하는 골격 — 관리 폴더를 정해 열고, 판정을 낸다.
library;

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import '../data/commands/command_json.dart';
import '../data/commands/file_command_environment.dart';
import '../data/db/app_database.dart';
import '../data/db/database_connection.dart';
import '../data/repositories/drift_file_node_repository.dart';
import '../data/repositories/drift_tag_repository.dart';
import '../data/scanner/directory_scanner.dart';
import '../data/scanner/locked_workspace_scan.dart';
import '../data/settings/console_settings_store.dart';
import '../data/settings/view_settings_store.dart';
import '../domain/entities/external_tag_command.dart';
import '../domain/repositories/workspace_scanner.dart';
import '../domain/usecases/apply_external_commands.dart';
import '../l10n/console_strings.dart';
import '../l10n/system_tag_names.dart';
import 'cli_output.dart';
import 'console_locale.dart';
import 'console_workspace.dart';

/// 관리 폴더 하나를 상대하는 명령.
///
/// 관리 폴더와 출력 형식은 **잎 명령마다 따로 받는다**. 명령 묶음(`tag`·`list`)의
/// 자리에 두면 `tag --json add ...`처럼 하위 명령 **앞에만** 쓸 수 있게 되는데,
/// 사람이 치는 순서는 `tag add <인자> --json` 쪽이다. 언어도 같은 이유로 여기 있다.
abstract class CliCommand extends Command<int> {
  CliCommand(this.strings) {
    argParser
      ..addOption(
        optWorkspace,
        abbr: 'C',
        valueHelp: strings.tokenPath,
        help: strings.optWorkspaceHelp,
      )
      ..addFlag(optJson, negatable: false, help: strings.optJsonHelp);
    addLanguageOption(argParser, strings);
  }

  /// 이 실행이 낼 문구. 표면을 세우기 전에 정해져 명령마다 그대로 건네진다.
  final ConsoleStrings strings;

  /// 관리 폴더의 기본값이 적힌 자리. 옵션을 주지 않은 명령만 여기를 본다.
  late final ConsoleSettingsStore settingsStore = ConsoleSettingsStore();

  bool get asJson => argResults![optJson] as bool;

  /// 이름을 지을 때 쓰는 언어. 시스템 태그 이름이 이것을 탄다.
  String get localeName => strings.languageCode;

  /// 위치 인자들. 옵션을 걷어낸 나머지다.
  List<String> get rest => argResults!.rest;

  /// 손댈 관리 폴더의 절대 경로. 관리 폴더가 아니면 null이고 사유는 이미 냈다.
  ///
  /// **어느 폴더인지를 옵션만 정하지 않는다** — 옵션이 없으면 설정에 적어 둔 폴더를,
  /// 그것도 없으면 부른 자리를 본다([resolveConsoleWorkspace]).
  ///
  /// **연결을 여는 것만으로 `.filetagger/`가 생기므로** 열기 전에 먼저 확인한다 —
  /// 오타 난 경로에 빈 관리 폴더를 만들어 두고 끝나면 안 된다.
  String? resolveRoot() {
    final root = resolveConsoleWorkspace(
      option: argResults![optWorkspace] as String?,
      store: settingsStore,
    ).path;
    if (!File(databaseFilePath(root)).existsSync()) {
      stderr.writeln(strings.notWorkspace(root));
      return null;
    }
    return root;
  }

  /// DB를 열어 [body]에 넘기고 반드시 닫는다.
  Future<int> withDatabase(
    String root,
    Future<int> Function(AppDatabase db) body,
  ) async {
    final db = AppDatabase.forWorkspace(root);
    try {
      return await body(db);
    } finally {
      await db.close();
    }
  }

  /// 관리 폴더를 정해 열기까지의 흔한 앞머리를 한 줄로 묶은 것.
  Future<int> withWorkspace(
    Future<int> Function(String root, AppDatabase db) body,
  ) async {
    final root = resolveRoot();
    if (root == null) return exitNoWorkspace;
    return withDatabase(root, (db) => body(root, db));
  }

  /// 명령들을 해석기에 넘겨 판정을 받는다.
  ///
  /// [imageBaseDir]는 명령이 적어 온 **상대** 이미지 경로를 푸는 기준이다 — 콘솔
  /// 인자로 들어온 것은 프로세스의 현재 디렉토리, 명령 파일에서 온 것은 그 파일이
  /// 놓인 폴더다.
  Future<List<ExternalCommandResult>> applyCommands(
    String root,
    AppDatabase db,
    List<ExternalTagCommand> commands, {
    required String imageBaseDir,
  }) async {
    final mode = (await JsonViewSettingsStore(root).load()).rootManageMode;
    return ApplyExternalCommands(
      nodes: DriftFileNodeRepository(db),
      tags: DriftTagRepository(db),
      environment: FileCommandEnvironment(root, imageBaseDir: imageBaseDir),
      systemTagNames: allSystemTagNames,
    )(commands, rootManageMode: mode);
  }

  /// 보류가 남으면 한 번 훑고 다시 판정한다. [addAutoScanOption]을 붙인 명령만
  /// 부른다.
  ///
  /// **보류에만 건다.** 보류는 "디스크엔 있는데 인덱스가 아직 모른다"는 판정이라
  /// 훑으면 그대로 서는 것이 확실한 유일한 갈래다. 거부는 훑어도 같은 자리에서
  /// 걸리고, 조건에 아무것도 안 걸린 것은 훑을 이유가 아니라 조건의 답이다.
  ///
  /// **다시 판정하는 것은 한 번뿐이다.** 두 번째에도 보류라면 그것은 경합이 아니라
  /// 훑어도 잡히지 않는 자리이므로, 되풀이해도 같은 답이 나온다.
  Future<List<ExternalCommandResult>> applyCommandsScanningIfHeld(
    String root,
    AppDatabase db,
    List<ExternalTagCommand> commands, {
    required String imageBaseDir,
  }) async {
    final first = await applyCommands(
      root,
      db,
      commands,
      imageBaseDir: imageBaseDir,
    );
    if (!autoScan || !first.any((r) => r is CommandHeld)) return first;
    if (!await scanWorkspace(root, db)) return first;
    return applyCommands(root, db, commands, imageBaseDir: imageBaseDir);
  }

  /// 관리 폴더를 한 번 훑는다. 훑지 못했으면 사유를 내고 거짓을 준다 — 그때는 앞선
  /// 판정(보류)이 그대로 서서, 스크립트가 종료 코드로 다시 시도할 수 있다.
  Future<bool> scanWorkspace(String root, AppDatabase db) async {
    final mode = (await JsonViewSettingsStore(root).load()).rootManageMode;
    try {
      await LockedWorkspaceScan(
        const DirectoryScanner(),
        DriftFileNodeRepository(db),
      )(root, rootManageMode: mode);
      return true;
    } on WorkspaceScanBusyException {
      stderr.writeln(strings.scanBusy);
      return false;
    } on WorkspaceUnreadableException {
      stderr.writeln(strings.workspaceUnreadable(root));
      return false;
    }
  }

  /// 판정 묶음을 내고 종료 코드를 돌려준다.
  ///
  /// 기계용은 **항목이 하나여도 배열**이다 — 받는 쪽이 개수에 따라 모양이 갈리는 것을
  /// 가려내지 않아도 되게 한다. 사람용은 여럿일 때만 맺음 줄을 덧붙인다.
  ///
  /// [unreadable]은 명령으로 **읽어 내지도 못한** 항목이다(명령 파일에서만 난다).
  /// 판정이 아니라 형식 오류지만 고쳐야 넘어가는 것은 같으므로 거부와 한자리에 둔다.
  int report(
    List<ExternalCommandResult> results, {
    List<UnreadableCommand> unreadable = const [],
  }) {
    if (asJson) {
      writeJson([
        for (final result in results) resultToJson(result),
        for (final record in unreadable) unreadableToJson(record),
      ]);
    } else {
      for (final result in results) {
        final line = resultLine(result, strings);
        if (result is CommandApplied) {
          stdout.writeln(line);
        } else {
          stderr.writeln(line);
        }
      }
      for (final record in unreadable) {
        stderr.writeln(unreadableLine(record, strings));
      }
      if (results.length + unreadable.length > 1) {
        stdout.writeln(
          summaryLine(results, strings, unreadable: unreadable.length),
        );
      }
    }
    final code = exitCodeFor(results);
    return unreadable.isEmpty ? code : exitRejected;
  }

  void writeJson(Object? json) => stdout.writeln(_encoder.convert(json));

  /// 보류를 만나면 스스로 훑을지. [addAutoScanOption]을 붙이지 않은 명령은 늘 거짓이다.
  bool get autoScan =>
      argParser.options.containsKey(optAutoScan) &&
      argResults![optAutoScan] as bool;

  /// 표의 머리글을 낸다. **사람용에만** 붙는다 — 기계용은 이미 JSON의 키가 같은
  /// 일을 하고, 사람이 읽는 자리에서는 열이 무엇인지 늘 보여야 한다. 필요 없는
  /// 자리에서 한 줄을 걷어 내는 것은 받는 쪽이 할 일이다.
  void writeHeader(List<String> columns) {
    if (asJson) return;
    stdout.writeln(columns.join('\t'));
  }
}

/// 하위 명령만 갖는 묶음(`tag`·`list`·`config`). 스스로 하는 일이 없다.
abstract class CliCommandGroup extends Command<int> {
  CliCommandGroup(List<Command<int>> subcommands) {
    for (final sub in subcommands) {
      addSubcommand(sub);
    }
  }
}

/// 언어 옵션을 [parser]에 붙인다.
///
/// **값은 여기서 읽지 않는다** — 문구는 표면을 세우기 전에 이미 정해졌다
/// ([languageOptionIn]). 등록하는 것은 사용법에 보이게 하고 파서가 모르는 옵션이라고
/// 거절하지 않게 하려는 것이다.
void addLanguageOption(ArgParser parser, ConsoleStrings strings) {
  parser.addOption(
    optLang,
    valueHelp: strings.tokenLanguage,
    help: strings.optLangHelp,
  );
}

/// 보류를 만나면 스스로 한 번 훑는 옵션을 [parser]에 붙인다.
void addAutoScanOption(ArgParser parser, ConsoleStrings strings) {
  parser.addFlag(optAutoScan, negatable: false, help: strings.optAutoScanHelp);
}

/// 실행 파일의 이름. 사용법 문구가 이 이름으로 시작한다.
const String executableName = 'filetagger_cli';

const String optWorkspace = 'workspace';
const String optJson = 'json';
const String optAutoScan = 'auto-scan';

const JsonEncoder _encoder = JsonEncoder.withIndent('  ');
