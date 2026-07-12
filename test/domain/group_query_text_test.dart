import 'package:filetagger/domain/entities/file_grouping.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/domain/usecases/group_query_text.dart';
import 'package:flutter_test/flutter_test.dart';

const _label = TagDefinition(id: 1, name: '숨김', valueType: TagValueType.label);
const _text = TagDefinition(id: 2, name: '메모', valueType: TagValueType.text);
const _number = TagDefinition(
  id: 3,
  name: '평점',
  valueType: TagValueType.number,
);

/// 공백을 이름에 품은, 인용이 필요한 태그.
const _spaced = TagDefinition(
  id: 4,
  name: '촬영 날짜',
  valueType: TagValueType.date,
);

/// 시스템 태그는 음수 id를 쓰며 이름 해석 대상에 함께 들어간다.
const _system = TagDefinition(
  id: -3,
  name: '확장자',
  valueType: TagValueType.text,
  isSystem: true,
);

const _defs = <TagDefinition>[_label, _text, _number, _spaced, _system];

final _defsById = <int, TagDefinition>{for (final d in _defs) d.id!: d};

List<GroupQuerySegment> _parse(String text) =>
    parseGroupQuery(text, definitions: _defs);

/// 조각 하나짜리 입력이 단계로 접혔는지 확인하고 그 키를 돌려준다.
GroupKey _key(String text) {
  final segments = _parse(text);
  expect(segments, hasLength(1));
  final segment = segments.single;
  expect(segment, isA<GroupQueryKey>(), reason: '"$text"가 단계로 접히지 않았다');
  return (segment as GroupQueryKey).key;
}

/// 조각 하나짜리 입력이 해석되지 않았는지 확인하고 그 이유를 돌려준다.
GroupQueryError _error(String text) {
  final segments = _parse(text);
  expect(segments, hasLength(1));
  final segment = segments.single;
  expect(segment, isA<GroupQueryFragment>(), reason: '"$text"가 접히면 안 된다');
  return (segment as GroupQueryFragment).error;
}

