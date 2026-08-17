import 'constants.dart';

/// 이 앱의 소스 코드가 놓인 저장소의 웹 페이지 주소.
///
/// 릴리즈를 조회하는 저장소와 같은 곳이므로 슬러그를 [releaseRepositorySlug] 하나에서
/// 가져온다 — 업데이트가 보는 저장소와 사용자가 여는 페이지가 어긋날 수 없다.
/// 스토어 제품 페이지([storePageUrl])와 달리 배포 형태·플랫폼과 무관하게 늘 있다.
Uri sourceRepositoryUrl() => Uri.https(_repositoryHost, releaseRepositorySlug);

/// 저장소 웹 호스트. 릴리즈를 조회하는 API 호스트와는 다른 이름이라 따로 둔다.
const String _repositoryHost = 'github.com';
