/// 컬렉션 비교 유틸(순수 Dart).
///
/// 값 동등성을 갖는 엔티티가 목록 필드를 가질 때 쓴다. Flutter의 `listEquals`는
/// `package:flutter/foundation.dart`에 있어 플랫폼 무관해야 하는 domain에서 쓸 수
/// 없고, `package:collection`은 직접 의존하지 않으므로 여기에 최소한만 둔다.
library;

/// 두 목록이 같은 길이·같은 순서로 서로 같은 원소를 담는지(원소는 `==`로 비교).
bool equalLists<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// 목록의 순서까지 반영한 해시(값 동등성과 짝을 이룬다).
int hashList<T>(List<T> items) => Object.hashAll(items);
