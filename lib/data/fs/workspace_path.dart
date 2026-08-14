import 'package:path/path.dart' as p;

/// 워크스페이스 루트 기준 '/' 상대 경로를 그 플랫폼의 절대 경로로 바꾼다.
///
/// 인덱스(DB)는 경로를 플랫폼과 무관하게 '/'로 저장하므로, 디스크·OS에 넘기기 직전에
/// 이 함수 한 곳에서 플랫폼 구분자로 되돌린다.
String workspaceAbsolutePath(String workspaceRoot, String relPath) =>
    p.normalize(p.joinAll([workspaceRoot, ...relPath.split('/')]));
