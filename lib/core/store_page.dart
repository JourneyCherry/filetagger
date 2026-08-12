import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

import 'constants.dart';

/// 이 빌드가 올라가 있는 스토어의 제품 페이지 주소.
///
/// 스토어가 갱신을 맡는 배포본에서, 사용자가 업데이트 확인을 눌렀을 때 보낼 곳이다.
/// **각 스토어가 정한 앱 실행 스킴을 그대로 쓴다** — https 주소는 브라우저를 한 번
/// 거치지만 스킴은 스토어 앱을 곧바로 제품 페이지로 띄운다.
///
/// 아직 스토어에 등록되지 않았거나(식별자가 빈 문자열) 스토어가 없는 플랫폼이면
/// null이다. 호출부는 null을 "열어 줄 곳이 없다"로 다뤄 안내만 낸다.
Uri? storePageUrl() => switch (defaultTargetPlatform) {
  // Microsoft가 권하는 형태는 Store ID를 쓰는 pdp 스킴이다(PFN·AppId는 폐기 예정).
  TargetPlatform.windows when microsoftStoreProductId.isNotEmpty => Uri.parse(
    'ms-windows-store://pdp/?ProductId=$microsoftStoreProductId',
  ),
  // Play가 정한 앱 실행 스킴. 스토어 앱이 없는 기기에서는 열리지 않는다.
  TargetPlatform.android when googlePlayApplicationId.isNotEmpty => Uri.parse(
    'market://details?id=$googlePlayApplicationId',
  ),
  _ => null,
};
