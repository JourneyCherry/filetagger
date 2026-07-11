/// 확정된 조각이 **글자 하나로 접히는** 텍스트 필드와, 그 바탕이 되는 캡슐 텍스트
/// 모델. 필터·정렬 텍스트 입력이 함께 쓴다.
///
/// 접힌 조각(캡슐)은 별도 위젯이 아니라 텍스트 버퍼의 한 코드 유닛이다. 그래서
/// 커서·선택·삭제가 보통 글자와 똑같이 한 칸씩 움직이고, 그리기만 칩으로 바뀐다.
/// 캡슐마다 다른 글자를 주므로 글자 자체가 그 조각의 신원이 된다.
///
/// 문법에 딸린 것 — 조각을 값으로 읽기, 값을 원문으로 되돌리기, 칩 그리기,
/// 자동완성 후보 내기 — 만 [CapsuleSyntax]와 [CapsuleTextField.completionsAt]으로
/// 주입한다. 미완성·무효 조각은 접히지 않고 원문으로 남으며, 확정된 값만 밖으로
/// 흘러간다.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/usecases/query_text_syntax.dart';

/// 필드 안 텍스트(와 그 안에 접힌 캡슐)의 왼쪽 시작 들여쓰기. 조건 줄 한 자리를
/// 칩 줄과 번갈아 쓰는 도구모음에서, 칩도 같은 만큼 들여써야 칩↔텍스트 전환에서
/// 캡슐의 시작점이 어긋나지 않는다.
const double kCapsuleFieldInset = 8;

// ── 캡슐 글자 ──

/// 캡슐 하나를 대신하는 글자의 범위. 유니코드 사용자 정의 영역을 쓴다 — 뜻이
/// 정해져 있지 않아 사용자가 칠 일이 없고, 한 코드 유닛이라 커서·삭제가 보통
/// 글자와 똑같이 한 칸씩 움직인다.
const int _capsuleCharFirst = 0xE000;
const int _capsuleCharLast = 0xF8FF;

/// 이 코드 유닛이 캡슐을 대신하는 글자인지.
bool isCapsuleChar(int codeUnit) =>
    codeUnit >= _capsuleCharFirst && codeUnit <= _capsuleCharLast;

/// 아직 텍스트에 쓰이지 않은 캡슐 글자. 남은 글자가 없으면 null.
int? _freeCapsuleChar(Set<int> used) {
  for (var c = _capsuleCharFirst; c <= _capsuleCharLast; c++) {
    if (!used.contains(c)) return c;
  }
  return null;
}

// ── 캡슐 텍스트 ──

/// 텍스트를 캡슐 글자와 그 사이의 원문 조각으로 나눈 한 토막.
///
/// 캡슐은 늘 홀로 선 조각이다(공백으로 나눈 조각을 캡슐 글자에서 한 번 더 자른다).
/// 캡슐 바로 옆에 이어 친 글자도 제 조각이 되어 따로 해석된다.
typedef CapsuleTextPiece = ({int start, int end, bool isCapsule});

/// [text]를 조각들로 나눈다. 조각 사이의 공백은 어느 조각에도 들지 않는다.
List<CapsuleTextPiece> capsuleTextPieces(String text) {
  final pieces = <CapsuleTextPiece>[];
  for (final range in queryChunkRanges(text)) {
    var start = -1;
    for (var i = range.start; i < range.end; i++) {
      if (isCapsuleChar(text.codeUnitAt(i))) {
        if (start >= 0) pieces.add((start: start, end: i, isCapsule: false));
        start = -1;
        pieces.add((start: i, end: i + 1, isCapsule: true));
      } else if (start < 0) {
        start = i;
      }
    }
    if (start >= 0) {
      pieces.add((start: start, end: range.end, isCapsule: false));
    }
  }
  return pieces;
}

/// 캡슐 글자를 섞어 담은 편집 상태. 위젯과 떼어 순수하게 다룬다.
@immutable
class CapsuleText<T> {
  const CapsuleText({
    required this.text,
    required this.selection,
    required this.capsules,
  });

  final String text;
  final TextSelection selection;

  /// 캡슐 글자(코드 유닛) → 그 글자가 대신하는 값.
  final Map<int, T> capsules;

  /// 텍스트에 놓인 순서대로의, 확정된 값들.
  List<T> get items => [
    for (final unit in text.codeUnits)
      if (capsules[unit] case final item?) item,
  ];
}

