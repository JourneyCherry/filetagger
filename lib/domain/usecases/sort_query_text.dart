/// 정렬 기준의 **텍스트 표현**을 파싱·포맷한다.
///
/// 필터와 같은 조각 문법을 쓰되([query_text_syntax]), 조각 하나가 조건이 아니라
/// **정렬 단계**다. 정렬에는 비교할 값이 없어 조각은 (방향 접두사)(태그 이름)뿐이고,
/// 텍스트에 놓인 왼→오 순서가 그대로 정렬 우선순위가 된다.
///
/// 저장 모델은 그대로다 — 단계는 태그 정의 id로 저장되며([SortKey]), 여기서 입력
/// 시 이름→정의로 해석하고 되펼칠 때 정의→이름으로 되돌린다.
///
/// 필터와 마찬가지로 파싱은 **해석하지 못한 원문을 보존**한다
/// ([SortQueryFragment]) — 미완성(입력 중)과 무효를 같은 방식으로 남겨, 포커스를
/// 잃어도 텍스트에 그대로 두고 저장할 때만 걸러낸다.
library;

import '../entities/file_sort.dart';
import '../entities/tag_definition.dart';
import '../entities/tag_value_type.dart';
import 'query_text_syntax.dart';

// ── 문법 토큰 (단일 출처) ──

/// 내림차순을 뜻하는, 태그 이름 앞의 접두사. 붙이지 않으면 오름차순이다.
///
/// 필터의 제외 접두사와 글자가 같지만 다른 언어의 다른 토큰이다. 두 줄이 한
/// 화면에 붙어 있으므로 뜻을 섞지 않도록 정의를 따로 둔다.
const String kSortDescendingPrefix = '-';

/// 방향을 가리는 태그인지. label은 값이 없어 존재 여부로만 정렬하므로 방향이 없다.
bool sortDirectionApplies(TagValueType type) => type != TagValueType.label;

// ── 파싱 결과 ──

/// 조각을 정렬 단계로 해석하지 못한 이유. 화면이 무효 표시를 고르는 데 쓴다.
enum SortQueryError {
  /// 그 이름의 태그 정의가 없다(오타이거나 삭제된 태그).
  unknownTag,

  /// 방향이 없는 태그(label)에 방향 접두사를 붙였다.
  directionNotAllowed,

  /// 인용부호가 닫히지 않았다(대개 입력 중인 미완성 조각).
  unterminatedQuote,

  /// 인용부호를 닫은 뒤에 군더더기가 붙었다.
  trailingText,
}

/// 텍스트 한 줄을 이루는 조각 하나. 정렬 단계로 접히거나([SortQueryKey]),
/// 원문 그대로 남는다([SortQueryFragment]).
sealed class SortQuerySegment {
  const SortQuerySegment(this.text);

  /// 이 조각의 원문. 이어 붙이면 입력을 되살릴 수 있다(공백 구간은 정규화된다).
  final String text;
}

/// 정렬 단계로 해석된 조각. 화면은 이걸 캡슐로 접어 보여준다.
final class SortQueryKey extends SortQuerySegment {
  const SortQueryKey(super.text, this.key);

  final SortKey key;
}

/// 해석하지 못해 원문으로 남는 조각. 저장에서 빠진다.
final class SortQueryFragment extends SortQuerySegment {
  const SortQueryFragment(super.text, this.error);

  final SortQueryError error;
}

// ── 파싱 ──

/// 텍스트 한 줄을 조각 목록으로 읽는다. [definitions]는 이름 해석의 대상이며,
/// 시스템 태그(음수 id)도 함께 넘겨야 이름으로 찾을 수 있다.
List<SortQuerySegment> parseSortQuery(
  String text, {
  required Iterable<TagDefinition> definitions,
}) {
  final byName = tagsByName(definitions);
  return [
    for (final chunk in splitQueryChunks(text)) _parseChunk(chunk, byName),
  ];
}

/// 조각들에서 해석된 단계만 모아 정렬 순서를 만든다(미완성·무효 조각은 빠진다).
FileSortOrder sortFromSegments(Iterable<SortQuerySegment> segments) =>
    sortFromKeys([
      for (final s in segments)
        if (s is SortQueryKey) s.key,
    ]);

/// 태그당 한 단계만 남긴 정렬 순서. 앞선 단계가 이기므로 뒤의 중복은 버린다
/// (같은 태그를 다시 비교해도 결과가 바뀌지 않아 무해하지만, 저장은 깨끗이 둔다).
FileSortOrder sortFromKeys(Iterable<SortKey> keys) {
  final seen = <int>{};
  return FileSortOrder(
    keys: [
      for (final k in keys)
        if (seen.add(k.tagDefinitionId)) k,
    ],
  );
}

