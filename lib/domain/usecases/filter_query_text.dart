/// 필터 조건의 **텍스트 표현**을 파싱·포맷한다.
///
/// 텍스트는 편집 표면일 뿐이고 저장 모델은 그대로다 — 조건은 태그 정의 id로
/// 저장되며([FilterCondition.tagDefinitionId]), 여기서 입력 시 이름→정의로
/// 해석하고 되펼칠 때 정의→이름으로 되돌린다.
///
/// 조각 하나가 조건 하나다. 조각을 나누고 이름·값을 읽고 인용하는 규칙은 정렬
/// 텍스트와 공유한다([query_text_syntax]). 여기엔 필터에만 있는 것 — 제외
/// 접두사와 값 비교 연산자 — 을 얹는다.
///
/// 파싱은 성공/실패 두 갈래가 아니라 **해석하지 못한 원문을 보존**한다
/// ([FilterQueryFragment]). 미완성(입력 중)과 무효를 같은 방식으로 남겨, 포커스를
/// 잃어도 텍스트에 그대로 두고 저장할 때만 걸러낼 수 있게 한다.
library;

import '../entities/file_filter.dart';
import '../entities/tag_definition.dart';
import '../entities/tag_value_format.dart';
import '../entities/tag_value_type.dart';
import 'query_text_syntax.dart';

// ── 문법 토큰 (단일 출처) ──
//
// 표시용 기호는 presentation의 `filterOperatorLabel`에 따로 있다. 그쪽엔 키보드로
// 칠 수 없는 문자가 있어 입력 토큰으로 쓸 수 없으므로, 입력은 여기 정의를 쓴다.

/// 조건을 제외 조건으로 만드는, 태그 이름 앞의 부정 접두사.
const String kFilterExcludePrefix = '-';

/// 값 비교 연산자의 정식 입력 토큰. 프로그래밍 언어의 비교 연산자를 따른다.
/// [FilterOperator.exists]는 토큰이 없다(이름만 쓴다). 포매터는 이 표기로 되펼친다.
const Map<FilterOperator, String> _operatorTokens = <FilterOperator, String>{
  FilterOperator.equals: '==',
  FilterOperator.notEquals: '!=',
  FilterOperator.lessOrEqual: '<=',
  FilterOperator.greaterOrEqual: '>=',
  FilterOperator.lessThan: '<',
  FilterOperator.greaterThan: '>',
  FilterOperator.contains: '~',
  FilterOperator.notContains: '!~',
};

/// 입력에서만 받아 주는 별칭. 검색 질의 언어의 관용대로 같음을 한 글자로 쓰는
/// 사람이 있어 함께 읽는다. 되펼칠 땐 정식 토큰으로 정규화된다.
const Map<String, FilterOperator> _operatorAliases = <String, FilterOperator>{
  '=': FilterOperator.equals,
};

/// [op]의 정식 입력 토큰. 값이 없는 존재 연산이면 null(태그 이름만으로 표현된다).
String? filterOperatorToken(FilterOperator op) => _operatorTokens[op];

/// 파싱이 시도하는 토큰 전부(정식 + 별칭). 긴 토큰을 먼저 맞춰야 짧은 토큰이
/// 접두사로 가로채지 않는다(같음의 두 표기, 비교와 그 등호 결합형).
final List<MapEntry<String, FilterOperator>> _matchOrder =
    <MapEntry<String, FilterOperator>>[
      for (final e in _operatorTokens.entries) MapEntry(e.value, e.key),
      ..._operatorAliases.entries,
    ]..sort((a, b) => b.key.length.compareTo(a.key.length));

/// 연산자 토큰이 시작될 수 있는 글자들. 인용하지 않은 태그 이름은 여기서 끝난다.
final Set<String> _operatorStartChars = {
  for (final entry in _matchOrder) entry.key[0],
};

/// 연산자 토큰에 쓰이는 글자 전부. 아직 토큰을 이루지 못한 입력 중인 연산자
/// 자리를 알아보는 데 쓴다(자동완성).
final Set<String> _operatorChars = {
  for (final entry in _matchOrder) ...entry.key.split(''),
};

// ── 파싱 결과 ──

/// 조각을 조건으로 해석하지 못한 이유. 화면이 무효 표시를 고르는 데 쓴다.
enum FilterQueryError {
  /// 그 이름의 태그 정의가 없다(오타이거나 삭제된 태그).
  unknownTag,

