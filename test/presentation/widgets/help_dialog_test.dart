import 'package:filetagger/domain/entities/system_tag.dart';
import 'package:filetagger/presentation/commands/app_commands.dart';
import 'package:filetagger/presentation/help_topics.dart'
    show HelpTab, helpTopics, systemTagDescription;
import 'package:filetagger/presentation/usage_tips.dart';
import 'package:filetagger/presentation/widgets/help_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 도움말을 띄운 상태의 앱. 다이얼로그는 Navigator 아래에서만 열리므로 버튼을 거친다.
Future<void> pumpHelp(WidgetTester tester, {HelpTab? initial}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => initial == null
                ? showHelpDialog(context)
                : showHelpDialog(context, initial: initial),
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
  testWidgets('도움말은 탭을 모두 내걸고 사용법 탭을 먼저 보인다', (tester) async {
    await pumpHelp(tester);

    expect(find.text(commandOf(AppCommandId.help).label), findsOneWidget);
    for (final tab in HelpTab.values) {
      expect(find.text(tab.label), findsOneWidget, reason: tab.label);
    }
    // 첫 탭의 첫 개념 설명이 이미 보인다.
    expect(find.text(helpTopics.first.title), findsOneWidget);
  });

  testWidgets('기능과 단축키 탭은 명령 라벨과 단축키를 카탈로그에서 보인다', (tester) async {
    await pumpHelp(tester, initial: HelpTab.shortcuts);

    final rescan = commandOf(AppCommandId.rescan);
    expect(find.text(rescan.label), findsOneWidget);
    expect(find.text(shortcutLabel(rescan.shortcut!)), findsWidgets);
  });

  testWidgets('사용 팁 탭은 팁 제목을 늘어놓는다', (tester) async {
    await pumpHelp(tester, initial: HelpTab.tips);

    expect(find.text(usageTips.first.title), findsOneWidget);
  });

  testWidgets('시스템 태그 탭은 태그 이름과 설명을 보인다', (tester) async {
    await pumpHelp(tester, initial: HelpTab.systemTags);

    final first = SystemTag.values.first;
    expect(find.text(first.displayName), findsOneWidget);
    expect(find.text(systemTagDescription(first)), findsOneWidget);
  });

  testWidgets('탭 막대를 눌러 다른 탭으로 옮겨 갈 수 있다', (tester) async {
    // 메뉴가 탭을 따로 열어 주더라도, 열고 나서 옮겨 다니는 것이 이 다이얼로그를
    // 하나로 둔 이유다.
    await pumpHelp(tester);
    await tester.tap(find.text(HelpTab.tips.label));
    await tester.pumpAndSettle();

    expect(find.text(usageTips.first.title), findsOneWidget);
  });
}
