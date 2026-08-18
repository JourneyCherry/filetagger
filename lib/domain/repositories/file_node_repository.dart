import '../entities/file_node.dart';
import '../entities/folder_manage_mode.dart';
import '../usecases/keyword_name.dart';

/// 인덱싱된 노드(스캔된 파일/폴더 + 키워드)의 저장소. 구현(Drift)은 data 계층에
/// 격리한다.
///
/// 키워드는 디스크에 실체가 없어 스캔·이동 추적·경로 재기록의 대상이 아니다. 어느
/// 연산이 키워드를 포함하는지는 각 메서드 문서가 밝힌다.
abstract interface class FileNodeRepository {
  /// 인덱싱된 전체 노드를 경로순으로 스트림한다(목록 UI 구독용). 키워드도 함께 낸다.
  Stream<List<FileNode>> watchAll();

  /// 현재 **디스크 노드** 인덱스를 경로→노드로 한 번 읽어 온다(키워드 제외). 스캔
  /// 최적화용: 크기·수정시각이 그대로인 파일은 저장된 부분 해시를 재사용하도록
  /// 스캐너에 넘겨준다. 경로로 노드를 지목하는 소비자(외부 명령 등)도 이걸 쓴다 —
  /// 키워드는 경로로 지목되지 않는다.
  Future<Map<String, FileNode>> indexByPath();

  /// 스캔 결과를 증분 반영한다: 경로 기준 upsert 후, 이번 스캔에서 관측되지
  /// 않은(=사라진) 노드를 정리한다. 단, 태그가 달린 채 사라졌고 자동 재연결도
  /// 안 된 노드는 삭제하지 않고 "연결 끊김"으로 보존한다. **키워드는 스캔 대상이
  /// 아니므로 이 정리에 걸리지 않는다.**
  ///
  /// [rootManageMode]로 인덱싱 범위를 계산해, **더 이상 관리되지 않는(불투명이 되었거나
  /// 부모가 사라진) 서브트리 안의 노드는 연결 끊김이라도 보존하지 않고 제거**한다
  /// (범위를 벗어나면 되살아나거나 재연결될 수 없으므로).
  ///
  /// [priorPaths]는 **스캔이 시작될 때** 인덱스에 있던 경로들이다. 이동 재연결은
  /// "이번 스캔에서 처음 본 경로"를 알아야 하는데, 스캔 도중 [applyPartialScan]으로
  /// 미리 반영한 노드가 있으면 지금 저장된 것만 봐서는 그 판정이 서지 않는다.
  Future<void> applyScan(
    List<FileNode> scanned, {
    required FolderManageMode rootManageMode,
    required Set<String> priorPaths,
  });

  /// 스캔 **도중** 관측된 노드를 목록에 미리 반영한다(경로 기준 upsert만).
  ///
  /// 사라진 노드 정리·이동 재연결은 스캔이 다 끝나야 판단할 수 있으므로 여기서는
  /// 하지 않는다 — 이 메서드는 "읽은 만큼 먼저 보이게" 하는 것이 전부이고, 최종
  /// 정합은 [applyScan]이 맞춘다.
  Future<void> applyPartialScan(List<FileNode> observed);

  /// 연결 끊긴(보존된) 노드 [missingNodeId]의 태그를 실제 존재하는 노드
  /// [targetNodeId]로 옮기고, 보존 노드를 정리한다. 사용자가 원본 파일을 직접
  /// 골라 수동 재연결할 때 쓰인다.
  Future<void> reconnectNode({
    required int missingNodeId,
    required int targetNodeId,
  });

  /// 노드 [nodeId]와 그 태그 부여 기록을 제거한다. 보존(연결 끊김) 노드를
  /// 재연결하지 않고 폐기할 때(사용자가 새로 태깅하려는 경우 등), 그리고 키워드를
  /// 지울 때 쓰인다.
  Future<void> removeNode(int nodeId);

  /// 현재 키워드를 **이름→노드**로 한 번 읽어 온다. 키워드는 경로 계층에 속하지 않아
  /// [indexByPath]와 키 공간이 아예 다르므로 따로 낸다 — 같은 맵에 섞으면 이름이
  /// 같은 파일과 키워드가 서로를 밀어낸다.
  Future<Map<String, FileNode>> keywordIndexByName();

  /// 키워드를 새로 만든다. 이름 규칙을 어기거나 같은 이름의 키워드가 이미 있으면
  /// 만들지 않고 사유를 돌려준다(성공이면 null). 성공하면 만들어진 노드를 함께
  /// 돌려준다 — 만들자마자 그 위에 태그를 매다는 호출부(외부 명령 큐)가 있다.
  ///
  /// 이름 말고 받을 것이 없다 — 키워드는 이름이 전부이고, 부연 정보는 태그로 붙는다.
  Future<({FileNode? node, KeywordNameError? error})> createKeyword(
    String name,
  );

  /// 키워드의 이름을 바꾼다. 규칙 위반·중복이면 바꾸지 않고 사유를 돌려준다.
  /// 디스크에 실체가 없으므로 rename 없이 저장된 이름만 바뀐다.
  Future<KeywordNameError?> renameKeyword({
    required int nodeId,
    required String name,
  });

  /// 디스크 노드의 경로를 [oldPath]에서 [newPath]로 재기록한다('파일 이름' 시스템
  /// 태그 편집이 디스크에서 rename된 뒤 인덱스를 맞추는 용도). 폴더면 그 하위
  /// 노드들의 경로 접두도 함께 치환한다. 태그 부여 기록은 노드 id로 걸려 있어
  /// 영향받지 않는다. 키워드는 디스크 rename과 무관하므로 건드리지 않는다.
  Future<void> renameNode({required String oldPath, required String newPath});

  /// 폴더 노드 [nodeId]의 관리 방식을 [mode]로 바꾼다.
  ///
  /// [FolderManageMode.opaque]로 바꾸면 더 이상 내부를 관리하지 않으므로 그 하위
  /// 인덱스를 즉시 정리한다(FK cascade로 하위의 태그 부여 기록도 함께 제거된다).
  /// [FolderManageMode.managed]로 바꾸는 것은 방식만 갱신하며, 내부 인덱싱은 이후
  /// 스캔이 채운다.
  Future<void> setManageMode({
    required int nodeId,
    required FolderManageMode mode,
  });

  /// 폴더 노드의 관리 방식을 **경로**로 설정한다. 방금 스캔으로 발견돼 아직 화면
  /// 스트림에 반영되지 않았을 수 있는 노드(중첩 병합 결정 적용 등)를 id 조회 없이
  /// 바로 갱신하는 데 쓴다. [setManageMode]와 달리 하위 즉시 정리는 하지 않으며,
  /// 범위 변화는 이어지는 재스캔이 반영한다.
  Future<void> setManageModeByPath({
    required String path,
    required FolderManageMode mode,
  });
}
