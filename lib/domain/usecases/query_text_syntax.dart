/// 필터·정렬 텍스트가 함께 쓰는 **조각 문법의 단일 출처**.
///
/// 두 언어는 조각 하나가 뜻하는 바가 다르지만(필터=조건, 정렬=단계), 조각을
/// 나누고 이름·값을 읽고 되감는 규칙은 같다. 그 규칙을 여기 모아 한쪽 문법을
/// 고쳐도 다른 쪽이 어긋나지 않게 한다.
///
/// 한 줄은 구분문자로 나뉜 여러 **조각**이다. 조각 안에는 구분문자가 들어갈 수
/// 없으므로, 공백이 든 태그 이름·값은 인용부호로 감싼다. 인용부호나 이스케이프
/// 문자 자신을 넣으려면 이스케이프한다 — 이스케이프가 없으면 되펼친 조각이 다시
/// 파싱되지 않는 태그가 생겨 왕복이 깨진다.
library;

import '../entities/tag_definition.dart';

// ── 문법 토큰 ──

/// 구분문자·예약 문자를 품은 이름/값을 감싸는 인용부호.
const String kQueryQuote = '"';

/// 다음 한 글자를 구분자가 아닌 보통 글자로 만드는 탈출 문자.
const String kQueryEscape = r'\';

/// 조각과 조각을 가르는 구분문자(표준 형태). 파싱은 모든 공백을 구분문자로 본다.
const String kQuerySeparator = ' ';

// ── 조각 나누기 ──

/// 텍스트를 조각 단위 구간으로 나눈다(인용부호 밖의 공백에서만 자른다).
///
/// 조각의 원문은 이스케이프를 포함해 그대로 보존한다(되펼침·재파싱이 같은
/// 문자열을 보게 하려고). 자동완성이 커서를 조각에 맞추려면 위치도 알아야 해서
/// 문자열이 아니라 구간을 돌려준다. 조각 사이의 공백은 어느 구간에도 들지 않는다.
List<({int start, int end})> queryChunkRanges(String text) {
  final ranges = <({int start, int end})>[];
  var start = -1;
  var inQuote = false;
  var escaped = false;

  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    final boundary = !escaped && !inQuote && ch.trim().isEmpty;
    if (escaped) {
      escaped = false;
    } else if (ch == kQueryEscape) {
      escaped = true;
    } else if (ch == kQueryQuote) {
      inQuote = !inQuote;
    }

    if (boundary) {
      if (start >= 0) ranges.add((start: start, end: i));
      start = -1;
    } else if (start < 0) {
      start = i;
    }
  }
  if (start >= 0) ranges.add((start: start, end: text.length));
  return ranges;
}

/// [text]를 조각 문자열들로 나눈다.
List<String> splitQueryChunks(String text) => [
  for (final r in queryChunkRanges(text)) text.substring(r.start, r.end),
];

/// [cursor]를 품은 조각의 구간. 조각 사이 공백에 있으면 null.
({int start, int end})? queryChunkRangeAt(String text, int cursor) {
  for (final r in queryChunkRanges(text)) {
    if (cursor >= r.start && cursor <= r.end) return r;
  }
  return null;
}

// ── 필드 읽기 ──

/// 이름/값 한 필드를 읽는다. 인용부호로 시작하면 닫힐 때까지, 아니면 [stopChars]
/// 앞까지(없으면 조각 끝까지) 읽는다. 인용부호가 닫히지 않으면 null.
({String value, int end})? readClosedQueryField(
  String raw,
  int start, {
  Set<String> stopChars = const {},
}) {
  final field = readQueryField(raw, start, stopChars: stopChars);
  return field.closed ? (value: field.value, end: field.end) : null;
}

/// [readClosedQueryField]와 같되 인용부호가 닫히지 않아도 **읽은 만큼** 돌려준다.
/// 입력 중인 조각의 커서 앞 문자열을 알아야 하는 자동완성이 쓴다.
({String value, int end, bool closed}) readQueryField(
  String raw,
  int start, {
  Set<String> stopChars = const {},
}) {
  if (start < raw.length && raw[start] == kQueryQuote) {
    return _readQuoted(raw, start);
  }
  final bare = _readBare(raw, start, stopChars);
  return (value: bare.value, end: bare.end, closed: true);
}

