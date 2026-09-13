import 'dart:async';

import '../../domain/entities/folder_manage_mode.dart';
import '../../domain/entities/scan_progress.dart';
import '../../domain/entities/scan_result.dart';
import '../../domain/repositories/workspace_scanner.dart';
import '../../domain/usecases/scan_workspace.dart';

/// 전체 스캔을 **한 프로세스 안에서 한 줄로 세우는** [ScanWorkspace].
///
/// 같은 앱 안에서 스캔 둘이 겹칠 자리가 여럿이다 — 폴더를 열면서 도는 스캔, watcher가
/// 트리거하는 조용한 재스캔, 폴더 관리 방식을 바꾼 뒤의 재스캔. 겹쳐도 결과가 틀리지
/// 않도록 정합 판정 자체를 고쳤지만([FileNodeRepository.applyScan]의 관측 도장 조건),
/// 같은 폴더를 두 번 훑는 것은 그냥 낭비다. 그 낭비만 여기서 막는다.
///
/// **기다리지, 건너뛰지 않는다.** 앞 스캔이 취소를 받아 접히는 중일 수 있고(취소 신호가
/// isolate에 닿기까지 폴더 하나를 나열하는 시간이 걸린다), 그때 새 스캔을 건너뛰면
/// **폴더를 열었는데 훑지 않는** 일이 생긴다 — 건너뛸지는 부르는 쪽이 정할 일이다(화면은
/// 조용한 재스캔만 건너뛴다).
///
/// **프로세스 사이는 막지 않는다.** 한때 `.filetagger/`의 락 파일로 막았는데, 그 락은
/// 플랫폼마다 뜻이 뒤집혀(Windows는 핸들 단위라 **자기 자신을** 막고, POSIX는 프로세스
/// 단위라 자기 자신을 **못** 막으며 같은 파일의 서술자 하나만 닫혀도 락이 전부 풀린다)
/// 정확성의 근거로 쓸 수 없었다. 프로세스 사이 겹침은 SQLite와 위 도장 조건에 맡긴다.
class SerialWorkspaceScan extends ScanWorkspace {
  SerialWorkspaceScan(super.scanner, super.repository);

  /// 지금 도는 스캔이 끝나면 완료되는 future. 없으면 null.
  ///
  /// 스캔의 결과가 아니라 **끝났음만** 나르는 future다 — 실패로 끝난 스캔의 예외가
  /// 기다리던 쪽으로 새면, 자기 스캔이 아닌 일로 무너진다.
  Future<void>? _running;

  @override
  Future<ScanResult> call(
    String workspaceRoot, {
    FolderManageMode rootManageMode = FolderManageMode.managed,
    void Function(ScanProgress progress)? onProgress,
    ScanCancellation? cancel,
  }) async {
    // 깨어난 뒤 다시 확인한다 — 여럿이 기다리고 있었다면 그중 하나가 먼저 자리를
    // 차지한다.
    while (_running != null) {
      await _running;
    }
    final done = Completer<void>();
    _running = done.future;
    try {
      return await super.call(
        workspaceRoot,
        rootManageMode: rootManageMode,
        onProgress: onProgress,
        cancel: cancel,
      );
    } finally {
      _running = null;
      done.complete();
    }
  }
}
