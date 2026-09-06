import 'package:filetagger/domain/entities/system_tag.dart';
import 'package:filetagger/l10n/app_localizations.dart';
import 'package:filetagger/l10n/system_tag_names.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/l10n.dart';

void main() {
  group('시스템 태그 이름표', () {
    test('지원 언어와 이름표의 언어가 정확히 같다', () {
      // 이름표는 ARB 밖에 있어 언어를 더할 때 함께 채워야 한다. 이 검사가 없으면
      // 새 언어에서 시스템 태그 이름이 조용히 템플릿 언어로 되돌아간다.
      final supported = {
        for (final locale in AppLocalizations.supportedLocales)
          locale.languageCode,
      };
      expect(systemTagNameLanguages, supported);
    });

    test('모든 언어가 모든 시스템 태그의 이름을 갖는다', () {
      for (final locale in AppLocalizations.supportedLocales) {
        final names = systemTagNamesFor(locale.languageCode);
        expect(
          names.keys.toSet(),
          SystemTag.values.toSet(),
          reason: '${locale.languageCode}에 빠진 시스템 태그가 있다',
        );
        expect(names.values.any((n) => n.trim().isEmpty), isFalse);
      }
    });

    test('모든 언어의 이름이 한 집합에 모인다', () {
      for (final locale in AppLocalizations.supportedLocales) {
        for (final name in systemTagNamesFor(locale.languageCode).values) {
          expect(allSystemTagNames, contains(name));
        }
      }
    });

    test('지역이 붙은 로케일도 언어만 보고 찾는다', () {
      expect(systemTagNamesFor('ko_KR'), systemTagNamesFor('ko'));
      expect(systemTagNamesFor('en-US'), systemTagNamesFor('en'));
    });

    test('모르는 언어는 템플릿 언어로 되돌아간다', () {
      // 되돌아가더라도 이름이 비어 화면이 무너지지는 않아야 한다.
      final unknown = systemTagNamesFor('zz');
      expect(unknown.keys.toSet(), SystemTag.values.toSet());
    });
  });

  group('폴더 계층 이름', () {
    test('ARB의 문구와 어긋나지 않는다', () {
      // 화면은 ARB에서, 콘솔은 이 표에서 같은 이름을 읽는다. 둘이 갈리면 화면에서
      // 만든 조건 텍스트를 콘솔이 못 읽는다.
      for (final l10n in allL10n) {
        expect(
          folderHierarchyNameFor(l10n.localeName),
          l10n.groupFolderHierarchy,
          reason: l10n.localeName,
        );
      }
    });

    test('모르는 언어도 이름을 갖는다', () {
      expect(folderHierarchyNameFor('zz'), isNotEmpty);
    });
  });

  group('이름으로 찾는 표', () {
    test('모든 언어의 이름이 함께 든다', () {
      final names = {for (final d in systemTagLookupDefinitions('ko')) d.name};

      // 남이 적어 준 조건이 어느 언어로 쓰였는지 알 수 없다.
      expect(names, containsAll(allSystemTagNames));
    });

    test('폴더 계층은 들지 않는다', () {
      final names = {for (final d in systemTagLookupDefinitions('ko')) d.name};

      // 그룹에만 있는 축이라, 필터·정렬에서 풀리면 있지도 않은 태그를 가리킨다.
      expect(names, isNot(contains(folderHierarchyNameFor('ko'))));
    });

    test('표시 언어의 정의가 뒤에 온다', () {
      final definitions = systemTagLookupDefinitions('en');
      final english = systemTagNamesFor('en')[SystemTag.fileSize]!;

      // 이름이 겹치면 나중 것이 이기므로, 표시 언어가 이겨야 한다.
      final lastFileSize = definitions.lastWhere(
        (d) => d.id == SystemTag.fileSize.id,
      );
      expect(lastFileSize.name, english);
    });

    test('모든 정의가 시스템 소유로 선다', () {
      for (final d in systemTagLookupDefinitions('ko')) {
        expect(d.isSystem, isTrue, reason: d.name);
        expect(d.id, isNotNull);
      }
    });
  });
}