/// 텍스트 조각과 확정된 값 사이를 오가는 규칙. 문법마다 다른 부분만 담는다.
abstract class CapsuleSyntax<T> {
  const CapsuleSyntax();

  /// 조각 원문 하나를 확정된 값으로 읽는다. 미완성·무효면 null.
  T? parse(String chunk);

  /// 확정된 값을 다시 고칠 수 있는 원문으로 되돌린다. 표현할 수 없으면 null
  /// (정의가 사라진 태그 등) — 그런 캡슐은 되펼쳐지지 않는다.
  String? format(T item);

  /// 접히지 않은 [chunk]를 무효로 표시할지(물결 밑줄).
  bool isInvalid(String chunk);

  /// 캡슐 글자 자리에 그릴 칩. 캡슐은 크기·자간을 스스로 고정하므로([TagCapsule])
  /// 필드의 편집 스타일을 물려받지 않는다 — 칩 줄의 같은 캡슐과 글자폭이 어긋나지
  /// 않게 한다.
  Widget chip(T item);
}

/// 커서가 걸치지 않은, 값으로 해석되는 조각을 캡슐 글자로 접는다.
///
/// 구분문자를 쳐서 커서가 조각을 벗어나거나, 커서를 딴 데로 옮기거나, 포커스를
/// 잃는 순간([ignoreCursor])이 모두 이 한 규칙으로 처리된다. 캡슐이 섞인 조각과
/// 커서가 놓인 조각은 손대지 않는다.
CapsuleText<T> collapseCapsules<T>(
  CapsuleText<T> value, {
  required CapsuleSyntax<T> syntax,
  bool ignoreCursor = false,
}) {
  final used = <int>{
    for (final unit in value.text.codeUnits)
      if (isCapsuleChar(unit)) unit,
  };
  // 텍스트에서 사라진 캡슐(사용자가 지운 값)은 함께 버린다.
  final capsules = <int, T>{
    for (final entry in value.capsules.entries)
      if (used.contains(entry.key)) entry.key: entry.value,
  };

  final edits = <_Edit>[];
  for (final piece in capsuleTextPieces(value.text)) {
    if (piece.isCapsule) continue;
    if (!ignoreCursor && _touches(value.selection, piece.start, piece.end)) {
      continue;
    }
    final item = syntax.parse(value.text.substring(piece.start, piece.end));
    if (item == null) continue;
    final char = _freeCapsuleChar(used);
    if (char == null) continue;
    used.add(char);
    capsules[char] = item;
    edits.add((
      start: piece.start,
      end: piece.end,
      text: String.fromCharCode(char),
    ));
  }

  if (edits.isEmpty) {
    if (capsules.length == value.capsules.length) return value;
    return CapsuleText<T>(
      text: value.text,
      selection: value.selection,
      capsules: capsules,
    );
  }
  final applied = _applyEdits(value.text, value.selection, edits);
  return CapsuleText<T>(
    text: applied.text,
    selection: applied.selection,
    capsules: capsules,
  );
}

/// [index]의 캡슐 글자를 다시 고칠 수 있는 원문 문자열로 펼친다.
///
/// 캡슐이 아니거나 원문으로 되돌릴 수 없으면 null. 커서는 [caretAtEnd]면 펼친
/// 문자열 끝(백스페이스), 아니면 앞(Delete)에 둔다.
CapsuleText<T>? expandCapsule<T>(
  CapsuleText<T> value,
  int index, {
  required CapsuleSyntax<T> syntax,
  required bool caretAtEnd,
}) {
  if (index < 0 || index >= value.text.length) return null;
  final char = value.text.codeUnitAt(index);
  final item = value.capsules[char];
  if (item == null) return null;
  final raw = syntax.format(item);
  if (raw == null) return null;

  return CapsuleText<T>(
    text: value.text.replaceRange(index, index + 1, raw),
    selection: TextSelection.collapsed(
      offset: caretAtEnd ? index + raw.length : index,
    ),
    capsules: {...value.capsules}..remove(char),
  );
}

/// 커서(또는 선택 범위)가 [start]~[end] 조각에 닿는지. 조각의 양 끝도 "닿음"으로
/// 본다 — 끝에 커서를 둔 채 이어 치는 중일 수 있다.
bool _touches(TextSelection selection, int start, int end) =>
    selection.isValid && selection.start <= end && selection.end >= start;

