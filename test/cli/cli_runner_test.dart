import 'package:args/command_runner.dart';
import 'package:filetagger/cli/cli_command.dart';
import 'package:filetagger/cli/cli_runner.dart';
import 'package:filetagger/cli/console_locale.dart';
import 'package:filetagger/cli/output_window.dart';
import 'package:filetagger/cli/query_options.dart';
import 'package:filetagger/l10n/console_strings.dart';
import 'package:flutter_test/flutter_test.dart';

/// 표면의 모든 잎 명령(하위 명령을 갖지 않는 것)을 **부르는 경로와 함께** 낸다.
///
/// 경로가 함께 있어야 이름이 겹치는 잎(`tag show`·`list show`·`config show`)을
/// 가려낼 수 있다.
Iterable<({List<String> path, Command<int> command})> _leaves(
  Iterable<Command<int>> commands, [
  List<String> prefix = const [],
]) sync* {
  for (final command in commands) {
    // 러너가 스스로 붙이는 `help`는 우리가 세운 표면이 아니다.
    if (command.name == 'help') continue;
    final path = [...prefix, command.name];
    if (command.subcommands.isEmpty) {
      yield (path: path, command: command);
    } else {
      yield* _leaves(command.subcommands.values.cast<Command<int>>(), path);
    }
  }
}

/// 관리 폴더를 열지 않는 잎 명령들. 나머지는 모두 폴더를 상대한다.
const Set<String> _withoutWorkspace = {
  'systemtags',
  'config show',
  'config set',
  'config unset',
};

/// 판정을 내는 잎 명령들 — 보류를 만나면 스스로 훑을 수 있어야 하는 자리다.
const Set<String> _judging = {
  'list add',
  'list modify',
  'list delete',
  'import',
};

