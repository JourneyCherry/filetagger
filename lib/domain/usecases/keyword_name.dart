/// 키워드 이름의 규칙과 그 위반. 키워드는 이름을 경로 자리에 담으므로, 이름이 곧
/// 노드의 식별자다.
enum KeywordNameError {
  /// 이름이 비었다.
  empty,

  /// 이름에 경로 구분자가 섞였다.
  separator,

  /// 같은 이름의 키워드가 이미 있다.
  duplicate,
}

/// 사용자가 친 이름을 다듬어 돌려준다. 규칙을 어기면 이름 없이 사유만 돌려준다.
///
/// 경로 구분자를 막는 이유는 키워드가 경로 계층에 속하지 않기 때문이다 — 이름에
/// 구분자가 들어가면 목록·그룹이 있지도 않은 조상 폴더를 세우려 든다.
/// 중복([KeywordNameError.duplicate])은 저장소만 알 수 있어 여기서 보지 않는다.
({String? name, KeywordNameError? error}) normalizeKeywordName(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return (name: null, error: KeywordNameError.empty);
  if (trimmed.contains('/') || trimmed.contains(r'\')) {
    return (name: null, error: KeywordNameError.separator);
  }
  return (name: trimmed, error: null);
}
