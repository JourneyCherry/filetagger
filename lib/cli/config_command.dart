/// `config` — 콘솔 **자신의** 설정을 다룬다.
///
/// **관리 폴더를 열지 않는다.** 여기 담기는 것은 폴더가 아니라 이 바이너리에 붙는
/// 값이라, `systemtags`와 같은 이유로 [CliCommand]를 딛지 않는다.
///
/// **동사를 표면에 두는 것은 자리와 계정을 보여 주기 위함이다.** 설정 파일은 실행 파일
/// 옆에 있지만 범위마다 갈라져 있고, 계정을 무엇으로 부르는지는 환경이 정한다 —
/// `show`가 그 둘을 낸다.
///
/// **무엇을 적을 수 있는지는 도움말이 낸다** — [ConfigKey]가 키의 단일 출처이고,
/// 그 목록이 `config`·`set`·`unset`의 도움말 꼬리에 그대로 붙는다.
library;

import 'dart:io';
import 'dart:math';

import 'package:args/command_runner.dart';

import '../data/settings/console_settings_store.dart';
import '../l10n/console_strings.dart';
import 'cli_command.dart';
import 'cli_output.dart';
import 'console_locale.dart';
import 'console_workspace.dart';

/// `config`가 다루는 설정 하나.
///
/// **키가 늘 때 손댈 자리를 여기 하나로 모은다** — 도움말의 목록도, `set`·`unset`의
/// 갈래도, `show`의 표도 모두 이 갈래를 밟는다. 저장되는 이름은 파일에 적히는 것과
/// 같아야 하므로 [ConsoleSettings]가 쥔 것을 그대로 쓴다.
enum ConfigKey {
  lang(ConsoleSettings.keyLanguage),
  workspace(ConsoleSettings.keyWorkspace);

  const ConfigKey(this.key);

  /// 설정 파일과 명령줄에 적히는 이름.
  final String key;

  /// [key]로 갈래를 찾는다. 모르는 이름이면 null.
  static ConfigKey? of(String key) {
    for (final candidate in values) {
      if (candidate.key == key) return candidate;
    }
    return null;
  }

  String describe(ConsoleStrings strings) => switch (this) {
    ConfigKey.lang => strings.configKeyLangHelp,
    ConfigKey.workspace => strings.configKeyWorkspaceHelp,
  };

  String? valueIn(ConsoleSettings settings) => switch (this) {
    ConfigKey.lang => settings.languageCode,
    ConfigKey.workspace => settings.workspacePath,
  };

  /// [value]를 담은 새 설정. null이면 그 자리를 비운다.
  ConsoleSettings put(ConsoleSettings settings, String? value) =>
      switch (this) {
        ConfigKey.lang => settings.copyWith(
          languageCode: value,
          clearLanguage: value == null,
        ),
        ConfigKey.workspace => settings.copyWith(
          workspacePath: value,
          clearWorkspace: value == null,
        ),
      };

  /// 적어 둘 꼴로 다듬는다.
  String normalize(String raw) => switch (this) {
    ConfigKey.lang => raw,
    // 어느 자리에서 불러도 같은 폴더를 가리켜야 한다.
    ConfigKey.workspace => normalizeWorkspacePath(raw),
  };

  /// 적기 전에 막아야 할 값이면 그 사유를, 아니면 null.
  String? refuse(String raw, ConsoleStrings strings) => switch (this) {
    // 문구를 갖지 않은 언어를 적어 두면 이후 모든 실행이 조용히 템플릿 언어로 눕는다.
    // 적는 자리에서 막는 편이 그것을 알아차릴 유일한 기회다.
    ConfigKey.lang =>
      consoleStringLanguages.contains(consoleLanguageOf(raw))
          ? null
          : strings.unknownLanguage(raw, consoleStringLanguages),
    // 관리 폴더는 막지 않는다 — 틀린 값은 부르는 자리에서 곧바로 "관리 폴더가 아니다"로
    // 드러나고 그때 지목되는 경로가 곧 고칠 자리다. 아직 꽂지 않은 디스크의 폴더를 미리
    // 적어 두는 자리도 있다.
    ConfigKey.workspace => null,
  };
}

/// 설정 키를 설명과 함께 늘어놓는다. 도움말의 꼬리에 붙는다 — 무엇을 적을 수 있는지
/// 물으러 다른 명령을 부르지 않아도 되게.
String configKeysHelp(ConsoleStrings strings) {
  final width = ConfigKey.values.map((key) => key.key.length).reduce(max);
  return [
    strings.configKeysHeading,
    for (final key in ConfigKey.values)
      '  ${key.key.padRight(width)}  ${key.describe(strings)}',
  ].join('\n');
}

