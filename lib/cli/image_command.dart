/// `image` — 바깥 이미지를 관리 폴더의 캐시에 등록하고 **캐시 키**를 낸다.
///
/// 이미지 태그의 저장값은 내용 해시로 지어진 불투명한 캐시 키라, 값 자리에 놓인 문자열
/// 하나만 보고는 "바깥 파일의 경로"인지 "이미 등록된 키"인지 콘솔이 가릴 수 없었다.
/// 그것이 명령 이름으로 갈린다 — 여기 오는 것은 **언제나 경로**이고, 나가는 것은
/// 언제나 키다. 부여는 `list add`가 그 키를 받아 마저 한다.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import '../data/thumbnails/thumbnail_store.dart';
import 'cli_command.dart';
import 'cli_output.dart';

class ImageCommand extends CliCommand {
  ImageCommand(super.strings);

  @override
  String get name => 'image';

  @override
  String get description => strings.imageDescription;

  @override
  String get invocation => '$executableName $name <${strings.tokenImageFile}>';

  @override
  Future<int> run() async {
    if (rest.length != 1) usageException(strings.needImageFile);
    // 상대 경로는 명령을 친 사람이 서 있는 자리를 기준으로 푼다.
    final source = p.absolute(rest.first);

    // 캐시는 파일이라 DB를 열 이유가 없다.
    final root = resolveRoot();
    if (root == null) return exitNoWorkspace;

    // 축소기를 넘기지 않으므로 원본 바이트를 형식 그대로 보관한다 — 줄이는 것은
    // 플랫폼 디코더에 기대는 일이라 콘솔에는 없다.
    final key = await registerThumbnailImage(root, source);
    if (key == null) {
      return fail(
        exitRejected,
        ConsoleFailure.notAnImage,
        strings.notAnImage(source),
        subject: source,
      );
    }
    final relative = p
        .relative(p.join(thumbnailCacheDirPath(root), key), from: root)
        .replaceAll(r'\', '/');

    if (asJson) {
      writeJson({_kSource: source, _kKey: key, _kPath: relative});
    } else {
      // 키를 앞에 둔다 — 다음 명령의 값 자리에 그대로 넣는 것이 키다.
      stdout.writeln('$key\t$relative');
    }
    return exitOk;
  }
}

const String _kSource = 'source';
const String _kKey = 'key';
const String _kPath = 'path';
