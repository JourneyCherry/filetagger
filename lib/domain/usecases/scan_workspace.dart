import '../entities/scan_result.dart';
import '../repositories/file_node_repository.dart';
import '../repositories/workspace_scanner.dart';

/// 워크스페이스를 스캔해 인덱스를 증분 갱신하고, 병합 후보 등 스캔 결과를
/// 그대로 돌려준다. 스캐너·저장소 구현에 의존하지 않는 순수 오케스트레이션.
class ScanWorkspace {
  const ScanWorkspace(this._scanner, this._repository);

  final WorkspaceScanner _scanner;
  final FileNodeRepository _repository;

  Future<ScanResult> call(String workspaceRoot) async {
    final result = await _scanner.scan(workspaceRoot);
    await _repository.applyScan(result.nodes);
    return result;
  }
}
