import '../entities/app_release.dart';

/// 배포처의 최신 릴리즈를 조회하는 저장소. 구현(HTTP)은 data 계층에 격리한다.
abstract interface class ReleaseRepository {
  /// 최신 **정식** 릴리즈. 아직 하나도 게시되지 않았으면 null이고, 조회·해석에
  /// 실패하면 예외를 던진다 — 판정 유즈케이스가 그것을 결과로 옮긴다.
  Future<AppRelease?> latestRelease();
}
