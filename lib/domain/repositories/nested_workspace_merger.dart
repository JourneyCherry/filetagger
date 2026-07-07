/// 하위 워크스페이스의 태거 DB를 현재 워크스페이스로 흡수하는 연산. 두 Drift DB
/// 사이의 행 이관이라 구현은 data 계층에 격리한다.
abstract interface class NestedWorkspaceMerger {
  /// 하위 폴더([childRelPath], 루트 기준 상대 경로)의 태거 DB를 현재 워크스페이스로
  /// 흡수한다. 태그 정의·부여·파일 노드를 옮기고 경로를 루트 기준으로 재기준화하며,
  /// 태그 이름이 충돌하면 식별 가능한 이름으로 바꿔 별도 태그로 만든다.
  /// [removeSource]면 흡수 후 하위 `.filetagger/`를 제거한다.
  Future<void> absorb({
    required String parentRoot,
    required String childRelPath,
    required bool removeSource,
  });
}
