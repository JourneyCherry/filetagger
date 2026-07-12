/// 그룹 기준의 **텍스트 표현**을 파싱·포맷한다.
///
/// 필터·정렬과 같은 조각 문법을 쓰되([query_text_syntax]), 조각 하나가 조건도
/// 단계도 아닌 **그룹 단계**다. 그룹에는 비교할 값도 방향도 없어 조각은 (태그 이름)
/// 뿐이고, 텍스트에 놓인 왼→오 순서가 그대로 바깥→안쪽 중첩 순서가 된다.
///
/// 폴더 계층은 값 버킷과 다른 축이라 전용 합성 정의([folderHierarchyDefinition])로
/// 흘려보낸다 — 이름을 해석하는 표에 그 정의를 항상 끼워 넣어, 폴더 키가 늘 유효한
/// 그룹 키로 해석되게 한다.
///
/// 저장 모델은 그대로다 — 단계는 태그 정의 id로 저장되며([GroupKey]), 여기서 입력
/// 시 이름→정의로 해석하고 되펼칠 때 정의→이름으로 되돌린다.
///
/// 필터·정렬과 마찬가지로 파싱은 **해석하지 못한 원문을 보존**한다
/// ([GroupQueryFragment]) — 미완성(입력 중)과 무효를 같은 방식으로 남겨, 포커스를
/// 잃어도 텍스트에 그대로 두고 저장할 때만 걸러낸다.
library;

import '../entities/file_grouping.dart';
import '../entities/tag_definition.dart';
import 'query_text_syntax.dart';

// ── 파싱 결과 ──

/// 조각을 그룹 단계로 해석하지 못한 이유. 화면이 무효 표시를 고르는 데 쓴다.
enum GroupQueryError {
  /// 그 이름의 태그 정의가 없다(오타이거나 삭제된 태그).
  unknownTag,

  /// 폴더 계층 키가 두 번 이상 나왔다(폴더 키는 최대 1회). 첫 번째만 유효하다.
  duplicateFolderHierarchy,

  /// 인용부호가 닫히지 않았다(대개 입력 중인 미완성 조각).
  unterminatedQuote,

  /// 인용부호를 닫은 뒤에 군더더기가 붙었다.
  trailingText,
}

/// 텍스트 한 줄을 이루는 조각 하나. 그룹 단계로 접히거나([GroupQueryKey]),
/// 원문 그대로 남는다([GroupQueryFragment]).
sealed class GroupQuerySegment {
  const GroupQuerySegment(this.text);

  /// 이 조각의 원문. 이어 붙이면 입력을 되살릴 수 있다(공백 구간은 정규화된다).
  final String text;
}

/// 그룹 단계로 해석된 조각. 화면은 이걸 캡슐로 접어 보여준다.
final class GroupQueryKey extends GroupQuerySegment {
  const GroupQueryKey(super.text, this.key);

  final GroupKey key;
}

/// 해석하지 못해 원문으로 남는 조각. 저장에서 빠진다.
final class GroupQueryFragment extends GroupQuerySegment {
  const GroupQueryFragment(super.text, this.error);

  final GroupQueryError error;
}

// ── 파싱 ──

/// 이름 해석의 대상 표. 폴더 계층 정의를 **항상** 끼워 넣어 폴더 키가 늘 유효한
/// 그룹 키로 해석되게 한다(사용자가 같은 이름의 태그를 만들어도 폴더 키가 이긴다).
Map<String, TagDefinition> _groupNames(Iterable<TagDefinition> definitions) =>
    tagsByName([...definitions, folderHierarchyDefinition]);

/// 텍스트 한 줄을 조각 목록으로 읽는다. [definitions]는 이름 해석의 대상이며,
/// 시스템 태그(음수 id)도 함께 넘겨야 이름으로 찾을 수 있다. 폴더 계층 정의는
/// 자동으로 더해지므로 넘기지 않아도 된다.
List<GroupQuerySegment> parseGroupQuery(
  String text, {
  required Iterable<TagDefinition> definitions,
}) {
  final byName = _groupNames(definitions);
  // 폴더 키는 최대 1회다 — 두 번째부터는 유효한 이름이라도 무효 조각으로 남긴다.
  // 태그 키의 중복은 결과를 바꾸지 않는 no-op이라 접힌 채 두고 저장에서만 버린다.
  var seenFolder = false;
  final result = <GroupQuerySegment>[];
  for (final chunk in splitQueryChunks(text)) {
    final segment = _parseChunk(chunk, byName);
    if (segment is GroupQueryKey && segment.key is FolderHierarchyGroupKey) {
      if (seenFolder) {
        result.add(
          GroupQueryFragment(chunk, GroupQueryError.duplicateFolderHierarchy),
        );
        continue;
      }
      seenFolder = true;
    }
    result.add(segment);
  }
  return result;
}

/// 조각들에서 해석된 단계만 모아 그룹을 만든다(미완성·무효 조각은 빠진다).
FileGrouping groupFromSegments(Iterable<GroupQuerySegment> segments) =>
    groupFromKeys([
      for (final s in segments)
        if (s is GroupQueryKey) s.key,
    ]);

