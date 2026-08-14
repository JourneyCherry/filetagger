import '../platform/link_opener.dart';
import 'workspace_path.dart';

/// 워크스페이스 안의 파일을 **OS가 그 확장자에 연결해 둔 앱**으로 실행하는 어댑터
/// (이미지면 이미지 뷰어, 문서면 문서 편집기 — 탐색기에서 더블클릭한 것과 같다).
///
/// 실행 방법의 플랫폼 분기는 [LinkOpener](url_launcher)가 흡수한다. 파일 관리자를
/// 여는 쪽과 달리 "항목을 선택한 채로" 같은 요구가 없어 손으로 분기하지 않는다.
///
/// 열지 못했으면 false를 돌려준다(연결된 앱이 없는 경우 포함) — 파일이 열리지 않는
/// 것은 사용자에게 알릴 일이지 진행 중인 동작을 끊을 일이 아니다.
class DefaultAppOpener {
  const DefaultAppOpener({this.launcher = const LinkOpener()});

  final LinkOpener launcher;

  /// 워크스페이스 루트 기준 '/' 상대 경로 [relPath]의 파일을 기본 앱으로 연다.
  Future<bool> open({required String workspaceRoot, required String relPath}) =>
      launcher.open(Uri.file(workspaceAbsolutePath(workspaceRoot, relPath)));
}