void main() {
  late CommandRunner<int> runner;

  setUp(() => runner = buildCliRunner());

  test('명사 묶음과 홀로 서는 동사가 함께 선다', () {
    expect(
      runner.commands.keys,
      containsAll(<String>[
        'tag',
        'list',
        'scan',
        'import',
        'image',
        'status',
        'systemtags',
        'config',
      ]),
    );
  });

  test('tag와 list는 같은 네 동사를 갖는다', () {
    const verbs = ['add', 'modify', 'delete', 'show'];

    // 정의(tag)와 부여(list)는 다루는 것이 다를 뿐 조작의 갈래는 같다.
    expect(runner.commands['tag']!.subcommands.keys, containsAll(verbs));
    expect(runner.commands['list']!.subcommands.keys, containsAll(verbs));
  });

  test('설정은 보고 적고 지우는 세 동사를 갖는다', () {
    expect(
      runner.commands['config']!.subcommands.keys,
      containsAll(<String>['show', 'set', 'unset']),
    );
  });

  test('잎 명령은 모두 출력 형식을 받는다', () {
    for (final leaf in _leaves(runner.commands.values)) {
      // 묶음 자리에 두면 하위 명령 **앞에만** 쓸 수 있게 되어, 사람이 치는 순서와
      // 어긋난다.
      expect(
        leaf.command.argParser.options.keys,
        contains(optJson),
        reason: leaf.path.join(' '),
      );
    }
  });

  test('잎 명령은 모두 언어를 받는다', () {
    // 값은 표면을 세우기 전에 미리 훑어 읽지만, 파서가 거절하지 않고 사용법에도
    // 보이려면 어느 잎에나 붙어 있어야 한다.
    for (final leaf in _leaves(runner.commands.values)) {
      expect(
        leaf.command.argParser.options.keys,
        contains(optLang),
        reason: leaf.path.join(' '),
      );
    }
    // 하위 명령 **앞에** 적는 자리도 있다.
    expect(runner.argParser.options.keys, contains(optLang));
  });

  test('판정을 내는 명령만 스스로 훑을 수 있다', () {
    for (final leaf in _leaves(runner.commands.values)) {
      final name = leaf.path.join(' ');
      expect(
        leaf.command.argParser.options.keys.contains(optAutoScan),
        _judging.contains(name),
        reason: name,
      );
    }
  });

  test('폴더를 상대하는 명령만 관리 폴더를 받는다', () {
    for (final leaf in _leaves(runner.commands.values)) {
      // 시스템 태그 카탈로그와 콘솔 설정은 코드·설정 파일이 쥔 값이라 폴더가 없어도
      // 답한다.
      final name = leaf.path.join(' ');
      expect(
        leaf.command.argParser.options.keys.contains(optWorkspace),
        !_withoutWorkspace.contains(name),
        reason: name,
      );
    }
  });

  test('잎 명령은 모두 사용법 문구를 갖는다', () {
    for (final leaf in _leaves(runner.commands.values)) {
      final name = leaf.path.join(' ');
      expect(leaf.command.invocation, startsWith(executableName));
      expect(leaf.command.description, isNotEmpty, reason: name);
    }
  });

  test('부여를 다루는 동사는 모두 집합 지목을 받는다', () {
    // 경로 하나를 지목하는 것과 조건으로 집합을 지목하는 것은 같은 자리의 두 방법이다.
    for (final verb in ['add', 'modify', 'delete', 'show']) {
      final command = runner.commands['list']!.subcommands[verb]!;
      expect(command.argParser.options.keys, contains(optFilter), reason: verb);
    }
  });

  test('차례를 정하는 조건은 조회에만 붙는다', () {
    final show = runner.commands['list']!.subcommands['show']!;
    expect(show.argParser.options.keys, containsAll([optSort, optGroup]));

    // 쓰기에는 뜻이 없다 — 무엇을 고르는지만 정하면 된다.
    for (final verb in ['add', 'modify', 'delete']) {
      final command = runner.commands['list']!.subcommands[verb]!;
      expect(command.argParser.options.keys, isNot(contains(optSort)));
      expect(command.argParser.options.keys, isNot(contains(optGroup)));
    }
  });

  test('정의 목록과 파생 태그 카탈로그는 갈라져 있다', () {
    // 한 목록에 섞으면 부여 수 같은 열이 한쪽에서만 뜻을 갖는다.
    final tagShow = runner.commands['tag']!.subcommands['show']!;
    expect(tagShow.argParser.options.keys, isNot(contains('system')));

    // 대상에 붙은 값을 물을 때는 파생 태그도 낼 수 있어야 한다.
    final listShow = runner.commands['list']!.subcommands['show']!;
    expect(listShow.argParser.options.keys, contains('system'));
  });

  test('조회는 모두 낼 수량을 정할 수 있다', () {
    for (final path in [
      ['tag', 'show'],
      ['list', 'show'],
    ]) {
      final command = runner.commands[path.first]!.subcommands[path.last]!;
      expect(
        command.argParser.options.keys,
        containsAll([optTop, optTail, optRange]),
        reason: path.join(' '),
      );
    }
    expect(
      runner.commands['systemtags']!.argParser.options.keys,
      containsAll([optTop, optTail, optRange]),
    );
  });

  test('표면은 세울 때 받은 문구로 선다', () {
    // 설명과 도움말은 파서에 **박히는** 값이라, 언어가 파싱 뒤에 정해지면 늦다.
    final ko = buildCliRunner(consoleStringsFor('ko'));
    final en = buildCliRunner(consoleStringsFor('en'));

    expect(
      ko.commands['scan']!.description,
      consoleStringsFor('ko').scanDescription,
    );
    expect(
      en.commands['scan']!.description,
      consoleStringsFor('en').scanDescription,
    );
    // 명령 **이름**은 바깥과의 계약이라 언어를 타지 않는다.
    expect(en.commands.keys, containsAll(ko.commands.keys));
  });

  test('모르는 명령은 잘못 쓴 것으로 끝난다', () async {
    // 사용법 오류가 예외로 새어 나가면 셸이 종료 코드로 가릴 수 없다.
    expect(await runCli(['없는명령']), 64);
  });

  test('문구를 갖지 않은 언어를 적으면 잘못 쓴 것으로 끝난다', () async {
    // 조용히 눕히면 직접 적은 것이 무시된 이유를 알 길이 없다.
    expect(await runCli(['--lang', 'zz', 'systemtags']), 64);
  });
}
