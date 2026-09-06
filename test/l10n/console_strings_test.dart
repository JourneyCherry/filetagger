import 'package:filetagger/l10n/app_localizations.dart';
import 'package:filetagger/l10n/console_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('콘솔 문구표', () {
    test('지원 언어와 문구표의 언어가 정확히 같다', () {
      // 문구는 ARB 밖에 있어 언어를 더할 때 함께 채워야 한다. 이 검사가 없으면 새
      // 언어에서 콘솔만 조용히 템플릿 언어로 되돌아간다.
      final supported = {
        for (final locale in AppLocalizations.supportedLocales)
          locale.languageCode,
      };
      expect(consoleStringLanguages, supported);
    });

    test('템플릿 언어는 ARB의 원문 언어와 같다', () {
      // 모르는 언어가 되돌아가는 자리라, 둘이 갈리면 폴백이 두 언어로 갈린다.
      expect(
        AppLocalizations.supportedLocales.map((l) => l.languageCode),
        contains(consoleTemplateLanguageCode),
      );
    });

    test('언어마다 자기 코드를 말한다', () {
      for (final code in consoleStringLanguages) {
        expect(consoleStringsFor(code).languageCode, code);
      }
    });

    test('지역이 붙은 로케일도 언어만 보고 찾는다', () {
      for (final name in ['ko_KR', 'ko-KR', 'en_US']) {
        expect(
          consoleStringsFor(name).languageCode,
          consoleLanguageOf(name),
          reason: name,
        );
      }
    });

    test('모르는 언어는 템플릿 언어로 눕는다', () {
      expect(consoleStringsFor('zz').languageCode, consoleTemplateLanguageCode);
      expect(consoleStringsFor('').languageCode, consoleTemplateLanguageCode);
    });

    test('빈 문구가 없다', () {
      for (final code in consoleStringLanguages) {
        final s = consoleStringsFor(code);
        for (final text in [
          s.runnerDescription,
          s.optWorkspaceHelp,
          s.optJsonHelp,
          s.optLangHelp,
          s.tagDescription,
          s.listDescription,
          s.scanDescription,
          s.importDescription,
          s.imageDescription,
          s.statusDescription,
          s.systemTagsDescription,
          s.configDescription,
          s.markApplied,
          s.markHeld,
          s.markRejected,
          s.markUnreadable,
        ]) {
          expect(text.trim(), isNotEmpty, reason: code);
        }
      }
    });

    test('언어가 다르면 문구도 다르다', () {
      // 채우는 것을 잊고 원문을 그대로 복사해 두면 번역이 없는 것과 같다.
      final ko = consoleStringsFor('ko');
      final en = consoleStringsFor('en');

      expect(en.runnerDescription, isNot(ko.runnerDescription));
      expect(en.scanDescription, isNot(ko.scanDescription));
      expect(en.markRejected, isNot(ko.markRejected));
    });

    test('값이 없는 열의 표식은 언어를 타지 않는다', () {
      // 열 자리를 채우는 표식이라 `cut`·`awk`가 집는 자리다.
      for (final code in consoleStringLanguages) {
        expect(
          consoleStringsFor(code).labelNone,
          consoleStringsFor('ko').labelNone,
        );
      }
    });
  });
}
