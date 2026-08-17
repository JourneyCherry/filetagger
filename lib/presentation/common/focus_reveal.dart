import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../theme.dart';

/// 커서 행을 화면에 드러내 달라는 **한 번짜리 요청**. 커서를 옮긴 뷰가 올리고
/// ([request]) 그 행이 받아 처리한다([serve]).
///
/// **"이미 드러냈다"는 기억을 행이 아니라 뷰가 든다.** 가상화 목록의 행 위젯은 스크롤에
/// 따라 만들어졌다 버려지므로, 행이 스스로 기억하면 휠로 그 행이 다시 만들어질 때마다
/// 새 커서인 줄 알고 화면을 자기 쪽으로 끌어당긴다 — 굴리던 스크롤이 그때마다 튄다.
/// 요청이 없으면 행은 다시 만들어져도 가만히 있는다.
class RowRevealRequest {
  int _requested = 0;
  int _served = 0;

  /// 아직 아무도 받지 않은 요청이 남아 있는지.
  bool get isPending => _requested != _served;

  /// 커서 행을 드러내 달라고 올린다. 처리되기 전에 겹쳐 올려도 한 번으로 친다.
  void request() => _requested++;

  /// 요청을 받았다고 표시한다. 드러낼 것이 없다고 판단했을 때도 부른다(요청이 남아
  /// 떠돌지 않게 한다).
  void serve() => _served = _requested;
}

/// 커서가 놓인 행이 [RowRevealRequest]를 받아 자기 자신을 뷰포트 안으로 밀어 넣는다.
/// 목록·자세히 보기가 공유한다.
///
/// **가장 가까운 뷰포트 하나만** 드러낸다(조상 전부가 아니라). 자세히 표는 행이 세로
/// 리스트뷰 안, 그 리스트뷰가 다시 가로 스크롤 안에 있어 — `Scrollable.ensureVisible`은
/// 가로까지 함께 옮겨 버린다. 세로 스크롤만 건드리려고 가까운 뷰포트만 민다.
class EnsureVisibleOnFocus extends StatefulWidget {
  const EnsureVisibleOnFocus({
    super.key,
    required this.active,
    required this.request,
    required this.child,
  });

  /// 커서가 이 행에 있는지. 요청을 받아 갈 수 있는 것은 커서 행뿐이다.
  final bool active;

  /// 뷰가 든 요청. 커서 행이 여럿일 수 없어 받아 가는 쪽도 하나다.
  final RowRevealRequest request;

  final Widget child;

  @override
  State<EnsureVisibleOnFocus> createState() => _EnsureVisibleOnFocusState();
}

class _EnsureVisibleOnFocusState extends State<EnsureVisibleOnFocus> {
  @override
  void initState() {
    super.initState();
    // 뷰가 어림잡아 옮겨 이제 막 만들어진 행이 여기로 온다 — 그 어림을 정확한 위치로
    // 마저 맞추는 것이 이 자리의 일이다.
    _revealIfRequested();
  }

  @override
  void didUpdateWidget(EnsureVisibleOnFocus old) {
    super.didUpdateWidget(old);
    _revealIfRequested();
  }

