import 'package:filetagger/domain/entities/file_sort.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/domain/usecases/sort_query_text.dart';
import 'package:flutter_test/flutter_test.dart';

const _label = TagDefinition(id: 1, name: '숨김', valueType: TagValueType.label);
const _text = TagDefinition(id: 2, name: '메모', valueType: TagValueType.text);
const _number = TagDefinition(
  id: 3,
  name: '평점',
  valueType: TagValueType.number,
);

/// 공백·방향 접두사를 이름에 품은, 인용이 필요한 태그들.
const _spaced = TagDefinition(
  id: 4,
  name: '촬영 날짜',
  valueType: TagValueType.date,
);
const _dashed = TagDefinition(id: 5, name: '-급', valueType: TagValueType.text);

/// 시스템 태그는 음수 id를 쓰며 이름 해석 대상에 함께 들어간다.
const _system = TagDefinition(
  id: -1,
  name: '이미지 크기',
  valueType: TagValueType.text,
  isSystem: true,
);

const _defs = <TagDefinition>[
  _label,
  _text,
  _number,
  _spaced,
  _dashed,
  _system,
];

final _defsById = <int, TagDefinition>{for (final d in _defs) d.id!: d};

List<SortQuerySegment> _parse(String text) =>
    parseSortQuery(text, definitions: _defs);

/// 조각 하나짜리 입력이 단계로 접혔는지 확인하고 그 단계를 돌려준다.
SortKey _key(String text) {
  final segments = _parse(text);
  expect(segments, hasLength(1));
  final segment = segments.single;
  expect(segment, isA<SortQueryKey>(), reason: '"$text"가 단계로 접히지 않았다');
  return (segment as SortQueryKey).key;
}

/// 조각 하나짜리 입력이 해석되지 않았는지 확인하고 그 이유를 돌려준다.
SortQueryError _error(String text) {
  final segments = _parse(text);
  expect(segments, hasLength(1));
  final segment = segments.single;
  expect(segment, isA<SortQueryFragment>(), reason: '"$text"가 접히면 안 된다');
  return (segment as SortQueryFragment).error;
}

