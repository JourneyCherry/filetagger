import 'dart:io';

import 'package:path/path.dart' as p;

/// OS 파일 관리자를 띄워 해당 항목의 위치를 드러내는 dart:io 어댑터.
///
/// 항목을 "선택된 채로" 여는 방법이 플랫폼마다 달라 여기 한 곳에서만 분기한다.
/// 파일 관리자를 띄우기만 하고 결과를 기다리지 않는다(사용자가 그쪽에서 계속 조작).
class FileManagerRevealer {
  const FileManagerRevealer();

  /// 워크스페이스 루트 기준 '/' 상대 경로 [relPath]의 항목을 파일 관리자에서 연다.
  /// 실행할 수 없으면 [ProcessException], 지원하지 않는 플랫폼이면 [UnsupportedError].
  Future<void> reveal({
    required String workspaceRoot,
    required String relPath,
  }) async {
    final target = p.normalize(
      p.joinAll([workspaceRoot, ...relPath.split('/')]),
    );

    if (Platform.isWindows) {
      // explorer는 성공해도 0이 아닌 종료 코드를 돌려주므로 결과를 보지 않는다.
      await Process.run('explorer.exe', ['/select,$target']);
      return;
    }
    if (Platform.isMacOS) {
      await _run('open', ['-R', target]);
      return;
    }
    if (Platform.isLinux) {
      // 리눅스 파일 관리자는 "항목 선택" 인자를 표준화하지 않았다. 표준 열기 도구로
      // 부모 폴더를 열어 위치까지만 안내한다.
      await _run('xdg-open', [p.dirname(target)]);
      return;
    }
    throw UnsupportedError('이 플랫폼에서는 파일 관리자를 열 수 없습니다.');
  }

  Future<void> _run(String executable, List<String> arguments) async {
    final result = await Process.run(executable, arguments);
    if (result.exitCode != 0) {
      throw ProcessException(
        executable,
        arguments,
        result.stderr.toString().trim(),
        result.exitCode,
      );
    }
  }
}
