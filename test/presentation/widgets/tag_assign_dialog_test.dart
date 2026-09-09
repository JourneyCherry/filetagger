import 'package:filetagger/l10n/app_localizations.dart';
import 'package:filetagger/domain/entities/assigned_tag.dart';
import 'package:filetagger/domain/entities/tag_assignment.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/presentation/providers/file_view_provider.dart';
import 'package:filetagger/presentation/providers/tag_provider.dart';
import 'package:filetagger/presentation/widgets/tag_assign_dialog.dart';
import 'package:filetagger/presentation/widgets/tag_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/desktop.dart';

/// 다이얼로그 높이를 넘길 만큼 많은 공통 태그. 수가 적으면 스크롤 자체가 생기지
/// 않아 이 테스트가 아무것도 지키지 못한다.
final _definitions = [
  for (var i = 1; i <= 12; i++)
    TagDefinition(id: i, name: '태그$i', valueType: TagValueType.text),
];

/// 선택한 두 노드에 모든 태그가 똑같이 걸린 상태(다중 선택의 '공통 부여').
final _assignments = [
  for (final def in _definitions)
    for (final fileNodeId in [1, 2])
      AssignedTag(
        assignment: TagAssignment(
          fileNodeId: fileNodeId,
          tagDefinitionId: def.id!,
          value: '값',
        ),
        definition: def,
      ),
];

Future<void> _openDialog(
  WidgetTester tester, {
  List<int> fileNodeIds = const [1, 2],
  List<int> displayOrder = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tagDefinitionsProvider.overrideWith(
          (ref) => Stream.value(_definitions),
        ),
        assignmentsProvider.overrideWith((ref) => Stream.value(_assignments)),
        tagDisplayOrderProvider.overrideWithValue(displayOrder),
      ],
      child: MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showTagAssignDialog(
                context,
                fileNodeIds: fileNodeIds,
                title: '선택한 항목',
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

void main() {
  desktopTestWidgets('부여된 태그가 많아도 태그 추가 영역은 다이얼로그 안에 남는다', (tester) async {
    await _openDialog(tester);

    final dialog = tester.getRect(find.byType(AlertDialog));
    final add = tester.getRect(find.text('태그 추가'));

    expect(add.bottom, lessThanOrEqualTo(dialog.bottom));
  });

  desktopTestWidgets('태그 추가 영역은 부여 목록의 스크롤 안에 들어가지 않는다', (tester) async {
    await _openDialog(tester);

    // 스크롤 밖에 있어야 부여 목록을 아무리 내려도 자리를 지킨다.
    expect(
      find.ancestor(
        of: find.text('태그 추가'),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
  });

  desktopTestWidgets('태그를 고르면 값 입력칸이 포커스를 받는다', (tester) async {
    await _openDialog(tester);

    // 콤보를 열어 태그 하나를 고른다(자동완성으로 골랐을 때와 같은 경로다).
    await tester.tap(find.byType(DropdownMenu<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MenuItemButton, '태그1').first);
    await tester.pumpAndSettle();

    // 값 칸이 포커스를 쥐고 있어야 곧바로 값을 칠 수 있다(Tab을 배울 필요가 없다).
    expect(_valueField(tester).focusNode?.hasFocus, isTrue);
  });

  desktopTestWidgets('부여 목록은 목록 행과 같은 표시 순서를 따른다', (tester) async {
    // 저장된 순서가 일부만 덮는 상태. 순서에 없는 태그(새로 만든 태그가 이 자리다)는
    // 앞에 서고, 실린 태그는 실린 차례대로 뒤따른다 — 목록 행 칩과 같은 규칙이다.
    await _openDialog(
      tester,
      fileNodeIds: const [1],
      displayOrder: const [3, 1, 2],
    );

    expect(_chipNames(tester), [
      for (var i = 4; i <= 12; i++) '태그$i',
      '태그3',
      '태그1',
      '태그2',
    ]);
  });

  desktopTestWidgets('다중 선택의 정의별 묶음도 같은 표시 순서를 따른다', (tester) async {
    await _openDialog(tester, displayOrder: const [3, 1, 2]);

    expect(_chipNames(tester), [
      for (var i = 4; i <= 12; i++) '태그$i',
      '태그3',
      '태그1',
      '태그2',
    ]);
  });
}

/// 부여 목록에 놓인 칩을 화면에 서는 차례대로 이름만 뽑는다. 다중 선택에서는
/// 정의마다 대표 칩이 하나씩이라 같은 함수로 묶음 순서를 본다.
List<String> _chipNames(WidgetTester tester) => [
  for (final chip in tester.widgetList<AssignedTagChip>(
    find.byType(AssignedTagChip),
  ))
    chip.tag.definition.name,
];

/// 추가 영역의 값 입력칸. 라벨로 짚어 부여 목록의 다른 입력들과 가른다.
TextField _valueField(WidgetTester tester) {
  final l10n = AppLocalizations.of(tester.element(find.byType(AlertDialog)));
  return tester.widget<TextField>(
    find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == l10n.tagValueField,
    ),
  );
}
