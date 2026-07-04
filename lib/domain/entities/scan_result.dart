import 'file_node.dart';

/// 한 번의 워크스페이스 스캔 결과.
class ScanResult {
  const ScanResult({
    required this.nodes,
    required this.nestedFiletaggerDirs,
  });

  /// 스캔으로 관측된 파일/폴더 노드들.
  final List<FileNode> nodes;

  /// 스캔 중 발견된, 루트 자신이 아닌 **중첩** `.filetagger/`를 가진 하위
  /// 워크스페이스들의 상대 경로.
  ///
  /// 비어 있지 않으면 각 폴더의 태그 DB를 현재 워크스페이스로 병합할지
  /// 사용자에게 물어야 한다(병합 동작 자체는 아직 미구현).
  final List<String> nestedFiletaggerDirs;
}
