/// 중첩 워크스페이스 하나에 대해 사용자가 다이얼로그에서 고른 처리 방식.
enum NestedMergeAction {
  /// 하위 태거의 태그·부여·노드를 현재 워크스페이스로 가져와 관리한다.
  absorb,

  /// 하위 폴더를 내부 미탐색 단일 노드로 둔다(하위 태거 불간섭).
  independent,

  /// 하위 태거를 무시하고 내부를 상위 규칙으로 인덱싱한다.
  ignore,
}

/// 중첩 폴더 [childRelPath]에 적용할 확정 결정.
class NestedMergeResolution {
  const NestedMergeResolution({
    required this.childRelPath,
    required this.action,
    this.removeSource = false,
  });

  /// 관리 폴더 루트 기준, `.filetagger/`를 소유한 하위 폴더의 상대 경로.
  final String childRelPath;

  final NestedMergeAction action;

  /// [NestedMergeAction.absorb]에서만 의미: 흡수 후 하위 `.filetagger/`를 제거할지.
  /// false면 하위 태거를 남기고 이후 '무시'로 전환한다.
  final bool removeSource;
}
