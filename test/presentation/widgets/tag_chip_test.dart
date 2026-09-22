import 'package:filetagger/l10n/app_localizations.dart';
import 'package:filetagger/domain/entities/assigned_tag.dart';
import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/node_kind.dart';
import 'package:filetagger/domain/entities/tag_assignment.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/presentation/providers/file_node_provider.dart';
import 'package:filetagger/presentation/providers/node_reveal_provider.dart';
import 'package:filetagger/presentation/widgets/tag_chip.dart';
import 'package:flutter/gestures.dart' show kDoubleTapMinTime;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _author = TagDefinition(id: 1, name: '작가', valueType: TagValueType.link);

const _memo = TagDefinition(id: 2, name: '메모', valueType: TagValueType.text);

AssignedTag _text(String value) => AssignedTag(
  assignment: TagAssignment(
    id: 2,
    fileNodeId: 1,
    tagDefinitionId: 2,
    value: value,
  ),
  definition: _memo,
);

/// 값 칸 글자에 **실제로 그려지는** 스타일(캡슐이 깔아 둔 기본 스타일까지 합쳐진 것).
/// 위젯의 `style`만 보면 물려받는 글자색이 빠져 밑줄색과 맞대 볼 수 없다.
TextStyle? _valueStyle(WidgetTester tester, String value) =>
    tester.renderObject<RenderParagraph>(find.text(value)).text.style;

/// 값 칸 글자에 밑줄이 걸려 있는지(따라갈 수 있는 값이라는 표식).
bool _valueUnderlined(WidgetTester tester, String value) =>
    _valueStyle(tester, value)?.decoration == TextDecoration.underline;

const _target = FileNode(id: 7, path: '작가 A', kind: NodeKind.keyword);

AssignedTag _link(String? value, {bool unresolved = false}) => AssignedTag(
  assignment: TagAssignment(
    id: 1,
    fileNodeId: 1,
    tagDefinitionId: 1,
    value: value,
    valueUnresolved: unresolved,
  ),
  definition: _author,
);

Future<void> _pump(
  WidgetTester tester,
  AssignedTag tag, {
  VoidCallback? onPressed,
  ProviderContainer? container,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container:
          container ??
          ProviderContainer(
            overrides: [
              fileNodesByIdProvider.overrideWithValue(const {7: _target}),
            ],
          ),
      child: MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: AssignedTagChip(tag: tag, onPressed: onPressed),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('해결된 링크는 대상 이름을 보이고 더블탭으로 그 노드로 간다', (tester) async {
    final container = ProviderContainer(
      overrides: [
        fileNodesByIdProvider.overrideWithValue(const {7: _target}),
      ],
    );
    addTearDown(container.dispose);

    await _pump(tester, _link('7'), container: container);

    expect(find.text('작가 A'), findsOneWidget);
    expect(find.byIcon(Icons.link_off), findsNothing);

    await tester.tap(find.byType(AssignedTagChip));
    await tester.pump(kDoubleTapMinTime);
    await tester.tap(find.byType(AssignedTagChip));
    await tester.pumpAndSettle();

    expect(container.read(nodeRevealProvider)?.nodeId, 7);
  });

  testWidgets('가져온 미해결 링크는 원문을 보이고 표식이 붙는다', (tester) async {
    // 값을 감추면 무엇을 가리키려던 링크인지 알 수 없어 재연결할 근거가 사라진다.
    await _pump(tester, _link('작가/홍길동', unresolved: true));

    expect(find.text('작가/홍길동'), findsOneWidget);
    expect(find.byIcon(Icons.link_off), findsOneWidget);
  });

  testWidgets('대상이 떠 버린 링크는 없음 표식으로 두되 미해결로 그린다', (tester) async {
    // 뜻 없는 옛 id를 그대로 보이지 않는다.
    await _pump(tester, _link('999'));

    expect(find.text('(없음)'), findsOneWidget);
    expect(find.byIcon(Icons.link_off), findsOneWidget);
  });

  testWidgets('미해결 링크의 더블탭은 이동이 아니라 재연결(값 편집)로 간다', (tester) async {
    final container = ProviderContainer(
      overrides: [
        fileNodesByIdProvider.overrideWithValue(const {7: _target}),
      ],
    );
    addTearDown(container.dispose);
    var edits = 0;

    await _pump(
      tester,
      _link('999'),
      onPressed: () => edits++,
      container: container,
    );

    await tester.tap(find.byType(AssignedTagChip));
    await tester.pump(kDoubleTapMinTime);
    await tester.tap(find.byType(AssignedTagChip));
    await tester.pumpAndSettle();

    expect(edits, greaterThan(0));
    // 갈 곳이 없으므로 이동 신호는 나가지 않는다.
    expect(container.read(nodeRevealProvider), isNull);
  });

  testWidgets('값이 웹 주소인 텍스트 태그는 밑줄로 따라갈 수 있음을 알린다', (tester) async {
    await _pump(tester, _text('https://example.com/a'));

    expect(_valueUnderlined(tester, 'https://example.com/a'), isTrue);
    expect(find.byType(Tooltip), findsOneWidget);
  });

  testWidgets('밑줄은 글자색으로 긋는다', (tester) async {
    // 비워 두면 테마 기본색으로 그어져 태그 색 위의 글자와 밑줄이 따로 논다.
    await _pump(tester, _text('https://example.com/a'));

    final style = _valueStyle(tester, 'https://example.com/a');
    expect(style?.color, isNotNull);
    expect(style?.decorationColor, style?.color);
  });

  testWidgets('주소가 아닌 텍스트 값은 표식 없이 그대로 둔다', (tester) async {
    // 스킴이 없는 값에 밑줄을 주면 눌러도 아무 데도 가지 않는 표식이 된다.
    await _pump(tester, _text('example.com'));

    expect(_valueUnderlined(tester, 'example.com'), isFalse);
    expect(find.byType(Tooltip), findsNothing);
  });

  testWidgets('주소가 아닌 텍스트 값의 더블탭은 값 편집으로 간다', (tester) async {
    // 따라갈 것이 없으면 두 번째 탭도 단일 탭과 같은 곳으로 떨어져야 한다.
    var edits = 0;
    await _pump(tester, _text('그냥 메모'), onPressed: () => edits++);

    await tester.tap(find.byType(AssignedTagChip));
    await tester.pump(kDoubleTapMinTime);
    await tester.tap(find.byType(AssignedTagChip));
    await tester.pumpAndSettle();

    expect(edits, greaterThan(0));
  });
}
