import 'package:filetagger/l10n/app_localizations.dart';
import 'package:filetagger/domain/entities/assigned_tag.dart';
import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/file_tree_node.dart';
import 'package:filetagger/domain/entities/node_kind.dart';
import 'package:filetagger/domain/entities/tag_assignment.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/presentation/common/file_list_view.dart';
import 'package:filetagger/presentation/common/flat_tree.dart';
import 'package:filetagger/presentation/common/navigation_cursor.dart';
import 'package:filetagger/presentation/providers/file_view_provider.dart';
import 'package:filetagger/presentation/providers/system_tag_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 목록 크기와 창 크기. 커서를 화면에서 한참 떨어진 자리에 둘 수 있을 만큼은 길어야
/// 하고(그래야 건너뛰기가 사이 행들을 훑고 지나간다), 테스트가 오래 끌지 않을 만큼만
/// 길어야 한다.
const int _count = 1000;
const double _viewportHeight = 400;

/// 커서를 세울 자리. 목록 뒤쪽이라 앞에서 건너뛰면 사이 행이 많이 스쳐 간다.
const int _far = 700;

FileNode _node(int i) =>
    FileNode(id: i, path: '폴더/항목$i.txt', kind: NodeKind.file);

/// 그룹 헤더가 섞이고 태그 유무로 높이가 갈리는 목록. **행 높이가 고르지 않은 것이
/// 요점이다** — 고르면 평균 어림만으로도 맞아, 실제 목록에서 나던 증상이 재현되지 않는다.
FlatTree _tree() {
  final nodes = [for (var i = 0; i < _count; i++) _node(i)];
  final rows = <TreeRow>[];
  for (var i = 0; i < _count; i++) {
    if (i % 20 == 0) {
      rows.add(
        TreeRow(
          item: GroupHeaderNode(
            tagDefinitionId: 1,
            value: '묶음${i ~/ 20}',
            itemCount: 20,
            children: const [],
          ),
          depth: 0,
          expandable: false,
          expanded: true,
          expandKey: 'h$i',
        ),
      );
    }
    rows.add(
      TreeRow(
        item: FileTreeNode(nodes[i], const []),
        depth: 1,
        expandable: false,
        expanded: false,
        expandKey: '폴더/항목$i.txt',
        nodeIndex: i,
      ),
    );
  }
  return FlatTree(rows: rows, nodes: nodes);
}

AssignedTag _tag(int fileNodeId) => AssignedTag(
  assignment: TagAssignment(
    id: fileNodeId,
    fileNodeId: fileNodeId,
    tagDefinitionId: 1,
    value: '값',
  ),
  definition: const TagDefinition(
    id: 1,
    name: '태그',
    valueType: TagValueType.text,
  ),
);

Map<int, List<AssignedTag>> _assignments() => {
  for (var i = 0; i < _count; i++)
    if (i % 3 == 0) i: [_tag(i)],
};

Future<ProviderContainer> _pump(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [
      flatTreeProvider.overrideWithValue(AsyncValue.data(_tree())),
      effectiveAssignmentsByFileProvider.overrideWithValue(_assignments()),
      tagChipVisibleProvider.overrideWithValue((_) => true),
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
          body: SizedBox(
            width: 600,
            height: _viewportHeight,
            child: FileListView(
              onTapNode: (_, _) {},
              onTapHeader: (_) {},
              onOpenNode: (_) {},
              onEditAssignment: (_) {},
              onRemoveAssignment: (_) {},
              onAddTag: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

ScrollController _scroll(WidgetTester tester) =>
    tester.widget<Scrollable>(find.byType(Scrollable).first).controller!;

/// 그 항목의 행이 창 안에 온전히 보이는지.
bool _visible(WidgetTester tester, int i) {
  final finder = find.text('항목$i.txt');
  if (finder.evaluate().isEmpty) return false;
  final box = tester.renderObject<RenderBox>(finder);
  final top = box.localToGlobal(Offset.zero).dy;
  return top >= 0 && top + box.size.height <= _viewportHeight;
}

/// 커서를 멀리 세운 뒤 휠로 굴려 화면 밖에 두는, 증상이 나던 출발 상태를 만든다.
Future<void> _leaveCursorOffScreen(
  WidgetTester tester,
  NavigationCursorController cursor,
) async {
  cursor.moveTo(_far);
  await tester.pumpAndSettle();
  _scroll(tester).jumpTo(0);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('커서가 화면 밖일 때 방향키가 목록을 따라오게 한다', (tester) async {
    // 건너뛰는 길에 스쳐 만들어진 커서 행이 요청만 삼키고 사라지면, 정착 루프까지 함께
    // 멎어 커서가 화면 밖에 남는다. 그 상태에서 방향키를 눌러도 회복되지 않던 자리다.
    final container = await _pump(tester);
    final cursor = container.read(navigationCursorProvider.notifier);
    await _leaveCursorOffScreen(tester, cursor);

    for (var i = _far + 1; i <= _far + 5; i++) {
      cursor.moveTo(i);
      await tester.pumpAndSettle();
      expect(_visible(tester, i), isTrue, reason: '항목$i');
    }
  });

  testWidgets('방향키를 연달아 눌러도 마지막 커서 행이 드러난다', (tester) async {
    // 한 프레임에 정착 루프가 겹쳐 서면, 뒤엣것이 "이미 목적지"라며 요청을 접어 버린다.
    final container = await _pump(tester);
    final cursor = container.read(navigationCursorProvider.notifier);
    await _leaveCursorOffScreen(tester, cursor);

    for (var i = _far + 1; i <= _far + 5; i++) {
      cursor.moveTo(i);
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(_visible(tester, _far + 5), isTrue);
  });
}