typedef _Edit = ({int start, int end, String text});

({String text, TextSelection selection}) _applyEdits(
  String text,
  TextSelection selection,
  List<_Edit> edits,
) {
  final buffer = StringBuffer();
  var last = 0;
  for (final edit in edits) {
    buffer.write(text.substring(last, edit.start));
    buffer.write(edit.text);
    last = edit.end;
  }
  buffer.write(text.substring(last));
  return (
    text: buffer.toString(),
    selection: TextSelection(
      baseOffset: _mapOffset(selection.baseOffset, edits),
      extentOffset: _mapOffset(selection.extentOffset, edits),
    ),
  );
}

/// 바뀐 구간들을 지나 옮겨간 커서 위치. 바뀐 조각 안쪽이었다면 새 조각 끝으로 민다.
int _mapOffset(int offset, List<_Edit> edits) {
  if (offset < 0) return offset;
  var shift = 0;
  for (final edit in edits) {
    if (offset >= edit.end) {
      shift += edit.text.length - (edit.end - edit.start);
    } else if (offset > edit.start) {
      return edit.start + shift + edit.text.length;
    } else {
      break;
    }
  }
  return offset + shift;
}

// ── 컨트롤러 ──

/// 캡슐을 접고 펼치며, 접힌 캡슐을 칩으로 그리는 텍스트 컨트롤러.
///
/// 값이 바뀌는 모든 길목([value] 설정)에서 한 번에 정규화한다. 그래서 키 입력·
/// 붙여넣기·커서 이동·프로그램적 변경이 모두 같은 규칙을 따른다.
class CapsuleTextController<T> extends TextEditingController {
  CapsuleTextController(this._syntax);

  CapsuleSyntax<T> _syntax;
  Map<int, T> _capsules = const {};

  CapsuleSyntax<T> get syntax => _syntax;

  /// 문법이 바뀌면(태그 이름·색이 바뀌면) 이미 접힌 칩도 다시 그린다.
  set syntax(CapsuleSyntax<T> value) {
    if (identical(_syntax, value)) return;
    _syntax = value;
    notifyListeners();
  }

  CapsuleText<T> get capsuleValue =>
      CapsuleText<T>(text: text, selection: selection, capsules: _capsules);

  /// 텍스트에 놓인 순서대로의, 확정된 값들(미완성·무효 조각은 빠진다).
  List<T> get items => capsuleValue.items;

  @override
  set value(TextEditingValue newValue) {
    // 조합 중(IME)에는 글자가 아직 확정되지 않아 접거나 펼치지 않는다.
    if (newValue.composing.isValid) {
      super.value = newValue;
      return;
    }
    final base =
        _expandDeletedCapsule(super.value, newValue) ??
        CapsuleText<T>(
          text: newValue.text,
          selection: newValue.selection,
          capsules: _capsules,
        );
    _store(collapseCapsules(base, syntax: _syntax));
  }

  /// 포커스를 잃을 때의 정리.
  ///
  /// 커서와 무관하게 접을 수 있는 조각을 모두 접은 뒤, 확정된 캡슐만으로 텍스트를
  /// 다시 세운다. 그래서 접히지 못한 원문(미완성·무효 조각)과 조각을 확정시키느라
  /// 친 여분의 공백이 남지 않는다 — 필드가 보여주는 것과 밖으로 나간 값이 같아진다.
  void commit() {
    setItems(
      collapseCapsules(capsuleValue, syntax: _syntax, ignoreCursor: true).items,
    );
  }

