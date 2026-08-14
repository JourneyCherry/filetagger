import 'package:filetagger/data/fs/reveal_in_file_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('explorerSelectArgument', () {
    // 이 함수가 있는 이유가 곧 이 테스트다: 경로에 공백이 있어도 탐색기가 스위치를
    // 알아봐야 한다. 스위치까지 통째로 인용되면 탐색기는 그것을 스위치로 읽지 못하고
    // 엉뚱한 기본 폴더를 연다.
    test('경로만 따옴표로 감싸고 스위치는 밖에 둔다', () {
      final arg = explorerSelectArgument(r'C:\root\My Folder\a.txt');
      expect(arg, endsWith(r'"C:\root\My Folder\a.txt"'));
      expect(arg.startsWith('"'), isFalse);
    });

    test('공백 유무와 무관하게 같은 스위치를 쓴다', () {
      String switchOf(String path) =>
          explorerSelectArgument(path).replaceFirst('"$path"', '');
      expect(switchOf(r'C:\root\sub\a.txt'), isNotEmpty);
      expect(
        switchOf(r'C:\root\My Folder\a.txt'),
        switchOf(r'C:\root\sub\a.txt'),
      );
    });

    test('따옴표는 경로를 감싸는 두 개뿐이다', () {
      final arg = explorerSelectArgument(r'C:\root\a b\c d.txt');
      expect('"'.allMatches(arg).length, 2);
    });
  });
}
