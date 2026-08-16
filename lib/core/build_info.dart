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

/// 빌드가 새긴 앱 버전. 릴리즈 패키징만 주입하므로 그 밖의 빌드에서는 빈 문자열이다.
const String injectedVersion = String.fromEnvironment(versionDefineKey);

/// 릴리즈 패키징이 배포 정보를 새겨 넣은 산출물인지.
///
/// **버전이 주입되었는지**로 판별한다 — 릴리즈 산출물은 반드시 버전을 달고 나오므로,
/// 새겨지지 않았다는 것은 정식 배포본이 아니라는 뜻이다. 버전 **값**은 직접 빌드에도
/// 있으므로([appVersion]) 값의 유무로는 가를 수 없다.
///
/// **컴파일 모드(디버그·릴리즈)와는 무관하다** — 직접 빌드한 실행은 어떻게 컴파일했든
/// 주입을 거치지 않아 여기서 거짓이다. [distributionChannel]은 주입이 없어도 값을
/// 가지므로(아래), **배포 형태를 말하는 자리는 이것을 먼저 물어야 한다**.
const bool isReleaseArtifact = injectedVersion != '';

String _appVersion = injectedVersion;

/// 이 실행의 앱 버전.
///
/// 릴리즈 산출물은 빌드가 새긴 값을 쓰고, 직접 빌드는 함께 실린 `pubspec.yaml`에서
/// 읽어 채운다([resolveAppVersion]). **양쪽 다 원본이 같은 파일이라 어긋날 수 없다.**
/// 아직 채워지지 않았거나 읽지 못했으면 빈 문자열이다.
String get appVersion => _appVersion;

/// 주입되지 않은 실행의 버전을 채운다(앱 시작 시 한 번).
///
/// 주입된 값이 있으면 그것을 이긴다 — 릴리즈 워크플로의 게이트가 태그와 대조해
/// 검증한 값이므로, 나중에 읽은 값이 그것을 덮어서는 안 된다.
void resolveAppVersion(String version) {
  if (injectedVersion.isNotEmpty) return;
  _appVersion = version;
}

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
  /// **모르는 값·빈 값은 [portable]로 눕는다.** 주입이 없는 실행은 직접 빌드한
  /// 산출물이고, 그것은 압축을 풀어 그 자리에서 쓰는 형태와 다를 것이 없다 — 설정이
  /// 빌드 폴더 안에 남아야 폴더째 옮겼을 때 따라간다. [package]로 나가는 패키징만
  /// 채널을 명시해 갈아탄다(그쪽은 설치 폴더가 읽기 전용이라, 명시가 빠지면 설정
  /// 저장이 실패해 곧바로 드러난다 — 틀렸을 때 알아차리기 쉬운 쪽을 명시로 돌렸다).
  ///
  /// **디버그 실행도 예외가 아니다.** 그 실행의 "실행 파일 옆"은 빌드 디렉토리라
  /// 빌드를 지우면 설정도 함께 사라지는데, 그것이 손해가 아니라 **첫 실행 상태를
  /// 시험하는 수단**이다(빌드하면 초기화된 앱으로 시작한다).
  static DistributionChannel parse(String name) => values.firstWhere(
    (channel) => channel.name == name,
    orElse: () => portable,
  );
}

/// 이 빌드의 배포 채널.
///
/// **주입이 없는 실행도 값을 갖는다**(포터블로 눕는다). 그래서 이 값만으로는 "정말 그
/// 형태로 배포된 것인가"를 알 수 없고, 그것을 묻는 자리는 [isReleaseArtifact]로 먼저
/// 거른다.
final DistributionChannel distributionChannel = DistributionChannel.parse(
  const String.fromEnvironment(channelDefineKey),
);
