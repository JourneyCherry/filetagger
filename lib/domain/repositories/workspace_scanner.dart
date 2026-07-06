import '../entities/file_node.dart';
import '../entities/folder_manage_mode.dart';
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
  Future<ScanResult> scan(
    String workspaceRoot, {
    Map<String, FileNode> priorIndex,
    FolderManageMode rootManageMode,
  });
}
