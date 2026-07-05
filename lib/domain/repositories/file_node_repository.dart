import '../entities/file_node.dart';

/// 인덱싱된 파일/폴더 노드의 저장소. 구현(Drift)은 data 계층에 격리한다.
abstract interface class FileNodeRepository {
  /// 인덱싱된 전체 노드를 경로순으로 스트림한다(목록 UI 구독용).
  Stream<List<FileNode>> watchAll();

  /// 스캔 결과를 증분 반영한다: 경로 기준 upsert 후, 이번 스캔에서 관측되지
  /// 않은(=사라진) 노드를 정리한다. 단, 태그가 달린 채 사라졌고 자동 재연결도
  /// 안 된 노드는 삭제하지 않고 "연결 끊김"으로 보존한다.
  Future<void> applyScan(List<FileNode> scanned);

  /// 연결 끊긴(보존된) 노드 [missingNodeId]의 태그를 실제 존재하는 노드
  /// [targetNodeId]로 옮기고, 보존 노드를 정리한다. 사용자가 원본 파일을 직접
  /// 골라 수동 재연결할 때 쓰인다.
  Future<void> reconnectNode({
    required int missingNodeId,
    required int targetNodeId,
  });

  /// 노드 [nodeId]와 그 태그 부여 기록을 제거한다. 보존(연결 끊김) 노드를
  /// 재연결하지 않고 폐기할 때(사용자가 새로 태깅하려는 경우 등) 쓰인다.
  Future<void> removeNode(int nodeId);
}
