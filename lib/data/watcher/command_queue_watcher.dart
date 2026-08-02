import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

import '../../core/constants.dart';
import '../../domain/repositories/workspace_watcher.dart';

/// 드롭인 큐 폴더만 감시하는 [WorkspaceWatcher] 구현.
///
/// 워크스페이스 감시자([DirectoryWorkspaceWatcher])는 `.filetagger/` 아래를 전부
/// 걸러 낸다. **그 필터를 느슨하게 하면 앱 자신의 DB 쓰기가 재스캔 루프를 만든다.**
/// 그래서 큐만 보는 감시자를 따로 두고, 이 신호는 재스캔이 아니라 큐 처리로 보낸다.
/// 덕분에 앱이 켜져 있는 동안 들어온 요청도 같은 경로로 처리되어, 별도의 실시간
/// API가 필요 없다.
class CommandQueueWatcher implements WorkspaceWatcher {
  const CommandQueueWatcher();

  /// 외부 앱이 여러 항목을 한꺼번에 떨구는 것이 흔하므로 한 번으로 묶는다.
  static const Duration _debounce = Duration(milliseconds: 400);

  @override
  Stream<void> watch(String workspaceRoot) {
    late final StreamController<void> controller;
    StreamSubscription<WatchEvent>? sub;
    Timer? debounce;

    final queuePath = p.join(
      workspaceRoot,
      filetaggerDirName,
      commandQueueDirName,
    );

    void start() {
      // 없는 폴더는 감시할 수 없다. 첫 패스가 만들기 전에 구독이 시작될 수 있어
      // 여기서도 자리를 만들어 둔다(만들지 못하면 감시만 포기하고 앱은 계속 뜬다).
      try {
        Directory(queuePath).createSync(recursive: true);
      } catch (_) {
        return;
      }
      sub = DirectoryWatcher(queuePath).events.listen((_) {
        debounce?.cancel();
        debounce = Timer(_debounce, () {
          if (!controller.isClosed) controller.add(null);
        });
      });
    }

    controller = StreamController<void>(
      onListen: start,
      onCancel: () async {
        debounce?.cancel();
        await sub?.cancel();
      },
    );
    return controller.stream;
  }
}
