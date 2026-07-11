import 'package:filetagger/domain/entities/file_filter.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/presentation/common/capsule_text_field.dart';
import 'package:filetagger/presentation/widgets/filter_condition_chip.dart';
import 'package:filetagger/presentation/widgets/filter_query_field.dart';
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

FilterQueryController controller() => FilterQueryController(definitions: _defs);

/// 커서를 [cursor]에 둔 채 [text]를 컨트롤러에 넣는다(입력 한 번을 흉내낸다).
void put(FilterQueryController controller, String text, int cursor) {
  controller.value = TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: cursor),
  );
}

/// 캡슐 글자 하나를 얻는다(글자값 자체는 구현이 단일 출처다).
String aCapsuleChar() {
  final c = controller();
  put(c, '숨김 ', 3);
  return c.text[0];
}

bool isCapsuleAt(String text, int index) =>
    isCapsuleChar(text.codeUnitAt(index));

void main() {
  group('capsuleTextPieces', () {
    test('캡슐 글자는 붙여 쳐도 홀로 선 조각이다', () {
      expect(capsuleTextPieces('${aCapsuleChar()}평점>=4'), [
        (start: 0, end: 1, isCapsule: true),
        (start: 1, end: 6, isCapsule: false),
      ]);
    });

    test('조각 사이의 공백은 어느 조각에도 들지 않는다', () {
      expect(capsuleTextPieces(' 메모 '), [(start: 1, end: 3, isCapsule: false)]);
    });
  });

  group('접기', () {
    test('구분문자를 쳐서 커서가 조각을 벗어나면 캡슐 한 글자로 접힌다', () {
      final c = controller();
      put(c, '평점>=4 ', 6);

      expect(c.text.length, 2);
      expect(isCapsuleAt(c.text, 0), isTrue);
      expect(c.text[1], ' ');
      expect(c.selection.baseOffset, 2);
      expect(c.conditions, hasLength(1));
      expect(c.conditions.single.operator, FilterOperator.greaterOrEqual);
      expect(c.conditions.single.operand, '4');
    });

    test('커서가 놓인 조각은 아직 접지 않는다', () {
      final c = controller();
      put(c, '평점>=4', 5);

      expect(c.text, '평점>=4');
      expect(c.conditions, isEmpty);
    });

    test('커서를 조각 밖으로 옮기면 접힌다', () {
      final c = controller();
      put(c, '평점>=4 메모~a', 10);
      expect(c.conditions, hasLength(1)); // 커서가 놓인 뒷 조각은 그대로.

      put(c, c.text, 0); // 커서만 앞으로 옮긴다.
      expect(c.text.length, 3); // 캡슐 · 구분문자 · 캡슐
      expect(isCapsuleAt(c.text, 2), isTrue);
      expect(c.conditions, hasLength(2));
    });

    test('포커스를 잃으면 커서가 놓인 조각도 마저 접힌다', () {
      final c = controller();
      put(c, '평점>=4', 5);
      expect(c.conditions, isEmpty);

      c.commit();
      expect(c.text.length, 1);
      expect(c.conditions, hasLength(1));
    });

    test('조각을 확정시키느라 친 공백은 포커스를 잃을 때 사라진다', () {
      final c = controller();
      put(c, '평점>=4 ', 6);
      expect(c.text[1], ' ');

      c.commit();
      expect(c.text.length, 1);
      expect(isCapsuleAt(c.text, 0), isTrue);
    });

    test('값 없는 라벨 태그는 이름만으로 접힌다', () {
      final c = controller();
      put(c, '숨김 ', 3);

      expect(c.conditions.single.operator, FilterOperator.exists);
      expect(c.conditions.single.exclude, isFalse);
    });

    test('부정 접두사는 제외 조건이 된다', () {
      final c = controller();
      put(c, '-숨김 ', 4);

      expect(c.conditions.single.exclude, isTrue);
    });
  });

  group('되펼치기', () {
    test('백스페이스는 캡슐을 원문으로 되펼치고 커서를 그 끝에 둔다', () {
      final c = controller();
      put(c, '평점>=4 ', 6);
      put(c, c.text, 1); // 캡슐 바로 뒤로 커서를 옮긴다.

      put(c, ' ', 0); // 캡슐 글자 하나가 지워진 변경 = 백스페이스.

      expect(c.text, '평점>=4 ');
      expect(c.selection.baseOffset, 5);
      expect(c.conditions, isEmpty);
    });

    test('앞에서 누른 Delete는 커서를 되펼친 문자열 앞에 둔다', () {
      final c = controller();
      put(c, '평점>=4 ', 6);
      put(c, c.text, 0); // 캡슐 바로 앞.

      put(c, ' ', 0);

      expect(c.text, '평점>=4 ');
      expect(c.selection.baseOffset, 0);
    });

    test('되펼친 문자열을 고쳐 커서를 빼면 다시 접힌다', () {
      final c = controller();
      put(c, '평점>=4 ', 6);
      put(c, c.text, 1);
      put(c, ' ', 0); // 되펼침.

      put(c, '평점>=5 ', 6);
      expect(c.text.length, 2);
      expect(c.conditions.single.operand, '5');
    });

    test('캡슐을 선택해 지우면 되펼치지 않고 조건이 사라진다', () {
      final c = controller();
      put(c, '평점>=4 ', 6);
      c.value = TextEditingValue(
        text: c.text,
        selection: const TextSelection(baseOffset: 0, extentOffset: 1),
      );

      put(c, ' ', 0);
      expect(c.text, ' ');
      expect(c.conditions, isEmpty);
    });
  });

  group('미완성·무효 조각', () {
    test('해석하지 못한 조각은 원문으로 남고 조건에서 빠진다', () {
      final c = controller();
      put(c, '없는태그>=4 평점>=4 ', 14);

      expect(c.text, startsWith('없는태그>=4 '));
      expect(c.conditions, hasLength(1));
      expect(c.conditions.single.tagDefinitionId, _rating.id);
    });

    test('포커스를 잃으면 접히지 못한 조각은 버려진다', () {
      final c = controller();
      put(c, '평점>=4 없는태그>=4 평점>=', 17);
      c.commit();

      // 확정된 조건 하나만 캡슐로 남고, 무효·미완성 조각과 공백은 사라진다.
      expect(c.text.length, 1);
      expect(isCapsuleAt(c.text, 0), isTrue);
      expect(c.conditions, hasLength(1));
      expect(c.conditions.single.tagDefinitionId, _rating.id);
    });

    test('태그 유형이 허용하지 않는 연산자는 접지 않는다', () {
      final c = controller();
      put(c, '숨김>=4 ', 6);

      expect(c.text, startsWith('숨김>=4'));
      expect(c.conditions, isEmpty);
    });
  });

  group('밖에서 주어진 필터', () {
    test('setFilter는 모든 조건을 캡슐로 접어 채운다', () {
      final c = controller();
      c.setFilter(
        const FileFilter(
          conditions: [
            FilterCondition(tagDefinitionId: 1),
            FilterCondition(tagDefinitionId: 3, exclude: true),
          ],
        ),
      );

      expect(c.text.length, 3);
      expect(isCapsuleAt(c.text, 0), isTrue);
      expect(c.text[1], ' ');
      expect(isCapsuleAt(c.text, 2), isTrue);
      expect(c.conditions, hasLength(2));
    });

    test('정의가 사라진 태그의 조건도 캡슐로 남겨 조용히 잃지 않는다', () {
      final c = controller();
      c.setFilter(
        const FileFilter(conditions: [FilterCondition(tagDefinitionId: 99)]),
      );

      expect(c.conditions, hasLength(1));
    });
  });

  group('FilterQueryField', () {
    Future<void> pumpField(
      WidgetTester tester, {
      required FileFilter filter,
      required void Function(FileFilter) onChanged,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterQueryField(
              filter: filter,
              definitions: _defs,
              onChanged: onChanged,
            ),
          ),
        ),
      );
    }

    testWidgets('확정된 조건은 칩으로 그려진다', (tester) async {
      await pumpField(
        tester,
        filter: const FileFilter(
          conditions: [
            FilterCondition(
              tagDefinitionId: 1,
              operator: FilterOperator.greaterOrEqual,
              operand: '4',
            ),
          ],
        ),
        onChanged: (_) {},
      );

      expect(find.byType(FilterConditionChip), findsOneWidget);
      // 이름과 조건은 구분선을 사이에 두고 따로 그려진다.
      expect(find.text('평점'), findsOneWidget);
      expect(find.text('≥ 4'), findsOneWidget);
    });

    testWidgets('구분문자까지 치면 캡슐이 생기고 조건이 밖으로 나간다', (tester) async {
      FileFilter? emitted;
      await pumpField(
        tester,
        filter: const FileFilter(),
        onChanged: (f) => emitted = f,
      );

      await tester.enterText(find.byType(TextField), '평점>=4 ');
      await tester.pump();

      expect(find.byType(FilterConditionChip), findsOneWidget);
      expect(emitted?.conditions, hasLength(1));
      expect(emitted!.conditions.single.operand, '4');
    });

    testWidgets('미완성 문자열은 칩이 되지 않고 조건도 나가지 않는다', (tester) async {
      FileFilter? emitted;
      await pumpField(
        tester,
        filter: const FileFilter(),
        onChanged: (f) => emitted = f,
      );

      await tester.enterText(find.byType(TextField), '평점>=');
      await tester.pump();

      expect(find.byType(FilterConditionChip), findsNothing);
      expect(emitted, isNull);
    });

    testWidgets('태그 정의가 뒤늦게 도착해 다시 빌드해도 터지지 않는다', (tester) async {
      // 폴더를 열면 정의 목록이 새로 내려와 문법이 바뀐다. 그때 컨트롤러가 보내는
      // 알림을 입력으로 오인하면 빌드 도중 자동완성 오버레이를 여닫아 죽는다.
      Future<void> pumpWith(List<TagDefinition> defs) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterQueryField(
              filter: const FileFilter(
                conditions: [FilterCondition(tagDefinitionId: 1)],
              ),
              definitions: defs,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await pumpWith(const [_rating]);
      await pumpWith(const [_rating, _memo, _hidden]);

      expect(tester.takeException(), isNull);
      expect(find.byType(FilterConditionChip), findsOneWidget);
    });

    testWidgets('태그 이름을 치면 자동완성 후보가 뜬다', (tester) async {
      await pumpField(tester, filter: const FileFilter(), onChanged: (_) {});

      await tester.enterText(find.byType(TextField), '메');
      await tester.pumpAndSettle();

      expect(find.text('메모'), findsOneWidget);
      expect(find.text('텍스트'), findsOneWidget);
    });
  });
}
