/// 태그 색의 **저장 표현 ↔ 16진 표기** 단일 출처(순수 변환).
///
/// 색은 DB에서 불투명 ARGB 정수로 살지만, 사람이 손으로 열어 고치는 파일에는 정수가
/// 아니라 16진 표기로 남는다(전역 설정의 사용자 색 목록). 두 방향을 한자리에 두는
/// 이유는 **읽는 쪽이 둘**이기 때문이다 — 설정 파일을 읽고 쓰는 data 계층과, 색을
/// 다루는 화면이 같은 해석을 써야 조용히 갈라지지 않는다.
library;

/// 태그 색이 늘 갖는 알파 비트. 팔레트에서 고르든 직접 고르든 불투명으로 고정한다 —
/// 반투명이면 칩이 뒤 배경과 섞여 글자색 대비 보장이 흔들린다.
const int opaqueTagColorBits = 0xFF000000;

/// 저장된 색 정수를 사람이 읽고 고쳐 쓰는 16진 표기로. 알파는 고정이라 내지 않는다.
String tagColorToHex(int argb) =>
    '#${(argb & 0xFFFFFF).toRadixString(16).toUpperCase().padLeft(6, '0')}';

/// 16진 표기를 저장 형식(불투명 ARGB 정수)으로. 해석할 수 없으면 null.
///
/// 앞의 '#'과 앞뒤 공백은 있어도 없어도 받고 대소문자를 가리지 않는다. 각 자리를
/// 한 번씩만 쓴 축약형도 받는다 — 손으로 칠 때 흔한 표기라 막을 이유가 없다.
/// 알파를 적어 넣는 표기는 받지 않는다(색은 늘 불투명이다).
int? parseTagColorHex(String input) {
  var text = input.trim();
  if (text.startsWith('#')) text = text.substring(1);
  if (!_hexDigits.hasMatch(text)) return null;
  if (text.length == _shortHexLength) {
    text = [for (final c in text.split('')) '$c$c'].join();
  }
  if (text.length != _fullHexLength) return null;
  return opaqueTagColorBits | int.parse(text, radix: 16);
}

final RegExp _hexDigits = RegExp(r'^[0-9a-fA-F]+$');

/// 축약형(각 자리 한 번)과 정식(각 자리 두 번) 표기의 길이.
const int _shortHexLength = 3;
const int _fullHexLength = 6;
