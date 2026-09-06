import 'package:filetagger/cli/config_command.dart';
import 'package:filetagger/data/settings/console_settings_store.dart';
import 'package:filetagger/l10n/console_strings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('파일에 적히는 키는 모두 config가 다룬다', () {
    // 저장소에만 키를 더하면 적을 길도 지울 길도 없는 설정이 생긴다.
    expect(
      ConfigKey.values.map((key) => key.key).toList(),
      ConsoleSettings.keys,
    );
  });

  test('모르는 이름은 키로 서지 않는다', () {
    expect(ConfigKey.of(ConsoleSettings.keyWorkspace), ConfigKey.workspace);
    expect(ConfigKey.of('없는키'), isNull);
  });

  test('도움말이 키마다 이름과 설명을 낸다', () {
    // 무엇을 적을 수 있는지 물으러 다른 명령을 부르지 않아도 되게.
    for (final strings in [consoleStringsFor('ko'), consoleStringsFor('en')]) {
      final help = configKeysHelp(strings);
      expect(help, startsWith(strings.configKeysHeading));
      for (final key in ConfigKey.values) {
        expect(help, contains(key.key), reason: key.name);
        expect(help, contains(key.describe(strings)), reason: key.name);
      }
    }
  });

  test('적는 자리와 되읽는 자리가 맞물린다', () {
    // 어긋나면 적은 값이 조용히 사라진다.
    for (final key in ConfigKey.values) {
      final written = key.put(const ConsoleSettings(), '값');
      expect(key.valueIn(written), '값', reason: key.name);
      expect(key.valueIn(key.put(written, null)), isNull, reason: key.name);
    }
  });

  test('한 키를 비워도 나머지 키는 남는다', () {
    var all = const ConsoleSettings();
    for (final key in ConfigKey.values) {
      all = key.put(all, '값-${key.key}');
    }

    for (final cleared in ConfigKey.values) {
      final left = cleared.put(all, null);
      for (final key in ConfigKey.values) {
        expect(
          key.valueIn(left),
          key == cleared ? isNull : '값-${key.key}',
          reason: '${cleared.name} → ${key.name}',
        );
      }
    }
  });

  group('적기 전에 거르는 것', () {
    final strings = consoleStringsFor(consoleTemplateLanguageCode);

    test('문구를 갖지 않은 언어는 막는다', () {
      // 적어 두면 이후 모든 실행이 조용히 템플릿 언어로 눕는다.
      expect(ConfigKey.lang.refuse('zz', strings), isNotNull);
      expect(
        ConfigKey.lang.refuse(consoleTemplateLanguageCode, strings),
        isNull,
      );
    });

    test('없는 폴더는 막지 않는다', () {
      // 틀린 값은 부르는 자리에서 곧바로 드러나고, 아직 꽂지 않은 디스크를 미리
      // 적어 두는 자리도 있다.
      expect(ConfigKey.workspace.refuse('없는폴더', strings), isNull);
    });

    test('관리 폴더만 절대 경로로 펴서 적는다', () {
      expect(p.isAbsolute(ConfigKey.workspace.normalize('그림')), isTrue);
      expect(ConfigKey.lang.normalize('en'), 'en');
    });
  });
}
