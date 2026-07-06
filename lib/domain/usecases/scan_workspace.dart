import '../entities/folder_manage_mode.dart';
import '../entities/scan_result.dart';
import '../repositories/file_node_repository.dart';
import '../repositories/workspace_scanner.dart';

/// 워크스페이스를 스캔해 인덱스를 증분 갱신하고, 병합 후보 등 스캔 결과를
/// 그대로 돌려준다. 스캐너·저장소 구현에 의존하지 않는 순수 오케스트레이션.
class ScanWorkspace {
  const ScanWorkspace(this._scanner, this._repository);

  final WorkspaceScanner _scanner;
  final FileNodeRepository _repository;

  /// [rootManageMode]는 루트 폴더의 관리 방식이다(뷰 설정에 저장된 값). 루트부터
  /// 상속이 시작되므로 스캔마다 넘긴다(기본은 직속 내용만 인덱싱하는 [managed]).
  Future<ScanResult> call(
    String workspaceRoot, {
    FolderManageMode rootManageMode = FolderManageMode.managed,
  }) async {
    // 직전 인덱스를 넘겨, 크기·수정시각이 그대로인 파일은 저장된 해시를 재사용해
    // 재해시(파일 재읽기)를 건너뛰게 하고, 폴더 관리 방식(override)도 이어받게 한다.
    final priorIndex = await _repository.indexByPath();
    final result = await _scanner.scan(
      workspaceRoot,
      priorIndex: priorIndex,
      rootManageMode: rootManageMode,
    );
    await _repository.applyScan(result.nodes, rootManageMode: rootManageMode);
    return result;
  }
}
