import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

/// 마우스·하드웨어 키보드를 기본 입력으로 보는 데스크톱 플랫폼인지.
///
/// 셸 선택(데스크톱/모바일), 목록 밀도, 조작 힌트 표시가 이 판별을 공유한다.
/// 실제 입력 장치 유무가 아니라 **플랫폼**만 본다 — 모바일에 키보드가 붙은 경우의
/// 적응은 별도 레이어가 맡는다.
bool get isDesktopPlatform =>
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.linux;

/// macOS인지. 보조키(Cmd)와 OS 네이티브 메뉴바 사용 여부를 가른다.
bool get isMacOS => defaultTargetPlatform == TargetPlatform.macOS;
