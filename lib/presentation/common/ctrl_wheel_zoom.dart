import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Ctrl(⌘)+휠을 크기 조절 신호로 가로채는, 셸에 독립적인 래퍼.
///
/// 보조키가 눌린 채 휠이 돌면 스크롤 대신 [onZoom]으로 세로 델타를 넘기고 그 이벤트를
/// **소비한다** — 포인터 신호 리졸버에 등록해 하위 스크롤뷰가 같은 신호로 스크롤하지
/// 못하게 한다. 보조키가 없으면 아무것도 하지 않아 보통 스크롤이 그대로 흐른다.
///
/// 입력 해석만 맡고 배율 계산·저장은 부모가 [onZoom]에서 정한다(도구모음이 조건
/// 편집과 저장을 분리하는 것과 같은 결).
class CtrlWheelZoom extends StatelessWidget {
  const CtrlWheelZoom({super.key, required this.onZoom, required this.child});

  /// 휠 한 칸의 세로 스크롤 델타(위로 굴리면 음수). 부호로 확대/축소를 정한다.
  final ValueChanged<double> onZoom;
  final Widget child;

  static bool get _modifierPressed {
    final keyboard = HardwareKeyboard.instance;
    return keyboard.isControlPressed || keyboard.isMetaPressed;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (event) {
        if (event is! PointerScrollEvent || !_modifierPressed) return;
        // 이 신호를 우리 것으로 등록해 하위 스크롤뷰가 같은 이벤트로 스크롤하지
        // 않게 한다(둘 다 등록하면 리졸버가 하나만 고른다).
        GestureBinding.instance.pointerSignalResolver.register(event, (
          resolved,
        ) {
          if (resolved is PointerScrollEvent) onZoom(resolved.scrollDelta.dy);
        });
      },
      child: child,
    );
  }
}