  /// 밖에서 정해진 값들로 텍스트를 갈아 끼운다(모두 캡슐로 접힌 상태).
  void setItems(Iterable<T> items) {
    final capsules = <int, T>{};
    final buffer = StringBuffer();
    for (final item in items) {
      final char = _freeCapsuleChar(capsules.keys.toSet());
      if (char == null) continue;
      if (buffer.isNotEmpty) buffer.write(kQuerySeparator);
      capsules[char] = item;
      buffer.writeCharCode(char);
    }
    final text = buffer.toString();
    _capsules = capsules;
    super.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _store(CapsuleText<T> next) {
    _capsules = next.capsules;
    super.value = TextEditingValue(
      text: next.text,
      selection: next.selection,
      composing: TextRange.empty,
    );
  }

  /// 캡슐 글자 하나만 지워진 변경이면(백스페이스·Delete) 지우는 대신 펼친다.
  ///
  /// 지우기 전 커서 위치로 어느 키였는지 가른다 — 백스페이스는 지운 글자의 뒤,
  /// Delete는 앞에 커서가 있었다. 여러 글자를 한 번에 지운 변경(범위 선택 삭제)은
  /// 그대로 두어 캡슐이 사라지게 한다.
  CapsuleText<T>? _expandDeletedCapsule(
    TextEditingValue before,
    TextEditingValue after,
  ) {
    if (!before.selection.isCollapsed || !after.selection.isCollapsed) {
      return null;
    }
    if (before.text.length != after.text.length + 1) return null;

    final caretBefore = before.selection.baseOffset;
    final caretAfter = after.selection.baseOffset;
    final bool caretAtEnd;
    final int index;
    if (caretAfter == caretBefore - 1) {
      caretAtEnd = true;
      index = caretAfter;
    } else if (caretAfter == caretBefore) {
      caretAtEnd = false;
      index = caretBefore;
    } else {
      return null;
    }
    if (index < 0 || index >= before.text.length) return null;
    if (before.text.replaceRange(index, index + 1, '') != after.text) {
      return null;
    }

    return expandCapsule(
      CapsuleText<T>(
        text: before.text,
        selection: before.selection,
        capsules: _capsules,
      ),
      index,
      syntax: _syntax,
      caretAtEnd: caretAtEnd,
    );
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final invalidStyle = (style ?? const TextStyle()).copyWith(
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.wavy,
      decorationColor: scheme.error,
    );

    final children = <InlineSpan>[];
    var cursor = 0;
    for (final piece in capsuleTextPieces(text)) {
      if (piece.start > cursor) {
        children.add(TextSpan(text: text.substring(cursor, piece.start)));
      }
      if (piece.isCapsule) {
        children.add(_capsuleSpan(text.codeUnitAt(piece.start)));
      } else {
        final raw = text.substring(piece.start, piece.end);
        children.add(
          TextSpan(text: raw, style: _isInvalid(piece) ? invalidStyle : null),
        );
      }
      cursor = piece.end;
    }
    if (cursor < text.length) {
      children.add(TextSpan(text: text.substring(cursor)));
    }
    return TextSpan(style: style, children: children);
  }

  /// 입력 중인 조각은 무효로 표시하지 않는다 — 한 글자 칠 때마다 붉어지지 않도록.
  bool _isInvalid(CapsuleTextPiece piece) {
    if (_touches(selection, piece.start, piece.end)) return false;
    return _syntax.isInvalid(text.substring(piece.start, piece.end));
  }

  /// 캡슐 글자 자리에 칩을 그린다. [WidgetSpan]도 한 코드 유닛을 차지하므로
  /// 커서 계산이 텍스트와 어긋나지 않는다.
  InlineSpan _capsuleSpan(int codeUnit) {
    final item = _capsules[codeUnit];
    if (item == null) return TextSpan(text: String.fromCharCode(codeUnit));
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: _syntax.chip(item),
    );
  }
}

// ── 자동완성 ──

/// 자동완성 후보 하나. 화면에 무엇으로 보이고 텍스트에 무엇을 넣을지만 담는다
/// (무엇을 고른 것인지는 문법마다 달라 여기 오지 않는다).
class CapsuleCompletion {
  const CapsuleCompletion({
    required this.insertText,
    required this.title,
    required this.description,
  });

  final String insertText;
  final String title;
  final String description;
}

/// 커서 한 위치에서 계산한 자동완성 상태.
class CapsuleCompletions {
  const CapsuleCompletions({
    required this.replaceStart,
    required this.replaceEnd,
    required this.items,
  });

  /// 후보를 고를 때 원문에서 갈아 끼울 구간.
  final int replaceStart;
  final int replaceEnd;

  final List<CapsuleCompletion> items;
}

/// 커서 위치의 후보를 내는 함수. 캡슐 글자가 구분문자로 가려진 텍스트와, 이미
/// 접힌 값들을 함께 받는다(이미 쓴 태그를 후보에서 빼는 데 쓴다).
typedef CapsuleCompletionsBuilder<T> =
    CapsuleCompletions? Function(String text, int cursor, List<T> items);

// ── 필드 ──

