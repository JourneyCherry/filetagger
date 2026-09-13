/// 조건 세 가지(`--filter`·`--sort`·`--group`)를 명령에 붙이고, 친 텍스트를 실제
/// 질의로 읽어 낸다.
///
/// 문자열을 태그 캡슐로 바꾸는 규칙은 **화면과 같은 것**이다 — 도구모음의 조건 줄에
/// 치는 문법을 콘솔에서 그대로 쓸 수 있어야 배울 것이 하나뿐이다.
///
/// **읽지 못한 조각이 하나라도 있으면 통째로 거부한다.** 화면은 입력 중인 미완성
/// 조각을 원문으로 남겨 두는 것이 옳지만(포커스를 잃어도 지워지지 않아야 한다),
/// 콘솔은 다르다 — 오타 하나를 조용히 버리면 `-크기>100`이 `크기>100`이 되어 **고르는
/// 집합이 뒤집힌 채** 명령이 돈다.
library;

import 'package:args/args.dart';

import '../domain/entities/file_filter.dart';
import '../domain/entities/file_grouping.dart';
import '../domain/entities/file_sort.dart';
import '../domain/entities/tag_definition.dart';
import '../domain/usecases/filter_query_text.dart';
import '../domain/usecases/group_query_text.dart';
import '../domain/usecases/query_text_syntax.dart';
import '../domain/usecases/sort_query_text.dart';
import '../l10n/console_strings.dart';
import '../l10n/system_tag_names.dart';

/// 대상 집합을 고르는 조건 하나를 [parser]에 붙인다. 문법 안내도 함께 단다 —
/// 조건을 칠 수 있는 자리면 어디서나 문법을 물어볼 수 있어야 한다.
void addFilterOption(ArgParser parser, ConsoleStrings strings) {
  parser
    ..addOption(
      optFilter,
      valueHelp: strings.tokenCondition,
      help: strings.optFilterHelp,
    )
    ..addFlag(optFilterHelp, negatable: false, help: strings.optFilterHelpHelp);
}

/// 조건 문법 안내 한 벌.
///
/// **토큰은 문법의 단일 출처에서 뽑는다** — 기호를 문구에 손으로 적어 두면 문법을
/// 고쳤을 때 안내만 옛것으로 남는다(`CLAUDE.md`의 "주석·문서에 실제 값 금지"와 같은
/// 자리다). 문구를 고르는 것은 언어를 아는 [ConsoleStrings]의 몫이고, 여기서는 그
/// 문구에 코드가 쥔 기호를 끼워 넣는다.
String filterHelpText(ConsoleStrings strings, {required String localeName}) {
  final rows = <String>[
    for (final op in FilterOperator.values)
      if (filterOperatorToken(op) case final token?)
        '  ${token.padRight(_tokenColumnWidth)}${strings.filterOperatorName(op)}',
  ];
  return [
    strings.filterHelpHeading,
    '',
    strings.filterHelpChunks(kQueryQuote, kQueryEscape),
    '',
    '--$optFilter',
    strings.filterHelpConditions(kFilterExcludePrefix, kFilterOrPrefix),
    ...rows,
    '  ${strings.filterHelpAlias(_equalsAliases, _canonicalEquals)}',
    '',
    '  ${strings.filterHelpMultiValue(_everyValueOperators)}',
    '',
    '--$optSort',
    strings.filterHelpSort(kSortDescendingPrefix, kSortRandomPrefix),
    '',
    '--$optGroup',
    strings.filterHelpGroup(folderHierarchyNameFor(localeName)),
  ].join('\n');
}

/// 값 여럿을 모두 견주는 연산들의 표기. 안내가 기호를 손으로 적지 않도록 토큰 표에서
/// 뽑는다(연산자 표와 같은 자리다).
final String _everyValueOperators = [
  for (final op in FilterOperator.values)
    if (requiresEveryValue(op))
      if (filterOperatorToken(op) case final token?) token,
].join(' ');

/// 정식 토큰이 아니라 **입력에서만 받는** 같음의 별칭들.
final String _equalsAliases = [
  for (final entry in filterOperatorAliases.entries)
    if (entry.value == FilterOperator.equals) entry.key,
].join(' ');

