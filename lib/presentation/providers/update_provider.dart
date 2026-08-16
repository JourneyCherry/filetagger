import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/build_info.dart';
import '../../data/update/github_release_repository.dart';
import '../../domain/entities/update_check_outcome.dart';
import '../../domain/repositories/release_repository.dart';
import '../../domain/usecases/check_for_update.dart';

/// 배포처 릴리즈 조회 저장소. 테스트는 이 provider를 갈아 끼운다.
final releaseRepositoryProvider = Provider<ReleaseRepository>(
  (ref) => GithubReleaseRepository(),
);

/// 이 빌드의 갱신을 스토어·패키지 관리자가 맡는지.
///
/// 설치판은 스토어를 거쳐 나가는 형태다 — 그쪽은 갱신을 스토어가 관장하고 앱이
/// 스스로 받아 까는 것을 지원하지 않으므로, 배포처를 조회할 이유가 없다.
///
/// **릴리즈 산출물인지를 먼저 묻는다.** 채널은 주입이 없어도 설치판으로 눕는데(설정
/// 저장 위치를 위한 안전판이다), 채널만 보면 직접 빌드한 실행까지 스토어 배포본으로
/// 잡혀 배포처를 조회하지 못한다 — 스토어가 갱신해 줄 리 없는 실행이 "스토어가
/// 관리한다"는 답만 받고 릴리즈 페이지로 갈 길이 막힌다.
bool get storeManagedBuild =>
    isReleaseArtifact && distributionChannel == DistributionChannel.package;

/// 업데이트 확인 결과.
///
/// 앱을 켤 때 한 번 자동으로 확인하고([FileTaggerApp]이 구독을 열어 둔다), 사용자가
/// 확인 명령을 실행하면 [UpdateCheckNotifier.recheck]로 다시 확인한다.
///
/// **자동 확인은 조용하다** — 결과가 [UpdateAvailable]일 때만 상태표시줄에 한 줄이
/// 늘고, 최신이거나 실패했을 때는 아무것도 알리지 않는다. 사용자가 시키지 않은
/// 확인의 결과로 창을 가로막지 않기 위함이다.
final updateCheckProvider =
    AsyncNotifierProvider<UpdateCheckNotifier, UpdateCheckOutcome>(
      UpdateCheckNotifier.new,
    );

class UpdateCheckNotifier extends AsyncNotifier<UpdateCheckOutcome> {
  @override
  Future<UpdateCheckOutcome> build() => _check();

  /// 다시 확인하고 그 결과를 돌려준다.
  ///
  /// 상태로만 흘리지 않고 값을 반환하는 것은, 부르는 쪽이 **그 자리에서** 결과
  /// 다이얼로그를 띄우기 때문이다(사용자가 직접 누른 확인은 조용하지 않다).
  Future<UpdateCheckOutcome> recheck() async {
    // 이전 결과를 안고 로딩으로 넘어간다 — 상태표시줄의 표시가 확인 도중 사라졌다
    // 다시 나타나며 깜빡이지 않게 한다.
    state = const AsyncLoading<UpdateCheckOutcome>().copyWithPrevious(state);
    final outcome = await _check();
    state = AsyncData(outcome);
    return outcome;
  }

  Future<UpdateCheckOutcome> _check() => CheckForUpdate(
    ref.read(releaseRepositoryProvider),
  )(currentVersion: appVersion, storeManaged: storeManagedBuild);
}
