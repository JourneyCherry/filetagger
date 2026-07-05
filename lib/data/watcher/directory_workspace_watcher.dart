import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

import '../../core/constants.dart';
import '../../domain/repositories/workspace_watcher.dart';

/// `package:watcher`(publisher `dart.dev`) 기반 [WorkspaceWatcher] 구현.
///
/// 파일 조작은 보통 여러 이벤트를 연달아 발생시키므로, 마지막 이벤트 이후
/// 짧은 정지 구간이 지나면 한 번만 신호를 방출(디바운스)한다. `.filetagger/`
/// 아래 변화는 앱 자신의 DB 쓰기이므로 재스캔을 유발하지 않게 걸러낸다.
class DirectoryWorkspaceWatcher implements WorkspaceWatcher {
  const DirectoryWorkspaceWatcher();

  /// 이벤트 폭주를 하나로 묶기 위한 정지 대기 시간.
  static const Duration _debounce = Duration(milliseconds: 400);

  @override
  Stream<void> watch(String workspaceRoot) {
    late final StreamController<void> controller;
    StreamSubscription<WatchEvent>? sub;
    Timer? debounce;

    void start() {
      sub = DirectoryWatcher(workspaceRoot).events.listen((event) {
        if (_isInsideFiletagger(workspaceRoot, event.path)) return;
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

  /// 변경 경로가 루트의 `.filetagger/` 폴더 안쪽인지.
  bool _isInsideFiletagger(String workspaceRoot, String changedPath) {
    final rel = p.relative(changedPath, from: workspaceRoot);
    final segments = p.split(rel);
    return segments.isNotEmpty && segments.first == filetaggerDirName;
  }
}
