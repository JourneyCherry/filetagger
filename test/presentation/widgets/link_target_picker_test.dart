import 'package:filetagger/domain/entities/assigned_tag.dart';
import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/node_kind.dart';
import 'package:filetagger/domain/entities/tag_assignment.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/l10n/app_localizations.dart';
import 'package:filetagger/presentation/providers/file_node_provider.dart';
import 'package:filetagger/presentation/providers/tag_provider.dart';
import 'package:filetagger/presentation/providers/workspace_provider.dart';
import 'package:filetagger/presentation/widgets/link_target_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/desktop.dart';
import '../../support/l10n.dart';

const _artistTag = TagDefinition(
  id: 1,
  name: '작가',
  valueType: TagValueType.label,
);
const _characterTag = TagDefinition(
  id: 2,
  name: '캐릭터',
  valueType: TagValueType.label,
);

const _artist = FileNode(id: 10, path: '아무개', kind: NodeKind.keyword);
const _character = FileNode(id: 11, path: '홍길동', kind: NodeKind.keyword);
const _image = FileNode(id: 12, path: '그림.png', kind: NodeKind.file);
const _character2 = FileNode(id: 13, path: '임꺽정', kind: NodeKind.keyword);

/// 이름순으로 늘어선 후보 전부(그·아·임·홍).
const _all = [_image, _artist, _character2, _character];

AssignedTag _assign(FileNode node, TagDefinition definition) => AssignedTag(
  assignment: TagAssignment(
    fileNodeId: node.id!,
    tagDefinitionId: definition.id!,
  ),
  definition: definition,
);

/// 마지막으로 고른 대상(취소하면 null). 다이얼로그가 닫힐 때 채워진다.
String? _picked;

/// 선택기를 띄운다. 후보는 작가 태그를 단 키워드 하나, 캐릭터 태그를 단 키워드 둘,
/// 태그 없는 파일 하나다(캐릭터가 둘이라야 태그 필터와 커서 이동의 효과가 갈린다).
Future<void> _open(WidgetTester tester, {String? initial}) async {
  _picked = null;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        fileNodesProvider.overrideWith((ref) => Stream.value(_all)),
        tagDefinitionsProvider.overrideWith(
          (ref) => Stream.value(const [_artistTag, _characterTag]),
        ),
        assignmentsProvider.overrideWith(
          (ref) => Stream.value([
            _assign(_artist, _artistTag),
            _assign(_character, _characterTag),
            _assign(_character2, _characterTag),
          ]),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  _picked = await pickLinkTarget(context, initial: initial),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    ),
  );
  await _reopen(tester);
}

/// 태그 필터 칸에 글자를 넣는다(칸은 스스로 포커스를 갖지 않으므로 `enterText`가
/// 포커스를 옮겨 준다). 조건으로 읽히는 낱말은 캡슐로 접힌다.
Future<void> _filter(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pumpAndSettle();
}

/// 빠른 탐색 글자 하나를 목록에 친다. 한글은 논리 키에 대응이 없어 글자를 직접 실어
/// 보낸다(실제 입력기도 조합이 끝난 글자를 이 자리에 싣는다).
Future<void> _typeAhead(WidgetTester tester, String character) async {
  await simulateKeyDownEvent(LogicalKeyboardKey.keyA, character: character);
  await simulateKeyUpEvent(LogicalKeyboardKey.keyA);
  await tester.pumpAndSettle();
}

