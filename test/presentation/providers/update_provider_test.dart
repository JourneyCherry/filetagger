import 'package:filetagger/core/build_info.dart';
import 'package:filetagger/presentation/providers/update_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('주입이 없는 실행은 스토어가 관리하는 배포본으로 잡히지 않는다', () {
    // 테스트는 주입 없이 도는 실행이라 직접 빌드와 같은 상태다. 여기가 참이 되면
    // 업데이트 확인이 배포처를 조회하지 않고 "스토어가 관리한다"로 답해, 갱신을
    // 맡아 줄 스토어가 없는 실행이 릴리즈 페이지로 갈 길을 잃는다.
    //
    // 지금은 채널 기본값(포터블)과 주입 여부 판정이 겹쳐 막고 있다. 둘 중 하나만
    // 무너져도 이 기대가 깨지도록 조건을 따로 두지 않고 결론만 못박는다.
    expect(isReleaseArtifact, isFalse);
    expect(storeManagedBuild, isFalse);
  });
}
