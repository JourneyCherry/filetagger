/// 배포처에 올라와 있는 릴리즈 하나.
///
/// 태그 이름이 아니라 **비교 가능한 버전 문자열**을 담는다 — 태그에 접두사를 붙일지는
/// 배포처 표기의 문제라 조회 구현(data 계층)이 흡수하고, 도메인은 버전만 본다.
class AppRelease {
  const AppRelease({required this.version, required this.pageUrl});

  /// semver 문자열.
  final String version;

  /// 사용자에게 열어 줄 릴리즈 페이지 주소.
  final Uri pageUrl;
}
