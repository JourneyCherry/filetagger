import 'package:filetagger/domain/entities/app_release.dart';
import 'package:filetagger/domain/entities/update_check_outcome.dart';
import 'package:filetagger/domain/repositories/release_repository.dart';
import 'package:filetagger/domain/usecases/check_for_update.dart';
import 'package:flutter_test/flutter_test.dart';

/// 정해진 릴리즈를 내거나 던지는 저장소 대역. 조회 횟수를 세어 "조회하지 않는다"를
/// 확인할 수 있게 한다.
class _FakeReleases implements ReleaseRepository {
  _FakeReleases(this.release);

  _FakeReleases.failing() : release = null, fails = true;

  final AppRelease? release;
  bool fails = false;
  int calls = 0;

  @override
  Future<AppRelease?> latestRelease() async {
    calls += 1;
    if (fails) throw Exception('조회 실패');
    return release;
  }
}

AppRelease _release(String version) => AppRelease(
  version: version,
  pageUrl: Uri.parse('https://example.test/releases/$version'),
);

Future<UpdateCheckOutcome> _run(
  ReleaseRepository releases, {
  String current = '1.0.0',
  bool storeManaged = false,
}) => CheckForUpdate(releases)(
  currentVersion: current,
  storeManaged: storeManaged,
);

void main() {
  test('배포본이 더 높으면 새 버전으로 알린다', () async {
    final outcome = await _run(_FakeReleases(_release('1.1.0')));
    expect(outcome, isA<UpdateAvailable>());
    expect((outcome as UpdateAvailable).release.version, '1.1.0');
  });

  test('같은 버전이면 최신이다', () async {
    expect(await _run(_FakeReleases(_release('1.0.0'))), isA<UpToDate>());
  });

  test('설치본이 배포본보다 앞서면 내리라고 권하지 않는다', () async {
    final outcome = await _run(_FakeReleases(_release('0.9.0')));
    expect(outcome, isA<UpToDate>());
  });

  test('프리릴리즈를 쓰는 중이면 같은 번호의 정식판이 새 버전이다', () async {
    final outcome = await _run(
      _FakeReleases(_release('1.0.0')),
      current: '1.0.0-beta.1',
    );
    expect(outcome, isA<UpdateAvailable>());
  });

  test('게시된 릴리즈가 하나도 없으면 최신으로 본다', () async {
    expect(await _run(_FakeReleases(null)), isA<UpToDate>());
  });

  test('조회가 실패해도 예외로 번지지 않고 확인 실패가 된다', () async {
    expect(await _run(_FakeReleases.failing()), isA<UpdateCheckFailed>());
  });

  test('해석할 수 없는 버전은 어느 쪽이든 확인 실패다', () async {
    expect(
      await _run(_FakeReleases(_release('최신판'))),
      isA<UpdateCheckFailed>(),
    );
    expect(
      await _run(_FakeReleases(_release('1.0.0')), current: 'nightly'),
      isA<UpdateCheckFailed>(),
    );
  });

  group('조회하지 않는 경우', () {
    test('버전을 모르면 조회하지 않고 건너뛴다', () async {
      final releases = _FakeReleases(_release('9.9.9'));
      final outcome = await _run(releases, current: '');
      expect(
        outcome,
        isA<UpdateCheckSkipped>().having(
          (s) => s.reason,
          'reason',
          UpdateCheckSkipReason.unknownVersion,
        ),
      );
      expect(releases.calls, 0);
    });

    test('스토어가 관리하는 배포본은 배포처를 조회하지 않는다', () async {
      final releases = _FakeReleases(_release('9.9.9'));
      final outcome = await _run(releases, storeManaged: true);
      expect(
        outcome,
        isA<UpdateCheckSkipped>().having(
          (s) => s.reason,
          'reason',
          UpdateCheckSkipReason.managedByStore,
        ),
      );
      expect(releases.calls, 0);
    });

    test('버전을 모른다는 판정이 스토어 판정보다 먼저다', () async {
      final outcome = await _run(
        _FakeReleases(null),
        current: '',
        storeManaged: true,
      );
      expect(
        (outcome as UpdateCheckSkipped).reason,
        UpdateCheckSkipReason.unknownVersion,
      );
    });
  });
}
