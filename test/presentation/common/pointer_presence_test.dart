import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:filetagger/presentation/common/pointer_presence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() {
    container.dispose();
    debugDefaultTargetPlatformOverride = null;
  });

  PointerPresence notifier() =>
      container.read(pointerPresenceProvider.notifier);

  test('데스크톱은 포인터가 있다고 보고 시작한다', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(container.read(pointerPresenceProvider), isTrue);
  });

  test('터치 플랫폼은 포인터를 볼 때까지 없다고 본다', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(container.read(pointerPresenceProvider), isFalse);
  });

  test('터치 입력만으로는 포인터가 있다고 보지 않는다', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    notifier().note(PointerDeviceKind.touch);
    notifier().note(PointerDeviceKind.stylus);
    expect(container.read(pointerPresenceProvider), isFalse);
  });

  test('마우스·트랙패드를 관측하면 포인터가 있다고 본다', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    notifier().note(PointerDeviceKind.mouse);
    expect(container.read(pointerPresenceProvider), isTrue);
  });

  test('한 번 관측한 포인터는 이후 터치 입력에도 유지된다', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    notifier().note(PointerDeviceKind.trackpad);
    notifier().note(PointerDeviceKind.touch);
    expect(container.read(pointerPresenceProvider), isTrue);
  });
}
