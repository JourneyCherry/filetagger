import 'package:filetagger/data/platform/platform_app_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 이 값이 곧장 버전 비교에 들어간다. 빌드 번호가 붙어 오면 릴리즈 태그와 모양이
  // 달라져 판정이 어긋나므로, 어떤 표기가 오든 태그와 같은 모양이 되어야 한다.
  test('빌드 번호가 붙어 와도 떼어 낸다', () {
    expect(versionWithoutBuildNumber('1.2.3+45'), '1.2.3');
    expect(versionWithoutBuildNumber('1.2.3'), '1.2.3');
  });

  test('프리릴리즈 접미사는 버전의 일부라 남긴다', () {
    expect(versionWithoutBuildNumber('1.2.3-beta.1+2'), '1.2.3-beta.1');
  });

  test('빈 값은 빈 값으로 남아 버전을 채우지 않는다', () {
    expect(versionWithoutBuildNumber(''), isEmpty);
  });
}
