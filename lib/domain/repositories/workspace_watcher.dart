/// 관리 폴더의 파일시스템 변화를 실시간 감시하는 감시자.
///
/// 파일시스템 이벤트(추가/수정/삭제)를 묶어(coalesce) "무언가 바뀌었다"는
/// 신호만 방출한다. 무엇이 바뀌었는지는 재스캔이 판정하므로 신호에는 세부
/// 정보를 싣지 않는다. 플랫폼 구현(dart `watcher`)은 data 계층에 격리한다.
abstract interface class WorkspaceWatcher {
  /// [workspaceRoot] 하위 변화를 감시하는 스트림을 연다. `.filetagger/` 내부
  /// 변화(앱 자신의 DB 쓰기 등)는 무시하고, 짧은 정지 구간으로 이벤트를 묶어
  /// 방출한다. 구독을 취소하면 감시를 멈춘다.
  Stream<void> watch(String workspaceRoot);
}
