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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _author = TagDefinition(id: 1, name: '작가', valueType: TagValueType.link);

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
}
