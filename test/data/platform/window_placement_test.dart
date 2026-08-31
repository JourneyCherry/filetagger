import 'package:filetagger/data/platform/window_placement.dart';
import 'package:flutter/material.dart' show Offset, Rect, Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_retriever/screen_retriever.dart' show Display;

/// 창 배치의 플랫폼 호출은 플러그인이 필요해 여기서 다루지 않는다. 되살릴지 말지를
/// 가르는 판단만 떼어 본다 — 모니터를 뗀 뒤 창이 사라지는 사고가 나는 자리다.
void main() {
  const primary = Rect.fromLTWH(0, 0, 1920, 1080);
  const secondary = Rect.fromLTWH(1920, 0, 1920, 1080);

  group('화면에 걸쳐 있는지', () {
    test('화면 안에 온전히 있으면 그대로 쓴다', () {
      expect(
        isOnScreen(const Rect.fromLTWH(100, 100, 800, 600), [primary]),
        isTrue,
      );
    });

    test('두 번째 화면에 있어도 쓴다', () {
      expect(
        isOnScreen(const Rect.fromLTWH(2000, 100, 800, 600), [
          primary,
          secondary,
        ]),
        isTrue,
      );
    });

    test('그 화면이 사라지면 버린다', () {
      expect(
        isOnScreen(const Rect.fromLTWH(2000, 100, 800, 600), [primary]),
        isFalse,
      );
    });

    test('가장자리를 조금 넘어간 창은 그대로 둔다', () {
      // 사용자가 일부러 그렇게 둔 자리다.
      expect(
        isOnScreen(const Rect.fromLTWH(-200, 900, 800, 600), [primary]),
        isTrue,
      );
    });

    test('실오라기만 걸친 창은 버린다', () {
      expect(
        isOnScreen(const Rect.fromLTWH(-798, 100, 800, 600), [primary]),
        isFalse,
      );
    });

    test('음수 좌표 화면(주 모니터 왼쪽)도 화면으로 친다', () {
      expect(
        isOnScreen(const Rect.fromLTWH(-1800, 100, 800, 600), [
          primary,
          const Rect.fromLTWH(-1920, 0, 1920, 1080),
        ]),
        isTrue,
      );
    });

    test('화면 목록을 못 읽었으면 판단하지 않고 그대로 둔다', () {
      expect(isOnScreen(const Rect.fromLTWH(5000, 5000, 800, 600), []), isTrue);
    });
  });

  group('화면 목록을 물리 좌표로', () {
    /// 배율을 키운 주 모니터 오른쪽에 배율 1인 세로 모니터를 붙인 배치. 화면마다
    /// 자기 배율로 나뉘어 오므로, 되돌리지 않으면 맞붙은 두 화면 사이에 틈이 생긴다.
    Display display(String id, Offset position, Size size, double scale) =>
        Display(
          id: id,
          size: size,
          visiblePosition: position,
          visibleSize: size,
          scaleFactor: scale,
        );

    List<Rect> mixedDpi() => physicalScreens([
      display('1', Offset.zero, const Size(2560, 1440), 1.5),
      display('2', const Offset(3840, -124), const Size(1080, 2560), 1),
    ]);

    test('각자의 배율을 도로 곱해 한 좌표계로 모은다', () {
      expect(mixedDpi(), [
        const Rect.fromLTWH(0, 0, 3840, 2160),
        const Rect.fromLTWH(3840, -124, 1080, 2560),
      ]);
    });

    test('되돌린 좌표계에서는 맞붙은 두 화면 사이에 틈이 없다', () {
      final screens = mixedDpi();
      expect(screens[0].right, screens[1].left);
    });

    test('배율이 오지 않으면 그대로 둔다', () {
      final screens = physicalScreens([
        const Display(
          id: '1',
          size: Size(1920, 1080),
          visiblePosition: Offset.zero,
          visibleSize: Size(1920, 1080),
        ),
      ]);

      expect(screens.single, primary);
    });

    test('작업 표시줄을 뺀 영역을 준다', () {
      final screens = physicalScreens([
        const Display(
          id: '1',
          size: Size(1920, 1080),
          visiblePosition: Offset(0, 40),
          visibleSize: Size(1920, 1040),
          scaleFactor: 1,
        ),
      ]);

      expect(screens.single, const Rect.fromLTWH(0, 40, 1920, 1040));
    });
  });

  group('저장된 창틀 손보기', () {
    const fallback = Rect.fromLTWH(10, 10, 1280, 720);
    const screens = [Rect.fromLTWH(0, 0, 1920, 1040)];

    test('멀쩡한 값은 그대로 둔다', () {
      const saved = Rect.fromLTWH(100, 100, 800, 600);
      expect(resolveFrame(saved, fallback, screens), saved);
    });

    test('자리를 잃으면 좌표만 되돌리고 크기는 지킨다', () {
      const saved = Rect.fromLTWH(20000, 100, 800, 600);
      expect(
        resolveFrame(saved, fallback, screens),
        const Rect.fromLTWH(10, 10, 800, 600),
      );
    });

    test('화면보다 큰 창이어도 크기는 건드리지 않는다', () {
      // 모니터가 여럿이면 알맞은 크기를 앱이 가늠할 수 없다. 보이기만 하면 크기는
      // 사용자가 조절한다.
      const saved = Rect.fromLTWH(100, 100, 2880, 1620);
      expect(resolveFrame(saved, fallback, screens), saved);
    });

    test('화면 밖으로 나간 큰 창은 좌표만 되돌리고 큰 크기를 유지한다', () {
      const saved = Rect.fromLTWH(20000, 100, 2880, 1620);
      expect(
        resolveFrame(saved, fallback, screens),
        const Rect.fromLTWH(10, 10, 2880, 1620),
      );
    });

    test('화면 배치를 모르면 손대지 않는다', () {
      const saved = Rect.fromLTWH(20000, 100, 800, 600);
      expect(resolveFrame(saved, fallback, const []), saved);
    });
  });
}
