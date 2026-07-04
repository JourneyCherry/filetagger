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
