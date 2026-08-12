import 'package:filetagger/core/build_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DistributionChannel.parse', () {
    test('주입된 이름을 그대로 옮긴다', () {
      for (final channel in DistributionChannel.values) {
        expect(DistributionChannel.parse(channel.name), channel);
      }
    });

    test('주입이 없으면 설치판으로 눕는다', () {
      expect(DistributionChannel.parse(''), DistributionChannel.package);
    });

    test('모르는 값도 설치판으로 눕는다 — 포터블로 오인하지 않는다', () {
      expect(DistributionChannel.parse('store'), DistributionChannel.package);
      expect(
        DistributionChannel.parse(
          DistributionChannel.portable.name.toUpperCase(),
        ),
        DistributionChannel.package,
      );
    });
  });

  test('주입 없이 돌린 테스트는 개발 빌드로 잡힌다', () {
    expect(injectedVersion, isEmpty);
    expect(isDevelopmentBuild, isTrue);
    expect(distributionChannel, DistributionChannel.package);
  });

  test('주입이 없으면 나중에 읽은 버전이 채워진다', () {
    // 앱은 시작할 때 함께 실린 pubspec에서 읽어 이걸 부른다. 주입된 값이 있으면
    // 무시하는 쪽은 컴파일 타임 상수라 여기서 확인할 수 없다.
    expect(appVersion, isEmpty);
    resolveAppVersion('9.9.9');
    expect(appVersion, '9.9.9');
  });
}
