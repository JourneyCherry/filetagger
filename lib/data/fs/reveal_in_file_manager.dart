import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

import 'workspace_path.dart';

/// OS 파일 관리자를 띄워 해당 항목의 위치를 드러내는 어댑터.
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
    final target = workspaceAbsolutePath(workspaceRoot, relPath);

    if (Platform.isWindows) {
      _revealOnWindows(target);
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

// --- Windows 탐색기 호출(FFI) -------------------------------------------------

/// 탐색기에 넘길 인자 문자열. **경로만** 따옴표로 감싸는 것이 요점이다.
///
/// `Process.run`은 공백이 든 인자를 스위치까지 통째로 감싸 버리는데, 탐색기는 자기
/// 명령줄을 직접 해석해 그 형태에서 스위치를 알아보지 못하고 엉뚱한 기본 폴더를 연다.
/// Dart에 원시 명령줄을 넘길 수단이 없어 아래 [_revealOnWindows]가 FFI로 부르고,
/// 이 함수가 그 인자를 만든다(Windows 파일 이름에는 따옴표가 들어갈 수 없어 이스케이프
/// 규칙이 필요 없다). 순수 문자열 로직이라 그대로 유닛테스트한다.
String explorerSelectArgument(String absolutePath) =>
    '$_explorerSelectSwitch"$absolutePath"';

/// 탐색기에게 "부모 폴더를 열고 이 항목을 고른 채로 두라"고 지시하는 스위치.
const String _explorerSelectSwitch = '/select,';

/// 실행할 파일 관리자와, 넘길 동사·표시 방식. `ShellExecuteW`의 계약값이다.
const String _explorerExecutable = 'explorer.exe';
const String _shellOpenVerb = 'open';
const int _swShowNormal = 1;

/// `ShellExecuteW`가 성공했는지 가르는 경계. 문서상 이 값보다 큰 반환값만 성공이고,
/// 이하는 오류 코드다.
const int _shellExecuteSuccessFloor = 32;

// shell32와 함수 심볼은 top-level final의 지연 초기화로, Windows에서 아래 함수가
// 처음 호출될 때만 로드된다(비-Windows에서는 DynamicLibrary.open이 실행되지 않음).
final DynamicLibrary _shell32 = DynamicLibrary.open('shell32.dll');
final int Function(
  int,
  Pointer<Utf16>,
  Pointer<Utf16>,
  Pointer<Utf16>,
  Pointer<Utf16>,
  int,
)
_shellExecuteW = _shell32
    .lookupFunction<
      IntPtr Function(
        IntPtr,
        Pointer<Utf16>,
        Pointer<Utf16>,
        Pointer<Utf16>,
        Pointer<Utf16>,
        Int32,
      ),
      int Function(
        int,
        Pointer<Utf16>,
        Pointer<Utf16>,
        Pointer<Utf16>,
        Pointer<Utf16>,
        int,
      )
    >('ShellExecuteW');

void _revealOnWindows(String absolutePath) {
  final verb = _shellOpenVerb.toNativeUtf16();
  final file = _explorerExecutable.toNativeUtf16();
  final args = explorerSelectArgument(absolutePath).toNativeUtf16();
  try {
    final result = _shellExecuteW(0, verb, file, args, nullptr, _swShowNormal);
    if (result <= _shellExecuteSuccessFloor) {
      throw ProcessException(
        _explorerExecutable,
        [explorerSelectArgument(absolutePath)],
        'ShellExecuteW 오류',
        result,
      );
    }
  } finally {
    malloc.free(verb);
    malloc.free(file);
    malloc.free(args);
  }
}