/// 확정된 조각이 칩으로 접히는 텍스트 입력 필드.
///
/// 확정된 값이 바뀔 때마다 [onChanged]로 알린다. 미완성·무효 문자열은 필드 안에
/// 남을 뿐 밖으로 나가지 않는다(저장 규칙은 칩 편집 경로와 같다).
class CapsuleTextField<T> extends StatefulWidget {
  const CapsuleTextField({
    super.key,
    required this.syntax,
    required this.items,
    required this.onChanged,
    required this.completionsAt,
    required this.hintText,
    this.focusNode,
    this.autofocus = false,
  });

  /// 조각↔값 변환과 칩 그리기. 태그 정의가 바뀌면 새 인스턴스를 넘긴다.
  final CapsuleSyntax<T> syntax;

  /// 밖에서 정해진 값들. 이 필드가 마지막으로 내보낸 것과 다를 때만 갈아 끼운다
  /// (칩 편집·다이얼로그 등 딴 경로가 값을 바꾼 경우).
  final List<T> items;

  final ValueChanged<List<T>> onChanged;
  final CapsuleCompletionsBuilder<T> completionsAt;
  final String hintText;

  /// 밖에서 쥔 포커스 노드. 이 필드가 편집 중인지를 바깥이 알아야 할 때 넘긴다
  /// (칩 줄과 자리를 바꾸는 등). 없으면 스스로 만든다.
  final FocusNode? focusNode;

  /// 트리에 놓이자마자 포커스를 가져올지. 딴 위젯을 밀어내고 그 자리에 나타나는
  /// 필드가 쓴다(나타난 까닭이 곧 "여기에 입력하겠다"이므로).
  final bool autofocus;

  @override
  State<CapsuleTextField<T>> createState() => _CapsuleTextFieldState<T>();
}

class _CapsuleTextFieldState<T> extends State<CapsuleTextField<T>> {
  late final CapsuleTextController<T> _controller;
  late final FocusNode _focus;

  /// 스스로 만든 포커스 노드(밖에서 받았으면 null). 만든 것만 버린다.
  FocusNode? _ownedFocus;
  final LayerLink _link = LayerLink();
  final OverlayPortalController _overlay = OverlayPortalController();

  CapsuleCompletions? _completions;
  int _highlighted = 0;
  String _lastText = '';

  /// Esc로 닫은 뒤에는 글자를 더 치기 전까지 목록을 다시 열지 않는다.
  bool _dismissed = false;

  /// 이 필드가 마지막으로 [CapsuleTextField.onChanged]로 내보낸 값들.
  List<T> _emitted = const [];

  /// 밖에서 온 것을 컨트롤러에 얹는 중인지. 그동안의 컨트롤러 알림은 사용자 입력이
  /// 아니므로 흘려보낸다 — 값을 나온 곳으로 도로 돌려보내지 않고, 빌드 도중에
  /// 자동완성 오버레이를 여닫지도 않는다(그 자리에선 오버레이를 만질 수 없다).
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _controller = CapsuleTextController<T>(widget.syntax);
    _controller.setItems(widget.items);
    _emitted = _controller.items;
    _lastText = _controller.text;
    _controller.addListener(_onValueChanged);
    _focus = widget.focusNode ?? (_ownedFocus = FocusNode());
    _focus.onKeyEvent = _onKeyEvent;
    _focus.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(CapsuleTextField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _applying = true;
    // 태그 정의가 바뀌면 이미 접힌 캡슐도 새 문법으로 다시 그린다.
    _controller.syntax = widget.syntax;
    // 이 필드가 내보낸 값이 되돌아온 것이면 텍스트는 이미 그 모양이다(편집 중인
    // 조각을 지우지 않도록 손대지 않는다). 딴 경로가 바꾼 값만 갈아 끼운다.
    if (!_sameItems(widget.items, _emitted)) {
      _controller.setItems(widget.items);
      _emitted = _controller.items;
    }
    _lastText = _controller.text;
    _applying = false;
  }