/// 중복을 걷어낸 그룹. 태그 키는 태그당 한 단계, 폴더 키는 최대 한 번만 남긴다
/// (앞선 단계가 이기고 뒤의 중복은 버린다 — 결과가 바뀌지 않아 무해하지만 저장은
/// 깨끗이 둔다).
FileGrouping groupFromKeys(Iterable<GroupKey> keys) {
  final seenTags = <int>{};
  var seenFolder = false;
  final result = <GroupKey>[];
  for (final k in keys) {
    switch (k) {
      case TagGroupKey(:final tagDefinitionId):
        if (seenTags.add(tagDefinitionId)) result.add(k);
      case FolderHierarchyGroupKey():
        if (!seenFolder) {
          seenFolder = true;
          result.add(k);
        }
    }
  }
  return FileGrouping(keys: result);
}

GroupQuerySegment _parseChunk(String raw, Map<String, TagDefinition> byName) {
  final name = readClosedQueryField(raw, 0);
  if (name == null) {
    return GroupQueryFragment(raw, GroupQueryError.unterminatedQuote);
  }
  // 인용부호를 닫은 뒤에 군더더기가 붙은 조각(예: 닫는 따옴표 뒤의 글자).
  if (name.end != raw.length) {
    return GroupQueryFragment(raw, GroupQueryError.trailingText);
  }
  final def = name.value.isEmpty ? null : byName[name.value];
  if (def == null) return GroupQueryFragment(raw, GroupQueryError.unknownTag);
  return GroupQueryKey(raw, _keyFor(def));
}

GroupKey _keyFor(TagDefinition def) => def.id == kFolderHierarchyGroupId
    ? const FolderHierarchyGroupKey()
    : TagGroupKey(def.id!);

// ── 포맷 ──

/// 그룹 단계 하나를 텍스트 조각으로 되돌린다. 캡슐을 되펼칠 때 쓰는 형태이며,
/// 그대로 다시 파싱하면 같은 단계가 나온다.
String formatGroupKey(GroupKey key, TagDefinition def) => groupTagToken(def);

/// 그룹 전체를 텍스트 한 줄로 되돌린다.
///
/// 정의가 사라진 태그의 단계는 이름을 알 수 없어 텍스트로 표현할 수 없으므로
/// 건너뛴다(그런 단계의 표시는 칩 UI가 별도 표기로 다룬다). 폴더 계층 키는
/// 합성 정의로 늘 되돌릴 수 있다.
String formatGroupQuery(
  FileGrouping grouping,
  Map<int, TagDefinition> definitionsById,
) {
  final parts = <String>[];
  for (final key in grouping.keys) {
    final def = _definitionFor(key, definitionsById);
    if (def != null) parts.add(groupTagToken(def));
  }
  return parts.join(kQuerySeparator);
}

TagDefinition? _definitionFor(
  GroupKey key,
  Map<int, TagDefinition> definitionsById,
) => switch (key) {
  FolderHierarchyGroupKey() => folderHierarchyDefinition,
  TagGroupKey(:final tagDefinitionId) => definitionsById[tagDefinitionId],
};

/// 태그 이름을 그룹 조각에 넣을 수 있는 형태로. 그룹엔 접두사·연산자가 없어
/// 공백·인용부호만 이스케이프하면 된다.
String groupTagToken(TagDefinition def) => quoteQueryToken(def.name);

// ── 자동완성 ──
//
// 그룹 조각은 통째로 태그 이름 자리다(접두사도 값도 없다). 그래서 자리를 가릴
// 것이 없고 후보는 늘 태그 이름이다. 폴더 계층 정의도 후보에 함께 오른다.

/// 태그 자리의 후보. 이름에 인용이 필요하면 인용된 형태로 넣는다.
final class GroupTagCompletion {
  GroupTagCompletion(this.definition) : insertText = groupTagToken(definition);

  final TagDefinition definition;

  /// 이 후보를 고르면 [GroupQueryCompletions]의 대체 구간이 이 문자열로 바뀐다.
  final String insertText;
}

/// 커서 한 위치에서 계산한 자동완성 상태.
final class GroupQueryCompletions {
  const GroupQueryCompletions({
    required this.query,
    required this.replaceStart,
    required this.replaceEnd,
    required this.items,
  });

  /// 이름 자리에 커서 앞까지 입력된, 인용·이스케이프를 푼 문자열. 후보를 거른 기준.
  final String query;

  /// 후보를 고를 때 원문에서 갈아 끼울 구간.
  final int replaceStart;
  final int replaceEnd;

  final List<GroupTagCompletion> items;
}

/// [text]의 [cursor] 위치에서 낼 자동완성 후보.
///
/// 이미 쓰인 태그·폴더 키를 후보에서 빼는 일(태그당 1단계·폴더 최대 1회)은
/// [definitions]를 넘기는 화면의 몫이다 — 접힌 캡슐이 어느 키인지는 텍스트만
/// 봐선 알 수 없다. 폴더 계층 정의는 여기서 후보에 더해진다.
GroupQueryCompletions groupQueryCompletions(
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

  final name = readQueryField(chunk, 0);
  final query = queryFieldPrefix(chunk, 0, local);

  return GroupQueryCompletions(
    query: query,
    replaceStart: chunkStart,
    replaceEnd: chunkStart + name.end,
    items: [
      for (final d in matchTagsByName(
        [...definitions, folderHierarchyDefinition],
        query,
      ))
        GroupTagCompletion(d),
    ],
  );
}
