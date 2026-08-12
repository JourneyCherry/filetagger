import 'app_release.dart';

/// 업데이트 확인 한 번의 결과.
///
/// "확인하지 않았다"([UpdateCheckSkipped])와 "확인했는데 실패했다"([UpdateCheckFailed])를
/// 가른다 — 앞은 사용자에게 배포 형태를 알려 다른 경로로 보내야 하고, 뒤는 다시
/// 시도하면 되는 일이라 안내가 달라진다.
sealed class UpdateCheckOutcome {
  const UpdateCheckOutcome();
}

/// 배포처에 더 높은 버전이 올라와 있다.
final class UpdateAvailable extends UpdateCheckOutcome {
  const UpdateAvailable(this.release);

  final AppRelease release;
}

/// 견줄 것이 없거나 현재 버전이 배포본과 같거나 더 앞선다.
final class UpToDate extends UpdateCheckOutcome {
  const UpToDate();
}

/// 확인을 시도하지 않았다.
final class UpdateCheckSkipped extends UpdateCheckOutcome {
  const UpdateCheckSkipped(this.reason);

  final UpdateCheckSkipReason reason;
}

/// 확인을 건너뛴 이유.
enum UpdateCheckSkipReason {
  /// 이 실행의 버전을 알 수 없어 견줄 것이 없다. 빌드가 버전을 새기지도, 함께 실린
  /// pubspec에서 읽어 내지도 못한 경우다.
  unknownVersion,

  /// 스토어·패키지 관리자가 갱신을 맡는 배포본이다. 앱이 스스로 받아 까는 것이
  /// 지원되지 않는 형태라, 확인 결과를 내밀면 사용자를 틀린 경로로 이끈다.
  managedByStore,
}

/// 조회하지 못했거나 응답을 해석하지 못했다(네트워크 단절·형식 변화 등).
final class UpdateCheckFailed extends UpdateCheckOutcome {
  const UpdateCheckFailed();
}
