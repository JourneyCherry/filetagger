/// 디렉토리를 스캔·관리하는 방식. 폴더 노드에만 의미가 있다.
///
/// 폴더의 저장값(`FileNode.manageMode`)은 **명시적 override**이며 null이면 부모의
/// effective 모드를 상속한다(→ [FolderManageMode] 상속 규칙은 도메인의 스코프
/// 계산 참고). 처음 발견되는 폴더는 override 없이(null) 부모를 따른다.
///
/// 이름 기반으로 저장(Drift `textEnum`)해 값 순서가 바뀌어도 영향받지 않는다.
enum FolderManageMode {
  /// 폴더 자체만 하나의 노드로 다루고 내부는 인덱싱하지 않는다(내부 감춤).
  opaque,

  /// 폴더의 직속 내용만 인덱싱한다. 하위 폴더는 (override가 없으면) 불투명이 되어
  /// 더 내려가지 않는다.
  managed,

  /// 폴더의 내용을 인덱싱하고, override가 없는 하위 폴더도 재귀적으로 함께
  /// 관리한다(상속). 하위를 [managed]/[opaque]로 명시하면 그 지점부터 재귀가 멈춘다.
  managedRecursive,
}
