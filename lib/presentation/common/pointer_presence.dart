import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform.dart';

/// 마우스·트랙패드 같은 정밀 포인터가 이 기기에 붙어 있는지.
///
/// 모바일 셸 위에 데스크톱식 포인터 조작(우클릭 컨텍스트 메뉴 등)을 덧입힐지
/// 판단하는 데 쓴다. 레이아웃과 탭 타깃은 이 값과 무관하게 모바일 그대로 둔다.
///
/// 하드웨어 키보드는 따로 감지하지 않는다 — 단축키는 플랫폼과 무관하게 늘
/// 등록해 두고(없으면 안 불릴 뿐), 보조키는 입력이 들어온 순간에 직접 읽는다.
class PointerPresence extends Notifier<bool> {
  /// 데스크톱은 포인터를 전제로 한다. 터치 플랫폼은 실제로 볼 때까지 없다고 본다.
  @override
  bool build() => isDesktopPlatform;

  /// 관측한 포인터 종류를 반영한다. 한 번 참이 되면 되돌리지 않는다 — 마우스를
  /// 잠시 안 쓴다고 조작 경로가 사라지면 오히려 혼란스럽기 때문.
  void note(PointerDeviceKind kind) {
    if (state) return;
    if (kind == PointerDeviceKind.mouse || kind == PointerDeviceKind.trackpad) {
      state = true;
    }
  }
}

final pointerPresenceProvider = NotifierProvider<PointerPresence, bool>(
  PointerPresence.new,
);

/// 자식에서 올라오는 포인터 이벤트를 엿보아 [pointerPresenceProvider]를 갱신한다.
///
/// 이미 포인터가 있다고 확정된 뒤에는 스스로 빠져 이벤트 경로에 남지 않는다.
class PointerPresenceDetector extends ConsumerWidget {
  const PointerPresenceDetector({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(pointerPresenceProvider)) return child;
    void note(PointerEvent event) =>
        ref.read(pointerPresenceProvider.notifier).note(event.kind);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerHover: note,
      onPointerDown: note,
      child: child,
    );
  }
}
