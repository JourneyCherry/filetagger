import 'package:filetagger/domain/entities/system_tag.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/domain/entities/workspace_view_settings.dart';
import 'package:filetagger/domain/repositories/view_settings_repository.dart';
import 'package:filetagger/l10n/app_localizations.dart';
import 'package:filetagger/presentation/providers/file_view_provider.dart';
import 'package:filetagger/presentation/providers/l10n_provider.dart';
import 'package:filetagger/presentation/tag_visuals.dart';
import 'package:filetagger/presentation/providers/tag_provider.dart';
import 'package:filetagger/presentation/widgets/subtitle_tag_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/l10n.dart';

const _author = TagDefinition(id: 1, name: '작가', valueType: TagValueType.text);

class _FakeViewStore implements ViewSettingsRepository {
  _FakeViewStore(this._current);

  final WorkspaceViewSettings _current;

  @override
  Future<WorkspaceViewSettings> load() async => _current;

  @override
  Future<void> save(WorkspaceViewSettings settings) async {}
}

Future<ProviderContainer> _openDialog(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [
      appLocalizationsProvider.overrideWithValue(koL10n),
      tagDefinitionsProvider.overrideWith((ref) => Stream.value([_author])),
      viewSettingsRepositoryProvider.overrideWithValue(
        _FakeViewStore(const WorkspaceViewSettings(grouping: kDefaultGrouping)),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showSubtitleTagDialog(context),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    ),
  );
  // 다이얼로그는 열리는 순간의 순서를 스냅숏으로 뜨므로, 저장소 로드가 끝난 뒤에
  // 연다 — 실제 앱에서도 폴더를 연 뒤라 이미 실려 있다.
  container.read(viewSettingsProvider);
  await tester.pumpAndSettle();

  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('시스템 태그도 부제 출처 후보로 나온다', (tester) async {
    await _openDialog(tester);

    expect(find.text(_author.name), findsOneWidget);
    expect(
      find.text(systemTagName(koL10n, SystemTag.imageWidth)),
      findsOneWidget,
    );
    // 라벨 시스템 태그는 이름 칸과 같은 판정으로 빠진다.
    expect(find.text(systemTagName(koL10n, SystemTag.keyword)), findsNothing);
  });

  testWidgets('후보를 누르면 시스템 태그 id가 부제 출처에 실린다', (tester) async {
    final container = await _openDialog(tester);
    expect(container.read(subtitleSourcesProvider), isEmpty);

    await tester.tap(find.text(systemTagName(koL10n, SystemTag.modifiedTime)));
    await tester.pumpAndSettle();

    expect(container.read(subtitleSourcesProvider), [
      SystemTag.modifiedTime.id,
    ]);
  });
}
