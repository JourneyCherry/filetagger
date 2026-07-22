import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../theme.dart';

/// 커서가 이 자식으로 오면([active]) 자기 자신을 뷰포트 안으로 스크롤해 드러낸다.
/// 목록·자세히는 가상화돼 화면 밖 행은 위젯이 없지만, 커서 이동은 한 칸씩이라 대상은
/// 대개 이미 실체화(캐시 범위)돼 있어 이 자기-노출이 먹는다. 세 보기 모드가 공유한다.
///
/// **가장 가까운 뷰포트 하나만** 드러낸다(조상 전부가 아니라). 자세히 표는 행이 세로
/// 리스트뷰 안, 그 리스트뷰가 다시 가로 스크롤 안에 있어 — `Scrollable.ensureVisible`은
/// 가로까지 함께 가운데로 옮겨 버린다. 세로 스크롤만 건드리려고 가까운 뷰포트만 민다.
class EnsureVisibleOnFocus extends StatefulWidget {
  const EnsureVisibleOnFocus({
    super.key,
    required this.active,
    required this.child,
    this.alignment = 0.5,
  });

  final bool active;

  /// 뷰포트 안에서 맞출 위치(0=시작, 0.5=가운데, 1=끝).
  final double alignment;

  final Widget child;

  @override
  State<EnsureVisibleOnFocus> createState() => _EnsureVisibleOnFocusState();
}

class _EnsureVisibleOnFocusState extends State<EnsureVisibleOnFocus> {
  @override
  void initState() {
    super.initState();
    if (widget.active) _reveal();
  }

  @override
  void didUpdateWidget(EnsureVisibleOnFocus old) {
    super.didUpdateWidget(old);
    // 커서가 이 자식으로 새로 왔을 때만 스크롤을 건드린다(이미 커서였으면 가만둔다).
    if (widget.active && !old.active) _reveal();
  }

  void _reveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final render = context.findRenderObject();
      if (render is! RenderBox || !render.attached) return;
      final scrollable = Scrollable.maybeOf(context);
      final viewport = RenderAbstractViewport.maybeOf(render);
      if (scrollable == null || viewport == null) return;
      final pos = scrollable.position;
      final target = viewport
          .getOffsetToReveal(render, widget.alignment)
          .offset
          .clamp(pos.minScrollExtent, pos.maxScrollExtent);
      if ((target - pos.pixels).abs() < 1) return; // 이미 제자리
      // 데스크톱은 stateChangeDuration이 0이라 애니메이션 없이 곧바로 이동한다.
      if (stateChangeDuration == Duration.zero) {
        pos.jumpTo(target);
      } else {
        pos.animateTo(
          target,
          duration: stateChangeDuration,
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
