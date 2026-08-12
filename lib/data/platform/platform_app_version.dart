import 'package:package_info_plus/package_info_plus.dart';

import '../../core/build_info.dart';

/// 플랫폼이 들고 있는 앱 메타데이터에서 버전을 읽어 [appVersion]에 채운다.
///
/// 원본은 릴리즈와 같은 `pubspec.yaml`이다 — Flutter 빌드가 그 값을 각 플랫폼의
/// 메타데이터(Windows는 실행 파일의 버전 리소스 등)에 새겨 넣고, 이 함수는 그것을
/// 되읽는다. 릴리즈 산출물은 빌드가 버전을 새겨 오므로 값이 바뀌지 않고
/// ([resolveAppVersion]), **직접 빌드·개발 실행에서도 버전이 보이게 하는 것**이 목적이다.
///
/// **실패해도 조용히 넘어간다** — 버전을 못 읽는 것은 앱을 못 켤 이유가 아니다.
/// 그때는 버전이 빈 채로 남아, 버전을 모르는 실행으로 다뤄진다.
Future<void> loadPlatformAppVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    final version = versionWithoutBuildNumber(info.version);
    if (version.isNotEmpty) resolveAppVersion(version);
  } catch (_) {
    // 버전 없이 계속 간다.
  }
}

/// 플랫폼이 돌려준 표기에서 릴리즈 태그와 견줄 수 있는 부분만 남긴다.
///
/// 지금 쓰는 플랫폼 구현들은 빌드 번호를 버전과 **이미 갈라서** 준다. 그래도 한 번 더
/// 거르는 것은 이 값이 곧장 버전 비교에 들어가기 때문이다 — 어느 플랫폼이 둘을 붙여
/// 주더라도 릴리즈 태그와 같은 모양이 되어야 판정이 어긋나지 않는다(릴리즈 워크플로도
/// 태그를 만들 때 같은 자리에서 자른다).
String versionWithoutBuildNumber(String version) =>
    version.split('+').first.trim();
