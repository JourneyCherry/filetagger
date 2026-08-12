import 'package:url_launcher/url_launcher.dart';

/// 주소를 **앱 밖**(기본 브라우저·스토어 앱)으로 넘기는 어댑터.
///
/// 플랫폼별 실행 방법과 스킴 처리는 url_launcher(공식 flutter.dev)가 흡수하므로
/// 손으로 분기하지 않는다.
///
/// 실패를 예외가 아니라 false로 돌려준다 — 링크가 열리지 않는 것은 사용자에게 알릴
/// 일이지, 진행 중인 동작을 끊을 일이 아니다.
class LinkOpener {
  const LinkOpener();

  /// [url]을 외부 앱으로 연다. 열지 못했으면 false.
  Future<bool> open(Uri url) async {
    try {
      // 앱 안의 웹뷰가 아니라 OS가 고른 프로그램에 넘긴다 — 릴리즈 페이지는
      // 브라우저가, 스토어 스킴은 스토어 앱이 받아야 한다.
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
