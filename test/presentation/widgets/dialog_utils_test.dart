import 'package:filetagger/presentation/widgets/dialog_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// [wrap]이 감싼 페이지를 push한 앱.
Future<void> _pushPage(
  WidgetTester tester,
  Widget Function(Widget page) wrap,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    wrap(const Scaffold(body: Center(child: Text('페이지')))),
              ),
            ),
            child: const Text('열기'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
  expect(find.text('페이지'), findsOneWidget);
}

Future<void> _pressEsc(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('감싼 전체 화면은 ESC로 닫힌다', (tester) async {
    await _pushPage(tester, escDismissiblePage);
    await _pressEsc(tester);

    expect(find.text('페이지'), findsNothing);
  });

  testWidgets('감싸지 않은 전체 화면은 ESC로 닫히지 않는다', (tester) async {
    // 이 헬퍼가 왜 있는지를 못박는 대조군. 프레임워크가 ESC로 닫아 주는 것은
    // 배리어를 눌러 닫히는 라우트(다이얼로그)뿐이라, 페이지 라우트는 그냥 두면
    // ESC가 아무 일도 하지 않는다.
    await _pushPage(tester, (page) => page);
    await _pressEsc(tester);

    expect(find.text('페이지'), findsOneWidget);
  });

  testWidgets('다이얼로그는 감싸지 않아도 ESC로 닫힌다', (tester) async {
    // 다이얼로그에 이 헬퍼를 다시 씌우지 않도록 남기는 가드레일. 씌우면 안의
    // 입력이 첫 포커스를 빼앗긴다.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const AlertDialog(title: Text('다이얼로그')),
              ),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('다이얼로그'), findsOneWidget);

    await _pressEsc(tester);

    expect(find.text('다이얼로그'), findsNothing);
  });
}
