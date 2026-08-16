import 'package:filetagger/core/build_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DistributionChannel.parse', () {
    test('주입된 이름을 그대로 옮긴다', () {
      for (final channel in DistributionChannel.values) {
        expect(DistributionChannel.parse(channel.name), channel);
      }
    });

    test('주입이 없으면 포터블로 눕는다', () {
      // 주입이 없는 실행은 직접 빌드한 산출물이고, 그것은 폴더째 들고 다니는
      // 형태다. 설치판은 패키징이 채널을 명시해 갈아탄다.
      expect(DistributionChannel.parse(''), DistributionChannel.portable);
    });

    test('모르는 값도 포터블로 눕는다 — 비슷한 이름을 주워 담지 않는다', () {
      expect(DistributionChannel.parse('store'), DistributionChannel.portable);
      // 대소문자가 다른 이름은 그 채널로 쳐 주지 않는다.
      expect(
        DistributionChannel.parse(
          DistributionChannel.package.name.toUpperCase(),
        ),
        DistributionChannel.portable,
      );
    });
  });

  test('주입이 없으면 릴리즈 산출물이 아니다', () {
    // 채널이 포터블로 눕는다고 해서 포터블 배포본인 것은 아니다 — 눕는 것은 안전한
    // 기본값을 고르는 일이지 배포 형태를 아는 일이 아니다. 배포 형태를 묻는 자리는
    // 눕은 값이 아니라 주입 여부를 봐야 한다(직접 빌드를 정식 배포본으로 오인하지
    // 않기 위함).
    expect(injectedVersion, isEmpty);
    expect(isReleaseArtifact, isFalse);
    expect(distributionChannel, DistributionChannel.portable);
  });

  test('주입이 없으면 나중에 읽은 버전이 채워진다', () {
    // 앱은 시작할 때 함께 실린 pubspec에서 읽어 이걸 부른다. 주입된 값이 있으면
    // 무시하는 쪽은 컴파일 타임 상수라 여기서 확인할 수 없다.
    expect(appVersion, isEmpty);
    resolveAppVersion('9.9.9');
    expect(appVersion, '9.9.9');
  });
}
