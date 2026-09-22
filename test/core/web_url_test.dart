import 'package:filetagger/core/web_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('webUrlOf', () {
    test('웹 스킴이 붙은 주소를 알아본다', () {
      expect(webUrlOf('https://example.com')?.host, 'example.com');
      expect(webUrlOf('http://example.com/a/b?q=1')?.host, 'example.com');
    });

    test('앞뒤 공백은 떼고 본다', () {
      expect(webUrlOf('  https://example.com  ')?.host, 'example.com');
    });

    test('조각(#앵커)이 붙어도 주소로 본다', () {
      // Uri.isAbsolute는 조각이 있으면 false라, 그것으로 가르면 여기서 걸린다.
      final url = webUrlOf('https://example.com/page#section');
      expect(url?.host, 'example.com');
      expect(url?.fragment, 'section');
    });

    test('스킴이 없으면 주소로 치지 않는다', () {
      // 스킴을 지어 붙이면 사용자가 적지 않은 주소를 앱이 만들어 내 여는 꼴이 된다.
      expect(webUrlOf('example.com'), isNull);
      expect(webUrlOf('www.example.com'), isNull);
      expect(webUrlOf('그냥 메모'), isNull);
    });

    test('웹이 아닌 스킴은 받지 않는다', () {
      expect(webUrlOf('file:///C:/a.txt'), isNull);
      expect(webUrlOf('mailto:a@b.com'), isNull);
      expect(webUrlOf('C:/Users/a.txt'), isNull);
    });

    test('갈 곳(호스트)이 없으면 주소로 치지 않는다', () {
      expect(webUrlOf('https:relative'), isNull);
      expect(webUrlOf('http:///path'), isNull);
    });

    test('비었거나 없으면 null', () {
      expect(webUrlOf(null), isNull);
      expect(webUrlOf(''), isNull);
      expect(webUrlOf('   '), isNull);
    });
  });
}
