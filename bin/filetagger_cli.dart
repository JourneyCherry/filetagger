/// File Tagger의 콘솔 진입점. GUI 실행 파일과 **같은 패키지**라 domain·data 계층을
/// 그대로 공유한다(로직 복제가 없다).
///
/// 바이너리를 나눈 이유는 GUI 실행 파일에 인자를 태우면 **셸이 종료를 기다리지 않기**
/// 때문이다 — 러너가 GUI 서브시스템이라 파이프도 종료 코드도 서지 않아, 스크립트에서
/// 쓴다는 목적 자체가 무너진다.
///
/// 빌드는 `dart build cli`로 한다. **`dart compile exe`로는 실행되지 않는다** — 네이티브
/// sqlite가 코드 애셋이라, 빌드 훅을 도는 명령만이 그 라이브러리를 번들에 함께 놓는다.
///
/// **앱이 떠 있든 아니든 DB에 그냥 쓴다.** 무결성은 SQLite가 보고, 떠 있는 앱은 바깥
/// 변경을 스스로 알아채 화면을 고쳐 그린다.
///
/// 명령 표면은 [runCli]에 있다 — 여기 두면 테스트가 손댈 수 없기 때문이다.
library;

import 'dart:io';

import 'package:filetagger/cli/cli_runner.dart';

Future<void> main(List<String> args) async {
  // 배경 isolate가 DB를 들고 있으므로, 닫은 뒤 명시적으로 끝낸다.
  exit(await runCli(args));
}
