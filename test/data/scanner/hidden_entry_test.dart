import 'dart:io';

import 'package:filetagger/data/scanner/hidden_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isHiddenName (POSIX 이름 기반 판정)', () {
    test('이름이 .으로 시작하면 숨김이다', () {
      expect(isHiddenName('.gitignore'), isTrue);
      expect(isHiddenName('.secret'), isTrue);
      expect(isHiddenName('.filetagger'), isTrue);
    });

    test('일반 이름은 숨김이 아니다', () {
      expect(isHiddenName('photo.png'), isFalse);
      expect(isHiddenName('report.txt'), isFalse);
      // 중간·끝의 점은 숨김이 아니다(앞이 .일 때만).
      expect(isHiddenName('a.b.txt'), isFalse);
      expect(isHiddenName('archive.'), isFalse);
    });
  });

  // markPathHidden은 Windows에서만 실제로 속성을 설정한다. 이름이 dot-prefix가 아닌
  // 폴더를 만들어 표시 전엔 숨김이 아니고, 표시 후엔 isHiddenEntry가 참이 되는지 본다.
  group(
    'markPathHidden (Windows 숨김 속성 설정)',
    () {
      late Directory tempRoot;

      setUp(() async {
        tempRoot = await Directory.systemTemp.createTemp(
          'filetagger_hidden_test',
        );
      });

      tearDown(() async {
        if (await tempRoot.exists()) {
          await tempRoot.delete(recursive: true);
        }
      });

      test('폴더에 숨김 속성을 걸면 숨김으로 판정된다', () {
        // dot-prefix가 아닌 이름이라 표시 전에는 숨김이 아니다.
        final dir = Directory(
          '${tempRoot.path}${Platform.pathSeparator}visible',
        );
        dir.createSync();
        expect(isHiddenEntry(dir), isFalse);

        markPathHidden(dir.path);
        expect(isHiddenEntry(dir), isTrue);

        // 멱등: 이미 숨김이어도 그대로 유지된다.
        markPathHidden(dir.path);
        expect(isHiddenEntry(dir), isTrue);
      });
    },
    skip: Platform.isWindows ? false : '숨김 속성 설정은 Windows 전용',
  );

  // 폴더 단위 조회는 항목별 판정을 싸게 대신하는 것이므로, 답이 달라지면 안 된다.
  // Windows에서는 나열로 받은 속성을, POSIX에서는 이름을 보게 된다.
  group('hiddenLookupFor (폴더 단위 숨김 조회)', () {
    late Directory tempRoot;

    setUp(() async {
      tempRoot = await Directory.systemTemp.createTemp(
        'filetagger_lookup_test',
      );
    });

    tearDown(() async {
      if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
    });

    /// 플랫폼이 숨김으로 보는 항목을 만든다(POSIX는 이름, Windows는 속성).
    File makeHiddenFile(String visibleName) {
      final name = Platform.isWindows ? visibleName : '.$visibleName';
      final file = File('${tempRoot.path}${Platform.pathSeparator}$name');
      file.createSync();
      if (Platform.isWindows) markPathHidden(file.path);
      return file;
    }

    test('항목별 판정과 같은 답을 낸다', () {
      File('${tempRoot.path}${Platform.pathSeparator}plain.txt').createSync();
      Directory(
        '${tempRoot.path}${Platform.pathSeparator}plain_dir',
      ).createSync();
      makeHiddenFile('hidden.txt');

      final lookup = hiddenLookupFor(tempRoot.path);
      final entries = tempRoot.listSync();
      expect(entries, hasLength(3));
      for (final entry in entries) {
        expect(
          lookup.isHidden(entry),
          isHiddenEntry(entry),
          reason: entry.path,
        );
      }
    });

    test('준비한 뒤에 생긴 항목도 판정한다(항목별 조회로 폴백)', () {
      final lookup = hiddenLookupFor(tempRoot.path);

      // 조회기를 만든 뒤에 나타난 항목이라 준비분에는 없다.
      final late = makeHiddenFile('late.txt');
      final plain = File('${tempRoot.path}${Platform.pathSeparator}late2.txt')
        ..createSync();

      expect(lookup.isHidden(late), isTrue);
      expect(lookup.isHidden(plain), isFalse);
    });

    test('나열할 수 없는 경로여도 판정은 계속된다', () {
      final missing = Directory(
        '${tempRoot.path}${Platform.pathSeparator}없는폴더',
      );
      final lookup = hiddenLookupFor(missing.path);
      // 준비분이 없으니 항목별 조회로 돌아간다(예외 없이 답이 나와야 한다).
      final file = File('${tempRoot.path}${Platform.pathSeparator}plain.txt')
        ..createSync();
      expect(lookup.isHidden(file), isFalse);
    });
  });
}
