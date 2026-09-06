import 'dart:io' show FileLock;

import '../../domain/entities/folder_manage_mode.dart';
import '../../domain/entities/scan_progress.dart';
import '../../domain/entities/scan_result.dart';
import '../../domain/repositories/workspace_scanner.dart';
import '../../domain/usecases/scan_workspace.dart';
import '../fs/workspace_lock.dart';

/// 전체 스캔을 워크스페이스 락 안에서 돌리는 [ScanWorkspace].
///
/// **락이 남아 있는 자리는 여기 하나뿐이다.** 태그를 고치는 것은 SQLite가 알아서
/// 직렬화하므로 프로세스가 몇이든 겹쳐도 되지만, 전체 스캔은 다르다 — 스캔은
/// "관측되지 않은 노드는 사라진 것"이라는 정합 판정을 하므로, 둘이 겹치면 한쪽이
/// 아직 훑지 못한 자리를 다른 쪽이 지운 것으로 읽는다. 각자는 올바른 트랜잭션이라
/// DB가 막아 주지 못하고, 결과만 조용히 틀린다.
///
/// 잡는 것은 **관측이 아니라 정합까지 끝나야** 뜻이 있으므로 스캐너가 아니라 이
/// 자리에서 감싼다. GUI·콘솔이 같은 규칙으로 잡는다.
class LockedWorkspaceScan extends ScanWorkspace {
  const LockedWorkspaceScan(super.scanner, super.repository);

  @override
  Future<ScanResult> call(
    String workspaceRoot, {
    FolderManageMode rootManageMode = FolderManageMode.managed,
    void Function(ScanProgress progress)? onProgress,
    ScanCancellation? cancel,
  }) async {
    // 기다리지 않는다. 이미 누가 훑고 있다면 그 스캔이 곧 같은 결과를 만들므로,
    // 줄을 서 두 번 훑을 이유가 없다.
    final lock = WorkspaceLock.tryAcquire(
      workspaceRoot,
      mode: FileLock.exclusive,
    );
    if (lock == null) throw WorkspaceScanBusyException(workspaceRoot);
    try {
      return await super.call(
        workspaceRoot,
        rootManageMode: rootManageMode,
        onProgress: onProgress,
        cancel: cancel,
      );
    } finally {
      lock.release();
    }
  }
}