  /// 요청이 남아 있으면 **곧바로 받아 두고**(같은 프레임에 뷰가 어림 점프로 다시 나서지
  /// 않게 한다) 프레임이 끝난 뒤 실제로 민다 — 레이아웃이 끝나야 위치를 잴 수 있다.
  void _revealIfRequested() {
    if (!widget.active || !widget.request.isPending) return;
    widget.request.serve();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  void _reveal() {
    if (mounted) revealSelfInNearestViewport(context);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// 커서가 놓인 **칸**(한 행 안의 태그 칩 등)을 가장 가까운 뷰포트로 밀어 넣는다.
///
/// [EnsureVisibleOnFocus]와 달리 요청 손잡이가 없다. 행은 스크롤에 따라 생겼다 사라져
/// "다시 만들어진 것"과 "새 커서"를 가릴 수 없지만, 칸이 든 가로 스크롤은 그 행과 함께
/// 새로 만들어져 늘 처음 자리에서 시작하므로 — 다시 드러내도 그 줄의 가로 위치만 제자리로
/// 돌아올 뿐, 사용자가 보던 세로 위치를 뺏지 않는다.
class RevealWhileFocused extends StatefulWidget {
  const RevealWhileFocused({
    super.key,
    required this.active,
    required this.child,
  });

  /// 커서가 이 칸에 있는지.
  final bool active;

  final Widget child;

  @override
  State<RevealWhileFocused> createState() => _RevealWhileFocusedState();
}

class _RevealWhileFocusedState extends State<RevealWhileFocused> {
  @override
  void initState() {
    super.initState();
    if (widget.active) _reveal();
  }

  @override
  void didUpdateWidget(RevealWhileFocused old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _reveal();
  }

  void _reveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) revealSelfInNearestViewport(context);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// [context]가 놓인 위젯을 **가장 가까운 뷰포트** 안으로 모자란 만큼만 민다. 레이아웃이
/// 끝난 뒤에 불러야 한다(위치를 재야 한다).
void revealSelfInNearestViewport(BuildContext context) {
  final render = context.findRenderObject();
  if (render is! RenderBox || !render.attached) return;
  final scrollable = Scrollable.maybeOf(context);
  final viewport = RenderAbstractViewport.maybeOf(render);
  if (scrollable == null || viewport == null) return;
  final pos = scrollable.position;
  final target = minimalRevealOffset(pos, viewport, render);
  if (target == null) return; // 이미 온전히 보인다.
  final clamped = target.clamp(pos.minScrollExtent, pos.maxScrollExtent);
  if ((clamped - pos.pixels).abs() < 1) return; // 이미 제자리
  // 데스크톱은 stateChangeDuration이 0이라 애니메이션 없이 곧바로 이동한다.
  if (stateChangeDuration == Duration.zero) {
    pos.jumpTo(clamped);
  } else {
    pos.animateTo(
      clamped,
      duration: stateChangeDuration,
      curve: Curves.easeInOut,
    );
  }
}

/// [row]가 온전히 보이도록 스크롤을 **모자란 만큼만** 옮길 목적지. 이미 보이면 null.
///
/// 행 앞머리를 뷰포트 앞머리에 맞추는 위치와 행 끝을 뷰포트 끝에 맞추는 위치 사이에
/// 지금 위치가 있으면 그 행은 온전히 보인다. 벗어난 쪽 끝으로만 옮긴다.
///
/// **가운데로 맞추지 않는 것이 요점이다** — 커서 행을 늘 가운데 두면 방향키를 누를 때마다
/// 목록 전체가 한 칸씩 흐르고 커서는 화면 한가운데 붙박이가 되어, 커서가 움직이지 않는
/// 것처럼 보인다. 멀리 건너뛴 뒤의 첫 착지만 어림 점프가 가운데로 잡아 준다.
double? minimalRevealOffset(
  ScrollPosition pos,
  RenderAbstractViewport viewport,
  RenderObject row,
) {
  final leading = viewport.getOffsetToReveal(row, 0).offset;
  final trailing = viewport.getOffsetToReveal(row, 1).offset;
  final at = pos.pixels;
  if (trailing > leading) {
    // 행이 뷰포트보다 크다(온전히 담을 수 없다). 이미 화면을 채우고 있으면 그대로 두고,
    // 아니면 앞머리부터 보인다.
    return (at >= leading && at <= trailing) ? null : leading;
  }
  if (at > leading) return leading; // 행이 위로 벗어났다.
  if (at < trailing) return trailing; // 행이 아래로 벗어났다.
  return null;
}

/// 아직 만들어지지 않은 [index] 행 **근처로** 어림잡아 옮긴다. 실제로 움직였으면 true.
///
/// 가상화 목록은 화면 밖 행의 위젯이 없어 정확한 위치를 물을 수 없다. 그래서 평균 행
/// 높이로 어림해 그 근처로 옮기고, 그렇게 만들어진 행이 [EnsureVisibleOnFocus]로 정확한
/// 위치를 마저 맞춘다. **어림의 정확도는 첫 착지가 얼마나 가까운지만 좌우하고, 끝내 맞는
/// 자리에 서는지는 좌우하지 않는다** — 행 높이가 들쭉날쭉해도 결과가 틀어지지 않는다.
///
/// [viewportsOff]는 그 어림 자리에서 화면 높이의 몇 배만큼 비켜 착지할지다(어림이
/// 빗나갔을 때 앞뒤를 더듬는 데 쓴다).
bool jumpNearRow(
  ScrollController controller,
  int index,
  int rowCount, {
  double viewportsOff = 0,
}) {
  if (!controller.hasClients) return false;
  if (rowCount <= 0 || index < 0 || index >= rowCount) return false;
  final pos = controller.position;
  if (!pos.hasPixels || !pos.hasContentDimensions) return false;
  final viewport = pos.viewportDimension;
  final avg = (pos.maxScrollExtent + viewport) / rowCount;
  final target = (index * avg - viewport / 2 + viewport * viewportsOff).clamp(
    pos.minScrollExtent,
    pos.maxScrollExtent,
  );
  if ((target - pos.pixels).abs() < 1) return false;
  pos.jumpTo(target);
  return true;
}

/// 어림 착지를 시도할 자리(어림 위치에서 화면 높이의 몇 배만큼 비켜설지).
///
/// 첫 자리에 내려도 그 행이 만들어지지 않으면 행 높이 편차 탓에 어림이 화면 하나보다
/// 크게 빗나간 것이므로, **앞뒤로 한 화면씩 더듬어** 그 행이 만들어질 자리를 찾는다.
/// 못 찾으면 처음 어림 자리로 돌려놓고 그만둔다 — 더듬던 자리에 남겨 두면 엉뚱한 데를
/// 보여 주게 된다.
const List<double> _revealLandings = [0, 1, -1, 0];

/// 한 번의 요청에 쓸 수 있는 프레임 수. 어림이 매 프레임 나아지는 동안에는 같은 자리를
/// 다시 겨누므로([CursorRevealMixin._settleReveal]) 프레임 수로 한도를 둔다.
const int _maxRevealFrames = 12;

/// 커서 행 드러내기를 뷰에 붙이는 손잡이. 커서를 옮긴 쪽이 [requestCursorReveal]을
/// 부르고, 행 위젯에는 [cursorReveal]을 [EnsureVisibleOnFocus]로 넘긴다.
///
/// **행이 이미 만들어져 있으면 그 행이 처리하고, 없으면 여기서 어림 점프로 만들어 낸다.**
/// 화면 밖인지를 미리 어림으로 판정하지 않는 것이 요점이다 — 판정이 틀리면 점프도
/// 자기-노출도 일어나지 않아 아무 일도 안 생기는데, 행 높이가 고르지 않으면 그 판정은
/// 실제로 틀린다. 여기서는 "아무도 받아 가지 않았다"는 사실만 보므로 틀릴 여지가 없다.
mixin CursorRevealMixin<T extends StatefulWidget> on State<T> {
  /// 이 뷰의 요청. 행 위젯에 그대로 넘긴다.
  final RowRevealRequest cursorReveal = RowRevealRequest();

  /// 행들이 놓인 스크롤 컨트롤러.
  ScrollController get revealScrollController;

  /// 커서가 놓인 표시 행의 위치. 커서가 없거나 목록에 없으면 -1.
  int get cursorRowIndex;

  /// 표시 행 수(어림 계산의 분모).
  int get revealRowCount;

  void requestCursorReveal() {
    cursorReveal.request();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _settleReveal(0, _maxRevealFrames),
    );
  }

  /// 이 프레임에 커서 행이 요청을 받아 갔으면 할 일이 없다. 아무도 받지 않았다면 그 행이
  /// 아직 만들어지지 않은 것이므로, 어림 점프로 만들어 내고 다음 프레임에 다시 본다.
  ///
  /// **어림이 아직 움직이는 동안에는 같은 자리를 다시 겨눈다.** 가상화 목록은 자기 전체
  /// 길이를 모르는 채 시작해 행이 놓일수록 어림이 나아지므로, 첫 착지가 멀어도 다음 번엔
  /// 더 가까워진다. 더 움직이지 않는데도 그 행이 없을 때만 앞뒤를 더듬는다
  /// ([_revealLandings]). 갈 곳이 없거나 프레임을 다 쓰면 요청을 접는다.
  void _settleReveal(int landing, int framesLeft) {
    if (!mounted || !cursorReveal.isPending) return;
    final index = cursorRowIndex;
    if (index < 0 || landing >= _revealLandings.length || framesLeft <= 0) {
      cursorReveal.serve();
      return;
    }
    final moved = jumpNearRow(
      revealScrollController,
      index,
      revealRowCount,
      viewportsOff: _revealLandings[landing],
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _settleReveal(moved ? landing : landing + 1, framesLeft - 1),
    );
  }
}