class ConfigCommand extends CliCommandGroup {
  ConfigCommand(this.strings, {ConsoleSettingsStore? store})
    : super([
        _ConfigShowCommand(strings, store),
        _ConfigSetCommand(strings, store),
        _ConfigUnsetCommand(strings, store),
      ]);

  final ConsoleStrings strings;

  @override
  String get name => 'config';

  @override
  String get description => strings.configDescription;

  @override
  String get usageFooter => configKeysHelp(strings);
}

/// 설정을 상대하는 명령들의 공통 앞머리.
abstract class _ConfigCommand extends Command<int> with CliOutput {
  _ConfigCommand(this.strings, ConsoleSettingsStore? store)
    : store = store ?? ConsoleSettingsStore() {
    argParser.addFlag(optJson, negatable: false, help: strings.optJsonHelp);
    addLanguageOption(argParser, strings);
  }

  @override
  final ConsoleStrings strings;
  final ConsoleSettingsStore store;

  String labelOf(ConsoleSettingsScope scope) => switch (scope) {
    ConsoleSettingsScope.global => strings.labelGlobalScope,
    ConsoleSettingsScope.user => strings.labelUserScope,
  };

  /// [scope]의 파일 자리. 계정을 몰라 파일을 지을 수 없으면 그렇게 말한다.
  String pathOf(ConsoleSettingsScope scope) =>
      store.fileOf(scope)?.path ?? strings.labelNone;
}

/// 범위를 골라 적는 명령들(`set`·`unset`)의 공통 앞머리.
abstract class _ConfigWriteCommand extends _ConfigCommand {
  _ConfigWriteCommand(super.strings, super.store) {
    argParser
      ..addFlag(_optGlobal, negatable: false, help: strings.optGlobalScopeHelp)
      ..addFlag(_optUser, negatable: false, help: strings.optUserScopeHelp);
  }

  @override
  String get usageFooter => configKeysHelp(strings);

  /// 적을 자리. **기본은 계정별이다** — 한 기계를 여럿이 쓰는 자리에서, 적는 사람이
  /// 남의 설정까지 바꾸는 쪽이 기본이어서는 안 된다.
  ConsoleSettingsScope get scope => (argResults![_optGlobal] as bool)
      ? ConsoleSettingsScope.global
      : ConsoleSettingsScope.user;

  /// 인자에서 키 하나를 읽는다. 모르는 이름이면 사유를 내고 null.
  ConfigKey? readKey(String raw) {
    final key = ConfigKey.of(raw);
    if (key == null) {
      fail(
        exitUsage,
        ConsoleFailure.unknownConfigKey,
        strings.unknownConfigKey(raw),
        subject: raw,
      );
    }
    return key;
  }

  /// [key] 자리를 [value]로 고쳐 적고 그 결과를 낸다. null이면 비운다.
  int write(ConfigKey key, String? value) {
    // 계정 이름을 모르면 계정별 자리를 가리킬 수단이 없다. 전역으로 몰래 옮겨 적으면
    // 부른 사람이 뜻하지 않게 모두의 설정을 바꾸게 된다.
    if (scope == ConsoleSettingsScope.user && store.accountName == null) {
      return fail(
        exitIoError,
        ConsoleFailure.noAccount,
        strings.noAccountToWrite,
      );
    }
    if (!store.save(scope, key.put(store.load(scope), value))) {
      return fail(
        exitIoError,
        ConsoleFailure.configWriteFailed,
        strings.configWriteFailed(pathOf(scope)),
        subject: pathOf(scope),
      );
    }
    if (asJson) {
      writeJson({
        _kScope: scope.name,
        _kFile: pathOf(scope),
        if (store.accountName != null) _kAccount: store.accountName,
        _kKey: key.key,
        _kValue: value,
      });
    } else {
      stdout.writeln(
        '${labelOf(scope)}\t${key.key}\t${value ?? strings.labelNone}',
      );
    }
    return exitOk;
  }
}

/// 지금 서 있는 설정과 설정 파일의 자리를 낸다.
class _ConfigShowCommand extends _ConfigCommand {
  _ConfigShowCommand(super.strings, super.store);

  @override
  String get name => 'show';

  @override
  String get description => strings.configShowDescription;

  @override
  String get invocation => '$executableName config $name';