  /// 연산자를 읽지 못했거나, 태그 유형이 허용하지 않는 연산자다.
  invalidOperator,

  /// 값 비교 연산인데 값이 비었다(대개 입력 중인 미완성 조각).
  missingValue,

  /// 태그 유형에 맞지 않는 값이다(숫자 자리의 비숫자 등).
  invalidValue,

  /// 인용부호가 닫히지 않았다(대개 입력 중인 미완성 조각).
  unterminatedQuote,
}

/// 텍스트 한 줄을 이루는 조각 하나. 조건으로 접히거나([FilterQueryCondition]),
/// 원문 그대로 남는다([FilterQueryFragment]).
sealed class FilterQuerySegment {
  const FilterQuerySegment(this.text);

  /// 이 조각의 원문. 이어 붙이면 입력을 되살릴 수 있다(공백 구간은 정규화된다).
  final String text;
}

/// 조건으로 해석된 조각. 화면은 이걸 캡슐로 접어 보여준다.
final class FilterQueryCondition extends FilterQuerySegment {
  const FilterQueryCondition(super.text, this.condition);

  final FilterCondition condition;
}

/// 해석하지 못해 원문으로 남는 조각. 저장에서 빠진다.
final class FilterQueryFragment extends FilterQuerySegment {
  const FilterQueryFragment(super.text, this.error);

  final FilterQueryError error;
}

// ── 파싱 ──

/// 텍스트 한 줄을 조각 목록으로 읽는다. [definitions]는 이름 해석의 대상이며,
/// 시스템 태그(음수 id)도 함께 넘겨야 이름으로 찾을 수 있다.
List<FilterQuerySegment> parseFilterQuery(
  String text, {
  required Iterable<TagDefinition> definitions,
}) {
  final byName = tagsByName(definitions);
  return [
    for (final chunk in splitQueryChunks(text)) _parseChunk(chunk, byName),
  ];
}

/// 조각들에서 해석된 조건만 모아 필터를 만든다(미완성·무효 조각은 저장하지 않는다).
FileFilter filterFromSegments(Iterable<FilterQuerySegment> segments) =>
    FileFilter(
      conditions: [
        for (final s in segments)
          if (s is FilterQueryCondition) s.condition,
      ],
    );

FilterQuerySegment _parseChunk(String raw, Map<String, TagDefinition> byName) {
  var cursor = 0;
  var exclude = false;
  if (raw.startsWith(kFilterExcludePrefix)) {
    exclude = true;
    cursor = kFilterExcludePrefix.length;
  }

  final name = readClosedQueryField(
    raw,
    cursor,
    stopChars: _operatorStartChars,
  );
  if (name == null) {
    return FilterQueryFragment(raw, FilterQueryError.unterminatedQuote);
  }
  final def = name.value.isEmpty ? null : byName[name.value];
  if (def == null) return FilterQueryFragment(raw, FilterQueryError.unknownTag);
  cursor = name.end;

  // 연산자가 없으면 존재 조건이다(label 태그의 유일한 형태).
  if (cursor == raw.length) {
    return FilterQueryCondition(
      raw,
      FilterCondition(tagDefinitionId: def.id!, exclude: exclude),
    );
  }

  final matched = _matchOperator(raw, cursor);
  if (matched == null ||
      !operatorsForType(def.valueType).contains(matched.op)) {
    return FilterQueryFragment(raw, FilterQueryError.invalidOperator);
  }
  final op = matched.op;
  cursor += matched.length;
  if (cursor == raw.length) {
    return FilterQueryFragment(raw, FilterQueryError.missingValue);
  }

  final value = readClosedQueryField(raw, cursor);
  if (value == null) {
    return FilterQueryFragment(raw, FilterQueryError.unterminatedQuote);
  }
  // 인용부호를 닫은 뒤에 군더더기가 붙은 조각(예: 닫는 따옴표 뒤의 글자).
  if (value.end != raw.length) {
    return FilterQueryFragment(raw, FilterQueryError.invalidValue);
  }
  if (value.value.isEmpty) {
    return FilterQueryFragment(raw, FilterQueryError.missingValue);
  }

  final operand = _normalizeOperand(def.valueType, value.value);
  if (operand == null) {
    return FilterQueryFragment(raw, FilterQueryError.invalidValue);
  }
  return FilterQueryCondition(
    raw,
    FilterCondition(
      tagDefinitionId: def.id!,
      operator: op,
      operand: operand,
      exclude: exclude,
    ),
  );
}

