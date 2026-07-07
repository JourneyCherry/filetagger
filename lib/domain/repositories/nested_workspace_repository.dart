import '../entities/nested_tagger_mode.dart';

/// 중첩 워크스페이스 병합 확정 기록의 저장소. 구현(Drift)은 data 계층에 격리한다.
///
/// 유일한 목적은 이미 처리한 중첩 폴더를 스캔 결과에서 걸러 병합 프롬프트가
/// 반복되지 않게 하는 것이다.
abstract interface class NestedWorkspaceRepository {
  /// 사용자가 이미 처리(확정)한 중첩 폴더의 상대 경로 집합.
  Future<Set<String>> decidedPaths();

  /// 중첩 폴더 [childRelPath]의 확정 유형을 기록한다(경로 기준 upsert).
  Future<void> record(String childRelPath, NestedTaggerMode mode);

  /// 중첩 폴더 [childRelPath]의 확정 기록을 지운다. 해당 위치의 하위 태거가
  /// 사라졌을 때(제거·이동) 호출해, 같은 위치에 다시 생기면 사용자에게 다시 묻도록
  /// 한다.
  Future<void> remove(String childRelPath);
}
