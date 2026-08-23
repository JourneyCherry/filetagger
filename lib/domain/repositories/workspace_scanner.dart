import 'dart:async';

import '../entities/file_node.dart';
import '../entities/folder_manage_mode.dart';
import '../entities/scan_progress.dart';
import '../entities/scan_result.dart';

/// 관리 폴더 루트를 재귀 스캔해 파일/폴더 노드를 수집하는 스캐너.
///
/// 파일시스템 접근(dart:io)에 의존하는 구현은 data 계층에 둔다.
abstract interface class WorkspaceScanner {
  /// [workspaceRoot]를 스캔한다. 루트의 `.filetagger/`는 제외하고, 중첩된
  /// `.filetagger/`는 병합 후보로 수집한다.
  ///
  /// [priorIndex]는 직전 인덱스(경로→노드)다. 크기·수정시각이 그대로인 파일은
  /// 저장된 부분 해시를 재사용해 파일 재읽기를 건너뛰는 최적화에 쓴다. 폴더의
  /// 관리 방식(override, [FileNode.manageMode])도 여기서 읽는다.
  ///
  /// 폴더의 effective 모드는 override(null=상속)와 부모 체인으로 정해진다:
  /// [rootManageMode]에서 시작해, override 없는 하위는 부모가
  /// [FolderManageMode.managedRecursive]면 재귀 관리를 물려받고 그렇지 않으면
  /// 불투명이 된다. 불투명 폴더는 내부(자식 노드·재귀)를 인덱싱하지 않는다.
  ///
  /// [onProgress]를 주면 스캔이 도는 동안 진행 상태를 주기적으로 알린다(폴더가
  /// 크면 스캔이 길어지므로, 화면이 "작업 중"임을 보일 수 있어야 한다).
  ///
  /// [cancel]을 주면 스캔이 도는 도중에 그만두게 할 수 있다. 취소된 스캔은
  /// [ScanCancelledException]으로 끝난다 — **결과를 돌려주지 않는다.** 중간까지 훑은
  /// 목록은 "여기까지가 전부"가 아니라 "여기까지밖에 못 봤다"이므로, 그것으로 정합을
  /// 돌리면 아직 안 훑은 자리가 통째로 사라진 것으로 판정된다.
  ///
  /// 루트 자신을 나열하지 못하면 [WorkspaceUnreadableException]을 던진다. 하위
  /// 폴더를 나열하지 못한 것은 예외가 아니라 [ScanResult.unreadableDirs]로 보고한다.
  Future<ScanResult> scan(
    String workspaceRoot, {
    Map<String, FileNode> priorIndex,
    FolderManageMode rootManageMode,
    void Function(ScanProgress progress)? onProgress,
    ScanCancellation? cancel,
  });
}

/// 진행 중인 스캔에 "그만두라"고 알리는 손잡이.
///
/// 스캐너 구현이 다른 isolate에서 돌 수 있으므로 이 객체 자체가 건너가지는 않는다 —
/// 구현이 [whenCancelled]를 받아 제 방식대로(포트 등) 신호를 옮긴다. 한 번 취소되면
/// 되돌릴 수 없다(다시 스캔하려면 새로 만든다).
class ScanCancellation {
  final Completer<void> _cancelled = Completer<void>();

  bool get isCancelled => _cancelled.isCompleted;

  /// 취소되는 순간 완료되는 future. 이미 취소되었으면 곧바로 완료된 것을 돌려준다.
  Future<void> get whenCancelled => _cancelled.future;

  void cancel() {
    if (!_cancelled.isCompleted) _cancelled.complete();
  }
}

/// 사용자가 폴더를 닫거나 다른 폴더를 여는 등으로 스캔이 도중에 끊겼을 때.
///
/// 실패가 아니라 **요청받은 중단**이므로 부르는 쪽은 이것을 알림거리로 삼지 않는다.
class ScanCancelledException implements Exception {
  const ScanCancelledException();

  @override
  String toString() => 'ScanCancelledException';
}

/// 워크스페이스 루트 자신을 나열하지 못해 스캔이 서지 못했을 때.
///
/// 하위 폴더 하나를 못 읽는 것과 달리 **아무것도 관측하지 못한** 상태라, 결과를
/// 빈 스캔으로 돌려주면 인덱스 전체가 사라진 것으로 판정된다. 그래서 결과가 아니라
/// 예외로 알려, 부르는 쪽이 정합을 아예 돌리지 않게 한다.
class WorkspaceUnreadableException implements Exception {
  const WorkspaceUnreadableException(this.workspaceRoot);

  /// 나열하지 못한 루트의 절대 경로.
  final String workspaceRoot;

  @override
  String toString() => 'WorkspaceUnreadableException: $workspaceRoot';
}
