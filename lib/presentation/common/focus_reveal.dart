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
  /// 요청을 받아 두고 **아직 밀지 못한** 상태인지. 받는 것(빌드 중)과 미는 것(프레임이
  /// 끝난 뒤)이 나뉘어 있어, 그 사이에 이 행이 사라지면 요청만 삼킨 꼴이 된다.
  bool _taken = false;

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

  /// **받아 놓고 밀지 못한 채 버려지면 요청을 되돌려 놓는다.**
  ///
  /// 가상화 목록은 멀리 건너뛸 때 한달음에 가지 못하고 **사이의 행들을 차례로 만들어
  /// 가며** 자리를 잡는다. 그렇게 스쳐 만들어진 행 중에 커서 행이 끼어 있으면, 그 행이
  /// 요청을 받아 챙긴 바로 그 레이아웃에서 화면 밖으로 밀려나 버려진다 — 프레임이 끝나
  /// 밀 차례가 되었을 땐 이미 사라진 뒤라 아무 일도 못 하고, 요청은 처리된 것으로 남아
  /// 뷰의 정착 루프까지 함께 멎는다. 커서가 화면 밖에 남고 방향키를 눌러도 따라오지
  /// 않던 자리다.
  ///
  /// **되돌리는 것이 안전한 까닭은 정착 루프가 수렴하기 때문이다**([measuredRowOffset]).
  /// 목적지가 두 자리를 왕복하던 때 이것을 하면 되풀이가 끝나지 않아 화면이 떨렸다.
  @override
  void dispose() {
    if (_taken) widget.request.request();
    super.dispose();
  }

  /// 요청이 남아 있으면 **곧바로 받아 두고**(같은 프레임에 뷰가 어림 점프로 다시 나서지
  /// 않게 한다) 프레임이 끝난 뒤 실제로 민다 — 레이아웃이 끝나야 위치를 잴 수 있다.
  void _revealIfRequested() {
    if (!widget.active || !widget.request.isPending) return;
    widget.request.serve();
    _taken = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  void _reveal() {
    _taken = false;
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

/// [index] 행의 **앞머리가 뷰포트 앞머리에 닿는** 스크롤 위치. 잴 수 없으면 null.
///
/// **목록이 지금 깔아 둔 행들의 실제 자리를 읽는다** — 평균 행 높이로 어림하지 않는다.
/// 평균의 출처인 `maxScrollExtent`는 가상화 목록이 *지금 깔린 행들*로 매번 다시 어림하는
/// 값이라, 높이가 고르지 않은 목록에서는 어느 구간에 서 있느냐에 따라 오르내린다. 그
/// 값으로 목적지를 잡으면 **두 자리를 왕복하며 영영 수렴하지 않고**, 그 사이 목표 행은
/// 스쳐 만들어졌다 버려지기를 되풀이한다(화면이 떨린다).
///
/// 그 행이 이미 깔려 있으면 **정확한 값**이다. 아니면 깔린 구간의 **국소 평균**으로
/// 외삽한 어림인데, 한 번 옮길 때마다 깔린 구간이 목표 쪽으로 가므로 다음 번 어림이
/// 더 정확해진다 — 전역 평균과 달리 되돌아오지 않는다.
double? measuredRowOffset(
  ScrollController controller,
  int index,
  int rowCount,
) {
  if (!controller.hasClients) return null;
  if (rowCount <= 0 || index < 0 || index >= rowCount) return null;
  final pos = controller.position;
  if (!pos.hasPixels || !pos.hasContentDimensions) return null;
  final sliver = _rowSliverOf(pos);
  final first = sliver?.firstChild;
  final last = sliver?.lastChild;
  if (sliver == null || first == null || last == null) return null;
  final viewport = RenderAbstractViewport.maybeOf(sliver);
  if (viewport == null) return null;

  // 자리는 **렌더 트리에서** 잰다(`getOffsetToReveal`). 지금 스크롤 픽셀을 섞으면, 한
  // 프레임에 두 번 옮길 때 값이 어긋난다 — 픽셀만 먼저 움직이고 행들은 아직 옛 자리에
  // 놓여 있기 때문이다.
  double offsetOf(RenderBox box) => viewport.getOffsetToReveal(box, 0).offset;

  for (RenderBox? c = first; c != null; c = sliver.childAfter(c)) {
    if (sliver.indexOf(c) == index) return offsetOf(c);
  }
  // 깔린 구간이 차지한 길이를 그 행 수로 나눈 국소 평균으로 외삽한다.
  final firstIndex = sliver.indexOf(first);
  final span = sliver.indexOf(last) - firstIndex + 1;
  final firstAt = offsetOf(first);
  final extent = offsetOf(last) + _mainExtentOf(last, pos.axis) - firstAt;
  if (span <= 0 || extent <= 0) return null;
  return firstAt + (index - firstIndex) * (extent / span);
}

/// [index] 행이 화면 가운데 오도록 옮긴다. 실제로 움직였으면 true.
///
/// 가운데로 잡는 것은 **어림이 빗나가도 앞뒤로 반 화면씩 여유가 생기기 때문**이다 —
/// 그 여유 안에 들면 행이 만들어지고, 거기서부터는 [EnsureVisibleOnFocus]가 정확한
/// 자리로 마저 맞춘다. 멀리 건너뛴 뒤의 첫 착지에만 쓰이므로, 커서가 화면 한가운데
/// 붙박이가 되지는 않는다.
bool jumpNearRow(ScrollController controller, int index, int rowCount) {
  final at = measuredRowOffset(controller, index, rowCount);
  if (at == null) return false;
  final pos = controller.position;
  final target = (at - pos.viewportDimension / 2).clamp(
    pos.minScrollExtent,
    pos.maxScrollExtent,
  );
  if ((target - pos.pixels).abs() < 1) return false;
  pos.jumpTo(target);
  return true;
}

/// [pos]가 굴리는 뷰포트 안의 **행 슬리버**(가상화 목록). 깔린 행의 실제 자리를 물을 수
/// 있는 유일한 창구다. 목록 여백처럼 그 위를 감싼 슬리버는 지나쳐 안쪽을 찾는다.
RenderSliverMultiBoxAdaptor? _rowSliverOf(ScrollPosition pos) {
  final root = pos.context.storageContext.findRenderObject();
  if (root == null) return null;
  RenderSliverMultiBoxAdaptor? found;
  void visit(RenderObject node) {
    if (found != null) return;
    if (node is RenderSliverMultiBoxAdaptor) {
      found = node;
      return;
    }
    node.visitChildren(visit);
  }

  visit(root);
  return found;
}

/// [box]가 스크롤 방향으로 차지하는 길이.
double _mainExtentOf(RenderBox box, Axis axis) =>
    axis == Axis.vertical ? box.size.height : box.size.width;

/// 어림 착지를 시도할 자리(어림 위치에서 화면 높이의 몇 배만큼 비켜설지).
/// 한 번의 요청에 쓸 수 있는 프레임 수. 어림이 매 프레임 나아지는 동안 같은 자리를 다시
/// 겨누므로([CursorRevealMixin._settleReveal]) 프레임 수로 한도를 둔다.
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

  /// 아직 만들어지지 않은 커서 행을 향해 **한 걸음** 옮긴다. 실제로 움직였으면 true,
  /// 더 갈 데가 없으면 false(되풀이를 멈추는 신호다).
  ///
  /// 기본 구현은 깔려 있는 행들을 재서 어림하므로([measuredRowOffset]) 한 걸음에 닿지
  /// 못하고 여러 프레임에 걸쳐 수렴한다. 게다가 그 한 걸음이 사이의 행을 모두 만들며
  /// 지나가 먼 거리일수록 느리다. **행 위치를 스스로 아는 목록은 이를 덮어써** 사이를
  /// 건너뛰고 한 걸음에 닿을 수 있다.
  bool stepTowardRow(int index) =>
      jumpNearRow(revealScrollController, index, revealRowCount);

  void requestCursorReveal() {
    cursorReveal.request();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _settleReveal(_maxRevealFrames),
    );
  }

  /// 이 프레임에 커서 행이 요청을 받아 갔으면 할 일이 없다. 아무도 받지 않았다면 그 행이
  /// 아직 만들어지지 않은 것이므로, 그 근처로 옮겨 만들어 내고 다음 프레임에 다시 본다.
  ///
  /// **어떻게 옮길지는 [stepTowardRow]가 정한다** — 기본 구현은 한 번 옮길
  /// 때마다 깔린 구간이 목표 쪽으로 가므로 다음 번 어림이 더 정확해지고, 그래서 되풀이가
  /// 목표로 수렴한다. 더 옮길 데가 없는데도 그 행이 없거나, 갈 곳이 없거나, 프레임을 다
  /// 쓰면 요청을 접는다.
  void _settleReveal(int framesLeft) {
    if (!mounted || !cursorReveal.isPending) return;
    final index = cursorRowIndex;
    if (index < 0 || framesLeft <= 0 || !stepTowardRow(index)) {
      cursorReveal.serve();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _settleReveal(framesLeft - 1),
    );
  }
}
