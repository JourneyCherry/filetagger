/// 목록에서 글자를 이어 쳐, 그 글자로 시작하는 항목으로 커서를 건너뛰는 "빠른 탐색".
///
/// 필터의 "포함" 조건이 **목록 자체를 줄이는** 것과 달리 이쪽은 목록을 그대로 두고
/// **커서만** 옮긴다 — 이미 걸러 둔 목록 안에서 원하는 항목을 짚는 자리다.
///
/// 훑는 순서 규칙은 순수 함수로 두어 세 보기 모드가 나눠 쓰고(각자 자기 표시 순서의
/// 이름 목록을 만들어 넘긴다), 검색어와 그 유효 시간만 프로바이더가 쥔다 — 어느
/// 보기에서 쳤든 화면에 뜨는 표시는 하나이기 때문이다.
library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 이어 친 글자를 한 검색어로 묶는 유효 시간. 지나면 다음 글자가 새 검색어가 된다.
const Duration kTypeAheadTimeout = Duration(milliseconds: 900);

/// 검색어에 글자 하나를 잇는다.
///
/// 같은 글자를 이어 치면 검색어를 늘리지 않는다 — 그러면 그 글자로 시작하는 항목들을
/// 차례로 도는 뜻이 되어(아래 [typeAheadSearchStart] 참조) 탐색기 관용과 같아진다.
/// 그 대가로 같은 글자로 시작하는 두 글자 검색어(예: 같은 글자를 두 번 친 이름)는
/// 칠 수 없는데, 탐색기도 같은 선택을 했고 얻는 쪽이 훨씬 흔하다.
String nextTypeAheadQuery(String current, String character) {
  if (current.isEmpty) return character;
  if (current.length == 1 && current.toLowerCase() == character.toLowerCase()) {
    return current;
  }
  return current + character;
}

/// 검색을 어디서부터 훑을지: 글자 하나짜리 검색어는 **다음** 항목부터(같은 글자를
/// 이어 치면 그 글자로 시작하는 항목들을 차례로 돈다), 두 글자 이상이면 **지금**
/// 항목부터(방금 맞춘 항목이 늘어난 검색어에도 맞으면 제자리에 머문다).
int typeAheadSearchStart(String query, int current) =>
    query.length <= 1 ? current + 1 : current;

/// [names](표시 순서)에서 [query]로 시작하는 첫 항목의 인덱스. [from]부터 훑고 끝에
/// 닿으면 처음으로 돌아 한 바퀴를 다 돈다. 대소문자는 가리지 않는다. 맞는 것이 없으면
/// null(부르는 쪽은 커서를 그대로 둔다).
///
/// 이름이 빈 항목은 결코 맞지 않는다 — 검색 대상이 아닌 자리(아이콘 보기의 그룹 헤더
/// 등)를 부르는 쪽이 빈 이름으로 넘겨 인덱스만 맞춰 두는 방식이다.
int? findTypeAheadMatch(List<String> names, String query, int from) {
  if (query.isEmpty || names.isEmpty) return null;
  final needle = query.toLowerCase();
  final start = from <= 0 ? 0 : from % names.length;
  for (var i = 0; i < names.length; i++) {
    final index = (start + i) % names.length;
    if (names[index].toLowerCase().startsWith(needle)) return index;
  }
  return null;
}

/// 키 이벤트에서 빠른 탐색이 받을 **글자**를 뽑는다. 아니면 null이라 그 키는 다른
/// 몫으로 그대로 흘러간다.
///
/// [node]가 **직접** 포커스를 쥔 때만 받는다 — 자식 텍스트 입력(필터·정렬 줄, 셀
/// 편집창)이 쥐고 있으면 거기 친 글자라 목록으로 새면 안 된다. 보조키(Ctrl·Alt·Cmd)가
/// 눌린 조합은 명령 단축키의 자리라 넘기지 않고(Shift는 대문자를 만드는 것이라 그대로
/// 받는다), 방향키·Enter처럼 글자가 없거나 제어문자를 내는 키도 뺀다. 눌림만 받아
/// 키를 누르고 있는 동안 목록이 미끄러지지 않게 한다.
String? typeAheadCharacter(FocusNode node, KeyEvent event) {
  if (event is! KeyDownEvent) return null;
  if (!identical(FocusManager.instance.primaryFocus, node)) return null;
  final keyboard = HardwareKeyboard.instance;
  if (keyboard.isControlPressed ||
      keyboard.isAltPressed ||
      keyboard.isMetaPressed) {
    return null;
  }
  final character = event.character;
  if (character == null || character.isEmpty) return null;
  final code = character.codeUnitAt(0);
  if (code < 0x20 || code == 0x7f) return null;
  return character;
}

/// 지금까지 이어 친 검색어를 쥐고, 다음 커서 자리를 골라 준다.
///
/// 상태는 검색어 하나뿐이다(화면에 그것만 보인다). 마지막 입력 시각과 만료 타이머는
/// 안에서만 쓰는 것이라 상태로 올리지 않는다 — 글자마다 상태가 새로 나가면 검색어가
/// 그대로인 입력에도 표시가 다시 그려진다.
class TypeAheadController extends Notifier<String> {
  Timer? _expiry;
  DateTime? _typedAt;

  @override
  String build() {
    ref.onDispose(() => _expiry?.cancel());
    return '';
  }

  /// 글자 하나를 이어 치고, [names]에서 다음 대상의 인덱스를 고른다. 맞는 것이 없거나
  /// 받을 글자가 아니면 null이다.
  ///
  /// [current]는 지금 커서가 놓인 인덱스(없으면 음수). [names]는 그 보기의 표시 순서와
  /// 인덱스가 같아야 한다.
  int? type(
    String character, {
    required List<String> names,
    required int current,
  }) {
    final now = DateTime.now();
    final at = _typedAt;
    final expired = at == null || now.difference(at) > kTypeAheadTimeout;
    final previous = expired ? '' : state;
    // 첫 글자로는 공백을 받지 않는다(검색어 안에서만 뜻이 있다) — 아무것도 치지 않은
    // 상태의 스페이스바를 빠른 탐색이 삼키지 않게 한다.
    if (previous.isEmpty && character.trim().isEmpty) return null;
    final query = nextTypeAheadQuery(previous, character);
    _typedAt = now;
    _restartExpiry();
    if (query != state) state = query;
    return findTypeAheadMatch(
      names,
      query,
      typeAheadSearchStart(query, current),
    );
  }

  /// 검색어를 비운다(표시도 함께 사라진다).
  void clear() {
    _expiry?.cancel();
    _typedAt = null;
    if (state.isNotEmpty) state = '';
  }

  void _restartExpiry() {
    _expiry?.cancel();
    _expiry = Timer(kTypeAheadTimeout, clear);
  }
}

/// 지금 이어 친 빠른 탐색 검색어(비었으면 검색 중이 아니다).
final typeAheadProvider = NotifierProvider<TypeAheadController, String>(
  TypeAheadController.new,
);
