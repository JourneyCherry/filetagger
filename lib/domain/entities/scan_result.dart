import 'file_node.dart';

/// 한 번의 워크스페이스 스캔 결과.
class ScanResult {
  const ScanResult({
    required this.nodes,
    required this.nestedFiletaggerDirs,
    required this.unreadableDirs,
  });

  /// 스캔으로 관측된 파일/폴더 노드들.
  final List<FileNode> nodes;

  /// 스캔 중 발견된, 루트 자신이 아닌 **중첩** `.filetagger/`를 가진 하위
  /// 워크스페이스들의 상대 경로.
  ///
  /// 비어 있지 않으면 각 폴더의 태그 DB를 현재 워크스페이스로 병합할지
  /// 사용자에게 물어야 한다(병합 동작 자체는 아직 미구현).
  final List<String> nestedFiletaggerDirs;

  /// 부모 나열에는 잡혔지만 **자기 내용을 나열하지 못한** 폴더들의 상대 경로.
  ///
  /// 이 폴더와 그 하위는 이번 스캔이 확인하지 못한 자리다. 관측되지 않았다고 해서
  /// 사라진 것이 아니므로, 정합은 이 서브트리를 삭제 대상에서 빼고 "연결 끊김"으로
  /// 표시만 한다(사용자가 보고 판단한다).
  final List<String> unreadableDirs;
}
