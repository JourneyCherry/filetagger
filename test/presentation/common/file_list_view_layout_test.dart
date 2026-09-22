import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/file_tree_node.dart';
import 'package:filetagger/domain/entities/node_kind.dart';
import 'package:filetagger/l10n/app_localizations.dart';
import 'package:filetagger/presentation/common/file_list_view.dart';
import 'package:filetagger/presentation/common/flat_tree.dart';
import 'package:filetagger/presentation/providers/file_view_provider.dart';
import 'package:filetagger/presentation/providers/system_tag_provider.dart';
import 'package:filetagger/presentation/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 창 폭. 여백을 좌우로 견주므로 폭 자체는 아무 값이어도 되지만, 이름·태그가 잘려
/// 오른쪽 끝을 못 재는 일이 없을 만큼은 넓어야 한다.
const double _width = 700;

FileNode _file(int id) =>
    FileNode(id: id, path: '항목$id.txt', kind: NodeKind.file);

FileNode _dir(int id) =>
    FileNode(id: id, path: '폴더$id', kind: NodeKind.directory);

/// 그룹 헤더 · 펼칠 수 있는 폴더 · 파일을 **모두 같은 깊이**에 둔 목록. 깊이가 같아야
/// 들여쓰기가 아니라 행 종류에서 오는 어긋남만 남는다.
FlatTree _tree() {
  final dir = _dir(1);
  final file = _file(2);
  return FlatTree(
    rows: [
      TreeRow(
        item: GroupHeaderNode(
          tagDefinitionId: 1,
          value: '묶음',
          itemCount: 2,
          children: const [],
        ),
        depth: 0,
        expandable: true,
        expanded: true,
        expandKey: 'h',
      ),
      TreeRow(
        item: FileTreeNode(dir, const []),
        depth: 0,
        expandable: true,
        expanded: false,
        expandKey: '폴더1',
        nodeIndex: 0,
      ),
      TreeRow(
        item: FileTreeNode(file, const []),
        depth: 0,
        expandable: false,
        expanded: false,
        expandKey: '항목2.txt',
        nodeIndex: 1,
      ),
    ],
    nodes: [dir, file],
  );
}

Future<void> _pump(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [
      flatTreeProvider.overrideWithValue(AsyncValue.data(_tree())),
      effectiveAssignmentsByFileProvider.overrideWithValue(const {}),
      tagChipVisibleProvider.overrideWithValue((_) => true),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildAppTheme(Brightness.dark),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: _width,
            height: 400,
            child: FileListView(
              onTapNode: (_, _) {},
              onTapHeader: (_) {},
              onOpenNode: (_) {},
              onEditAssignment: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// [finder]가 가리키는 첫 위젯의 화면 좌우 x.
({double left, double right}) _span(WidgetTester tester, Finder finder) {
  final box = tester.renderObject<RenderBox>(finder.first);
  final left = box.localToGlobal(Offset.zero).dx;
  return (left: left, right: left + box.size.width);
}

void main() {
  testWidgets('같은 깊이면 그룹 헤더와 폴더의 펼침 캐럿이 한 세로줄에 선다', (tester) async {
    // 헤더는 `ListTile`을 쓰지 않아 그 기본 좌우 여백을 받지 않는데, 파일 행만 그
    // 여백만큼 밀려 두 캐럿이 어긋나 있었다. 들여쓰기 가이드 라인은 행 전체 폭에
    // 그려져 라인끼리는 맞으므로, 어긋남은 내용 쪽에서만 드러난다.
    await _pump(tester);

    final carets = find.byType(IconButton);
    expect(carets, findsNWidgets(2), reason: '헤더 캐럿 + 폴더 캐럿');
    expect(_span(tester, carets.at(0)).left, _span(tester, carets.at(1)).left);
  });

  testWidgets('행 내용의 좌우 여백이 같다', (tester) async {
    // `ListTile`의 M3 기본값은 오른쪽이 더 넓다(trailing 컨트롤 자리를 비워 두는
    // 규격). 이 행에는 그 자리가 늘 있는 것이 아니라 좌우를 같게 둔다.
    await _pump(tester);

    // 선택 배경을 칠하는 Material이 여백의 기준면이다(그 안쪽이 내용).
    final tile = find.byType(FileNodeTile).last;
    final frame = _span(
      tester,
      find.descendant(of: tile, matching: find.byType(Material)),
    );
    final leading = _span(
      tester,
      find.descendant(of: tile, matching: find.byType(Row)),
    );
    final title = _span(
      tester,
      find.descendant(of: tile, matching: find.text('항목2.txt')),
    );

    expect(leading.left - frame.left, frame.right - title.right);
  });
}
