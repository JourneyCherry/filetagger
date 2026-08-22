import 'package:filetagger/l10n/app_localizations.dart';
import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/node_kind.dart';
import 'package:filetagger/presentation/providers/file_view_provider.dart';
import 'package:filetagger/presentation/providers/thumbnail_provider.dart';
import 'package:filetagger/presentation/providers/workspace_provider.dart';
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

/// 폴더 [dir]의 대표 이미지가 [relPaths]일 때 겹쳐 쌓은 썸네일을 그리고, **그려진
/// 차례대로** 이미지 경로를 돌려준다(Stack은 나중 자식을 위에 그리므로 마지막이 맨 위).
/// 파일이 실제로 없어도 층 구조는 그대로 만들어지므로 임시 파일을 두지 않는다.
Future<List<String>> _stackedOrder(
  WidgetTester tester,
  List<String> relPaths,
) async {
  const dir = FileNode(path: 'album', kind: NodeKind.directory);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        workspaceRootProvider.overrideWith((ref) => 'root'),
        folderThumbnailIndexProvider.overrideWithValue({'album': relPaths}),
        // 태그 출처를 두지 않아 기본 썸네일(폴더=하위 대표)로 떨어뜨린다.
        thumbnailSourcesProvider.overrideWithValue(const []),
      ],
      child: const MaterialApp(
        home: Scaffold(body: FileThumbnail(node: dir, dimension: 100)),
      ),
    ),
  );
  return [
    for (final image in tester.widgetList<Image>(find.byType(Image)))
      _fileOf(image.image),
  ];
}

/// 표시 크기에 맞춘 디코딩([ResizeImage])에 싸인 파일 경로를 꺼낸다.
String _fileOf(ImageProvider provider) {
  final inner = provider is ResizeImage ? provider.imageProvider : provider;
  return (inner as FileImage).file.path;
}

void main() {
  testWidgets('겹쳐 쌓은 폴더 썸네일은 첫 장이 맨 위에 온다', (tester) async {
    final order = await _stackedOrder(tester, const [
      'album/1.png',
      'album/2.png',
      'album/3.png',
    ]);

    // 마지막에 그려진 것이 맨 위 — 고른 순서의 첫 장이어야 한다.
    expect(order.last, endsWith('1.png'));
    expect(order, hasLength(3));
  });

  testWidgets('상한보다 적게 쌓아도 맨 위 장은 똑바로 놓인다', (tester) async {
    // 층 표를 앞에서부터 쓰면 두 장일 때 똑바른 장이 하나도 없다.
    final order = await _stackedOrder(tester, const [
      'album/1.png',
      'album/2.png',
    ]);
    expect(order.last, endsWith('1.png'));

    final top = find.byWidget(
      tester.widgetList<Image>(find.byType(Image)).last,
    );
    final transforms = tester.widgetList<Transform>(
      find.ancestor(of: top, matching: find.byType(Transform)),
    );
    // 맨 위 장은 기울지도 밀리지도 않는다(회전·이동 둘 다 항등).
    expect(transforms, isNotEmpty);
    for (final transform in transforms) {
      expect(transform.transform.isIdentity(), isTrue);
    }
  });

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