Future<void> _press(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

/// 다이얼로그만 닫는다(앱은 그대로 남아 기억한 필터도 살아 있다).
Future<void> _close(WidgetTester tester) async {
  await tester.tap(find.text(koL10n.commonCancel));
  await tester.pumpAndSettle();
}

Future<void> _reopen(WidgetTester tester) async {
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
}

/// 목록에 남은 후보 이름들.
List<String> _listed(WidgetTester tester) => [
  for (final tile in tester.widgetList<ListTile>(find.byType(ListTile)))
    ((tile.title as Text).data)!,
];

/// 커서가 놓인 후보의 이름(없으면 null).
String? _cursored(WidgetTester tester) {
  for (final tile in tester.widgetList<ListTile>(find.byType(ListTile))) {
    if (tile.selected) return (tile.title as Text).data;
  }
  return null;
}

void main() {
  desktopTestWidgets('아무것도 하지 않으면 폴더가 아닌 후보가 모두 보인다', (tester) async {
    await _open(tester);

    expect(_listed(tester), [for (final n in _all) n.name]);
    expect(_cursored(tester), isNull, reason: '가리키던 값이 없으면 커서도 없다');
  });

  desktopTestWidgets('지금 가리키는 대상에서 커서가 시작한다', (tester) async {
    await _open(tester, initial: '${_character.id}');

    expect(_cursored(tester), _character.name);
  });

  desktopTestWidgets('글자를 치면 그 글자로 시작하는 후보로 커서가 간다', (tester) async {
    await _open(tester);
    await _typeAhead(tester, '홍');

    expect(_cursored(tester), _character.name);
    // 목록을 줄이는 것이 아니라 커서만 옮긴다.
    expect(_listed(tester), hasLength(_all.length));
  });

  desktopTestWidgets('방향키로 커서를 옮기고 Enter로 고른다', (tester) async {
    await _open(tester);

    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(_cursored(tester), _image.name, reason: '커서가 없으면 처음 항목부터');
    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(_cursored(tester), _artist.name);
    await _press(tester, LogicalKeyboardKey.arrowUp);
    expect(_cursored(tester), _image.name);

    await _press(tester, LogicalKeyboardKey.enter);
    expect(_picked, '${_image.id}');
  });

  desktopTestWidgets('태그 필터는 후보 목록을 줄인다', (tester) async {
    await _open(tester);
    await _filter(tester, '${_artistTag.name} ');

    expect(_listed(tester), [_artist.name]);
  });

  desktopTestWidgets('필터를 건 뒤에도 목록에서 빠른 탐색이 이어진다', (tester) async {
    await _open(tester);
    await _filter(tester, '${_characterTag.name} ');
    expect(_listed(tester), [_character2.name, _character.name]);

    // 필터 칸이 포커스를 쥔 채로는 글자가 목록으로 새지 않는다. 조각이 접힌 뒤에는
    // 다음 조건을 고르라고 자동완성이 다시 떠 있으므로, 첫 Esc가 그것을 닫고 두
    // 번째가 목록으로 돌려보낸다.
    await _press(tester, LogicalKeyboardKey.escape);
    await _press(tester, LogicalKeyboardKey.escape);
    await _typeAhead(tester, '홍');

    expect(_cursored(tester), _character.name);
  });

  desktopTestWidgets('필터 칸에서 Enter를 누르면 목록으로 돌아온다', (tester) async {
    await _open(tester);
    await _filter(tester, '${_characterTag.name} ');

    // 자동완성이 떠 있는 동안의 Enter는 후보 고르기라 목록까지 오지 않는다.
    await _press(tester, LogicalKeyboardKey.escape);
    await _press(tester, LogicalKeyboardKey.enter);
    await _typeAhead(tester, '홍');

    expect(_cursored(tester), _character.name);
  });

  desktopTestWidgets('관리 폴더가 바뀌면 기억한 필터를 버린다', (tester) async {
    await _open(tester);
    await _filter(tester, '${_characterTag.name} ');
    await _close(tester);

    // 조건이 담은 태그 정의 id는 폴더마다 다른 DB의 것이라 물려받으면 안 된다.
    ProviderScope.containerOf(
      tester.element(find.text('열기')),
    ).read(workspaceRootProvider.notifier).state = '다른 폴더';
    await _reopen(tester);

    expect(_listed(tester), hasLength(_all.length));
  });

  desktopTestWidgets('다시 열어도 태그 필터가 남아 있다', (tester) async {
    await _open(tester);
    await _filter(tester, '${_characterTag.name} ');
    await _close(tester);
    await _reopen(tester);

    expect(_listed(tester), [_character2.name, _character.name]);
  });
}
