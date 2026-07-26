import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 다이얼로그를 ESC 키로 닫히게 감싼다.
///
/// 콤보박스 등 다이얼로그 내부 위젯이 처음부터 포커스를 갖지 않을 수 있어,
/// [Focus]`(autofocus)`로 포커스를 다이얼로그 안으로 넣어 ESC가 이 단축키까지
/// 확실히 전파되게 한다. 콤보박스 후보가 열려 있으면 그쪽이 ESC를 먼저 소비한다.
Widget escDismissible(BuildContext context, Widget dialog) {
  return CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.escape): () =>
          Navigator.of(context).maybePop(),
    },
    child: Focus(autofocus: true, child: dialog),
  );
}

/// 다이얼로그 본문이 화면 밖으로 넘치지 않도록 남겨 두는 여백.
///
/// 다이얼로그가 화면 가장자리에 두는 자기 여백과, 세로로는 제목·버튼 줄이 차지하는
/// 몫까지 미리 뺀다. 데스크톱 창에서는 요청 크기가 늘 이보다 작아 아무 영향이 없고,
/// 좁은 화면(모바일·작게 줄인 창)에서만 요청 크기를 깎는다.
const double _dialogWidthMargin = 96;
const double _dialogHeightMargin = 200;

/// 다이얼로그 본문의 크기 상자.
///
/// [width]·[height]는 **원하는 크기**이고, 화면이 좁으면 그만큼 줄어든다. 고정 크기를
/// 그대로 쓰면 좁은 화면에서 본문이 잘려 나가므로 다이얼로그 본문은 이걸 쓴다.
Widget dialogContentBox(
  BuildContext context, {
  required double width,
  double? height,
  required Widget child,
}) {
  final screen = MediaQuery.sizeOf(context);
  return SizedBox(
    width: _atMost(width, screen.width - _dialogWidthMargin),
    height: height == null
        ? null
        : _atMost(height, screen.height - _dialogHeightMargin),
    child: child,
  );
}

/// [desired]를 [available]까지만 줄인다. 화면이 여백보다도 작은 극단에서 음수가
/// 되지 않도록 [desired]를 하한으로 두지 않고 0 아래로만 내려가지 않게 막는다.
double _atMost(double desired, double available) =>
    available <= 0 ? desired : (desired < available ? desired : available);
