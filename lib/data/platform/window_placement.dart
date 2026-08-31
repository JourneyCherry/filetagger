import 'dart:async';
import 'dart:ui' show Offset, Rect;

import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/platform.dart';
import '../settings/app_settings_store.dart';

/// 창을 마지막으로 두었던 자리·크기로 되돌리고, 그 뒤의 변화를 설정에 남긴다.
///
/// **데스크톱에서만 동작한다** — 모바일 셸에는 창이라는 개념도, 플러그인 구현도
/// 없다. 그 판별을 이 안에서 하므로 부르는 쪽은 플랫폼을 묻지 않는다.
///
/// 창 좌표를 다루는 Dart 표준·공식 API가 없어 서드파티 플러그인에 기댄다(채택 근거는
/// `ARCHITECTURE.md`의 의존성 메모). 그 사실이 이 파일 밖으로 새지 않도록, 앱의 나머지
/// 부분은 [AppSettings.windowFrame]이라는 값만 본다.
///
/// ## 좌표계
///
/// 안팎으로 오가는 값은 모두 **물리 픽셀의 가상 데스크톱 좌표**다. 배율이 다른
/// 모니터가 섞인 배치에서 창 자리를 말할 수 있는 자는 그것 하나뿐이다.
///
/// 플러그인이 주고받는 값은 그렇지 않다 — **지금 창이 놓인 모니터의 배율로** 나눈
/// 값을 주고, 되돌릴 때 다시 곱한다. 그래서 배율이 다른 모니터에서 저장하고 되돌리면
/// 자리가 배율의 비만큼 어긋나고, 화면 밖으로 나가기도 한다. 여기서는 넘기기 직전에
/// 같은 배율로 나눠 **플러그인이 도로 곱하는 것을 상쇄**하고, 받은 값에는 곱해서
/// 물리 좌표로 되돌린다.
class WindowPlacement with WindowListener {
  WindowPlacement(this._store);

  final AppSettingsStore _store;

  /// 창을 끄는 동안 저장이 폭주하지 않도록, 손을 뗀 뒤에 한 번만 쓴다. 드래그 한 번에
  /// 이벤트가 수십 번 오기 때문이다.
  static const Duration _settleDelay = Duration(milliseconds: 400);

  /// 화면에 걸쳐 있다고 볼 최소 크기. 이보다 적게 걸치면 잡아 옮길 수도 없어 창이
  /// 사라진 것과 다름없다.
  static const double _minVisibleExtent = 48;

  Timer? _pendingSave;
  WindowFrame? _known;

  /// 저장된 자리로 창을 되돌리고 이후의 변화를 따라가기 시작한다.
  ///
  /// **첫 프레임 전에 끝내야** 창이 기본 자리에서 제자리로 튀는 것이 보이지 않는다.
  /// 러너가 첫 프레임에야 창을 보여주기 때문이다.
  ///
  /// 통째로 감싼 것은, 창 자리를 못 되돌리는 것과 앱이 못 뜨는 것은 다른 문제이기
  /// 때문이다. 여기서 새는 예외는 `runApp`을 막는다.
  Future<void> attach() async {
    if (!isDesktopPlatform) return;
    try {
      await windowManager.ensureInitialized();
      final frame = (await _store.load()).windowFrame;
      _known = frame;
      windowManager.addListener(this);
      if (frame == null) return;

      // 옮기기 전 자리를 쥐고 간다. 러너가 주 모니터에 띄운 자리라 **보인다는 것이
      // 보장된 유일한 값**이고, 되돌릴 때도 방금 읽은 그 값이라 그대로 왕복한다.
      final fallback = await _currentBounds();

      var applied = resolveFrame(frame.bounds, fallback, await _screens());
      await _moveTo(applied);
      // 옮긴 **결과**를 다시 본다. 예측이 아니라 실제 창틀을 보는 것이라, 배율
      // 오산·OS의 재조정·OS 보정·좌표계를 잘못 짚은 경우까지 한 번에 걸린다.
      if (!await _onScreenNow()) {
        applied = fallback;
        await _moveTo(fallback);
      }
      // 손본 자리를 "알던 값"으로 삼아 **저장을 건너뛴다**. 그래야 파일에는 원래 값이
      // 그대로 남아, 잠시 꺼 두었던 모니터가 돌아오거나 더 큰 화면을 붙이면 다시 그
      // 자리·크기로 간다. 사용자가 창을 옮기는 순간부터는 평소대로 새 값이 저장된다.
      if (applied != frame.bounds) {
        _known = WindowFrame(bounds: applied, maximized: frame.maximized);
      }
      // 최대화는 크기를 되돌린 **뒤에** 건다. 그래야 사용자가 최대화를 풀었을 때 원래
      // 쓰던 크기가 나온다.
      if (frame.maximized) await windowManager.maximize();
    } catch (_) {
      // 기본 자리에 뜨는 것으로 족하다.
    }
  }

