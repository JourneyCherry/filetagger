import 'package:filetagger/l10n/app_localizations.dart';
import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/node_kind.dart';
import 'package:filetagger/presentation/widgets/file_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 관리 폴더가 열려 있지 않으면 보일 이미지가 없어 늘 기본 아이콘으로 폴백한다 —
/// 폴백 크기만 재는 자리라 워크스페이스를 열지 않은 상태를 그대로 쓴다.
const _node = FileNode(path: 'memo.txt', kind: NodeKind.file);

/// [box] 크기의 프리뷰 영역에 폴백 아이콘을 그렸을 때의 글리프 크기.
Future<double> _fallbackIconSize(WidgetTester tester, Size box) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox.fromSize(
              size: box,
              child: const FileThumbnail(
                node: _node,
                expand: true,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return tester.widget<Icon>(find.byType(Icon)).size!;
}

void main() {
  testWidgets('프리뷰 폴백 아이콘은 세로로 눌린 영역 밖으로 나가지 않는다', (tester) async {
    const box = Size(600, 60);

    expect(
      await _fallbackIconSize(tester, box),
      lessThanOrEqualTo(box.shortestSide),
    );
  });

  testWidgets('영역이 넉넉하면 폴백 아이콘 크기는 상한에 머문다', (tester) async {
    // 상한이 없으면 큰 영역에서 아이콘만 끝없이 커진다.
    final roomy = await _fallbackIconSize(tester, const Size(600, 400));
    final roomier = await _fallbackIconSize(tester, const Size(700, 500));

    expect(roomy, roomier);
  });
}
