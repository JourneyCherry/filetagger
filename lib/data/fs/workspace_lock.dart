/// 관리 폴더를 지금 누가 훑고 있는지 알리는 advisory 락.
///
/// **전체 스캔만 감싼다**([LockedWorkspaceScan]). 태그를 고치는 것은 SQLite가 알아서
/// 직렬화하므로 프로세스가 몇이든 겹쳐도 되지만, 스캔은 "관측되지 않은 노드는 사라진
/// 것"이라는 정합 판정을 해서 둘이 겹치면 결과가 조용히 틀린다. GUI·콘솔이 같은 규칙으로
/// 잡는다. 자세한 근거는 `ARCHITECTURE.md`의 설계 결정에 있다.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/constants.dart';
import '../db/database_connection.dart';
import '../scanner/hidden_entry.dart';

/// 관리 폴더 루트에 대한 락 파일 경로.
String workspaceLockFilePath(String workspaceRoot) =>
    p.join(filetaggerDirPath(workspaceRoot), workspaceLockFileName);

/// 잡아 둔 락 하나. 쥐고 있는 동안 [release]를 부르지 않으면 프로세스가 끝날 때
/// OS가 푼다.
class WorkspaceLock {
  WorkspaceLock._(this._file);

  final RandomAccessFile _file;

  /// [workspaceRoot]의 락을 [mode]로 잡아 본다. **이미 겹칠 수 없는 락이 잡혀 있으면
  /// 기다리지 않고 null**을 돌려준다 — 대기 모드를 쓰지 않는 것이 요점이다. 호출부는
  /// null을 "다른 프로세스가 쓰는 중"으로 읽고 다른 길로 간다.
  ///
  /// 폴더를 만들지 못하는 등 잠금과 무관한 실패도 null로 접힌다. 락은 안전장치이지
  /// 기능이 아니므로, 못 잡았다고 해서 호출부가 멈춰 서지는 않는다.
  static WorkspaceLock? tryAcquire(
    String workspaceRoot, {
    required FileLock mode,
  }) {
    final path = workspaceLockFilePath(workspaceRoot);
    RandomAccessFile? file;
    try {
      final dir = Directory(p.dirname(path));
      if (!dir.existsSync()) dir.createSync(recursive: true);
      markPathHidden(dir.path);
      // 배타 락은 쓰기로 연 파일에만 걸린다. 덧붙이기로 여는 것은 내용을 비우지
      // 않기 위함이며, 이 파일에는 아무것도 쓰지 않는다.
      file = File(path).openSync(mode: FileMode.append);
      file.lockSync(mode);
      return WorkspaceLock._(file);
    } on FileSystemException {
      try {
        file?.closeSync();
      } on FileSystemException {
        // 닫기 실패는 알릴 곳이 없다 — 프로세스가 끝나면 OS가 거둔다.
      }
      return null;
    }
  }

  /// 락을 푼다. 두 번 불러도 안전하다.
  ///
  /// POSIX의 advisory 락은 **같은 프로세스가 그 파일의 서술자를 하나라도 닫으면 그
  /// 파일의 락이 전부 풀린다.** 그래서 락 파일은 여기서만 열고 닫으며, 다른 곳에서
  /// 같은 파일을 건드리지 않는다.
  void release() {
    try {
      _file.unlockSync();
    } on FileSystemException {
      // 이미 풀렸거나 파일이 사라진 경우. 닫기만으로 정리된다.
    }
    try {
      _file.closeSync();
    } on FileSystemException {
      // 이미 닫혔다.
    }
  }
}
