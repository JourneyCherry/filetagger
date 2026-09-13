import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/db/workspace_change_watch.dart';
import 'workspace_provider.dart';

/// 현재 워크스페이스에 종속된 태그 DB.
///
/// 열린 폴더가 없으면 null. 폴더가 바뀌면 이전 DB를 닫고(새 watch로 재생성)
/// 새 폴더의 `.filetagger/` DB로 다시 연다.
///
/// **락을 잡지 않는다.** 다른 프로세스가 같은 DB를 고치는 것은 SQLite가 직렬화하고,
/// 그렇게 들어온 변경은 바깥 변경 감시가 알아채 화면을 고쳐 그린다. 전체 스캔도
/// 마찬가지다 — 겹쳐도 결과가 틀리지 않게 정합 판정을 세워 두었고, 같은 프로세스
/// 안에서만 한 줄로 세운다([SerialWorkspaceScan]).
final databaseProvider = Provider<AppDatabase?>((ref) {
  final root = ref.watch(workspaceRootProvider);
  if (root == null) return null;

  final db = AppDatabase.forWorkspace(root);
  ref.onDispose(db.close);
  return db;
});

/// 바깥에서(콘솔 등) 들어온 변경을 앱이 스스로 알아채게 하는 감시.
///
/// **창이 앞에 있는 동안만 돈다.** 뒤에 있는 창을 위해 확인해 봐야 볼 사람이 없고,
/// 돌아오는 순간 한 번 보면 그동안의 변경이 함께 따라온다([WorkspaceChangeWatch.start]).
///
/// 값을 내지 않는 프로바이더라 **누군가 지켜봐야 살아난다** — 화면이 워크스페이스를
/// 여는 자리에서 함께 지켜본다.
final workspaceChangeWatchProvider = Provider<void>((ref) {
  final db = ref.watch(databaseProvider);
  if (db == null) return;

  final watch = WorkspaceChangeWatch.of(db)..start();
  final lifecycle = AppLifecycleListener(
    onStateChange: (state) {
      if (state == AppLifecycleState.resumed) {
        watch.start();
      } else {
        watch.pause();
      }
    },
  );
  ref.onDispose(() {
    lifecycle.dispose();
    watch.dispose();
  });
});
