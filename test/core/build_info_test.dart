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
    expect(appVersion, isEmpty);
    expect(isDevelopmentBuild, isTrue);
    expect(distributionChannel, DistributionChannel.package);
  });
}
