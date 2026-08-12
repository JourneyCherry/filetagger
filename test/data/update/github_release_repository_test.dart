import 'dart:convert';

import 'package:filetagger/core/constants.dart';
import 'package:filetagger/data/update/github_release_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _slug = 'owner/repo';

GithubReleaseRepository _repo(MockClientHandler handler) =>
    GithubReleaseRepository(client: MockClient(handler), repositorySlug: _slug);

void main() {
  test('정식 릴리즈 엔드포인트를 API 버전 핀과 함께 친다', () async {
    late http.BaseRequest sent;
    final repo = _repo((request) async {
      sent = request;
      return http.Response(
        jsonEncode({
          'tag_name': 'v1.2.3',
          'html_url': 'https://example.test/r',
        }),
        200,
      );
    });

    await repo.latestRelease();

    // `releases/latest`가 초안·프리릴리즈를 걸러 주는 자리라, 이 경로여야 한다.
    expect(
      sent.url,
      Uri.https('api.github.com', 'repos/$_slug/releases/latest'),
    );
    expect(sent.headers['Accept'], githubApiMediaType);
    expect(sent.headers['X-GitHub-Api-Version'], githubApiVersion);
  });

  test('태그에서 접두사를 떼고 릴리즈 페이지 주소를 함께 낸다', () async {
    final repo = _repo(
      (_) async => http.Response(
        jsonEncode({
          'tag_name': 'v1.2.3',
          'html_url': 'https://example.test/r/v1.2.3',
        }),
        200,
      ),
    );

    final release = await repo.latestRelease();

    expect(release!.version, '1.2.3');
    expect(release.pageUrl, Uri.parse('https://example.test/r/v1.2.3'));
  });

  test('릴리즈가 하나도 없는 저장소는 실패가 아니라 없음이다', () async {
    final repo = _repo((_) async => http.Response('{}', 404));
    expect(await repo.latestRelease(), isNull);
  });

  test('그 밖의 실패 응답은 예외로 낸다', () async {
    final repo = _repo((_) async => http.Response('', 503));
    expect(repo.latestRelease(), throwsA(isA<http.ClientException>()));
  });

  test('태그나 페이지 주소가 없는 응답은 예외로 낸다', () async {
    final repo = _repo(
      (_) async => http.Response(jsonEncode({'name': 'no tag here'}), 200),
    );
    expect(repo.latestRelease(), throwsA(isA<FormatException>()));
  });

  test('본문을 UTF-8로 읽는다(문자 집합을 밝히지 않는 응답도)', () async {
    // 응답이 charset을 밝히지 않으면 http는 본문을 latin-1로 해석한다. 태그 이름에
    // ASCII 밖 문자가 섞이면 그대로 깨지므로 바이트에서 직접 읽어야 한다.
    final repo = _repo(
      (_) async => http.Response.bytes(
        utf8.encode(
          jsonEncode({'tag_name': 'v1.0.0-한글', 'html_url': 'https://e.test/r'}),
        ),
        200,
      ),
    );

    expect((await repo.latestRelease())!.version, '1.0.0-한글');
  });

  test('접두사가 없는 태그는 그대로 버전이다', () {
    expect(versionFromTag('1.2.3'), '1.2.3');
  });
}
