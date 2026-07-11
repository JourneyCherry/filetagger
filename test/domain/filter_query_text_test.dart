import 'package:filetagger/domain/entities/file_filter.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_format.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/domain/usecases/filter_query_text.dart';
import 'package:flutter_test/flutter_test.dart';

const _label = TagDefinition(id: 1, name: '숨김', valueType: TagValueType.label);
const _text = TagDefinition(id: 2, name: '메모', valueType: TagValueType.text);
const _number = TagDefinition(
  id: 3,
  name: '평점',
  valueType: TagValueType.number,
);
const _date = TagDefinition(id: 4, name: '촬영', valueType: TagValueType.date);

/// 공백·연산자 문자·부정 접두사를 이름에 품은, 인용이 필요한 태그들.
const _spaced = TagDefinition(
  id: 5,
  name: '촬영 날짜',
  valueType: TagValueType.date,
);
const _operatorish = TagDefinition(
  id: 6,
  name: '평점>',
  valueType: TagValueType.number,
);
const _dashed = TagDefinition(id: 7, name: '-급', valueType: TagValueType.text);

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
  _date,
  _spaced,
  _operatorish,
  _dashed,
  _system,
];

final _defsById = <int, TagDefinition>{for (final d in _defs) d.id!: d};

List<FilterQuerySegment> _parse(String text) =>
    parseFilterQuery(text, definitions: _defs);

/// 조각 하나짜리 입력이 조건으로 접혔는지 확인하고 그 조건을 돌려준다.
FilterCondition _condition(String text) {
  final segments = _parse(text);
  expect(segments, hasLength(1));
  final segment = segments.single;
  expect(
    segment,
    isA<FilterQueryCondition>(),
    reason: segment is FilterQueryFragment ? '${segment.error}' : null,
  );
  return (segment as FilterQueryCondition).condition;
}

/// 조각 하나짜리 입력이 해석되지 않았는지 확인하고 그 이유를 돌려준다.
FilterQueryError _error(String text) {
  final segments = _parse(text);
  expect(segments, hasLength(1));
  expect(segments.single, isA<FilterQueryFragment>());
  return (segments.single as FilterQueryFragment).error;
}

