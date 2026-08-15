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

/// 커서 점프 판정에서 "실체화 범위"로 보는 뷰포트 밖 여유. 가상화 목록의 기본 캐시
/// 범위와 맞춰, 이 안의 행은 이미 그려져 [EnsureVisibleOnFocus]가 처리한다고 본다.
const double kListCacheExtent = 250;

/// 가상화된 목록에서 [index] 행이 **실체화 범위 밖**이면 대략 위치로 먼저 점프해 그
/// 행을 실체화시킨다. 그러면 그 행의 [EnsureVisibleOnFocus]가 정확한 위치로 마저
/// 맞춘다. 범위 안이면 아무것도 하지 않고 그쪽에 맡긴다(가까운 이동의 부드러움 유지).
///
/// 한 칸씩 옮기는 방향키에는 필요 없지만 **멀리 건너뛰는** 이동(빠른 탐색)은 대상 행에
/// 위젯이 없어 자기-노출이 먹지 않는다. 격자(아이콘 보기)는 항목이 아니라 **줄**을
/// 단위로 넘긴다.
void jumpToRowIfOffscreen(
  ScrollController controller,
  int index,
  int rowCount,
) {
  if (!controller.hasClients || index < 0 || index >= rowCount) return;
  final pos = controller.position;
  final viewport = pos.viewportDimension;
  // 평균 행 높이로 대상의 대략 위치를 어림한다(행 높이가 태그 줄 등으로 조금씩
  // 달라져도 근사면 충분하다 — 실체화 후 정확한 위치는 자기-노출이 맞춘다).
  final avg = (pos.maxScrollExtent + viewport) / rowCount;
  final targetTop = index * avg;
  final viewTop = pos.pixels;
  final viewBottom = viewTop + viewport;
  if (targetTop + avg >= viewTop - kListCacheExtent &&
      targetTop <= viewBottom + kListCacheExtent) {
    return; // 실체화 범위 안 → EnsureVisibleOnFocus가 처리
  }
  controller.jumpTo((targetTop - viewport / 2).clamp(0.0, pos.maxScrollExtent));
}
