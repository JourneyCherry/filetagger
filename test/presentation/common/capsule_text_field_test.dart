import 'package:filetagger/presentation/common/capsule_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/desktop.dart';

/// 낱말 하나가 곧 값인, 가장 단순한 문법(필드의 동작만 보려는 것이라 문법은 최소로).
class _WordSyntax extends CapsuleSyntax<String> {
  const _WordSyntax();

  @override
  String? parse(String chunk) => _words.contains(chunk) ? chunk : null;

  @override
  String? format(String item) => item;

  @override
  bool isInvalid(String chunk) => false;

  @override
  Widget chip(String item) => Text(item);
}

const _words = ['작가', '캐릭터'];

/// 지금 친 조각으로 시작하는 낱말을 후보로 낸다.
CapsuleCompletions? _completionsAt(
  String text,
  int cursor,
  List<String> items,
) {
  if (cursor <= 0) return null;
  final start = text.lastIndexOf(' ', cursor - 1) + 1;
  final chunk = text.substring(start, cursor);
  if (chunk.isEmpty) return null;
  return CapsuleCompletions(
    replaceStart: start,
    replaceEnd: cursor,
    items: [
      for (final w in _words)
        if (w.startsWith(chunk))
          CapsuleCompletion(insertText: w, title: w, description: ''),
    ],
  );
}

/// 이 필드가 확정해 내보낸 값들(마지막 알림).
final _emitted = <String>[];

Future<void> _pump(WidgetTester tester) async {
  _emitted.clear();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CapsuleTextField<String>(
          syntax: const _WordSyntax(),
          items: const [],
          onChanged: (items) => _emitted
            ..clear()
            ..addAll(items),
          completionsAt: _completionsAt,
          hintText: '',
        ),
      ),
    ),
  );
}

/// 지금 필드에 들어 있는 원문.
String _text(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

void main() {
  desktopTestWidgets('자동완성 목록을 눌러 후보를 고를 수 있다', (tester) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField), '작');
    await tester.pumpAndSettle();
    expect(find.text('작가'), findsOneWidget, reason: '후보 목록이 떠 있어야 한다');

    // 누르는 순간 포커스가 풀리면 조각이 접히고 목록이 닫혀 손을 뗄 곳이 사라진다.
    await tester.tap(find.text('작가'));
    await tester.pumpAndSettle();

    expect(_text(tester), '작가');
  });

  desktopTestWidgets('목록을 눌러도 입력 포커스는 필드에 남는다', (tester) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField), '작');
    await tester.pumpAndSettle();
    await tester.tap(find.text('작가'));
    await tester.pumpAndSettle();

    // 포커스가 남아야 이어 쳐서 조건을 마저 짤 수 있다(고르고 나면 값·연산자가 남는다).
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode!.hasFocus, isTrue);
  });

  desktopTestWidgets('필드 밖을 누르면 조각이 접혀 값으로 확정된다', (tester) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField), '작가');
    await tester.pumpAndSettle();
    expect(_emitted, isEmpty, reason: '커서가 놓인 조각은 아직 확정이 아니다');

    // 탭 영역 밖(빈 바닥)을 누르면 포커스를 놓고, 그때 조각이 접힌다.
    await tester.tapAt(const Offset(400, 500));
    await tester.pumpAndSettle();

    expect(_emitted, ['작가']);
  });
}
