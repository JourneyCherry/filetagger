/// 큐 적용이 DB 밖(파일시스템)에 물어봐야 하는 것들. 구현은 data 계층에 격리한다.
///
/// 적용 유즈케이스는 순수 오케스트레이션이라 파일을 직접 만지지 않는다. 그런데
/// 명령 두 가지는 디스크를 봐야만 판정된다 — 대상이 실제로 있는지(없으면 즉시
/// 실패, 있는데 인덱스에만 없으면 보류)와, 이미지 값이 가리키는 외부 파일이다.
abstract interface class CommandEnvironment {
  /// 워크스페이스 루트 기준 상대 경로 [relPath]가 디스크에 실제로 있는지.
  ///
  /// 외부 앱은 파일을 먼저 쓴 뒤 큐에 넣기로 약속되어 있으므로, 이 답이 false면
  /// 곧 나타나기를 기다리지 않는다.
  Future<bool> targetExists(String relPath);

  /// 워크스페이스 **밖**의 이미지 파일 [externalPath]를 썸네일 캐시에 등록하고
  /// 저장할 캐시 키를 돌려준다. 이미지가 아니거나 읽지 못하면 null.
  Future<String?> registerImage(String externalPath);
}
