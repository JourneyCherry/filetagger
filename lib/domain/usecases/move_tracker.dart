import '../entities/file_node.dart';

/// 스캔 사이에 경로가 바뀐(=이동/이름변경된) 파일을 내용 시그니처로 짝지어
/// 태그를 잃지 않게 재연결하기 위한 순수 매칭 로직.
///
/// 파일시스템·저장소에 의존하지 않는다. 사라진 노드(옛 경로)와 새로 나타난
/// 노드(새 경로)를 받아, **동일 파일이라고 확신할 수 있는 쌍만** 돌려준다.
class MoveTracker {
  const MoveTracker();

  /// [disappeared](이번 스캔에서 사라진 옛 노드)와 [appeared](새로 나타난 노드)를
  /// 내용 시그니처(크기+수정시각+부분해시)로 매칭한다.
  ///
  /// 오연결을 막기 위해 **양쪽 모두 유일하게 대응되는 쌍만** 채택한다: 옛 노드가
  /// 딱 하나의 새 노드와 일치하고, 그 새 노드도 딱 하나의 옛 노드와 일치할 때만
  /// 이동으로 본다. 폴더는 내용 해시가 없어 매칭 대상이 아니다.
  Map<FileNode, FileNode> match(
    List<FileNode> disappeared,
    List<FileNode> appeared,
  ) {
    final result = <FileNode, FileNode>{};
    for (final old in disappeared) {
      final forward = appeared.where((n) => _sameContent(old, n)).toList();
      if (forward.length != 1) continue;
      final candidate = forward.single;
      final backward =
          disappeared.where((o) => _sameContent(o, candidate)).toList();
      if (backward.length != 1) continue;
      result[old] = candidate;
    }
    return result;
  }

  /// 두 노드가 같은 파일 내용을 가리키는지. 파일에 한해 크기·부분해시가 모두
  /// 있고 같으며, 수정시각이 초 단위로 일치해야 한다.
  ///
  /// 수정시각을 초 단위로 비교하는 이유: 저장된 값은 초 정밀도(Drift 기본
  /// DateTime 저장)인데 새로 stat한 값은 더 정밀해 그대로 비교하면 어긋난다.
  bool _sameContent(FileNode a, FileNode b) {
    if (a.isDirectory || b.isDirectory) return false;
    if (a.size == null || a.size != b.size) return false;
    if (a.contentHashPrefix == null ||
        a.contentHashPrefix != b.contentHashPrefix) {
      return false;
    }
    final am = a.modifiedAt, bm = b.modifiedAt;
    if (am == null || bm == null) return false;
    return _epochSeconds(am) == _epochSeconds(bm);
  }

  int _epochSeconds(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;
}
