import '../entities/file_node.dart';

/// 인덱싱된 파일/폴더 노드의 저장소. 구현(Drift)은 data 계층에 격리한다.
abstract interface class FileNodeRepository {
  /// 인덱싱된 전체 노드를 경로순으로 스트림한다(목록 UI 구독용).
  Stream<List<FileNode>> watchAll();

  /// 스캔 결과를 증분 반영한다: 경로 기준 upsert 후, 이번 스캔에서 관측되지
  /// 않은(=사라진) 노드를 제거한다.
  Future<void> applyScan(List<FileNode> scanned);
}
