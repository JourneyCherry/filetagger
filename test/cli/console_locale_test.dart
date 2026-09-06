import 'dart:io';

import 'package:filetagger/cli/console_locale.dart';
import 'package:filetagger/data/settings/console_settings_store.dart';
import 'package:filetagger/l10n/console_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temp;
  late ConsoleSettingsStore store;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('filetagger_cli_locale');
    store = ConsoleSettingsStore(directory: temp, accountName: 'sunny');
  });

  tearDown(() => temp.deleteSync(recursive: true));

  void write(ConsoleSettingsScope scope, String language) =>
      store.save(scope, ConsoleSettings(languageCode: language));

  group('우선순위', () {
    test('아무것도 없으면 OS 로케일을 따른다', () {
      final chosen = resolveConsoleLanguage(
        store: store,
        systemLocaleName: 'en_US',
      );

      expect(chosen.strings.languageCode, 'en');
      expect(chosen.source, ConsoleLanguageSource.system);
    });

    test('전역 설정이 OS를 이긴다', () {
      write(ConsoleSettingsScope.global, 'ko');

      final chosen = resolveConsoleLanguage(
        store: store,
        systemLocaleName: 'en_US',
      );

      expect(chosen.strings.languageCode, 'ko');
      expect(chosen.source, ConsoleLanguageSource.global);
    });

    test('계정별 설정이 전역을 이긴다', () {
      write(ConsoleSettingsScope.global, 'ko');
      write(ConsoleSettingsScope.user, 'en');

      final chosen = resolveConsoleLanguage(
        store: store,
        systemLocaleName: 'ko_KR',
      );

      expect(chosen.strings.languageCode, 'en');
      expect(chosen.source, ConsoleLanguageSource.user);
    });

    test('명령줄 옵션이 모두를 이긴다', () {
      write(ConsoleSettingsScope.global, 'ko');
      write(ConsoleSettingsScope.user, 'ko');

      final chosen = resolveConsoleLanguage(
        option: 'en',
        store: store,
        systemLocaleName: 'ko_KR',
      );

      expect(chosen.strings.languageCode, 'en');
      expect(chosen.source, ConsoleLanguageSource.option);
    });

    test('OS조차 로케일을 알리지 않으면 템플릿 언어로 선다', () {
      final chosen = resolveConsoleLanguage(store: store, systemLocaleName: '');

      expect(chosen.strings.languageCode, consoleTemplateLanguageCode);
    });

    test('문구를 갖지 않은 언어는 눕되 그 사실을 알린다', () {
      final chosen = resolveConsoleLanguage(
        option: 'zz',
        store: store,
        systemLocaleName: 'ko_KR',
      );

      // 조용히 누우면 직접 적은 것이 무시된 이유를 알 길이 없다.
      expect(chosen.strings.languageCode, consoleTemplateLanguageCode);
      expect(chosen.fellBack, isTrue);
    });

    test('지역이 붙어 있어도 되돌아간 것으로 보지 않는다', () {
      final chosen = resolveConsoleLanguage(
        store: store,
        systemLocaleName: 'en_US',
      );

      expect(chosen.fellBack, isFalse);
    });
  });

  group('인자 미리 훑기', () {
    test('띄어 쓴 꼴과 붙여 쓴 꼴을 함께 읽는다', () {
      expect(languageOptionIn(['--lang', 'en', 'status']), 'en');
      expect(languageOptionIn(['--lang=en', 'status']), 'en');
    });

    test('자리를 가리지 않는다', () {
      // 잎 명령에도 붙는 옵션이라 하위 명령 뒤에 올 수 있다.
      expect(languageOptionIn(['tag', 'show', '--lang', 'en']), 'en');
    });

    test('적지 않았으면 없다', () {
      expect(languageOptionIn(['status']), isNull);
      expect(languageOptionIn(const []), isNull);
      // 값을 빠뜨린 것은 뒤이어 도는 파서가 제 몫으로 거절한다.
      expect(languageOptionIn(['--lang']), isNull);
    });

    test('옵션의 끝을 알리는 표식에서 멈춘다', () {
      expect(languageOptionIn(['--', '--lang', 'en']), isNull);
    });
  });
}