  @override
  Future<int> run() async {
    if (argResults!.rest.isNotEmpty) {
      usageException(strings.takesNoArguments(name));
    }

    // 지금 서 있는 값은 **이 실행이 고른 것 그대로**다. 다시 계산하면 `--lang`을
    // 준 실행에서 낸 답과 실제로 쓰인 언어가 갈린다.
    final language = resolveConsoleLanguage(
      option: argResults![optLang] as String?,
      store: store,
    );
    // 관리 폴더는 `config`가 받지 않는 옵션이라, 옵션 없이 부른 명령이 볼 자리를 낸다.
    final workspace = resolveConsoleWorkspace(store: store);
    final scoped = {
      for (final scope in ConsoleSettingsScope.values) scope: store.load(scope),
    };

    if (asJson) {
      writeJson({
        _kAccount: store.accountName,
        _kEffective: {
          ConfigKey.lang.key: {
            _kValue: language.strings.languageCode,
            _kSource: language.source.name,
          },
          ConfigKey.workspace.key: {
            _kValue: workspace.path,
            _kSource: workspace.source.name,
          },
        },
        // 설정 이름과 파일 자리를 한 층에 섞지 않는다 — 나중에 `file`이라는 이름의
        // 설정이 생기면 부딪힌다.
        for (final scope in ConsoleSettingsScope.values)
          scope.name: {
            _kFile: store.fileOf(scope)?.path,
            _kValues: scoped[scope]!.toJson(),
          },
      });
      return exitOk;
    }

    // 계정과 지금 서 있는 값은 표의 열이 아니라 표가 딛고 선 사실이라 먼저 낸다.
    stdout
      ..writeln(
        '${strings.labelAccount}\t'
        '${store.accountName ?? strings.labelNoAccount}',
      )
      ..writeln(
        '${strings.labelInForce}\t${ConfigKey.lang.key}'
        '\t${language.strings.languageCode}\t${_languageFrom(language.source)}',
      )
      ..writeln(
        '${strings.labelInForce}\t${ConfigKey.workspace.key}'
        '\t${workspace.path}\t${_workspaceFrom(workspace.source)}',
      )
      ..writeln(
        [
          strings.columnScope,
          strings.columnKey,
          strings.columnValue,
          strings.columnFile,
        ].join('\t'),
      );
    for (final scope in ConsoleSettingsScope.values) {
      for (final key in ConfigKey.values) {
        stdout.writeln(
          '${labelOf(scope)}\t${key.key}\t'
          '${key.valueIn(scoped[scope]!) ?? strings.labelNone}\t'
          '${pathOf(scope)}',
        );
      }
    }
    return exitOk;
  }

  String _languageFrom(ConsoleLanguageSource source) => switch (source) {
    ConsoleLanguageSource.option => '--$optLang',
    ConsoleLanguageSource.user => strings.labelUserScope,
    ConsoleLanguageSource.global => strings.labelGlobalScope,
    ConsoleLanguageSource.system => strings.labelFromSystem,
  };

  String _workspaceFrom(ConsoleWorkspaceSource source) => switch (source) {
    ConsoleWorkspaceSource.option => '--$optWorkspace',
    ConsoleWorkspaceSource.user => strings.labelUserScope,
    ConsoleWorkspaceSource.global => strings.labelGlobalScope,
    ConsoleWorkspaceSource.currentDirectory => strings.labelFromCurrentDir,
  };
}

/// 설정 하나를 적는다.
class _ConfigSetCommand extends _ConfigWriteCommand {
  _ConfigSetCommand(super.strings, super.store);

  @override
  String get name => 'set';

  @override
  String get description => strings.configSetDescription;

  @override
  String get invocation =>
      '$executableName config $name <${strings.tokenKey}>'
      ' <${strings.tokenValue}>';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 2) usageException(strings.needKeyAndValue);
    final key = readKey(rest.first);
    if (key == null) return exitUsage;

    final raw = rest[1];
    final refused = key.refuse(raw, strings);
    if (refused != null) {
      // 지금 막히는 키는 언어 하나뿐이다. 키가 늘어 갈래가 갈리면 [ConfigKey]가
      // 문구와 함께 갈래도 내주어야 한다.
      return fail(
        exitUsage,
        ConsoleFailure.unknownLanguage,
        refused,
        subject: raw,
      );
    }
    return write(key, key.normalize(raw));
  }
}

/// 설정 하나를 지운다. 지우면 아래 범위(또는 환경)로 넘어간다.
class _ConfigUnsetCommand extends _ConfigWriteCommand {
  _ConfigUnsetCommand(super.strings, super.store);

  @override
  String get name => 'unset';

  @override
  String get description => strings.configUnsetDescription;

  @override
  String get invocation => '$executableName config $name <${strings.tokenKey}>';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) usageException(strings.needConfigKey);
    final key = readKey(rest.first);
    if (key == null) return exitUsage;
    return write(key, null);
  }
}

const String _optGlobal = 'global';
const String _optUser = 'user';

const String _kKey = 'key';
const String _kValue = 'value';
const String _kValues = 'values';
const String _kSource = 'source';
const String _kScope = 'scope';
const String _kEffective = 'effective';
const String _kFile = 'file';
const String _kAccount = 'account';
