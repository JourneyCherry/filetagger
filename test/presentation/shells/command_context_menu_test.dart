import 'package:filetagger/l10n/app_localizations.dart';
import 'package:filetagger/presentation/commands/app_commands.dart';
import 'package:filetagger/presentation/commands/command_scope.dart';
import 'package:filetagger/presentation/shells/command_context_menu.dart';
import 'package:filetagger/presentation/shells/menu_model.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/l10n.dart';

/// 메뉴를 띄우는 버튼 하나짜리 화면. 컨텍스트 메뉴는 오버레이가 필요해
/// [MaterialApp] 안에서 연다.
Future<void> _pumpMenu(
  WidgetTester tester, {
  required List<MenuNode> items,
  required CommandHandlers handlers,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => Align(
            alignment: Alignment.topLeft,
            child: TextButton(
              onPressed: () => showCommandContextMenu(
                context: context,
                globalPosition: const Offset(20, 20),
                handlers: handlers,
                items: items,
              ),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
}

/// 포인터를 [finder] 위로 옮긴다(하위 메뉴는 호버로 펼쳐진다).
Future<void> _hover(WidgetTester tester, Finder finder) async {
  final pointer = TestPointer(1, PointerDeviceKind.mouse);
  await tester.sendEventToBinding(pointer.hover(tester.getCenter(finder)));
  await tester.pumpAndSettle();
}

void main() {
  final create = commandOf(AppCommandId.createKeyword).label(koL10n);
  final edit = commandOf(AppCommandId.editKeyword).label(koL10n);

  testWidgets('하위 메뉴는 호버만으로 펼쳐진다', (tester) async {
    await _pumpMenu(
      tester,
      items: const [
        MenuSubmenu('키워드', [MenuCommand(AppCommandId.createKeyword)]),
      ],
      handlers: CommandHandlers(createKeyword: () {}),
    );

    expect(find.text('키워드'), findsOneWidget);
    expect(find.text(create), findsNothing);

    await _hover(tester, find.text('키워드'));

    expect(find.text(create), findsOneWidget);
  });

  testWidgets('하위 메뉴 밖으로 나가면 하위 메뉴만 닫히고 부모는 남는다', (tester) async {
    await _pumpMenu(
      tester,
      items: const [
        MenuSubmenu('키워드', [MenuCommand(AppCommandId.createKeyword)]),
        MenuCommand(AppCommandId.assignTags),
      ],
      handlers: CommandHandlers(createKeyword: () {}, assignTags: () {}),
    );

    await _hover(tester, find.text('키워드'));
    expect(find.text(create), findsOneWidget);

    await _hover(
      tester,
      find.text(commandOf(AppCommandId.assignTags).label(koL10n)),
    );

    expect(find.text(create), findsNothing);
    // 부모 메뉴는 그대로 열려 있다.
    expect(find.text('키워드'), findsOneWidget);
  });

  testWidgets('하위 메뉴에서 고르면 그 명령이 실행되고 메뉴가 모두 닫힌다', (tester) async {
    var ran = 0;
    await _pumpMenu(
      tester,
      items: const [
        MenuSubmenu('키워드', [MenuCommand(AppCommandId.createKeyword)]),
      ],
      handlers: CommandHandlers(createKeyword: () => ran++),
    );

    await _hover(tester, find.text('키워드'));
    await tester.tap(find.text(create));
    await tester.pumpAndSettle();

    expect(ran, 1);
    expect(find.text('키워드'), findsNothing);
  });

  testWidgets('핸들러가 없는 항목은 자리를 지키되 눌리지 않는다', (tester) async {
    // 우클릭한 대상에 따라 항목이 사라졌다 나타나면 어디에 무엇이 있는지 외울 수 없다.
    var ran = 0;
    await _pumpMenu(
      tester,
      items: const [
        MenuSubmenu('키워드', [
          MenuCommand(AppCommandId.createKeyword),
          MenuCommand(AppCommandId.editKeyword),
        ]),
      ],
      handlers: CommandHandlers(createKeyword: () => ran++),
    );

    await _hover(tester, find.text('키워드'));
    expect(find.text(edit), findsOneWidget);

    await tester.tap(find.text(edit));
    await tester.pumpAndSettle();

    expect(ran, 0);
    // 비활성 항목을 눌러도 메뉴는 열린 채 남는다.
    expect(find.text(create), findsOneWidget);
  });

  testWidgets('체크 항목은 콜백으로 실행된다(명령 식별자가 없어도)', (tester) async {
    var picked = '';
    await _pumpMenu(
      tester,
      items: [
        MenuSubmenu('폴더 관리 옵션', [
          MenuChecked('내부 관리', checked: true, onSelected: () => picked = '관리'),
          const MenuChecked('재귀적으로 관리', checked: false),
        ]),
      ],
      handlers: const CommandHandlers(),
    );

    await _hover(tester, find.text('폴더 관리 옵션'));
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.tap(find.text('내부 관리'));
    await tester.pumpAndSettle();

    expect(picked, '관리');
  });

  testWidgets('첫 층의 명령은 그대로 실행된다', (tester) async {
    var ran = 0;
    await _pumpMenu(
      tester,
      items: const [
        MenuCommand(AppCommandId.createKeyword),
        MenuDivider(),
        MenuCommand(AppCommandId.editKeyword),
      ],
      handlers: CommandHandlers(createKeyword: () => ran++),
    );

    await tester.tap(find.text(create));
    await tester.pumpAndSettle();

    expect(ran, 1);
  });

  testWidgets('메뉴 밖을 누르면 닫히고 오버레이도 걷힌다', (tester) async {
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Align(
              alignment: Alignment.topLeft,
              child: TextButton(
                onPressed: () async {
                  await showCommandContextMenu(
                    context: context,
                    globalPosition: const Offset(20, 20),
                    handlers: const CommandHandlers(),
                    items: const [MenuCommand(AppCommandId.createKeyword)],
                  );
                  closed = true;
                },
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text(create), findsOneWidget);

    // 메뉴에서 멀찍이 떨어진 곳을 누른다.
    await tester.tapAt(const Offset(700, 500));
    await tester.pumpAndSettle();

    expect(find.text(create), findsNothing);
    // 닫히면 호출부의 기다림이 풀린다(오버레이가 걷혔다는 뜻).
    expect(closed, isTrue);
  });
}