/// [start]에서 [cursor]까지 입력된 만큼을 읽어 인용·이스케이프를 푼 문자열.
/// 잘라 낸 조각을 읽으므로 인용이 닫히지 않은 상태 그대로 해석된다.
String queryFieldPrefix(
  String chunk,
  int start,
  int cursor, {
  Set<String> stopChars = const {},
}) {
  if (cursor <= start) return '';
  return readQueryField(
    chunk.substring(0, cursor),
    start,
    stopChars: stopChars,
  ).value;
}

({String value, int end, bool closed}) _readQuoted(String raw, int start) {
  final buffer = StringBuffer();
  var i = start + 1;
  while (i < raw.length) {
    final ch = raw[i];
    if (ch == kQueryEscape && i + 1 < raw.length) {
      buffer.write(raw[i + 1]);
      i += 2;
      continue;
    }
    if (ch == kQueryQuote) {
      return (value: buffer.toString(), end: i + 1, closed: true);
    }
    buffer.write(ch);
    i++;
  }
  return (value: buffer.toString(), end: raw.length, closed: false);
}

({String value, int end}) _readBare(
  String raw,
  int start,
  Set<String> stopChars,
) {
  final buffer = StringBuffer();
  var i = start;
  while (i < raw.length) {
    final ch = raw[i];
    if (ch == kQueryEscape && i + 1 < raw.length) {
      buffer.write(raw[i + 1]);
      i += 2;
      continue;
    }
    if (stopChars.contains(ch)) break;
    buffer.write(ch);
    i++;
  }
  return (value: buffer.toString(), end: i);
}

// ── 되감기 ──

/// 다시 읽었을 때 한 필드로 남도록 필요한 경우에만 인용한다.
///
/// [reserved]는 그 자리에서 필드를 끊는 글자(연산자 시작 글자 등),
/// [reservedPrefix]는 필드 첫 글자로 오면 다른 뜻이 되는 접두사다.
String quoteQueryToken(
  String raw, {
  Set<String> reserved = const {},
  String? reservedPrefix,
}) {
  if (!_needsQuote(raw, reserved, reservedPrefix)) return raw;
  final escaped = raw
      .replaceAll(kQueryEscape, '$kQueryEscape$kQueryEscape')
      .replaceAll(kQueryQuote, '$kQueryEscape$kQueryQuote');
  return '$kQueryQuote$escaped$kQueryQuote';
}

bool _needsQuote(String raw, Set<String> reserved, String? reservedPrefix) {
  if (raw.isEmpty) return true;
  for (final ch in raw.split('')) {
    if (ch.trim().isEmpty) return true;
    if (ch == kQueryQuote || ch == kQueryEscape) return true;
    if (reserved.contains(ch)) return true;
  }
  return reservedPrefix != null && raw.startsWith(reservedPrefix);
}

// ── 태그 이름 해석 ──

/// 이름으로 태그 정의를 찾는 표. 저장 전(id 없는) 정의는 조건·정렬이 가리킬 수
/// 없어 뺀다.
Map<String, TagDefinition> tagsByName(Iterable<TagDefinition> definitions) => {
  for (final d in definitions)
    if (d.id != null) d.name: d,
};

/// 이름이 [query]로 시작하는 태그를 앞에, 품기만 한 태그를 뒤에 둔다(대소문자 무시).
List<TagDefinition> matchTagsByName(
  Iterable<TagDefinition> definitions,
  String query,
) {
  final defs = [
    for (final d in definitions)
      if (d.id != null) d,
  ];
  if (query.isEmpty) return defs;
  final q = query.toLowerCase();
  final prefixed = <TagDefinition>[];
  final contained = <TagDefinition>[];
  for (final d in defs) {
    final name = d.name.toLowerCase();
    if (name.startsWith(q)) {
      prefixed.add(d);
    } else if (name.contains(q)) {
      contained.add(d);
    }
  }
  return [...prefixed, ...contained];
}