SortQuerySegment _parseChunk(String raw, Map<String, TagDefinition> byName) {
  var cursor = 0;
  var descending = false;
  if (raw.startsWith(kSortDescendingPrefix)) {
    descending = true;
    cursor = kSortDescendingPrefix.length;
  }

  final name = readClosedQueryField(raw, cursor);
  if (name == null) {
    return SortQueryFragment(raw, SortQueryError.unterminatedQuote);
  }
  // 인용부호를 닫은 뒤에 군더더기가 붙은 조각(예: 닫는 따옴표 뒤의 글자).
  if (name.end != raw.length) {
    return SortQueryFragment(raw, SortQueryError.trailingText);
  }
  final def = name.value.isEmpty ? null : byName[name.value];
  if (def == null) return SortQueryFragment(raw, SortQueryError.unknownTag);

  if (descending && !sortDirectionApplies(def.valueType)) {
    return SortQueryFragment(raw, SortQueryError.directionNotAllowed);
  }
  return SortQueryKey(
    raw,
    SortKey(
      tagDefinitionId: def.id!,
      direction: descending
          ? SortDirection.descending
          : SortDirection.ascending,
    ),
  );
}

// ── 포맷 ──

/// 정렬 단계 하나를 텍스트 조각으로 되돌린다. 캡슐을 되펼칠 때 쓰는 형태이며,
/// 그대로 다시 파싱하면 같은 단계가 나온다.
String formatSortKey(SortKey key, TagDefinition def) {
  // 방향이 없는 태그에 접두사를 붙이면 되읽을 때 무효 조각이 된다. 저장된 값이
  // 어떻든 왕복이 깨지지 않도록 여기서 방향을 지운다.
  final descending =
      key.direction == SortDirection.descending &&
      sortDirectionApplies(def.valueType);
  return '${descending ? kSortDescendingPrefix : ''}${sortTagToken(def)}';
}

/// 정렬 순서 전체를 텍스트 한 줄로 되돌린다.
///
/// 정의가 사라진 태그의 단계는 이름을 알 수 없어 텍스트로 표현할 수 없으므로
/// 건너뛴다(그런 단계의 표시는 칩 UI가 별도 표기로 다룬다).
String formatSortQuery(
  FileSortOrder sort,
  Map<int, TagDefinition> definitionsById,
) {
  final parts = <String>[];
  for (final key in sort.keys) {
    final def = definitionsById[key.tagDefinitionId];
    if (def != null) parts.add(formatSortKey(key, def));
  }
  return parts.join(kQuerySeparator);
}

/// 태그 이름을 정렬 조각에 넣을 수 있는 형태로. 방향 접두사로 시작하는 이름은
/// 인용해야 내림차순 표기와 갈리지 않는다.
String sortTagToken(TagDefinition def) =>
    quoteQueryToken(def.name, reservedPrefix: kSortDescendingPrefix);

// ── 자동완성 ──
//
// 방향이 접두사라 조각은 통째로 태그 이름 자리다(접두사 위의 커서도 여기 든다).
// 그래서 필터와 달리 자리를 가릴 것이 없고, 후보는 늘 태그 이름이다.

/// 태그 자리의 후보. 이름에 인용이 필요하면 인용된 형태로 넣는다.
final class SortTagCompletion {
  SortTagCompletion(this.definition) : insertText = sortTagToken(definition);

  final TagDefinition definition;

  /// 이 후보를 고르면 [SortQueryCompletions]의 대체 구간이 이 문자열로 바뀐다.
  final String insertText;
}

/// 커서 한 위치에서 계산한 자동완성 상태.
final class SortQueryCompletions {
  const SortQueryCompletions({
    required this.query,
    required this.replaceStart,
    required this.replaceEnd,
    required this.items,
  });

  /// 이름 자리에 커서 앞까지 입력된, 인용·이스케이프를 푼 문자열. 후보를 거른 기준.
  final String query;

  /// 후보를 고를 때 원문에서 갈아 끼울 구간(방향 접두사는 건드리지 않는다).
  final int replaceStart;
  final int replaceEnd;

  final List<SortTagCompletion> items;
}

/// [text]의 [cursor] 위치에서 낼 자동완성 후보.
///
/// 이미 쓰인 태그를 후보에서 빼는 일(태그당 1단계)은 [definitions]를 넘기는
/// 화면의 몫이다 — 접힌 캡슐이 어느 태그인지는 텍스트만 봐선 알 수 없다.
SortQueryCompletions sortQueryCompletions(
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

  final nameStart = chunk.startsWith(kSortDescendingPrefix)
      ? kSortDescendingPrefix.length
      : 0;
  final name = readQueryField(chunk, nameStart);
  final query = queryFieldPrefix(chunk, nameStart, local);

  return SortQueryCompletions(
    query: query,
    replaceStart: chunkStart + nameStart,
    replaceEnd: chunkStart + name.end,
    items: [
      for (final d in matchTagsByName(definitions, query)) SortTagCompletion(d),
    ],
  );
}
