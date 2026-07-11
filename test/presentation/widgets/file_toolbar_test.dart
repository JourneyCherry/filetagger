import 'package:filetagger/domain/entities/file_filter.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/domain/entities/workspace_view_settings.dart';
import 'package:filetagger/domain/repositories/view_settings_repository.dart';
import 'package:filetagger/presentation/providers/file_view_provider.dart';
import 'package:filetagger/presentation/providers/tag_provider.dart';
import 'package:filetagger/presentation/widgets/file_toolbar.dart';
import 'package:filetagger/presentation/widgets/filter_condition_chip.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _rating = TagDefinition(
  id: 1,
  name: '평점',
  valueType: TagValueType.number,
);

/// 주어진 설정을 그대로 돌려주는 가짜 저장소(저장은 버린다).
class _FakeStore implements ViewSettingsRepository {
  _FakeStore(this._current);

  final WorkspaceViewSettings _current;

  @override
  Future<WorkspaceViewSettings> load() async => _current;

  @override
  Future<void> save(WorkspaceViewSettings settings) async {}
}

/// 조건 줄이 지금 텍스트 입력을 그리고 있는지(아니면 조건 칩을 그린다).
bool isEditing(WidgetTester tester) => find.byType(TextField).evaluate().isNotEmpty;

Future<void> pumpToolbar(WidgetTester tester, FileFilter filter) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        viewSettingsRepositoryProvider.overrideWithValue(
          _FakeStore(WorkspaceViewSettings(filter: filter)),
        ),
        tagDefinitionsProvider.overrideWith((ref) => Stream.value([_rating])),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            child: FileToolbar(showSort: false),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 텍스트 입력은 데스크톱에서만 나므로 그 플랫폼으로 못박고 본다. 되돌리기는 테스트
/// 본문 안에서 해야 한다(프레임워크가 본문 직후에 전역 디버그 변수를 검사한다).
void desktopTestWidgets(String description, WidgetTesterCallback body) {
  testWidgets(description, (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await body(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

void main() {
  desktopTestWidgets('조건이 있고 편집 중이 아니면 조건 칩을 그린다', (tester) async {
    await pumpToolbar(
      tester,
      const FileFilter(conditions: [FilterCondition(tagDefinitionId: 1)]),
    );

    expect(isEditing(tester), isFalse);
    // 칩에는 순서 변경 손잡이와 삭제 버튼이 함께 붙는다.
    expect(find.byIcon(Icons.drag_indicator), findsOneWidget);
    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(find.byType(FilterConditionChip), findsOneWidget);
  });

  desktopTestWidgets('칩 줄의 빈 곳을 누르면 텍스트 입력이 그 자리에 들어선다', (tester) async {
    await pumpToolbar(
      tester,
      const FileFilter(conditions: [FilterCondition(tagDefinitionId: 1)]),
    );
    expect(isEditing(tester), isFalse);

    // 칩이 차지하지 않은 오른쪽 끝을 누른다.
    final row = tester.getRect(find.byType(FileToolbar));
    await tester.tapAt(Offset(row.right - 64, row.top + 8));
    await tester.pumpAndSettle();

    expect(isEditing(tester), isTrue);
    // 들어서면서 포커스를 가져가, 곧바로 이어 칠 수 있다.
    final node = tester.widget<TextField>(find.byType(TextField)).focusNode;
    expect(node?.hasFocus, isTrue);
    // 확정된 조건은 텍스트 안에서도 칩(캡슐)으로 남는다.
    expect(find.byType(FilterConditionChip), findsOneWidget);
  });

  desktopTestWidgets('포커스를 잃으면 다시 조건 칩으로 돌아온다', (tester) async {
    await pumpToolbar(
      tester,
      const FileFilter(conditions: [FilterCondition(tagDefinitionId: 1)]),
    );
    final row = tester.getRect(find.byType(FileToolbar));
    await tester.tapAt(Offset(row.right - 64, row.top + 8));
    await tester.pumpAndSettle();
    expect(isEditing(tester), isTrue);

    tester.widget<TextField>(find.byType(TextField)).focusNode!.unfocus();
    await tester.pumpAndSettle();

    expect(isEditing(tester), isFalse);
    expect(find.byIcon(Icons.drag_indicator), findsOneWidget);
  });

  desktopTestWidgets('조건이 없으면 편집 중이 아니어도 텍스트 입력을 낸다', (tester) async {
    await pumpToolbar(tester, const FileFilter());

    expect(isEditing(tester), isTrue);
    expect(find.text('태그 이름으로 조건 입력'), findsOneWidget);
  });
}