  /// 창을 물리 좌표 [target]으로 옮긴다.
  ///
  /// **두 번 건다.** 배율이 다른 모니터로 건너가면 OS가 그 사실을 창에 알리면서
  /// 배율 비만큼 크기를 다시 잡는데(러너가 그 제안을 그대로 따른다), 첫 번째 이동으로
  /// 이미 목적지 모니터에 가 있으므로 두 번째는 배율이 바뀌지 않아 그대로 앉는다.
  /// 모니터를 건너가지 않은 경우 두 번째는 하는 일이 없다.
  Future<void> _moveTo(Rect target) async {
    for (var pass = 0; pass < 2; pass++) {
      // 플러그인이 곱할 값과 같은 순간의 배율로 나눈다. 값이 무엇이든 정확히 상쇄된다.
      final scale = windowManager.getDevicePixelRatio();
      await windowManager.setBounds(_scaled(target, 1 / scale));
    }
  }

  /// 지금 창이 실제로 화면에 걸쳐 있는지. 화면 배치를 못 읽으면 판단할 근거가 없으니
  /// 걸쳐 있다고 본다 — 멀쩡한 복원을 근거 없이 되돌리는 편이 더 나쁘다.
  Future<bool> _onScreenNow() async {
    final screens = await _screens();
    if (screens.isEmpty) return true;
    try {
      return isOnScreen(await _currentBounds(), screens);
    } catch (_) {
      return true;
    }
  }

  /// 지금 화면 배치. 읽지 못하면 빈 목록이며, 그것은 **판정하지 않는다**는 뜻이다.
  Future<List<Rect>> _screens() async {
    try {
      return physicalScreens(await screenRetriever.getAllDisplays());
    } catch (_) {
      return const [];
    }
  }

  /// 밀어 둔 저장을 지금 쓴다. **종료 직전에 부른다** — 창을 옮기고 곧바로 닫으면
  /// 기다리는 동안 프로세스가 사라져 그 이동이 통째로 없던 일이 되기 때문이다.
  Future<void> flush() async {
    final pending = _pendingSave;
    if (pending == null || !pending.isActive) return;
    pending.cancel();
    _pendingSave = null;
    await _save();
  }

  @override
  void onWindowMove() => _scheduleSave();

  @override
  void onWindowResize() => _scheduleSave();

  @override
  void onWindowMaximize() => _scheduleSave();

  @override
  void onWindowUnmaximize() => _scheduleSave();

  void _scheduleSave() {
    _pendingSave?.cancel();
    _pendingSave = Timer(_settleDelay, _save);
  }

