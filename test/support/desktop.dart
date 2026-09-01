/// 데스크톱에서만 나는 화면을 보는 테스트용 감싸개.
///
/// 되돌리기를 **테스트 본문 안에서** 하는 것이 요점이다 — 프레임워크가 본문 직후에
/// 전역 디버그 변수를 검사하므로 tearDown에서 되돌리면 늦다.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// 데스크톱 플랫폼으로 못박고 [body]를 도는 [testWidgets].
void desktopTestWidgets(String description, WidgetTesterCallback body) {
  testWidgets(description, (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await body(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
