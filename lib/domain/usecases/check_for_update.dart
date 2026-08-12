import 'package:pub_semver/pub_semver.dart';

import '../entities/update_check_outcome.dart';
import '../repositories/release_repository.dart';

/// 현재 버전과 배포처의 최신 릴리즈를 견줘 알릴 것이 있는지 판정하는 순수 유즈케이스.
///
/// **조회하지 않아야 할 때를 먼저 거른다.** 버전을 알 수 없는 실행과, 갱신을
/// 스토어·패키지 관리자가 맡는 배포본이다 — 뒤쪽은 앱이 스스로 받아 까는 것이
/// 지원되지 않는 배포 형태라, 확인해 봐야 사용자를 틀린 경로로 이끈다.
///
/// 조회·해석의 모든 실패는 [UpdateCheckFailed]로 눕힌다. 업데이트 확인은 사용자가
/// 시킨 일의 곁다리라, 실패가 예외로 번져 다른 동작을 끊어서는 안 된다.
class CheckForUpdate {
  const CheckForUpdate(this.releases);

  final ReleaseRepository releases;

  /// [currentVersion]이 비면 버전을 모르는 실행이다([storeManaged]보다 먼저 따진다 —
  /// 견줄 값이 없는 것은 어느 채널로 잡히든 마찬가지다).
  Future<UpdateCheckOutcome> call({
    required String currentVersion,
    required bool storeManaged,
  }) async {
    if (currentVersion.isEmpty) {
      return const UpdateCheckSkipped(UpdateCheckSkipReason.unknownVersion);
    }
    if (storeManaged) {
      return const UpdateCheckSkipped(UpdateCheckSkipReason.managedByStore);
    }

    final current = _parse(currentVersion);
    if (current == null) return const UpdateCheckFailed();

    try {
      final latest = await releases.latestRelease();
      // 릴리즈가 하나도 없으면 권할 것이 없다 — 실패가 아니다.
      if (latest == null) return const UpToDate();

      final published = _parse(latest.version);
      if (published == null) return const UpdateCheckFailed();

      // 직접 빌드하거나 시험판을 쓰는 사용자는 배포본보다 앞설 수 있다. 그때
      // 최신판으로 "내리라"고 권하지 않는다.
      return published > current ? UpdateAvailable(latest) : const UpToDate();
    } catch (_) {
      return const UpdateCheckFailed();
    }
  }

  Version? _parse(String version) {
    try {
      return Version.parse(version);
    } on FormatException {
      return null;
    }
  }
}
