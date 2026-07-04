import '../entities/scan_result.dart';

/// 관리 폴더 루트를 재귀 스캔해 파일/폴더 노드를 수집하는 스캐너.
///
/// 파일시스템 접근(dart:io)에 의존하는 구현은 data 계층에 둔다.
abstract interface class WorkspaceScanner {
  /// [workspaceRoot]를 재귀 스캔한다. 루트의 `.filetagger/`는 제외하고,
  /// 중첩된 `.filetagger/`는 병합 후보로 수집한다.
  Future<ScanResult> scan(String workspaceRoot);
}
