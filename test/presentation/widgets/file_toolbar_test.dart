import 'package:filetagger/domain/entities/file_filter.dart';
import 'package:filetagger/domain/entities/file_grouping.dart';
import 'package:filetagger/domain/entities/file_sort.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/domain/entities/workspace_view_settings.dart';
import 'package:filetagger/domain/repositories/view_settings_repository.dart';
import 'package:filetagger/presentation/providers/file_view_provider.dart';
import 'package:filetagger/presentation/providers/tag_provider.dart';
import 'package:filetagger/presentation/tag_visuals.dart';
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
bool isEditing(WidgetTester tester) =>
    find.byType(TextField).evaluate().isNotEmpty;

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
            // 필터 줄만 남겨 칩↔텍스트 동작을 분리해 본다(프리셋·정렬·그룹 줄의 칩이
            // 손잡이·x 아이콘 수나 줄 위치를 흔들지 않도록).
            child: FileToolbar(
              showPresets: false,
              showSort: false,
              showGroup: false,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 그룹 줄만 남긴 도구모음을 띄운다. [grouping]을 주지 않으면 기본(폴더 계층)이다.
Future<void> pumpGroupToolbar(
  WidgetTester tester, {
  FileGrouping? grouping,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        viewSettingsRepositoryProvider.overrideWithValue(
          _FakeStore(
            grouping == null
                ? const WorkspaceViewSettings()
                : WorkspaceViewSettings(grouping: grouping),
          ),
        ),
        tagDefinitionsProvider.overrideWith((ref) => Stream.value([_rating])),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            child: FileToolbar(
              showPresets: false,
              showFilter: false,
              showSort: false,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 필터·정렬·그룹이 모두 차 있는 도구모음을 띄우고, 상태를 읽을 컨테이너를 준다.
Future<ProviderContainer> pumpFullToolbar(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [
      viewSettingsRepositoryProvider.overrideWithValue(
        _FakeStore(
          const WorkspaceViewSettings(
            filter: FileFilter(
              conditions: [FilterCondition(tagDefinitionId: 1)],
            ),
            sort: FileSortOrder(keys: [SortKey(tagDefinitionId: 1)]),
            grouping: kDefaultGrouping,
          ),
        ),
      ),
      tagDefinitionsProvider.overrideWith((ref) => Stream.value([_rating])),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            // 프리셋 줄은 빼, 남은 세 줄의 '모두 지우기' 버튼이 순서대로 놓이게 한다.
            child: FileToolbar(showPresets: false),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
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

    // 칩이 차지하지 않은 오른쪽 빈 곳(줄 끝 버튼들보다는 왼쪽)을 누른다.
    final chip = tester.getRect(find.byType(FilterConditionChip));
    await tester.tapAt(Offset(chip.right + 8, chip.center.dy));
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
    // 칩이 차지하지 않은 오른쪽 빈 곳(줄 끝 버튼들보다는 왼쪽)을 누른다.
    final chip = tester.getRect(find.byType(FilterConditionChip));
    await tester.tapAt(Offset(chip.right + 8, chip.center.dy));
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
    expect(find.text(kEmptyQueryLabel), findsOneWidget);
  });

  desktopTestWidgets('그룹 줄은 기본(폴더 계층) 키를 칩으로 그린다', (tester) async {
    await pumpGroupToolbar(tester);

    // 폴더 계층 키 하나가 칩(손잡이·x 포함)으로 보이고 텍스트 입력은 아니다.
    expect(isEditing(tester), isFalse);
    expect(find.text('폴더 계층'), findsOneWidget);
    expect(find.byIcon(Icons.drag_indicator), findsOneWidget);
    expect(find.byIcon(Icons.cancel), findsOneWidget);
  });

  desktopTestWidgets('그룹이 비면 편집 중이 아니어도 텍스트 입력을 낸다', (tester) async {
    await pumpGroupToolbar(tester, grouping: const FileGrouping());

    expect(isEditing(tester), isTrue);
    expect(find.text(kEmptyQueryLabel), findsOneWidget);
  });

  desktopTestWidgets('모두 지우기는 그 줄만 비운다', (tester) async {
    final container = await pumpFullToolbar(tester);
    // 필터·정렬·그룹 세 줄이 각자 지우기 버튼을 갖는다(프리셋 줄은 없음).
    expect(find.byIcon(Icons.clear_all), findsNWidgets(3));

    await tester.tap(find.byIcon(Icons.clear_all).first);
    await tester.pumpAndSettle();

    expect(container.read(fileFilterProvider).isEmpty, isTrue);
    expect(container.read(fileSortProvider).isEmpty, isFalse);
    expect(container.read(groupingProvider).isEmpty, isFalse);
  });

  desktopTestWidgets('지울 것이 없는 줄의 지우기 버튼은 비활성이다', (tester) async {
    await pumpToolbar(tester, const FileFilter());

    final button = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.clear_all),
        matching: find.byType(IconButton),
      ),
    );
    expect(button.onPressed, isNull);
  });
}
