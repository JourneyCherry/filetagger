import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/domain/usecases/query_text_syntax.dart';
import 'package:flutter_test/flutter_test.dart';

const _rating = TagDefinition(
  id: 1,
  name: '평점',
  valueType: TagValueType.number,
);
const _memo = TagDefinition(id: 2, name: '메모', valueType: TagValueType.text);
const _unsaved = TagDefinition(name: '아직', valueType: TagValueType.text);

void main() {
  group('queryChunkRanges', () {
    test('조각 사이의 공백은 어느 구간에도 들지 않는다', () {
      expect(queryChunkRanges('  평점>=4   숨김 '), [
        (start: 2, end: 7),
        (start: 10, end: 12),
      ]);
    });

    test('인용부호 안의 공백에서는 자르지 않는다', () {
      final text = '"촬영 날짜">=2024-01-01';
      expect(queryChunkRanges(text), [(start: 0, end: text.length)]);
    });

    test('이스케이프한 공백에서는 자르지 않는다', () {
      expect(splitQueryChunks(r'촬영\ 날짜'), [r'촬영\ 날짜']);
    });

    test('빈 텍스트는 구간이 없다', () {
      expect(queryChunkRanges('   '), isEmpty);
    });
  });

  group('queryChunkRangeAt', () {
    test('조각의 양 끝도 그 조각으로 본다', () {
      expect(queryChunkRangeAt('평점 메모', 0), (start: 0, end: 2));
      expect(queryChunkRangeAt('평점 메모', 2), (start: 0, end: 2));
    });

    test('조각 사이의 공백 안이면 null', () {
      expect(queryChunkRangeAt('평점  메모', 3), isNull);
    });
  });

  group('readQueryField', () {
    test('인용하지 않은 필드는 멈춤 글자 앞까지 읽는다', () {
      final field = readQueryField('평점>=4', 0, stopChars: {'>', '='});
      expect(field.value, '평점');
      expect(field.end, 2);
      expect(field.closed, isTrue);
    });

    test('멈춤 글자가 없으면 조각 끝까지 읽는다', () {
      final field = readQueryField('평점>=4', 0);
      expect(field.value, '평점>=4');
    });

    test('인용부호 안은 멈춤 글자를 보통 글자로 읽는다', () {
      final field = readQueryField('"평점>"=4', 0, stopChars: {'>', '='});
      expect(field.value, '평점>');
      expect(field.end, 5);
    });

    test('이스케이프한 글자는 그대로 값에 들어간다', () {
      expect(readQueryField(r'a\"b', 0).value, 'a"b');
    });

    test('닫히지 않은 인용부호는 읽은 만큼 돌려주되 closed가 아니다', () {
      final field = readQueryField('"평점', 0);
      expect(field.value, '평점');
      expect(field.closed, isFalse);
      expect(readClosedQueryField('"평점', 0), isNull);
    });
  });

  group('queryFieldPrefix', () {
    test('커서 앞까지만 인용·이스케이프를 풀어 읽는다', () {
      expect(queryFieldPrefix('"촬영 날짜"', 0, 4), '촬영 ');
    });

    test('커서가 시작보다 앞이면 빈 문자열', () {
      expect(queryFieldPrefix('-평점', 1, 0), '');
    });
  });

  group('quoteQueryToken', () {
    test('그냥 읽히는 이름은 인용하지 않는다', () {
      expect(quoteQueryToken('평점'), '평점');
    });

    test('공백·인용부호·이스케이프 문자는 인용을 부른다', () {
      expect(quoteQueryToken('촬영 날짜'), '"촬영 날짜"');
      expect(quoteQueryToken('a"b'), r'"a\"b"');
      expect(quoteQueryToken(r'a\b'), r'"a\\b"');
    });

    test('빈 문자열은 인용해야 조각으로 남는다', () {
      expect(quoteQueryToken(''), '""');
    });

    test('예약 글자는 그 자리에서만 인용을 부른다', () {
      expect(quoteQueryToken('평점>'), '평점>');
      expect(quoteQueryToken('평점>', reserved: {'>'}), '"평점>"');
    });

    test('예약 접두사로 시작하는 이름만 인용한다', () {
      expect(quoteQueryToken('-급', reservedPrefix: '-'), '"-급"');
      expect(quoteQueryToken('급-', reservedPrefix: '-'), '급-');
    });

    test('인용한 이름을 다시 읽으면 원래 이름이 나온다', () {
      const raw = '촬영 "날짜"';
      final quoted = quoteQueryToken(raw);
      expect(readQueryField(quoted, 0).value, raw);
    });
  });

  group('tagsByName', () {
    test('저장 전(id 없는) 정의는 이름 해석 대상이 아니다', () {
      final byName = tagsByName([_rating, _unsaved]);
      expect(byName['평점'], _rating);
      expect(byName['아직'], isNull);
    });
  });

  group('matchTagsByName', () {
    const contained = TagDefinition(
      id: 3,
      name: '누적 평점',
      valueType: TagValueType.number,
    );

    test('접두 일치가 포함 일치보다 앞에 온다', () {
      expect(matchTagsByName([contained, _rating], '평점'), [_rating, contained]);
    });

    test('빈 질의는 모든 태그를 낸다', () {
      expect(matchTagsByName([_rating, _memo], ''), [_rating, _memo]);
    });

    test('맞는 이름이 없으면 후보가 비어 있다', () {
      expect(matchTagsByName([_rating, _memo], 'zzz'), isEmpty);
    });
  });
}