void main() {
  group('parseFilterQuery - 조건 해석', () {
    test('이름만 있으면 존재 조건이다', () {
      final c = _condition('숨김');
      expect(c.tagDefinitionId, _label.id);
      expect(c.operator, FilterOperator.exists);
      expect(c.operand, isNull);
      expect(c.exclude, isFalse);
    });

    test('부정 접두사는 제외 조건으로 읽는다', () {
      expect(_condition('-숨김').exclude, isTrue);
    });

    test('라벨 태그는 존재/미존재 두 형태뿐이다', () {
      // 존재 = 이름만, 미존재 = 부정 접두사. 값 연산자는 붙일 수 없다.
      final present = _condition('숨김');
      expect(present.operator, FilterOperator.exists);
      expect(present.exclude, isFalse);

      final absent = _condition('-숨김');
      expect(absent.operator, FilterOperator.exists);
      expect(absent.exclude, isTrue);

      expect(_error('숨김~x'), FilterQueryError.invalidOperator);
      expect(_error('숨김>1'), FilterQueryError.invalidOperator);
    });

    test('연산자 토큰을 유형에 맞게 읽는다', () {
      expect(_condition('평점>=4').operator, FilterOperator.greaterOrEqual);
      expect(_condition('평점>4').operator, FilterOperator.greaterThan);
      expect(_condition('평점<=4').operator, FilterOperator.lessOrEqual);
      expect(_condition('평점<4').operator, FilterOperator.lessThan);
      expect(_condition('평점==4').operator, FilterOperator.equals);
      expect(_condition('평점!=4').operator, FilterOperator.notEquals);
      expect(_condition('메모~서울').operator, FilterOperator.contains);
      expect(_condition('메모!~서울').operator, FilterOperator.notContains);
    });

    test('같은 글자로 시작하는 부정 토큰끼리 갈린다', () {
      expect(_condition('메모!=서울').operator, FilterOperator.notEquals);
      expect(_condition('메모!~서울').operator, FilterOperator.notContains);
      expect(_condition('메모!~서울').operand, '서울');
    });

    test('같음은 한 글자 별칭으로도 읽는다', () {
      final aliased = _condition('평점=4');
      expect(aliased.operator, FilterOperator.equals);
      expect(aliased.operand, '4');
    });

    test('긴 토큰이 짧은 토큰에 가로채이지 않는다', () {
      expect(_condition('평점>=4').operand, '4');
      // 같음의 두 글자 표기가 한 글자 별칭에 가로채이면 값이 등호로 시작해 깨진다.
      expect(_condition('평점==4').operand, '4');
      expect(_condition('평점==-5').operand, '-5');
    });

    test('제외 조건과 값 비교를 함께 쓸 수 있다', () {
      final c = _condition('-평점<4');
      expect(c.exclude, isTrue);
      expect(c.operator, FilterOperator.lessThan);
      expect(c.operand, '4');
    });

    test('음수 값은 부정 접두사와 헷갈리지 않는다', () {
      expect(_condition('평점>-5').operand, '-5');
    });

    test('구분문자로 여러 조건을 나눈다', () {
      final segments = _parse('평점>=4 -숨김 메모~서울');
      expect(segments, hasLength(3));
      expect(segments.every((s) => s is FilterQueryCondition), isTrue);
    });

    test('공백이 연달아 있어도 빈 조각을 만들지 않는다', () {
      expect(_parse('  평점>=4   -숨김  '), hasLength(2));
    });

    test('시스템 태그도 이름으로 해석한다', () {
      expect(_condition('"이미지 크기"~1920').tagDefinitionId, _system.id);
    });

    test('날짜 값은 저장 형식으로 정규화한다', () {
      final c = _condition('촬영>=2026-01-01');
      expect(c.operand, dateToStoredValue(DateTime(2026, 1, 1)));
    });
  });

  group('parseFilterQuery - 인용과 이스케이프', () {
    test('인용 안의 공백은 조각을 가르지 않는다', () {
      final segments = _parse('메모~"서울 여행"');
      expect(segments, hasLength(1));
      expect(_condition('메모~"서울 여행"').operand, '서울 여행');
    });

    test('공백이 든 태그 이름을 인용으로 쓴다', () {
      final c = _condition('"촬영 날짜">=2026-01-01');
      expect(c.tagDefinitionId, _spaced.id);
      expect(c.operator, FilterOperator.greaterOrEqual);
    });

    test('이스케이프한 인용부호는 값의 글자가 된다', () {
      expect(_condition(r'메모~"그는 \"안녕\"이라 말했다"').operand, '그는 "안녕"이라 말했다');
    });

    test('이스케이프한 탈출 문자 자신도 값의 글자가 된다', () {
      expect(_condition(r'메모~"C:\\경로"').operand, r'C:\경로');
    });

    test('인용하지 않아도 이스케이프로 공백을 넣을 수 있다', () {
      expect(_condition(r'메모~서울\ 여행').operand, '서울 여행');
    });

    test('이스케이프한 연산자 문자는 이름을 끊지 않는다', () {
      expect(_condition(r'평점\>=4').tagDefinitionId, _operatorish.id);
    });
  });

  group('parseFilterQuery - 미완성·무효 조각', () {
    test('없는 태그 이름', () {
      expect(_error('없는태그=1'), FilterQueryError.unknownTag);
      expect(_error('없는태그'), FilterQueryError.unknownTag);
    });

    test('부정 접두사만 있으면 이름이 비어 해석하지 못한다', () {
      expect(_error('-'), FilterQueryError.unknownTag);
    });

    test('태그 유형이 허용하지 않는 연산자', () {
      // label은 존재 여부만, text는 대소 비교가 없다.
      expect(_error('숨김=1'), FilterQueryError.invalidOperator);
      expect(_error('메모>1'), FilterQueryError.invalidOperator);
    });

    test('연산자 없이 붙은 군더더기는 이름의 일부로 읽혀 태그를 찾지 못한다', () {
      expect(_error('평점4'), FilterQueryError.unknownTag);
      expect(_error('평점?4'), FilterQueryError.unknownTag);
    });

    test('값이 비었으면 미완성이다', () {
      expect(_error('평점>='), FilterQueryError.missingValue);
      expect(_error('메모~""'), FilterQueryError.missingValue);
    });

    test('인용부호가 닫히지 않으면 미완성이다', () {
      expect(_error('메모~"서울'), FilterQueryError.unterminatedQuote);
      expect(_error('"촬영 날짜'), FilterQueryError.unterminatedQuote);
    });

    test('유형에 맞지 않는 값', () {
      expect(_error('평점>=넷'), FilterQueryError.invalidValue);
      expect(_error('촬영>=어제'), FilterQueryError.invalidValue);
    });

    test('닫는 인용부호 뒤의 군더더기', () {
      expect(_error('메모~"서울"여행'), FilterQueryError.invalidValue);
    });

    test('무효 조각은 원문을 그대로 보존한다', () {
      final segments = _parse('평점>= 숨김');
      expect(segments, hasLength(2));
      expect(segments.first, isA<FilterQueryFragment>());
      expect(segments.first.text, '평점>=');
      expect(segments.last, isA<FilterQueryCondition>());
    });
  });

  group('filterFromSegments', () {
    test('해석된 조건만 담고 미완성·무효는 버린다', () {
      final filter = filterFromSegments(_parse('평점>=4 없는태그=1 메모~"서울 여행"'));
      expect(filter.conditions, hasLength(2));
      expect(filter.conditions.first.tagDefinitionId, _number.id);
      expect(filter.conditions.last.tagDefinitionId, _text.id);
    });
  });

  group('formatFilterCondition', () {
    test('존재 조건은 이름만 쓴다', () {
      expect(
        formatFilterCondition(
          const FilterCondition(tagDefinitionId: 1),
          _label,
        ),
        '숨김',
      );
    });

    test('제외 조건은 부정 접두사를 앞에 붙인다', () {
      expect(
        formatFilterCondition(
          const FilterCondition(tagDefinitionId: 1, exclude: true),
          _label,
        ),
        '-숨김',
      );
    });

    test('공백이 든 이름·값만 인용한다', () {
      expect(
        formatFilterCondition(
          const FilterCondition(
            tagDefinitionId: 2,
            operator: FilterOperator.contains,
            operand: '서울',
          ),
          _text,
        ),
        '메모~서울',
      );
      expect(
        formatFilterCondition(
          const FilterCondition(
            tagDefinitionId: 2,
            operator: FilterOperator.contains,
            operand: '서울 여행',
          ),
          _text,
        ),
        '메모~"서울 여행"',
      );
    });

    test('별칭으로 입력해도 정식 토큰으로 되펼친다', () {
      final parsed = _condition('평점=4');
      expect(formatFilterCondition(parsed, _number), '평점==4');
    });

    test('연산자 문자나 부정 접두사로 시작하는 이름은 인용한다', () {
      expect(
        formatFilterCondition(
          const FilterCondition(tagDefinitionId: 6),
          _operatorish,
        ),
        '"평점>"',
      );
      expect(
        formatFilterCondition(
          const FilterCondition(tagDefinitionId: 7),
          _dashed,
        ),
        '"-급"',
      );
    });
  });

  group('왕복', () {
    /// 조건 → 텍스트 → 조건이 같은 값으로 돌아오는지.
    void roundTrip(FilterCondition condition, TagDefinition def) {
      final text = formatFilterCondition(condition, def);
      final parsed = _condition(text);
      expect(parsed.tagDefinitionId, condition.tagDefinitionId, reason: text);
      expect(parsed.operator, condition.operator, reason: text);
      expect(parsed.operand, condition.operand, reason: text);
      expect(parsed.exclude, condition.exclude, reason: text);
    }

    test('존재·제외·값 비교 조건이 왕복한다', () {
      roundTrip(const FilterCondition(tagDefinitionId: 1), _label);
      roundTrip(
        const FilterCondition(tagDefinitionId: 1, exclude: true),
        _label,
      );
      roundTrip(
        const FilterCondition(
          tagDefinitionId: 3,
          operator: FilterOperator.greaterOrEqual,
          operand: '4',
        ),
        _number,
      );
      roundTrip(
        const FilterCondition(
          tagDefinitionId: 3,
          operator: FilterOperator.lessThan,
          operand: '-5',
          exclude: true,
        ),
        _number,
      );
    });

    test('공백·인용부호·탈출 문자가 든 값이 왕복한다', () {
      roundTrip(
        const FilterCondition(
          tagDefinitionId: 2,
          operator: FilterOperator.contains,
          operand: '서울 여행',
        ),
        _text,
      );
      roundTrip(
        const FilterCondition(
          tagDefinitionId: 2,
          operator: FilterOperator.equals,
          operand: '그는 "안녕"이라 말했다',
        ),
        _text,
      );
      roundTrip(
        const FilterCondition(
          tagDefinitionId: 2,
          operator: FilterOperator.equals,
          operand: r'C:\경로',
        ),
        _text,
      );
    });

    test('인용이 필요한 이름이 왕복한다', () {
      roundTrip(const FilterCondition(tagDefinitionId: 6), _operatorish);
      roundTrip(const FilterCondition(tagDefinitionId: 7), _dashed);
      roundTrip(
        const FilterCondition(
          tagDefinitionId: 5,
          operator: FilterOperator.greaterOrEqual,
          operand: '2026-01-01T00:00:00.000',
        ),
        _spaced,
      );
    });

    test('날짜 조건이 저장 형식 그대로 왕복한다', () {
      roundTrip(
        FilterCondition(
          tagDefinitionId: 4,
          operator: FilterOperator.lessOrEqual,
          operand: dateToStoredValue(DateTime(2026, 7, 9)),
        ),
        _date,
      );
    });
  });

  group('formatFilterQuery', () {
    test('조건들을 구분문자로 잇는다', () {
      const filter = FileFilter(
        conditions: [
          FilterCondition(
            tagDefinitionId: 3,
            operator: FilterOperator.greaterOrEqual,
            operand: '4',
          ),
          FilterCondition(tagDefinitionId: 1, exclude: true),
        ],
      );
      expect(formatFilterQuery(filter, _defsById), '평점>=4 -숨김');
    });

    test('정의가 사라진 태그의 조건은 텍스트로 표현하지 않는다', () {
      const filter = FileFilter(
        conditions: [
          FilterCondition(tagDefinitionId: 999),
          FilterCondition(tagDefinitionId: 1),
        ],
      );
      expect(formatFilterQuery(filter, _defsById), '숨김');
    });

    test('텍스트 한 줄이 필터로 왕복한다', () {
      const text = '평점>=4 -숨김 메모~"서울 여행"';
      final filter = filterFromSegments(_parse(text));
      expect(formatFilterQuery(filter, _defsById), text);
    });
  });

  group('filterQueryCompletions', () {
    /// 커서를 `|`로 표시한 입력에서 후보를 낸다(위치를 눈으로 확인하려고).
    FilterQueryCompletions at(String marked) {
      final cursor = marked.indexOf('|');
      expect(cursor, isNonNegative, reason: '커서 표시가 없다');
      return filterQueryCompletions(
        marked.replaceFirst('|', ''),
        cursor,
        definitions: _defs,
      );
    }

    List<String> tagNames(FilterQueryCompletions c) => [
      for (final item in c.items) (item as FilterTagCompletion).definition.name,
    ];

    List<FilterOperator> operators(FilterQueryCompletions c) => [
      for (final item in c.items) (item as FilterOperatorCompletion).operator,
    ];

    group('태그 자리', () {
      test('빈 입력은 모든 태그를 후보로 낸다', () {
        final c = at('|');
        expect(c.slot, FilterQuerySlot.tag);
        expect(c.query, isEmpty);
        expect(tagNames(c), _defs.map((d) => d.name));
        expect(c.tag, isNull);
      });

      test('조각 사이 공백에서는 새 조각을 시작한다', () {
        final c = at('평점>=4 | 숨김');
        expect(c.slot, FilterQuerySlot.tag);
        expect(c.query, isEmpty);
        expect(c.replaceStart, c.replaceEnd);
      });

      test('이름 접두사로 후보를 거른다', () {
        final c = at('촬영|');
        expect(c.slot, FilterQuerySlot.tag);
        expect(c.query, '촬영');
        expect(tagNames(c), ['촬영', '촬영 날짜']);
      });

      test('접두사로 시작하는 태그가 품기만 한 태그보다 앞선다', () {
        expect(tagNames(at('크기|')), ['이미지 크기']);
        expect(tagNames(at('이미지|')), ['이미지 크기']);
      });

      test('부정 접두사 뒤의 커서도 태그 자리다', () {
        final c = at('-|');
        expect(c.slot, FilterQuerySlot.tag);
        expect(c.query, isEmpty);
        expect(tagNames(c), _defs.map((d) => d.name));

        final typed = at('-숨|');
        expect(typed.slot, FilterQuerySlot.tag);
        expect(typed.query, '숨');
        expect(tagNames(typed), ['숨김']);
      });

      test('부정 접두사 앞의 커서는 접두사를 갈아 끼우지 않는다', () {
        final c = at('|-숨김');
        expect(c.slot, FilterQuerySlot.tag);
        expect(c.query, isEmpty);
        expect(c.replaceStart, kFilterExcludePrefix.length);
        expect(c.replaceEnd, '-숨김'.length);
      });

      test('인용 안쪽의 커서는 인용을 푼 문자열로 거른다', () {
        final c = at('"촬영 |');
        expect(c.slot, FilterQuerySlot.tag);
        expect(c.query, '촬영 ');
        expect(tagNames(c), ['촬영 날짜']);
      });

      test('인용이 닫힌 이름 안쪽의 커서', () {
        final c = at('"촬영|"');
        expect(c.slot, FilterQuerySlot.tag);
        expect(c.query, '촬영');
        // 갈아 끼울 구간은 닫는 인용부호까지다.
        expect(c.replaceStart, 0);
        expect(c.replaceEnd, '"촬영"'.length);
      });

      test('이름 끝의 커서는 뒤에 연산자가 있어도 태그 자리다', () {
        final c = at('평점|>=4');
        expect(c.slot, FilterQuerySlot.tag);
        expect(c.query, '평점');
        expect(c.replaceEnd, '평점'.length);
      });

      test('후보를 고르면 인용이 필요한 이름은 인용된 채로 들어간다', () {
        final c = at('촬영 날|');
        // 공백에서 조각이 갈려 '날'이 새 조각의 이름이 된다.
        expect(c.query, '날');
        final item = c.items.single as FilterTagCompletion;
        expect(item.definition.name, '촬영 날짜');
        expect(item.insertText, '"촬영 날짜"');
      });

      test('맞는 태그가 없으면 후보가 비고 원문 구간은 남는다', () {
        final c = at('없는태그|');
        expect(c.slot, FilterQuerySlot.tag);
        expect(c.items, isEmpty);
        expect(c.replaceStart, 0);
        expect(c.replaceEnd, '없는태그'.length);
      });
    });

    group('연산자 자리', () {
      test('이름 뒤의 커서는 태그 유형이 허용하는 연산자를 낸다', () {
        final c = at('평점>|');
        expect(c.slot, FilterQuerySlot.operator);
        expect(c.tag?.name, '평점');
        expect(c.query, '>');
        expect(operators(c), [
          FilterOperator.greaterThan,
          FilterOperator.greaterOrEqual,
        ]);
      });

      test('입력 중인 토큰으로 후보를 거른다', () {
        expect(operators(at('메모!|')), [
          FilterOperator.notEquals,
          FilterOperator.notContains,
        ]);
        expect(operators(at('메모!~|')), [FilterOperator.notContains]);
      });

      test('토큰을 갈아 끼울 구간은 값 앞까지다', () {
        final c = at('평점>|=4');
        expect(c.slot, FilterQuerySlot.operator);
        expect(c.replaceStart, '평점'.length);
        expect(c.replaceEnd, '평점>='.length);
        expect(
          c.items.first.insertText,
          filterOperatorToken(FilterOperator.greaterThan),
        );
      });

      test('존재 연산은 토큰이 없어 후보에 없다', () {
        // label 태그는 존재 연산뿐이라 후보가 빈다.
        final label = at('숨김>|');
        expect(label.slot, FilterQuerySlot.operator);
        expect(label.tag?.name, '숨김');
        expect(label.items, isEmpty);

        expect(operators(at('메모~|x')), [FilterOperator.contains]);
      });

      test('별칭을 치면 정식 토큰을 후보로 낸다', () {
        final c = at('평점=|');
        expect(c.slot, FilterQuerySlot.operator);
        expect(c.query, '=');
        expect(operators(c), [FilterOperator.equals]);
        expect(
          c.items.single.insertText,
          filterOperatorToken(FilterOperator.equals),
        );
      });

      test('태그를 해석하지 못하면 후보가 없다', () {
        final c = at('없는태그>|');
        expect(c.slot, FilterQuerySlot.operator);
        expect(c.tag, isNull);
        expect(c.items, isEmpty);
      });

      test('인용한 이름 뒤에서도 연산자를 낸다', () {
        final c = at('"촬영 날짜">|');
        expect(c.slot, FilterQuerySlot.operator);
        expect(c.tag?.name, '촬영 날짜');
        expect(operators(c), [
          FilterOperator.greaterThan,
          FilterOperator.greaterOrEqual,
        ]);
      });
    });

    group('값 자리', () {
      test('연산자 뒤의 커서는 값 자리이고 후보가 없다', () {
        final c = at('평점>=4|');
        expect(c.slot, FilterQuerySlot.value);
        expect(c.tag?.name, '평점');
        expect(c.query, '4');
        expect(c.items, isEmpty);
        expect(c.replaceStart, '평점>='.length);
        expect(c.replaceEnd, '평점>=4'.length);
      });

      test('인용 안쪽의 커서는 인용을 푼 값을 낸다', () {
        final c = at('메모~"서울 여|행"');
        expect(c.slot, FilterQuerySlot.value);
        expect(c.query, '서울 여');
        expect(c.replaceEnd, '메모~"서울 여행"'.length);
      });

      test('별칭 연산자로 시작한 값도 값 자리다', () {
        final c = at('평점=4|');
        expect(c.slot, FilterQuerySlot.value);
        expect(c.tag?.name, '평점');
        expect(c.query, '4');
      });
    });

    test('커서가 텍스트 밖이면 끝으로 잘라 읽는다', () {
      final c = filterQueryCompletions('평점', 99, definitions: _defs);
      expect(c.slot, FilterQuerySlot.tag);
      expect(c.query, '평점');
    });
  });
}
