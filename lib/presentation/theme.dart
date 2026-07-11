import 'package:flutter/material.dart';

import '../core/platform.dart';

/// 앱 테마의 단일 출처.
///
/// 데스크톱은 마우스 포인터를 전제로 목록·버튼을 촘촘하게 그리고(높은 정보 밀도),
/// 터치 플랫폼은 탭 타깃을 넉넉히 남긴다. 또한 데스크톱은 눌린 자리를 번지게 하는
/// 잉크 효과(스플래시·하이라이트)를 쓰지 않는다 — 렌더 비용을 시각 장식보다 앞에
/// 둔다. 호버 색은 끄지 않는다(메뉴·버튼이 조작 가능함을 알리는 데 쓴다). 매 포인터
/// 이동마다 다시 칠려 비용이 큰 곳(파일 목록 행)만 자기 자리에서 호버를 끈다.
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: _seedColor);
  final noInk = isDesktopPlatform;
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: isDesktopPlatform
        ? VisualDensity.compact
        : VisualDensity.standard,
    // 데스크톱 목록은 행 높이를 줄여 한 화면에 더 많은 항목을 담는다.
    listTileTheme: isDesktopPlatform
        ? const ListTileThemeData(
            dense: true,
            horizontalTitleGap: 8,
            minVerticalPadding: 2,
          )
        : null,
    dividerTheme: const DividerThemeData(space: 1, thickness: 1),
    // null이면 플랫폼 기본 잉크 효과가 그대로 쓰인다(터치 플랫폼).
    splashFactory: noInk ? NoSplash.splashFactory : null,
    splashColor: noInk ? Colors.transparent : null,
    highlightColor: noInk ? Colors.transparent : null,
  );
}

/// 선택 배경처럼 상태에 따라 바뀌는 색의 전환 시간. 데스크톱은 즉시 바꾼다
/// (애니메이션이 도는 동안 목록 행이 매 프레임 다시 칠해지는 것을 없앤다).
Duration get stateChangeDuration =>
    isDesktopPlatform ? Duration.zero : kThemeChangeDuration;

const Color _seedColor = Colors.indigo;