/// 별칭이 정규화되어 되펼쳐지는 정식 토큰.
final String _canonicalEquals = filterOperatorToken(FilterOperator.equals)!;

/// 안내 표에서 토큰 칸이 차지하는 너비. 뜻이 같은 자리에서 시작해야 훑어 읽힌다.
const int _tokenColumnWidth = 6;

/// 낼 차례를 정하는 조건 둘을 [parser]에 붙인다.
void addSortGroupOptions(ArgParser parser, ConsoleStrings strings) {
  parser
    ..addOption(
      optSort,
      valueHelp: strings.tokenCriterion,
      help: strings.optSortHelp,
    )
    ..addOption(
      optGroup,
      valueHelp: strings.tokenCriterion,
      help: strings.optGroupHelp,
    );
}

/// 조건 텍스트를 읽어 낸 결과.
sealed class QuerySpec {
  const QuerySpec();
}

/// 세 조건이 모두 서 있다. 주지 않은 것은 빈 조건이다.
final class QueryResolved extends QuerySpec {
  const QueryResolved({
    this.filter = const FileFilter(),
    this.sort = const FileSortOrder(),
    this.grouping = const FileGrouping(),
    this.hasFilter = false,
  });

  final FileFilter filter;
  final FileSortOrder sort;
  final FileGrouping grouping;

  /// `--filter`를 **주었는지**. 조건이 비어 있는 것과 아예 주지 않은 것은 다르다 —
  /// 앞은 "전부"를 뜻하고 뒤는 "대상을 다른 방법으로 지목한다"는 뜻이다.
  final bool hasFilter;
}

/// 읽지 못한 조각이 있다. [problems]가 어느 옵션의 무엇이 어긋났는지 말한다.
final class QueryUnreadable extends QuerySpec {
  const QueryUnreadable(this.problems);

  final List<String> problems;
}

/// 친 텍스트를 질의로 읽는다. [definitions]는 사용자 정의와 시스템 태그를 함께 담은
/// 카탈로그여야 한다([loadQueryData]).
QuerySpec resolveQuery(
  ArgResults results, {
  required List<TagDefinition> definitions,
  required String localeName,
}) {
  final filterText = results.options.contains(optFilter)
      ? results[optFilter] as String?
      : null;
  final sortText = results.options.contains(optSort)
      ? results[optSort] as String?
      : null;
  final groupText = results.options.contains(optGroup)
      ? results[optGroup] as String?
      : null;

  final problems = <String>[];
  var filter = const FileFilter();
  var sort = const FileSortOrder();
  var grouping = const FileGrouping();

  if (filterText != null) {
    final segments = parseFilterQuery(filterText, definitions: definitions);
    for (final s in segments) {
      if (s is FilterQueryFragment) {
        problems.add(_problem(optFilter, s.text, s.error.name));
      }
    }
    filter = filterFromSegments(segments);
  }
  if (sortText != null) {
    final segments = parseSortQuery(sortText, definitions: definitions);
    for (final s in segments) {
      if (s is SortQueryFragment) {
        problems.add(_problem(optSort, s.text, s.error.name));
      }
    }
    sort = sortFromSegments(segments);
  }
  if (groupText != null) {
    final segments = parseGroupQuery(
      groupText,
      definitions: definitions,
      folderHierarchyName: folderHierarchyNameFor(localeName),
    );
    for (final s in segments) {
      if (s is GroupQueryFragment) {
        problems.add(_problem(optGroup, s.text, s.error.name));
      }
    }
    grouping = groupFromSegments(segments);
  }

  if (problems.isNotEmpty) return QueryUnreadable(problems);
  return QueryResolved(
    filter: filter,
    sort: sort,
    grouping: grouping,
    hasFilter: filterText != null,
  );
}

/// 어긋난 조각 하나의 사람용 한 줄. 사유는 **이름 그대로** 낸다 — 기계가 분기할 수
/// 있고, 사람에게도 어느 갈래인지가 문장보다 분명하다.
String _problem(String option, String text, String reason) =>
    '--$option\t$text\t$reason';

const String optFilter = 'filter';
const String optSort = 'sort';
const String optGroup = 'group';
const String optFilterHelp = 'filter-help';
