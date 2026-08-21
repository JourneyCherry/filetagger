import 'package:filetagger/presentation/widgets/keyword_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _open(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showKeywordDialog(
              context,
              title: '키워드 만들기',
              confirmLabel: '만들기',
            ),
            child: const Text('열기'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('열자마자 친 이름이 이름 칸에 들어간다', (tester) async {
    await _open(tester);

    // 포커스를 손으로 옮기지 않고 그대로 친다 — 이름 칸이 스스로 포커스를 쥐고
    // 있어야 입력이 붙는다. 다이얼로그를 통째로 감싸는 Focus가 있으면 그쪽이
    // 첫 포커스를 가져가 이 입력이 어디에도 닿지 않는다.
    tester.testTextInput.enterText('만화');
    await tester.pump();

    expect(find.widgetWithText(TextField, '만화'), findsOneWidget);
  });

  testWidgets('ESC로 닫으면 이름을 돌려주지 않는다', (tester) async {
    await _open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('키워드 만들기'), findsNothing);
  });
}
