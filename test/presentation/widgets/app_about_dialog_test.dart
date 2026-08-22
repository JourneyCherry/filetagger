import 'package:filetagger/l10n/app_localizations.dart';
import 'package:filetagger/core/constants.dart';
import 'package:filetagger/presentation/commands/app_commands.dart';
import 'package:filetagger/presentation/widgets/app_about_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/l10n.dart';

/// 정보 다이얼로그를 띄운 상태의 앱. 다이얼로그는 Navigator 아래에서만 열리므로
/// 버튼을 거친다.
Future<void> pumpAbout(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showAppAboutDialog(context),
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
  testWidgets('정보는 명령 라벨을 제목으로, 앱 이름을 본문에 보인다', (tester) async {
    await pumpAbout(tester);

    expect(
      find.text(commandOf(AppCommandId.about).label(koL10n)),
      findsOneWidget,
    );
    expect(find.text(appDisplayName), findsOneWidget);
  });

  testWidgets('버전 줄에 배포 형태를 함께 보인다', (tester) async {
    // 테스트는 주입 없이 도는 실행이라 직접 빌드와 같은 상태다 — 채널이 포터블로
    // 눕고, 그 실행은 정말로 설정을 실행 파일 옆에 두므로 그대로 적어도 맞다.
    await pumpAbout(tester);

    expect(find.textContaining('포터블'), findsOneWidget);
    expect(find.textContaining('설치판'), findsNothing);
    // 빌드 종류(개발 빌드 등)는 어느 빌드에서도 적지 않는다.
    expect(find.textContaining('개발'), findsNothing);
  });

  testWidgets('라이선스 화면으로 넘어간다', (tester) async {
    // 라이선스 원문은 프레임워크 내장 화면이 맡는다. 여기선 그 입구가 살아 있는지만
    // 본다(목록 내용은 빌드가 모으는 것이라 테스트 환경에 없다).
    await pumpAbout(tester);
    await tester.tap(find.text('오픈소스 라이선스'));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('라이선스 화면은 ESC로 닫히고 정보 다이얼로그가 남는다', (tester) async {
    // 전체 화면 라우트라 프레임워크는 ESC를 받아 주지 않는다 — 그래서 이 자리는
    // 프레임워크 헬퍼 대신 직접 라우트를 밀어 넣어 ESC로 닫는 길을 붙였다.
    await pumpAbout(tester);
    await tester.tap(find.text('오픈소스 라이선스'));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsNothing);
    expect(find.text(appDisplayName), findsOneWidget);
  });
}