/// [start]에서 시작하는 연산자 토큰과 그 길이. 별칭은 정식 토큰과 길이가 다를 수
/// 있으므로, 커서를 옮길 땐 정식 토큰이 아니라 **맞은 토큰**의 길이를 써야 한다.
({FilterOperator op, int length})? _matchOperator(String raw, int start) {
  for (final entry in _matchOrder) {
    if (raw.startsWith(entry.key, start)) {
      return (op: entry.value, length: entry.key.length);
    }
  }
  return null;
}

/// 저장 형식으로 정규화한 값. 유형에 맞지 않으면 null.
String? _normalizeOperand(TagValueType type, String value) {
  switch (type) {
    case TagValueType.number:
      return num.tryParse(value) == null ? null : value;
    case TagValueType.date:
      final parsed = DateTime.tryParse(value);
      return parsed == null ? null : dateToStoredValue(parsed);
    case TagValueType.text:
    case TagValueType.label:
      return value;
  }
}

// ── 포맷 ──

/// 조건 하나를 텍스트 조각으로 되돌린다. 캡슐을 되펼칠 때 쓰는 형태이며,
/// 그대로 다시 파싱하면 같은 조건이 나온다.
String formatFilterCondition(FilterCondition condition, TagDefinition def) {
  final buffer = StringBuffer();
  if (condition.exclude) buffer.write(kFilterExcludePrefix);
  buffer.write(filterTagToken(def));
  final token = filterOperatorToken(condition.operator);
  if (token != null) {
    buffer.write(token);
    buffer.write(quoteQueryToken(condition.operand ?? ''));
  }
  return buffer.toString();
}

/// 필터 전체를 텍스트 한 줄로 되돌린다.
///
/// 정의가 사라진 태그의 조건은 이름을 알 수 없어 텍스트로 표현할 수 없으므로
/// 건너뛴다(그런 조건의 표시는 칩 UI가 별도 표기로 다룬다).
String formatFilterQuery(
  FileFilter filter,
  Map<int, TagDefinition> definitionsById,
) {
  final parts = <String>[];
  for (final condition in filter.conditions) {
    final def = definitionsById[condition.tagDefinitionId];
    if (def != null) parts.add(formatFilterCondition(condition, def));
  }
  return parts.join(kQuerySeparator);
}

/// 태그 이름을 조건 조각에 넣을 수 있는 형태로. 이름은 연산자 토큰·부정 접두사와도
/// 헷갈릴 수 있어 인용 판단 기준이 값보다 넓다.
String filterTagToken(TagDefinition def) => quoteQueryToken(
  def.name,
  reserved: _operatorStartChars,
  reservedPrefix: kFilterExcludePrefix,
);

// ── 자동완성 ──
//
// 커서가 놓인 조각을 (부정 접두사)(태그 이름)(연산자)(값)으로 나눠 어느 자리인지
// 가리고 후보를 낸다. 위젯과 분리된 순수 함수라 커서 위치별로 유닛테스트한다.

/// 커서가 놓인 자리.
enum FilterQuerySlot { tag, operator, value }

/// 자동완성 후보 하나.
///
/// 표시 문구(연산자 설명 등)는 화면이 고르므로 여기엔 무엇을 고른 것인지와 텍스트에
/// 어떻게 넣을지만 담는다.
sealed class FilterQueryCompletion {
  const FilterQueryCompletion(this.insertText);

  /// 이 후보를 고르면 [FilterQueryCompletions]의 대체 구간이 이 문자열로 바뀐다.
  final String insertText;
}

/// 태그 자리의 후보. 이름에 인용이 필요하면 인용된 형태로 넣는다.
final class FilterTagCompletion extends FilterQueryCompletion {
  FilterTagCompletion(this.definition) : super(filterTagToken(definition));

  final TagDefinition definition;
}

/// 연산자 자리의 후보. 앞 태그의 유형이 허용하는 연산자만 나온다.
final class FilterOperatorCompletion extends FilterQueryCompletion {
  FilterOperatorCompletion(this.operator) : super(_operatorTokens[operator]!);