void main() {
  group('파싱', () {
    test('태그 이름은 태그 그룹 키가 된다', () {
      final key = _key('평점');
      expect(key, isA<TagGroupKey>());
      expect((key as TagGroupKey).tagDefinitionId, _number.id);
    });

    test('폴더 계층은 인용해 한 조각으로 넣으면 폴더 키가 된다', () {
      expect(_key('"폴더 계층"'), isA<FolderHierarchyGroupKey>());
    });

    test('빈 줄은 조각이 없다', () {
      expect(_parse('   '), isEmpty);
    });

    test('여러 조각은 텍스트 순서대로 중첩 순서가 된다', () {
      final keys = _parse('"폴더 계층" 평점 메모')
          .whereType<GroupQueryKey>()
          .map((s) => s.key)
          .toList();
      expect(keys[0], isA<FolderHierarchyGroupKey>());
      expect((keys[1] as TagGroupKey).tagDefinitionId, _number.id);
      expect((keys[2] as TagGroupKey).tagDefinitionId, _text.id);
    });

    test('폴더 키 뒤의 값 키는 유효하다(폴더 내 재그룹)', () {
      final keys = _parse('"폴더 계층" 평점')
          .whereType<GroupQueryKey>()
          .toList();
      expect(keys, hasLength(2));
    });

    test('폴더 키가 두 번 나오면 두 번째는 무효다', () {
      final segments = _parse('"폴더 계층" 평점 "폴더 계층"');
      expect(segments[0], isA<GroupQueryKey>());
      expect(segments[1], isA<GroupQueryKey>());
      expect(segments[2], isA<GroupQueryFragment>());
      expect(
        (segments[2] as GroupQueryFragment).error,
        GroupQueryError.duplicateFolderHierarchy,
      );
    });

    test('시스템 태그도 이름으로 찾는다', () {
      expect((_key('확장자') as TagGroupKey).tagDefinitionId, _system.id);
    });

    test('라벨 태그도 그룹 키가 된다(존재/미분류 버킷)', () {
      expect((_key('숨김') as TagGroupKey).tagDefinitionId, _label.id);
    });

    test('공백이 든 이름은 인용해야 한 조각이 된다', () {
      expect((_key('"촬영 날짜"') as TagGroupKey).tagDefinitionId, _spaced.id);
      expect(_parse('촬영 날짜'), hasLength(2));
    });

    test('없는 이름은 해석하지 못한다', () {
      expect(_error('없는태그'), GroupQueryError.unknownTag);
    });

    test('닫히지 않은 인용부호는 미완성 조각으로 남는다', () {
      expect(_error('"평점'), GroupQueryError.unterminatedQuote);
    });

    test('인용부호를 닫은 뒤의 군더더기는 무효다', () {
      expect(_error('"평점"x'), GroupQueryError.trailingText);
    });

    test('해석하지 못한 조각은 원문을 그대로 지닌다', () {
      final segments = _parse('없는태그 평점');
      expect(segments.first.text, '없는태그');
    });
  });

  group('groupFromSegments', () {
    test('해석된 단계만 순서대로 모은다', () {
      final grouping = groupFromSegments(_parse('평점 없는태그 메모'));
      expect(grouping.keys, hasLength(2));
      expect((grouping.keys[0] as TagGroupKey).tagDefinitionId, _number.id);
      expect((grouping.keys[1] as TagGroupKey).tagDefinitionId, _text.id);
    });

    test('같은 태그의 뒤 단계는 버린다', () {
      final grouping = groupFromKeys(const [
        TagGroupKey(3),
        TagGroupKey(2),
        TagGroupKey(3),
      ]);
      expect(grouping.keys, hasLength(2));
      expect((grouping.keys.first as TagGroupKey).tagDefinitionId, _number.id);
      expect((grouping.keys.last as TagGroupKey).tagDefinitionId, _text.id);
    });

    test('폴더 키의 뒤 중복은 버린다', () {
      final grouping = groupFromKeys(const [
        FolderHierarchyGroupKey(),
        TagGroupKey(3),
        FolderHierarchyGroupKey(),
      ]);
      expect(grouping.keys, hasLength(2));
      expect(grouping.keys.first, isA<FolderHierarchyGroupKey>());
      expect((grouping.keys.last as TagGroupKey).tagDefinitionId, _number.id);
    });
  });

  group('FileGrouping', () {
    test('폴더 키 유무를 안다', () {
      const empty = FileGrouping();
      expect(empty.hasFolderHierarchy, isFalse);
      expect(
        const FileGrouping(
          keys: [FolderHierarchyGroupKey()],
        ).hasFolderHierarchy,
        isTrue,
      );
    });

    test('태그 포함 여부를 안다', () {
      const g = FileGrouping(keys: [TagGroupKey(3)]);
      expect(g.containsTag(3), isTrue);
      expect(g.containsTag(2), isFalse);
    });

    test('재배치가 순서를 바꾼다', () {
      const g = FileGrouping(keys: [TagGroupKey(2), TagGroupKey(3)]);
      final r = g.reorder(0, 1);
      expect((r.keys.first as TagGroupKey).tagDefinitionId, _number.id);
    });
  });

  group('포맷', () {
    /// 되펼친 문자열을 다시 파싱하면 같은 키가 나와야 한다.
    void expectRoundTrip(GroupKey key) {
      final def = key is FolderHierarchyGroupKey
          ? folderHierarchyDefinition
          : _defsById[(key as TagGroupKey).tagDefinitionId]!;
      final parsed = _key(formatGroupKey(key, def));
      expect(parsed, equals(key));
    }

    test('태그 키는 이름만 되돌린다', () {
      expect(formatGroupKey(const TagGroupKey(3), _number), '평점');
    });

    test('폴더 키는 폴더 계층 이름을 인용해 되돌린다', () {
      expect(
        formatGroupKey(
          const FolderHierarchyGroupKey(),
          folderHierarchyDefinition,
        ),
        '"폴더 계층"',
      );
    });

    test('인용이 필요한 이름은 인용해 되펼친다', () {
      expect(formatGroupKey(const TagGroupKey(4), _spaced), '"촬영 날짜"');
    });

    test('되펼친 조각은 다시 파싱하면 같은 키다', () {
      expectRoundTrip(const TagGroupKey(3));
      expectRoundTrip(const TagGroupKey(4));
      expectRoundTrip(const TagGroupKey(-3));
      expectRoundTrip(const FolderHierarchyGroupKey());
    });

    test('그룹 전체를 한 줄로 되돌린다', () {
      const grouping = FileGrouping(
        keys: [FolderHierarchyGroupKey(), TagGroupKey(3)],
      );
      expect(formatGroupQuery(grouping, _defsById), '"폴더 계층" 평점');
    });

    test('정의가 사라진 태그의 단계는 텍스트에서 빠진다', () {
      const grouping = FileGrouping(keys: [TagGroupKey(99), TagGroupKey(2)]);
      expect(formatGroupQuery(grouping, _defsById), '메모');
    });
  });

  group('자동완성', () {
    GroupQueryCompletions completions(String text, int cursor) =>
        groupQueryCompletions(text, cursor, definitions: _defs);

    test('빈 자리는 모든 태그와 폴더 계층을 후보로 낸다', () {
      // 사용자·시스템 정의에 폴더 계층 정의가 더해진다.
      expect(completions('', 0).items, hasLength(_defs.length + 1));
    });

    test('친 만큼으로 후보를 거른다', () {
      final c = completions('평', 1);
      expect(c.query, '평');
      expect(c.items.single.definition, _number);
    });

    test('폴더 계층도 이름으로 걸린다', () {
      final c = completions('폴더', 2);
      expect(c.items.single.definition, folderHierarchyDefinition);
      expect(c.items.single.insertText, '"폴더 계층"');
    });

    test('인용이 필요한 이름은 인용된 형태로 넣는다', () {
      final c = completions('촬영', 2);
      expect(c.items.single.insertText, '"촬영 날짜"');
    });

    test('커서가 놓인 조각만 본다', () {
      final c = completions('평점 메', 4);
      expect(c.query, '메');
      expect(c.replaceStart, 3);
    });

    test('커서가 텍스트 밖이면 끝으로 잘라 읽는다', () {
      expect(completions('평점', 99).query, '평점');
    });
  });
}
