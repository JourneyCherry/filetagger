import 'file_node.dart';

/// 스캔이 도는 동안 화면에 알릴 진행 상태.
///
/// 스캔은 화면과 다른 isolate에서 돌기 때문에, 진행 중임을 알리려면 이 값이
/// 주기적으로 건너와야 한다. 보고 자체가 비용이 되지 않도록 스캐너가 최소 간격을
/// 두고 보내므로, 마지막 값과 완료 시점 사이에는 늘 약간의 지연이 있다.
class ScanProgress {
  const ScanProgress({
    required this.entriesSeen,
    required this.filesIndexed,
    required this.currentPath,
    this.newNodes = const [],
  });

  /// 지금까지 폴더를 훑으며 만난 항목(파일·폴더) 수.
  final int entriesSeen;

  /// 지금까지 내용을 읽어 노드로 만든 파일 수. 훑기가 끝난 뒤에 늘어난다.
  final int filesIndexed;

  /// 마지막으로 훑은 폴더의 루트 기준 상대 경로. 루트 자신이면 빈 문자열.
  final String currentPath;

  /// 지난 보고 이후 새로 관측한 노드들. 스캔이 끝나기 전에 목록에 미리 반영해,
  /// 큰 폴더에서도 읽은 만큼 바로 보이게 하는 데 쓴다. 비어 있는 보고도 있다 —
  /// 목록을 다시 계산하는 비용 때문에 노드는 수치보다 성기게 실어 보낸다.
  final List<FileNode> newNodes;
}
