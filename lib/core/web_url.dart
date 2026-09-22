/// 사람이 적어 넣은 문자열에서 **웹 주소**를 알아보는 순수 헬퍼. 플랫폼·UI 프레임워크에
/// 의존하지 않아 그대로 유닛테스트한다.
library;

/// 열어 줄 스킴(소문자). [Uri]가 스킴을 소문자로 정규화해 두어 그대로 대조한다.
const Set<String> webUrlSchemes = {'http', 'https'};

/// [value]가 웹 주소면 그 [Uri], 아니면 null.
///
/// **스킴이 적혀 있어야 한다** — `example.com` 같은 맨몸 문자열에 스킴을 지어 붙이면
/// 사용자가 적지 않은 주소를 앱이 만들어 내 여는 꼴이 된다. 받아들이는 스킴도
/// [webUrlSchemes] 둘로 좁힌다 — 임의 스킴을 OS에 넘기면 사용자가 뜻하지 않은
/// 프로그램이 뜬다.
///
/// 갈 곳(호스트)이 없는 주소도 웹 주소로 치지 않는다. 앞뒤 공백은 떼고 본다 — 값을
/// 붙여 넣을 때 딸려 오는 것이라 적은 사람의 뜻이 아니다.
Uri? webUrlOf(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  final uri = Uri.tryParse(trimmed);
  // 조각(#앵커)이 붙은 주소도 그대로 받는다 — `Uri.isAbsolute`는 조각이 있으면
  // false라, 스킴이 있는지는 스킴 자체로 본다.
  if (uri == null || !webUrlSchemes.contains(uri.scheme)) return null;
  return uri.host.isEmpty ? null : uri;
}