void main() {
  group('파싱', () {
    test('이름만 쓰면 오름차순이다', () {
      final key = _key('평점');
      expect(key.tagDefinitionId, _number.id);
      expect(key.direction, SortDirection.ascending);
    });

    test('방향 접두사를 붙이면 내림차순이다', () {
      expect(_key('-평점').direction, SortDirection.descending);
    });

    test('빈 줄은 조각이 없다', () {
      expect(_parse('   '), isEmpty);
    });

    test('여러 조각은 텍스트 순서대로 우선순위가 된다', () {
      final keys = _parse('-평점 메모 숨김').whereType<SortQueryKey>().toList();
      expect(keys.map((s) => s.key.tagDefinitionId), [
        _number.id,
        _text.id,
        _label.id,
      ]);
    });

    test('시스템 태그도 이름으로 찾는다', () {
      expect(_key('"이미지 크기"').tagDefinitionId, _system.id);
    });

    test('공백이 든 이름은 인용해야 한 조각이 된다', () {
      expect(_key('-"촬영 날짜"').direction, SortDirection.descending);
      expect(_parse('촬영 날짜'), hasLength(2));
    });

    test('방향 접두사로 시작하는 이름은 인용해야 방향과 갈린다', () {
      expect(_key('"-급"').tagDefinitionId, _dashed.id);
      // 인용하지 않으면 접두사로 읽혀 "급"이라는 태그를 찾는다.
      expect(_error('-급'), SortQueryError.unknownTag);
    });

    test('라벨 태그는 방향이 없어 접두사를 거부한다', () {
      expect(_key('숨김').direction, SortDirection.ascending);
      expect(_error('-숨김'), SortQueryError.directionNotAllowed);
    });

    test('없는 이름은 해석하지 못한다', () {
      expect(_error('없는태그'), SortQueryError.unknownTag);
      expect(_error('-'), SortQueryError.unknownTag);
    });

    test('닫히지 않은 인용부호는 미완성 조각으로 남는다', () {
      expect(_error('"평점'), SortQueryError.unterminatedQuote);
    });

    test('인용부호를 닫은 뒤의 군더더기는 무효다', () {
      expect(_error('"평점"x'), SortQueryError.trailingText);
    });

    test('해석하지 못한 조각은 원문을 그대로 지닌다', () {
      final segments = _parse('없는태그 평점');
      expect(segments.first.text, '없는태그');
    });
  });

  group('sortFromSegments', () {
    test('해석된 단계만 순서대로 모은다', () {
      final sort = sortFromSegments(_parse('-평점 없는태그 메모'));
      expect(sort.keys.map((k) => k.tagDefinitionId), [_number.id, _text.id]);
    });

    test('같은 태그의 뒤 단계는 버린다', () {
      final sort = sortFromKeys(const [
        SortKey(tagDefinitionId: 3, direction: SortDirection.descending),
        SortKey(tagDefinitionId: 2),
        SortKey(tagDefinitionId: 3),
      ]);
      expect(sort.keys, hasLength(2));
      expect(sort.keys.first.direction, SortDirection.descending);
      expect(sort.keys.last.tagDefinitionId, _text.id);
    });
  });

  group('포맷', () {
    /// 되펼친 문자열을 다시 파싱하면 같은 단계가 나와야 한다.
    void expectRoundTrip(SortKey key) {
      final def = _defsById[key.tagDefinitionId]!;
      final parsed = _key(formatSortKey(key, def));
      expect(parsed.tagDefinitionId, key.tagDefinitionId);
      expect(parsed.direction, key.direction);
    }

    test('오름차순은 이름만, 내림차순은 접두사를 붙인다', () {
      expect(formatSortKey(const SortKey(tagDefinitionId: 3), _number), '평점');
      expect(
        formatSortKey(
          const SortKey(
            tagDefinitionId: 3,
            direction: SortDirection.descending,
          ),
          _number,
        ),
        '-평점',
      );
    });

    test('인용이 필요한 이름은 인용해 되펼친다', () {
      expect(formatSortKey(const SortKey(tagDefinitionId: 5), _dashed), '"-급"');
      expect(
        formatSortKey(
          const SortKey(
            tagDefinitionId: 4,
            direction: SortDirection.descending,
          ),
          _spaced,
        ),
        '-"촬영 날짜"',
      );
    });

    test('라벨 태그에 남은 방향은 되펼칠 때 지워진다', () {
      expect(
        formatSortKey(
          const SortKey(
            tagDefinitionId: 1,
            direction: SortDirection.descending,
          ),
          _label,
        ),
        '숨김',
      );
    });

    test('되펼친 조각은 다시 파싱하면 같은 단계다', () {
      expectRoundTrip(const SortKey(tagDefinitionId: 3));
      expectRoundTrip(
        const SortKey(tagDefinitionId: 4, direction: SortDirection.descending),
      );
      expectRoundTrip(const SortKey(tagDefinitionId: 5));
      expectRoundTrip(const SortKey(tagDefinitionId: -1));
    });

    test('정렬 전체를 한 줄로 되돌린다', () {
      const sort = FileSortOrder(
        keys: [
          SortKey(tagDefinitionId: 3, direction: SortDirection.descending),
          SortKey(tagDefinitionId: 2),
        ],
      );
      expect(formatSortQuery(sort, _defsById), '-평점 메모');
    });

    test('정의가 사라진 태그의 단계는 텍스트에서 빠진다', () {
      const sort = FileSortOrder(
        keys: [SortKey(tagDefinitionId: 99), SortKey(tagDefinitionId: 2)],
      );
      expect(formatSortQuery(sort, _defsById), '메모');
    });
  });

  group('자동완성', () {
    SortQueryCompletions completions(String text, int cursor) =>
        sortQueryCompletions(text, cursor, definitions: _defs);

    test('빈 자리는 모든 태그를 후보로 낸다', () {
      expect(completions('', 0).items, hasLength(_defs.length));
    });

    test('친 만큼으로 후보를 거른다', () {
      final c = completions('평', 1);
      expect(c.query, '평');
      expect(c.items.single.definition, _number);
    });

    test('방향 접두사 위의 커서도 태그 자리다', () {
      final c = completions('-평점', 0);
      expect(c.query, '');
      expect(c.items, isNotEmpty);
    });

    test('대체 구간은 방향 접두사를 건드리지 않는다', () {
      final c = completions('-평', 2);
      expect(c.query, '평');
      expect(c.replaceStart, kSortDescendingPrefix.length);
      expect(c.replaceEnd, 2);
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
