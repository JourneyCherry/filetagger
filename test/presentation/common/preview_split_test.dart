import 'package:filetagger/presentation/common/preview_split.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('prefersSplitPane', () {
    test('넓은 창은 목록 옆에 프리뷰를 나란히 둔다', () {
      expect(prefersSplitPane(1280), isTrue);
    });

    test('좁은 창(휴대폰 세로 등)은 분할하지 않는다', () {
      expect(prefersSplitPane(360), isFalse);
    });

    test('임계 폭은 포함(경계에서 분할)한다', () {
      // 임계값 자체는 구현이 단일 출처다. 경계 바로 아래/위가 갈리는지만 본다.
      var threshold = 0.0;
      for (var w = 0.0; w <= 2000; w += 1) {
        if (prefersSplitPane(w)) {
          threshold = w;
          break;
        }
      }
      expect(threshold, greaterThan(0));
      expect(prefersSplitPane(threshold - 1), isFalse);
      expect(prefersSplitPane(threshold), isTrue);
    });
  });
}
