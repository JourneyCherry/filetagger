import 'package:filetagger/domain/entities/app_release.dart';
import 'package:filetagger/domain/repositories/release_repository.dart';
import 'package:filetagger/presentation/commands/app_commands.dart';
import 'package:filetagger/presentation/providers/update_provider.dart';
import 'package:filetagger/presentation/widgets/update_check_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 정해진 릴리즈를 내는 저장소 대역.
class _FakeReleases implements ReleaseRepository {
  _FakeReleases(this.version);

  final String? version;

  @override
  Future<AppRelease?> latestRelease() async => version == null
      ? null
      : AppRelease(
          version: version!,
          pageUrl: Uri.parse('https://example.test/r/$version'),
        );
}

/// 업데이트 확인 다이얼로그를 띄운 상태의 앱.
///
/// 테스트는 앱의 시작 절차를 타지 않아 버전이 채워지지 않으므로 판정이 '버전을 알 수
/// 없음'으로 떨어진다. 그래서 여기서는 다이얼로그가 결과를 어떻게 **보이는지**만
/// 확인한다 — 버전 비교 자체는 `CheckForUpdate`의 유닛테스트가 맡는다.
Future<void> _pumpDialog(WidgetTester tester, {String? latest}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        releaseRepositoryProvider.overrideWithValue(_FakeReleases(latest)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => showUpdateCheckDialog(context, ref),
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

void main() {
  testWidgets('명령 라벨을 제목으로 쓰고 결과를 한 줄로 알린다', (tester) async {
    await _pumpDialog(tester);

    expect(
      find.text(commandOf(AppCommandId.checkForUpdates).label),
      findsOneWidget,
    );
    // 버전이 채워지지 않은 실행이라 견줄 것이 없다는 답이 나와야 한다.
    expect(find.text('버전을 알 수 없습니다.'), findsOneWidget);
    // 보낼 곳이 없으면 닫기만 남는다.
    expect(find.widgetWithText(FilledButton, '릴리즈 페이지 열기'), findsNothing);
    expect(find.text('닫기'), findsOneWidget);
  });

  testWidgets('닫기로 닫힌다', (tester) async {
    await _pumpDialog(tester);
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });
}