  final FilterOperator operator;
}

/// 커서 한 위치에서 계산한 자동완성 상태.
final class FilterQueryCompletions {
  const FilterQueryCompletions({
    required this.slot,
    required this.query,
    required this.replaceStart,
    required this.replaceEnd,
    required this.items,
    this.tag,
  });

  final FilterQuerySlot slot;

  /// 이 자리에 커서 앞까지 입력된, 인용·이스케이프를 푼 문자열. 후보를 거른 기준.
  final String query;

  /// 후보를 고를 때 원문에서 갈아 끼울 구간(커서 앞뒤의 이 자리 전체).
  final int replaceStart;
  final int replaceEnd;

  /// 이 조각의 태그 정의. 태그 자리이거나 이름을 해석하지 못했으면 null.
  final TagDefinition? tag;

  final List<FilterQueryCompletion> items;
}

/// [text]의 [cursor] 위치에서 낼 자동완성 후보.
///
/// 값 자리에는 후보가 없다(값의 출처가 태그 부여 기록이라 domain 파서가 알지
/// 못한다). 자리와 대체 구간은 그대로 돌려주므로 화면이 값 입력기를 붙일 수 있다.
FilterQueryCompletions filterQueryCompletions(
  String text,
  int cursor, {
  required Iterable<TagDefinition> definitions,
}) {
  final at = cursor.clamp(0, text.length);

  // 조각 사이의 공백에 커서가 있으면 빈 조각을 새로 시작하는 자리로 본다.
  final range = queryChunkRangeAt(text, at);
  final chunkStart = range?.start ?? at;
  final chunk = range == null ? '' : text.substring(range.start, range.end);
  final local = at - chunkStart;

  final nameStart = chunk.startsWith(kFilterExcludePrefix)
      ? kFilterExcludePrefix.length
      : 0;
  final name = readQueryField(chunk, nameStart, stopChars: _operatorStartChars);

  // 이름 끝까지는 태그 자리다(부정 접두사 위의 커서도 여기 포함된다).
  if (local <= name.end) {
    final query = queryFieldPrefix(
      chunk,
      nameStart,
      local,
      stopChars: _operatorStartChars,
    );
    return FilterQueryCompletions(
      slot: FilterQuerySlot.tag,
      query: query,
      replaceStart: chunkStart + nameStart,
      replaceEnd: chunkStart + name.end,
      items: [
        for (final d in matchTagsByName(definitions, query))
          FilterTagCompletion(d),
      ],
    );
  }

  final def = name.closed ? tagsByName(definitions)[name.value] : null;

  // 연산자 자리는 아직 토큰을 이루지 못한 입력 중의 글자들까지 뻗는다.
  final opStart = name.end;
  final matched = _matchOperator(chunk, opStart);
  var opEnd = opStart + (matched?.length ?? 0);
  if (matched == null) {
    while (opEnd < chunk.length && _operatorChars.contains(chunk[opEnd])) {
      opEnd++;
    }
  }

  if (local <= opEnd) {
    final query = chunk.substring(opStart, local);
    return FilterQueryCompletions(
      slot: FilterQuerySlot.operator,
      query: query,
      replaceStart: chunkStart + opStart,
      replaceEnd: chunkStart + opEnd,
      tag: def,
      items: _operatorCompletions(def, query),
    );
  }

  final value = readQueryField(chunk, opEnd);
  return FilterQueryCompletions(
    slot: FilterQuerySlot.value,
    query: queryFieldPrefix(chunk, opEnd, local),
    replaceStart: chunkStart + opEnd,
    replaceEnd: chunkStart + value.end,
    tag: def,
    items: const [],
  );
}

/// 태그 유형이 허용하고 [query]로 시작하는 연산자. 값이 없는 존재 연산은 토큰이
/// 없어(이름만으로 확정된다) 후보에 넣지 않는다 — label 태그는 후보가 비게 된다.
List<FilterQueryCompletion> _operatorCompletions(
  TagDefinition? def,
  String query,
) {
  if (def == null) return const [];
  return [
    for (final op in operatorsForType(def.valueType))
      if (_operatorTokens[op]?.startsWith(query) ?? false)
        FilterOperatorCompletion(op),
  ];
}
