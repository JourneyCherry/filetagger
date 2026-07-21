import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "이 노드로 이동" 요청. 링크 캡슐을 더블탭(더블클릭)하면 그 대상 노드로 옮겨
/// 조상 폴더를 펼치고 선택·프리뷰한다. 같은 노드를 연달아 눌러도 다시 반응하도록
/// 단조 증가 토큰과 함께 담는다(값이 같아도 토큰이 달라 listen이 재발동).
class NodeRevealRequest {
  const NodeRevealRequest(this.nodeId, this.token);

  final int nodeId;
  final int token;
}

/// 노드 이동 요청 신호의 단일 출처. 홈 화면이 listen해 실제 이동을 수행하고,
/// 링크 캡슐이 요청을 싣는다. 셸과 캡슐을 직접 잇지 않고 신호로 떼어 둔다.
class NodeRevealNotifier extends Notifier<NodeRevealRequest?> {
  int _token = 0;

  @override
  NodeRevealRequest? build() => null;

  void request(int nodeId) => state = NodeRevealRequest(nodeId, ++_token);
}

final nodeRevealProvider =
    NotifierProvider<NodeRevealNotifier, NodeRevealRequest?>(
      NodeRevealNotifier.new,
    );