  /// 두 값 목록이 같은 값을 같은 순서로 담았는지. 값은 불변이라 동일성으로 가른다
  /// (조건·정렬 단계는 텍스트를 다시 읽을 때마다 새로 만들어진다).
  bool _sameItems(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _controller.removeListener(_onValueChanged);
    _controller.dispose();
    _focus.removeListener(_onFocusChanged);
    _focus.onKeyEvent = null;
    _ownedFocus?.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focus.hasFocus) return;
    _controller.commit();
    _overlay.hide();
  }

  void _onValueChanged() {
    // 밖에서 갈아 끼우는 중이면 자동완성·알림 없이 지나간다(빌드 도중일 수 있다).
    if (_applying) return;

    final textChanged = _controller.text != _lastText;
    _lastText = _controller.text;

    final selection = _controller.selection;
    final completions = selection.isCollapsed && selection.baseOffset >= 0
        ? widget.completionsAt(
            _maskCapsules(_controller.text),
            selection.baseOffset,
            _controller.items,
          )
        : null;

    setState(() {
      if (textChanged) _dismissed = false;
      _completions = completions;
      _highlighted = 0;
    });

    final items = completions?.items ?? const [];
    if (_focus.hasFocus && !_dismissed && items.isNotEmpty) {
      _overlay.show();
    } else {
      _overlay.hide();
    }
    _emitIfChanged();
  }

  void _emitIfChanged() {
    final next = _controller.items;
    if (_sameItems(next, _emitted)) return;
    _emitted = next;
    widget.onChanged(next);
  }

  /// 캡슐 글자를 구분문자로 바꾼 텍스트. 자동완성은 캡슐을 모르지만, 캡슐은 늘
  /// 홀로 선 조각이라 공백으로 갈아 끼우면 글자 수를 그대로 둔 채 같은 뜻이 된다.
  String _maskCapsules(String text) => String.fromCharCodes([
    for (final unit in text.codeUnits)
      if (isCapsuleChar(unit)) _separatorUnit else unit,
  ]);

  static final int _separatorUnit = kQuerySeparator.codeUnitAt(0);

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent || !_overlay.isShowing) {
      return KeyEventResult.ignored;
    }
    final items = _completions?.items ?? const [];
    if (items.isEmpty) return KeyEventResult.ignored;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() => _highlighted = (_highlighted + 1) % items.length);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      setState(
        () => _highlighted = (_highlighted - 1 + items.length) % items.length,
      );
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.tab) {
      _accept(items[_highlighted]);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      setState(() => _dismissed = true);
      _overlay.hide();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _accept(CapsuleCompletion item) {
    final completions = _completions;
    if (completions == null) return;

    final text = _controller.text;
    final start = completions.replaceStart;
    var insert = item.insertText;
    // 캡슐 바로 뒤에서 새 조각을 시작하면 구분문자를 끼워 서로 붙지 않게 한다.
    if (start > 0 &&
        start == completions.replaceEnd &&
        isCapsuleChar(text.codeUnitAt(start - 1))) {
      insert = '$kQuerySeparator$insert';
    }

    _controller.value = TextEditingValue(
      text: text.replaceRange(start, completions.replaceEnd, insert),
      selection: TextSelection.collapsed(offset: start + insert.length),
    );
    setState(() => _dismissed = true);
    _overlay.hide();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlay,
        overlayChildBuilder: _buildOverlay,
        child: TextField(
          controller: _controller,
          focusNode: _focus,
          autofocus: widget.autofocus,
          maxLines: 1,
          // 도구모음 줄에 얹히므로 테두리·바탕 없이 뒷배경에 녹인다(같은 자리에
          // 그려지는 조건 칩 줄과 겉모습이 이어지도록).
          decoration: InputDecoration(
            isDense: true,
            filled: false,
            border: InputBorder.none,
            hintText: widget.hintText,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: kCapsuleFieldInset,
              vertical: 8,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final items = _completions?.items ?? const <CapsuleCompletion>[];
    return Positioned(
      left: 0,
      top: 0,
      child: CompositedTransformFollower(
        link: _link,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(0, 4),
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280, maxHeight: 240),
            child: _CompletionList(
              items: items,
              highlighted: _highlighted,
              onSelected: _accept,
            ),
          ),
        ),
      ),
    );
  }
}

/// 자동완성 목록. 왼쪽에 고를 것의 이름, 오른쪽에 그 설명을 둔다.
class _CompletionList extends StatelessWidget {
  const _CompletionList({
    required this.items,
    required this.highlighted,
    required this.onSelected,
  });

  final List<CapsuleCompletion> items;
  final int highlighted;
  final ValueChanged<CapsuleCompletion> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(4),
      clipBehavior: Clip.antiAlias,
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            onTap: () => onSelected(item),
            child: Container(
              color: index == highlighted
                  ? theme.colorScheme.secondaryContainer
                  : null,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(item.title, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
