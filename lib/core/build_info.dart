/// 빌드 시각에 못박히는 정보(버전·배포 채널)의 단일 출처.
///
/// 값은 `--dart-define`으로 들어온다. 버전의 원본은 `pubspec.yaml`이며 패키징
/// 스크립트가 그것을 읽어 주입하므로, 코드가 버전을 따로 들고 있지 않는다.
///
/// **배포 채널을 런타임에 자동 판별하지 않는 것은 의도된 선택**이다 — 실행 위치나
/// 쓰기 권한 따위로 넘겨짚으면 포터블이 설치판처럼 굴거나 그 반대가 되는 사고가
/// 난다. 어느 형태로 배포할지는 빌드가 안다.
library;

/// 버전을 주입하는 `--dart-define` 키. 패키징 스크립트가 같은 이름을 써야 한다.
const String versionDefineKey = 'FILETAGGER_VERSION';

/// 배포 채널을 주입하는 `--dart-define` 키. 값은 [DistributionChannel]의 이름이다.
const String channelDefineKey = 'FILETAGGER_CHANNEL';

/// 주입된 앱 버전. 주입이 없으면 빈 문자열이다([isDevelopmentBuild]).
const String appVersion = String.fromEnvironment(versionDefineKey);

/// 패키징을 거치지 않은 실행인지(`flutter run`·IDE 실행).
///
/// 버전이 주입되지 않았다는 사실 하나로 판별한다 — 릴리즈 산출물은 반드시 버전을
/// 달고 나오므로, 버전이 없다는 것은 정식 배포본이 아니라는 뜻이다.
const bool isDevelopmentBuild = appVersion == '';

/// 이 빌드가 어떤 형태로 배포되는지.
///
/// 설정 파일 위치를 가르는 데 쓰이고, 나중의 업데이트 확인 기능이 판별해야 할
/// 자리이기도 하다.
enum DistributionChannel {
  /// 압축을 풀어 그 자리에서 실행하는 형태(설치 없음).
  portable,

  /// 설치 관리자를 거쳐 시스템에 깔리는 형태.
  package;

  /// 주입 문자열을 채널로 옮긴다.
  ///
  /// 모르는 값·빈 값은 [package]로 눕힌다. 개발 실행이 [portable]로 잡히면 설정이
  /// 빌드 디렉토리에 쓰이고 빌드를 지울 때마다 사라지므로, 안전한 쪽이 설치판이다.
  static DistributionChannel parse(String name) => values.firstWhere(
    (channel) => channel.name == name,
    orElse: () => package,
  );
}

/// 이 빌드의 배포 채널.
final DistributionChannel distributionChannel = DistributionChannel.parse(
  const String.fromEnvironment(channelDefineKey),
);
