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
  group('markPathHidden (Windows 숨김 속성 설정)', () {
    late Directory tempRoot;

    setUp(() async {
      tempRoot = await Directory.systemTemp.createTemp('filetagger_hidden_test');
    });

    tearDown(() async {
      if (await tempRoot.exists()) {
        await tempRoot.delete(recursive: true);
      }
    });

    test('폴더에 숨김 속성을 걸면 숨김으로 판정된다', () {
      // dot-prefix가 아닌 이름이라 표시 전에는 숨김이 아니다.
      final dir = Directory('${tempRoot.path}${Platform.pathSeparator}visible');
      dir.createSync();
      expect(isHiddenEntry(dir), isFalse);

      markPathHidden(dir.path);
      expect(isHiddenEntry(dir), isTrue);

      // 멱등: 이미 숨김이어도 그대로 유지된다.
      markPathHidden(dir.path);
      expect(isHiddenEntry(dir), isTrue);
    });
  }, skip: Platform.isWindows ? false : '숨김 속성 설정은 Windows 전용');
}
