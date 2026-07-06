import '../entities/file_node.dart';
import '../entities/folder_manage_mode.dart';

/// 인덱싱된 파일/폴더 노드의 저장소. 구현(Drift)은 data 계층에 격리한다.
abstract interface class FileNodeRepository {
  /// 인덱싱된 전체 노드를 경로순으로 스트림한다(목록 UI 구독용).
  Stream<List<FileNode>> watchAll();

  /// 현재 인덱스를 경로→노드로 한 번 읽어 온다. 스캔 최적화용: 크기·수정시각이
  /// 그대로인 파일은 저장된 부분 해시를 재사용하도록 스캐너에 넘겨준다.
  Future<Map<String, FileNode>> indexByPath();

  /// 스캔 결과를 증분 반영한다: 경로 기준 upsert 후, 이번 스캔에서 관측되지
  /// 않은(=사라진) 노드를 정리한다. 단, 태그가 달린 채 사라졌고 자동 재연결도
  /// 안 된 노드는 삭제하지 않고 "연결 끊김"으로 보존한다.
  ///
  /// [rootManageMode]로 인덱싱 범위를 계산해, **더 이상 관리되지 않는(불투명이 되었거나
  /// 부모가 사라진) 서브트리 안의 노드는 연결 끊김이라도 보존하지 않고 제거**한다
  /// (범위를 벗어나면 되살아나거나 재연결될 수 없으므로).
  Future<void> applyScan(
    List<FileNode> scanned, {
    required FolderManageMode rootManageMode,
  });

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

  /// 노드의 경로를 [oldPath]에서 [newPath]로 재기록한다('파일 이름' 시스템 태그
  /// 편집이 디스크에서 rename된 뒤 인덱스를 맞추는 용도). 폴더면 그 하위 노드들의
  /// 경로 접두도 함께 치환한다. 태그 부여 기록은 노드 id로 걸려 있어 영향받지 않는다.
  Future<void> renameNode({
    required String oldPath,
    required String newPath,
  });

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
}
