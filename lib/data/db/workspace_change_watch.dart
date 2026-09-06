import 'dart:async';

import 'app_database.dart';

/// 이 DB를 **다른 프로세스가** 고쳤는지 주기로 확인해, 열려 있는 화면이 스스로 다시
/// 흐르게 하는 감시.
///
/// 콘솔 진입점이 태그를 고쳐도 떠 있는 앱은 그것을 알 길이 없다 — 워크스페이스
/// 감시자는 `.filetagger/` 아래를 통째로 거르고(느슨하게 하면 앱 자신의 DB 쓰기가
/// 재스캔 루프를 만든다), drift의 스트림 무효화는 **연결 단위**라 남의 커밋으로는
/// 깨지지 않는다. 그 구멍을 메우는 것이 이 감시다.
///
/// **`PRAGMA data_version`을 쓴다.** 이 값은 *다른 연결이* 커밋했을 때만 오르고 제
/// 연결의 쓰기로는 변하지 않아, "내가 쓴 것"과 "남이 쓴 것"을 가르는 일이 공짜다.
/// 파일 수정 시각이나 해시로 같은 것을 하려 들면 앱이 스스로 태그를 붙여 대는 통에
/// 쉴 새 없이 달라져 쓸모가 없다. 읽는 것은 정수 하나뿐이다.
class WorkspaceChangeWatch {
  WorkspaceChangeWatch({
    required this.readVersion,
    required this.onChanged,
    this.interval = _defaultInterval,
  });

  /// [AppDatabase]에 붙은 감시. 값은 `PRAGMA data_version`으로 읽고, 바뀌면 **모든**
  /// 테이블을 갱신된 것으로 알린다 — 무엇이 바뀌었는지는 알 수 없으므로 통째로 다시 묻는다.
  factory WorkspaceChangeWatch.of(AppDatabase db, {Duration? interval}) =>
      WorkspaceChangeWatch(
        readVersion: () => _readDataVersion(db),
        onChanged: () => db.markTablesUpdated(db.allTables),
        interval: interval ?? _defaultInterval,
      );

  /// 지금 값을 읽어 온다. 못 읽으면 null.
  final Future<int?> Function() readVersion;

  /// 남이 고쳤을 때 부를 것.
  final void Function() onChanged;

  /// 확인 간격. 밖에서 들어오는 변경은 사람이 명령을 치는 속도라 촘촘할 이유가 없다.
  final Duration interval;

  Timer? _timer;

  /// 마지막으로 본 값. 처음 본 값은 **기준일 뿐** 변경이 아니다.
  int? _seen;

  /// 확인이 겹쳐 돌지 않게 하는 빗장. 간격보다 오래 걸리는 일은 아니지만, 화면이
  /// 돌아올 때의 즉시 확인과 주기 확인이 맞물릴 수 있다.
  bool _checking = false;

  bool get isRunning => _timer != null;

  /// 확인을 시작한다(이미 돌고 있으면 아무것도 하지 않는다). 시작하는 김에 한 번
  /// 본다 — 창이 가려져 있던 동안 들어온 변경을 돌아오자마자 반영하기 위함이다.
  void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(interval, (_) => checkNow());
    unawaited(checkNow());
  }

  /// 확인을 멈춘다. 본 값은 남겨 두므로 [start]로 이어서 돌 수 있다.
  void pause() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => pause();

  /// 지금 한 번 확인한다. 남이 고쳤으면 알린다.
  ///
  /// **값을 읽지 못하면 기준을 버리지 않는다** — 폴더를 닫는 중이라 연결이 없을 수
  /// 있는데, 그때 기준을 비우면 다음 확인이 그것을 첫 값으로 보아 실제 변경을 놓친다.
  Future<void> checkNow() async {
    if (_checking) return;
    _checking = true;
    try {
      final version = await readVersion();
      if (version == null) return;
      final seen = _seen;
      _seen = version;
      if (seen == null || seen == version) return;
      onChanged();
    } finally {
      _checking = false;
    }
  }
}

Future<int?> _readDataVersion(AppDatabase db) async {
  try {
    final row = await db.customSelect(_pragma).getSingleOrNull();
    final value = row?.data.values.firstOrNull;
    return value is int ? value : null;
  } catch (_) {
    // 폴더를 닫는 중이라 연결이 이미 없을 수 있다. 다음 차례에 다시 본다.
    return null;
  }
}

const Duration _defaultInterval = Duration(seconds: 30);
const String _pragma = 'PRAGMA data_version';