  /// 타이머가 부르는 자리라 예외를 받아 줄 곳이 없다. 여기서 끝까지 삼킨다.
  Future<void> _save() async {
    try {
      // 최소화·전체화면 중의 창틀은 사용자가 고른 크기가 아니다. 그대로 담으면 다음
      // 실행이 엉뚱한 크기로 뜨므로 직전에 알던 값을 지킨다.
      if (await windowManager.isMinimized()) return;
      if (await windowManager.isFullScreen()) return;

      final maximized = await windowManager.isMaximized();
      final bounds = maximized
          ? (_known?.bounds ?? await _currentBounds())
          : await _currentBounds();

      final frame = WindowFrame(bounds: bounds, maximized: maximized);
      if (frame == _known) return;
      _known = frame;

      // 같은 파일을 나눠 쓰는 다른 설정을 덮지 않도록 현재 값 위에 얹는다. 실패는
      // 저장소가 삼키고 이후 저장을 멈춘다.
      await _store.save((await _store.load()).copyWith(windowFrame: frame));
    } catch (_) {
      // 다음 이동·크기 변경 때 다시 시도된다.
    }
  }

  /// 지금 창틀을 물리 좌표로 읽는다. 플러그인이 나눠 준 것을 도로 곱한다.
  Future<Rect> _currentBounds() async {
    final scale = windowManager.getDevicePixelRatio();
    return _scaled(await windowManager.getBounds(), scale);
  }
}

/// 화면 목록을 **물리 픽셀의 가상 데스크톱 좌표**의 작업 영역 사각형으로 옮긴다.
///
/// `screen_retriever`는 화면마다 **그 화면 자신의 배율로 나눈** 값을 준다. 배율이
/// 섞인 배치에서 그렇게 나온 사각형들은 서로 다른 자로 잰 값이라 한 좌표계를 이루지
/// 못한다 — 맞붙어 있는 두 화면 사이에 없는 틈이 생기고, 그 틈에 든 창을 "화면 밖"으로
/// 잘못 판정한다. 각자의 배율을 도로 곱해야 창 좌표와 같은 자 위에 놓인다.
List<Rect> physicalScreens(Iterable<Display> displays) => [
  for (final display in displays)
    _scaled(
      (display.visiblePosition ?? Offset.zero) &
          (display.visibleSize ?? display.size),
      (display.scaleFactor ?? 1).toDouble(),
    ),
];

/// 저장된 창틀을 지금 화면 배치에 맞게 손봐 실제로 적용할 값을 낸다.
///
/// **위치만 본다. 크기는 저장된 것을 그대로 쓴다** — 모니터가 여럿이면 어느 정도가
/// 알맞은 크기인지 앱이 가늠할 수 없고, 화면에 보이기만 하면 크기는 사용자가 바로
/// 조절할 수 있다. 되돌릴 자리는 [fallback] — 러너가 띄운, 보인다는 것이 보장된 창틀이다.
///
/// 화면 목록이 비면 판단할 근거가 없으므로 저장된 값을 그대로 쓴다.
Rect resolveFrame(Rect saved, Rect fallback, List<Rect> screens) {
  if (screens.isEmpty || isOnScreen(saved, screens)) return saved;
  return Rect.fromLTWH(fallback.left, fallback.top, saved.width, saved.height);
}

/// [frame]이 [screens] 중 어느 하나에 쓸 만큼 걸쳐 있는지. 둘 다 물리 좌표여야 한다.
///
/// 화면 밖으로 조금 나간 창은 그대로 두고(사용자가 그렇게 둔 것이다), 실질적으로
/// 잡을 데가 없는 창만 걸러낸다. 화면 목록이 비면 판단할 근거가 없으므로 그대로 둔다.
bool isOnScreen(
  Rect frame,
  List<Rect> screens, {
  double minExtent = WindowPlacement._minVisibleExtent,
}) {
  if (screens.isEmpty) return true;
  for (final screen in screens) {
    final shared = screen.intersect(frame);
    if (shared.width >= minExtent && shared.height >= minExtent) return true;
  }
  return false;
}

Rect _scaled(Rect rect, double factor) => Rect.fromLTWH(
  rect.left * factor,
  rect.top * factor,
  rect.width * factor,
  rect.height * factor,
);
