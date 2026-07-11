import 'package:filetagger/domain/entities/file_sort.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/presentation/common/capsule_text_field.dart';
import 'package:filetagger/presentation/widgets/sort_key_chip.dart';
import 'package:filetagger/presentation/widgets/sort_query_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _rating = TagDefinition(
  id: 1,
  name: '평점',
  valueType: TagValueType.number,
);
const _memo = TagDefinition(id: 2, name: '메모', valueType: TagValueType.text);
const _hidden = TagDefinition(id: 3, name: '숨김', valueType: TagValueType.label);

const _defs = [_rating, _memo, _hidden];

SortQueryController controller() => SortQueryController(definitions: _defs);

/// 커서를 [cursor]에 둔 채 [text]를 컨트롤러에 넣는다(입력 한 번을 흉내낸다).
void put(SortQueryController controller, String text, int cursor) {
  controller.value = TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: cursor),
  );
}

bool isCapsuleAt(String text, int index) =>
    isCapsuleChar(text.codeUnitAt(index));

void main() {
  group('접기', () {
    test('구분문자를 쳐서 커서가 조각을 벗어나면 캡슐 한 글자로 접힌다', () {
      final c = controller();
      put(c, '평점 ', 3);

      expect(c.text.length, 2);
      expect(isCapsuleAt(c.text, 0), isTrue);
      expect(c.keys.single.tagDefinitionId, _rating.id);
      expect(c.keys.single.direction, SortDirection.ascending);
    });

    test('방향 접두사는 내림차순 단계가 된다', () {
      final c = controller();
      put(c, '-평점 ', 4);

      expect(c.keys.single.direction, SortDirection.descending);
    });

    test('커서가 놓인 조각은 아직 접지 않는다', () {
      final c = controller();
      put(c, '평점', 2);

      expect(c.text, '평점');
      expect(c.keys, isEmpty);
    });

    test('포커스를 잃으면 커서가 놓인 조각도 마저 접힌다', () {
      final c = controller();
      put(c, '평점', 2);
      c.commit();

      expect(c.text.length, 1);
      expect(c.keys, hasLength(1));
    });

    test('텍스트 순서가 그대로 정렬 우선순위다', () {
      final c = controller();
      put(c, '-평점 메모 ', 7);

      expect(c.keys.map((k) => k.tagDefinitionId), [_rating.id, _memo.id]);
    });
  });

  group('되펼치기', () {
    test('백스페이스는 캡슐을 원문으로 되펼치고 커서를 그 끝에 둔다', () {
      final c = controller();
      put(c, '-평점 ', 4);
      put(c, c.text, 1); // 캡슐 바로 뒤로 커서를 옮긴다.

      put(c, ' ', 0); // 캡슐 글자 하나가 지워진 변경 = 백스페이스.

      expect(c.text, '-평점 ');
      expect(c.selection.baseOffset, 3);
      expect(c.keys, isEmpty);
    });

    test('되펼친 문자열에서 방향 접두사를 지우면 오름차순으로 다시 접힌다', () {
      final c = controller();
      put(c, '-평점 ', 4);
      put(c, c.text, 1);
      put(c, ' ', 0); // 되펼침.

      put(c, '평점 ', 3);
      expect(c.text.length, 2);
      expect(c.keys.single.direction, SortDirection.ascending);
    });

    test('캡슐을 선택해 지우면 되펼치지 않고 단계가 사라진다', () {
      final c = controller();
      put(c, '평점 ', 3);
      c.value = TextEditingValue(
        text: c.text,
        selection: const TextSelection(baseOffset: 0, extentOffset: 1),
      );

      put(c, ' ', 0);
      expect(c.keys, isEmpty);
    });
  });

  group('미완성·무효 조각', () {
    test('없는 태그는 원문으로 남고 단계에서 빠진다', () {
      final c = controller();
      put(c, '없는태그 평점 ', 9);

      expect(c.text, startsWith('없는태그 '));
      expect(c.keys.single.tagDefinitionId, _rating.id);
    });

    test('방향이 없는 라벨 태그에 접두사를 붙이면 접지 않는다', () {
      final c = controller();
      put(c, '-숨김 ', 4);

      expect(c.text, startsWith('-숨김'));
      expect(c.keys, isEmpty);
    });

    test('라벨 태그는 이름만으로 접힌다', () {
      final c = controller();
      put(c, '숨김 ', 3);

      expect(c.keys.single.tagDefinitionId, _hidden.id);
    });
  });

  group('밖에서 주어진 정렬', () {
    test('setSort는 모든 단계를 캡슐로 접어 채운다', () {
      final c = controller();
      c.setSort(
        const FileSortOrder(
          keys: [
            SortKey(tagDefinitionId: 1, direction: SortDirection.descending),
            SortKey(tagDefinitionId: 2),
          ],
        ),
      );

      expect(c.text.length, 3);
      expect(isCapsuleAt(c.text, 0), isTrue);
      expect(c.text[1], ' ');
      expect(c.keys, hasLength(2));
    });

    test('정의가 사라진 태그의 단계도 캡슐로 남겨 조용히 잃지 않는다', () {
      final c = controller();
      c.setSort(const FileSortOrder(keys: [SortKey(tagDefinitionId: 99)]));

      expect(c.keys, hasLength(1));
    });
  });

  group('SortQueryField', () {
    Future<void> pumpField(
      WidgetTester tester, {
      required FileSortOrder sort,
      required void Function(FileSortOrder) onChanged,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SortQueryField(
              sort: sort,
              definitions: _defs,
              onChanged: onChanged,
            ),
          ),
        ),
      );
    }

    testWidgets('확정된 단계는 칩으로 그려진다', (tester) async {
      await pumpField(
        tester,
        sort: const FileSortOrder(
          keys: [
            SortKey(tagDefinitionId: 1, direction: SortDirection.descending),
          ],
        ),
        onChanged: (_) {},
      );

      expect(find.byType(SortKeyChip), findsOneWidget);
      expect(find.text('평점'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets('구분문자까지 치면 캡슐이 생기고 단계가 밖으로 나간다', (tester) async {
      FileSortOrder? emitted;
      await pumpField(
        tester,
        sort: const FileSortOrder(),
        onChanged: (s) => emitted = s,
      );

      await tester.enterText(find.byType(TextField), '-평점 ');
      await tester.pump();

      expect(find.byType(SortKeyChip), findsOneWidget);
      expect(emitted?.keys.single.direction, SortDirection.descending);
    });

    testWidgets('미완성 문자열은 칩이 되지 않고 단계도 나가지 않는다', (tester) async {
      FileSortOrder? emitted;
      await pumpField(
        tester,
        sort: const FileSortOrder(),
        onChanged: (s) => emitted = s,
      );

      await tester.enterText(find.byType(TextField), '-숨김 ');
      await tester.pump();

      expect(find.byType(SortKeyChip), findsNothing);
      expect(emitted, isNull);
    });

    testWidgets('태그 이름을 치면 자동완성 후보가 뜬다', (tester) async {
      await pumpField(tester, sort: const FileSortOrder(), onChanged: (_) {});

      await tester.enterText(find.byType(TextField), '메');
      await tester.pumpAndSettle();

      expect(find.text('메모'), findsOneWidget);
      expect(find.text('텍스트'), findsOneWidget);
    });

    testWidgets('이미 접힌 단계의 태그는 후보에서 빠진다(태그당 한 단계)', (tester) async {
      await pumpField(tester, sort: const FileSortOrder(), onChanged: (_) {});

      await tester.enterText(find.byType(TextField), '메모 메');
      await tester.pumpAndSettle();

      // 앞 조각은 칩으로 접혔고, 뒤 조각의 '메'에 맞는 남은 태그가 없어 후보가 없다.
      expect(find.byType(SortKeyChip), findsOneWidget);
      expect(find.text('메모'), findsOneWidget); // 칩 하나뿐(후보 목록 없음).
      expect(find.text('텍스트'), findsNothing); // 후보의 값 유형 설명도 없다.
    });
  });
}
