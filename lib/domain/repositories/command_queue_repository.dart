import '../entities/external_tag_command.dart';

/// 외부 앱이 떨궈 둔 명령 큐의 저장소. 구현(파일)은 data 계층에 격리한다.
///
/// 한 번의 "패스"는 [takePending]으로 적용할 항목을 받아 처리한 뒤, 항목마다
/// [remove](성공) 또는 [markFailed](실패)를 부르는 것으로 끝난다. **둘 중 어느
/// 것도 부르지 않으면 그 항목은 다음 패스로 넘어간다** — 대상이 디스크에는 있는데
/// 인덱스에만 없는 순간(스캔이 아직 잡지 못한 경합)을 위한 자리다. 실패로 적으면
/// 이후 건너뛰므로 경합 한 번이 영구 실패로 굳는다.
abstract interface class CommandQueueRepository {
  /// 이번 패스에서 적용할 항목들. 실패 표식이 붙은 항목은 여기 오지 않는다.
  ///
  /// 이 호출이 큐 정리도 함께 맡는다 — 명령으로 읽히지 않는 항목에 형식 오류
  /// 표식을 남기고, 오래되거나 너무 많이 쌓인 실패 항목을 치운다.
  Future<List<QueuedCommand>> takePending();

  /// 적용에 성공한 항목을 큐에서 지운다.
  Future<void> remove(String id);

  /// 실패한 항목을 **제자리에 남긴 채** 사유만 적어 둔다(이동·개명 없음).
  ///
  /// 외부 앱은 자기가 만든 경로를 그대로 다시 읽어 원인을 알 수 있고, 다시
  /// 시도하려면 표식 없이 같은 파일을 덮어쓰면 된다.
  Future<void> markFailed(String id, CommandFailure failure);
}
