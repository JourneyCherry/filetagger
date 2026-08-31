import 'package:filetagger/domain/entities/system_tag.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/domain/entities/workspace_view_settings.dart';
import 'package:filetagger/domain/repositories/view_settings_repository.dart';
import 'package:filetagger/l10n/app_localizations.dart';
import 'package:filetagger/presentation/providers/file_view_provider.dart';
import 'package:filetagger/presentation/providers/l10n_provider.dart';
import 'package:filetagger/presentation/providers/tag_provider.dart';
import 'package:filetagger/presentation/widgets/name_tag_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/l10n.dart';

const _title = TagDefinition(id: 1, name: '제목', valueType: TagValueType.text);

class _FakeViewStore implements ViewSettingsRepository {
  _FakeViewStore(this._current);

  final WorkspaceViewSettings _current;

  @override
  Future<WorkspaceViewSettings> load() async => _current;

  @override
  Future<void> save(WorkspaceViewSettings settings) async {}
}

/// 이미 시스템 태그 하나가 세워진 상태로 다이얼로그를 연다 — 후보로 고를 수 있는지와,
/// 세워 둔 뒤 그것이 태그로 보이는지를 한자리에서 본다.
Future<ProviderContainer> _openDialog(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [
      appLocalizationsProvider.overrideWithValue(koL10n),
      tagDefinitionsProvider.overrideWith((ref) => Stream.value([_title])),
      viewSettingsRepositoryProvider.overrideWithValue(
        _FakeViewStore(
          WorkspaceViewSettings(
            grouping: kDefaultGrouping,
            nameSources: [SystemTag.extension.id],
          ),
        ),
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
              onPressed: () => showNameTagDialog(context),
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
  testWidgets('시스템 태그도 이름 출처 후보로 나온다', (tester) async {
    await _openDialog(tester);

    expect(find.text(_title.name), findsOneWidget);
    expect(find.text(koL10n.systemTagModifiedTime), findsOneWidget);
  });

  testWidgets('글자를 낼 수 없는 시스템 태그는 후보에서 빠진다', (tester) async {
    await _openDialog(tester);

    // 라벨은 값이 없어 고르면 늘 폴백한다 — 사용자 태그와 같은 판정을 받는다.
    expect(find.text(koL10n.systemTagKeyword), findsNothing);
    expect(find.text(koL10n.systemTagUnresolvedLink), findsNothing);
  });

  testWidgets('세워 둔 시스템 태그는 없는 태그가 아니라 그 태그로 보인다', (tester) async {
    await _openDialog(tester);

    expect(find.text(koL10n.systemTagExtension), findsOneWidget);
    expect(
      find.text(koL10n.sourceMissingTag(SystemTag.extension.id)),
      findsNothing,
    );
  });

  testWidgets('후보를 누르면 시스템 태그 id가 이름 출처에 실린다', (tester) async {
    final container = await _openDialog(tester);
    expect(container.read(nameSourcesProvider), [SystemTag.extension.id]);

    await tester.tap(find.text(koL10n.systemTagModifiedTime));
    await tester.pumpAndSettle();

    expect(container.read(nameSourcesProvider), [
      SystemTag.extension.id,
      SystemTag.modifiedTime.id,
    ]);
  });
}
