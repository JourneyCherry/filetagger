import 'package:filetagger/domain/entities/assigned_tag.dart';
import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/folder_manage_mode.dart';
import 'package:filetagger/domain/entities/node_kind.dart';
import 'package:filetagger/domain/entities/tag_assignment.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/presentation/common/file_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _path = '여행/2024/봄/풍경사진.jpg';

const _file = FileNode(id: 1, path: _path, kind: NodeKind.file);

AssignedTag _tag(int id, String value) => AssignedTag(
  assignment: TagAssignment(
    id: id,
    fileNodeId: 1,
    tagDefinitionId: id,
    value: value,
  ),
  definition: TagDefinition(
    id: id,
    name: '태그$id',
    valueType: TagValueType.text,
  ),
);

Future<void> _pump(
  WidgetTester tester, {
  FileNode node = _file,
  String? displaySubtitle,
  FolderManageMode? folderMode,
  List<AssignedTag> assignments = const [],
}) => tester.pumpWidget(
  ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: FileNodeTile(
          node: node,
          selected: false,
          displaySubtitle: displaySubtitle,
          folderMode: folderMode,
          assignments: assignments,
          isTagVisible: (_) => true,
          onTap: () {},
          onEditAssignment: (_) {},
        ),
      ),
    ),
  ),
);

/// 부제 자리의 Text(경로 또는 부제 태그 값). 제목은 이름만 담아 겹치지 않는다.
Text _subtitleTextOf(WidgetTester tester, String data) =>
    tester.widget<Text>(find.text(data));

void main() {
  testWidgets('부제는 경로를 한 줄로만 보인다', (tester) async {
    await _pump(tester);

    final subtitle = _subtitleTextOf(tester, _path);
    // 깊은 경로가 여러 줄로 접히면 행 높이가 노드마다 달라진다.
    expect(subtitle.maxLines, 1);
    expect(subtitle.overflow, TextOverflow.ellipsis);
  });

  testWidgets('부제 태그가 값을 내면 경로 대신 그 값이 보인다', (tester) async {
    await _pump(tester, displaySubtitle: '김작가');

    expect(find.text('김작가'), findsOneWidget);
    expect(find.text(_path), findsNothing);
  });

  testWidgets('연결 끊김은 문장 줄이 아니라 이름 옆 표식으로 알린다', (tester) async {
    await _pump(
      tester,
      node: FileNode(
        id: 1,
        path: _path,
        kind: NodeKind.file,
        missingSince: DateTime(2026),
      ),
    );

    // 설명은 툴팁에 있고 줄을 차지하지 않는다(썸네일 자리도 같은 아이콘으로 폴백하므로
    // 이름 옆 표식만 집어 본다).
    const message = '연결 끊김 — 원본 파일을 찾아 태그를 재연결하세요';
    expect(find.byTooltip(message), findsOneWidget);
    expect(
      find.descendant(
        of: find.byTooltip(message),
        matching: find.byIcon(Icons.link_off),
      ),
      findsOneWidget,
    );
    expect(find.text(message), findsNothing);
  });

  testWidgets('내부 감춤 폴더도 같은 자리에 표식으로 알린다', (tester) async {
    await _pump(
      tester,
      node: const FileNode(id: 2, path: '보관함', kind: NodeKind.directory),
      folderMode: FolderManageMode.opaque,
    );

    const message = '내부 감춤 — 메뉴에서 ‘내부 관리’로 펼치기';
    expect(
      find.descendant(
        of: find.byTooltip(message),
        matching: find.byIcon(Icons.visibility_off_outlined),
      ),
      findsOneWidget,
    );
    expect(find.text(message), findsNothing);
  });

  testWidgets('태그가 많아도 줄바꿈하지 않고 가로로 스크롤한다', (tester) async {
    await _pump(
      tester,
      assignments: [for (var i = 1; i <= 8; i++) _tag(i, '값$i')],
    );

    expect(
      find.byWidgetPredicate(
        (w) =>
            w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      ),
      findsOneWidget,
    );
    // 줄바꿈으로 쌓이면 태그 수만큼 행이 두꺼워진다.
    expect(find.byType(Wrap), findsNothing);
  });

  testWidgets('키워드는 경로 자리에 종류를 알린다(이름을 두 번 보이지 않는다)', (tester) async {
    await _pump(
      tester,
      node: const FileNode(id: 3, path: '작가 A', kind: NodeKind.keyword),
    );

    expect(find.text('키워드'), findsOneWidget);
  });
}
