/// 조회가 내는 결과를 몇 개만 잘라 보는 옵션(`--top`·`--tail`·`--range`).
///
/// 셋 다 **자를 뿐 실패시키지 않는다.** 있는 것보다 많이 달라거나 범위가 끝을 넘어가도
/// 오류가 아니라 낼 수 있는 만큼만 낸다 — 목록의 길이는 부르는 쪽이 미리 알 수 없는
/// 값이라, 그것을 맞히지 못했다고 명령이 실패하면 스크립트가 늘 개수를 먼저 세어야 한다.
/// 잘못 쓴 것(형식이 아닌 범위, 음수 등)만 오류다.
library;

import 'package:args/args.dart';

import '../l10n/console_strings.dart';

/// 결과를 자르는 옵션들을 [parser]에 붙인다.
void addWindowOptions(ArgParser parser, ConsoleStrings strings) {
  parser
    ..addOption(optTop, valueHelp: strings.tokenCount, help: strings.optTopHelp)
    ..addOption(
      optTail,
      valueHelp: strings.tokenCount,
      help: strings.optTailHelp,
    )
    ..addOption(
      optRange,
      valueHelp: strings.tokenRange,
      help: strings.optRangeHelp,
    );
}

/// 결과를 자르는 방법. 아무것도 주지 않으면 [OutputWindow.all]이다.
sealed class OutputWindow {
  const OutputWindow();

  /// 자르지 않는다.
  static const OutputWindow all = _All();

  /// [items]에서 이 창이 가리키는 만큼만 돌려준다. 원본이 짧으면 짧은 대로 낸다.
  List<T> apply<T>(List<T> items);
}

final class _All extends OutputWindow {
  const _All();

  @override
  List<T> apply<T>(List<T> items) => items;
}

final class _Top extends OutputWindow {
  const _Top(this.count);

  final int count;

  @override
  List<T> apply<T>(List<T> items) =>
      items.sublist(0, count < items.length ? count : items.length);
}

final class _Tail extends OutputWindow {
  const _Tail(this.count);

  final int count;

  @override
  List<T> apply<T>(List<T> items) =>
      items.sublist(count < items.length ? items.length - count : 0);
}

/// 1부터 세는 닫힌 구간. 시작이 끝을 넘어서거나 목록 밖이면 아무것도 내지 않는다.
final class _Range extends OutputWindow {
  const _Range(this.start, this.end);

  final int start;
  final int end;

  @override
  List<T> apply<T>(List<T> items) {
    if (end < start || start > items.length) return const [];
    final from = start - 1;
    final to = end < items.length ? end : items.length;
    return items.sublist(from, to);
  }
}

/// 친 옵션을 창으로 읽어 낸다.
sealed class WindowSpec {
  const WindowSpec();
}

final class WindowResolved extends WindowSpec {
  const WindowResolved(this.window);

  final OutputWindow window;
}

/// 옵션을 읽지 못했다. [message]가 무엇이 어긋났는지 말한다.
final class WindowUnreadable extends WindowSpec {
  const WindowUnreadable(this.message);

  final String message;
}

/// [results]에 실린 자르기 옵션을 읽는다.
///
/// **셋을 겹쳐 쓸 수는 없다** — `--top`과 `--tail`을 함께 주면 어느 쪽을 뜻하는지
/// 알 수 없고, 조용히 한쪽을 고르면 나오지 않은 결과의 이유를 짚을 수 없다.
WindowSpec resolveWindow(ArgResults results, ConsoleStrings strings) {
  final given = [
    for (final name in const [optTop, optTail, optRange])
      if (results.options.contains(name) && results[name] != null) name,
  ];
  if (given.isEmpty) return const WindowResolved(OutputWindow.all);
  if (given.length > 1) return WindowUnreadable(strings.windowConflict);

  final name = given.single;
  final raw = results[name] as String;
  if (name == optRange) {
    final parts = raw.split(_rangeSeparator);
    if (parts.length != 2) return WindowUnreadable(strings.badRange(raw));
    final start = _positive(parts[0]);
    final end = _positive(parts[1]);
    if (start == null || end == null) {
      return WindowUnreadable(strings.badRange(raw));
    }
    return WindowResolved(_Range(start, end));
  }
  final count = _positive(raw);
  if (count == null) return WindowUnreadable(strings.badCount(name, raw));
  return WindowResolved(name == optTop ? _Top(count) : _Tail(count));
}

/// 1 이상의 정수로 읽는다. 아니면 null.
///
/// 0을 받지 않는 것은 "아무것도 내지 마라"를 옵션으로 적는 것이 뜻이 없기 때문이다 —
/// 그럴 것이면 명령을 부르지 않으면 된다. 오타를 잡아 주는 편이 낫다.
int? _positive(String raw) {
  final value = int.tryParse(raw.trim());
  return (value == null || value < 1) ? null : value;
}

const String optTop = 'top';
const String optTail = 'tail';
const String optRange = 'range';

const String _rangeSeparator = ':';
