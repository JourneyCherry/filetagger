import 'package:filetagger/domain/entities/assigned_tag.dart';
import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/file_tree_node.dart';
import 'package:filetagger/domain/entities/node_kind.dart';
import 'package:filetagger/domain/entities/tag_assignment.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/presentation/commands/command_scope.dart';
import 'package:filetagger/presentation/common/file_list_view.dart';
import 'package:filetagger/presentation/common/flat_tree.dart';
import 'package:filetagger/presentation/providers/file_view_provider.dart';
import 'package:filetagger/presentation/providers/system_tag_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _node = FileNode(id: 1, path: '여행/풍경.jpg', kind: NodeKind.file);

AssignedTag _tag(int id) => AssignedTag(
  assignment: TagAssignment(
    id: id,
    fileNodeId: 1,
    tagDefinitionId: id,
    value: '값$id',
  ),
  definition: TagDefinition(
    id: id,
    name: '태그$id',
    valueType: TagValueType.text,
  ),
);

final _tags = [for (var i = 1; i <= 8; i++) _tag(i)];

final _tree = FlatTree(
  rows: const [
    TreeRow(
      item: FileTreeNode(_node, []),
      depth: 0,
      expandable: false,
      expanded: false,
      expandKey: '여행/풍경.jpg',
      nodeIndex: 0,
    ),
  ],
  nodes: const [_node],
);

final _log = <String>[];

Future<void> _pump(WidgetTester tester) async {
  _log.clear();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        flatTreeProvider.overrideWithValue(AsyncValue.data(_tree)),
        effectiveAssignmentsByFileProvider.overrideWithValue({1: _tags}),
        tagChipVisibleProvider.overrideWithValue((_) => true),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: CommandScope(
            handlers: CommandHandlers(
              cursorLeft: () => _log.add('cursorLeft'),
              cursorRight: () => _log.add('cursorRight'),
              moveCursorDown: () => _log.add('moveCursorDown'),
            ),
            child: SizedBox(
              width: 400,
              height: 300,
              child: FileListView(
                onTapNode: (_, _) {},
                onTapHeader: (_) {},
                onOpenNode: (_) {},
                onEditAssignment: (_) {},
                inlineEdit: true,
                onRemoveAssignment: (_) {},
                onAddTag: (_) {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

bool _scopeHasFocus() =>
    FocusManager.instance.primaryFocus?.debugLabel == 'CommandScope';

/// 지금 포커스가 목록 행([FileNodeTile]) 안에 있는지.
bool _focusInsideRow() {
  final ctx = FocusManager.instance.primaryFocus?.context;
  if (ctx == null) return false;
  var found = false;
  ctx.visitAncestorElements((e) {
    if (e.widget is FileNodeTile) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}

void main() {
  testWidgets('Tab이 목록 행 안에 앉지 않는다', (tester) async {
    await _pump(tester);
    expect(_scopeHasFocus(), isTrue, reason: '본문 스코프에서 시작한다');

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    // 행 안의 위젯(행 자체·태그 칩·x·'+')이 정거장이면 여기서 포커스를 빼앗긴다.
    // 그러면 스코프 포커스를 요구하는 방향키 명령이 한꺼번에 죽는다.
    expect(_focusInsideRow(), isFalse);
    expect(_scopeHasFocus(), isTrue);
  });

  testWidgets('Tab을 눌러 본 뒤에도 방향키가 앱 명령에 닿는다', (tester) async {
    await _pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    _log.clear();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();

    expect(_log, ['cursorRight', 'cursorLeft', 'moveCursorDown']);
  });

  testWidgets('행 안에는 Tab 정거장이 없다', (tester) async {
    await _pump(tester);

    // 남는 정거장은 프레임워크의 스코프들과 본문 스코프뿐이어야 한다 — 행 위젯이
    // 하나라도 섞이면 Tab이 목록 안에 앉을 수 있다는 뜻이다.
    final inRow = FocusManager.instance.rootScope.traversalDescendants.where((
      node,
    ) {
      final ctx = node.context;
      if (ctx == null) return false;
      var found = false;
      ctx.visitAncestorElements((e) {
        if (e.widget is FileNodeTile) {
          found = true;
          return false;
        }
        return true;
      });
      return found;
    });

    expect(inRow, isEmpty);
  });
}
