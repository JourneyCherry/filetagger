import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants.dart';
import '../../domain/entities/app_release.dart';
import '../../domain/repositories/release_repository.dart';

/// GitHub 릴리즈로 최신 버전을 조회하는 [ReleaseRepository] 구현.
///
/// `releases/latest` 엔드포인트는 **초안·프리릴리즈를 제외한** 가장 최근 릴리즈를
/// 낸다. 버전에 접미사가 붙은 태그를 프리릴리즈로 표시하는 릴리즈 워크플로와 맞물려,
/// 시험판이 정식 사용자에게 새 버전으로 권해지지 않는다.
///
/// 토큰 없이 부른다 — 공개 저장소의 릴리즈는 인증이 필요 없다. 대신 미인증 호출은
/// 시간당 횟수 제한이 낮으므로, 호출 빈도는 부르는 쪽(앱 시작 시 한 번 + 사용자가
/// 누를 때)이 책임진다.
class GithubReleaseRepository implements ReleaseRepository {
  GithubReleaseRepository({
    http.Client? client,
    String repositorySlug = releaseRepositorySlug,
  }) : _client = client ?? http.Client(),
       _slug = repositorySlug;

  /// 릴리즈가 하나도 없는 저장소가 내는 상태 코드. 실패가 아니라 "견줄 것이 없음"이다.
  static const int _notFoundStatus = 404;
  static const int _okStatus = 200;

  final http.Client _client;
  final String _slug;

  @override
  Future<AppRelease?> latestRelease() async {
    final response = await _client.get(
      Uri.https('api.github.com', 'repos/$_slug/releases/latest'),
      headers: const {
        'Accept': githubApiMediaType,
        'X-GitHub-Api-Version': githubApiVersion,
      },
    );

    if (response.statusCode == _notFoundStatus) return null;
    if (response.statusCode != _okStatus) {
      throw http.ClientException('릴리즈 조회 실패(${response.statusCode})');
    }

    // 인코딩을 명시하지 않는 응답이 latin-1로 해석되지 않도록 본문을 직접 디코딩한다.
    final json = jsonDecode(utf8.decode(response.bodyBytes));
    if (json is! Map<String, dynamic>) {
      throw const FormatException('릴리즈 응답이 객체가 아닙니다.');
    }

    final tag = json['tag_name'];
    final page = json['html_url'];
    if (tag is! String || page is! String) {
      throw const FormatException('릴리즈 응답에 태그나 페이지 주소가 없습니다.');
    }

    return AppRelease(version: versionFromTag(tag), pageUrl: Uri.parse(page));
  }
}

/// 릴리즈 태그에서 버전 문자열을 뽑는다. 접두사가 없으면 태그를 그대로 쓴다.
String versionFromTag(String tag) => tag.startsWith(releaseTagPrefix)
    ? tag.substring(releaseTagPrefix.length)
    : tag;
