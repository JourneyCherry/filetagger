import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/usecases/export_tag_commands.dart';
import '../thumbnails/thumbnail_store.dart';
import 'command_json.dart';

/// 내보낸 결과가 만든 파일 수(안내 문구용). 요청 파일 하나와 동봉 이미지들이다.
class ExportWriteResult {
  const ExportWriteResult({required this.commands, required this.images});

  final int commands;
  final int images;
}

/// [exported]를 **큐 배열 파일 하나**로 쓰고, 참조하는 이미지 캐시 파일을 그 **옆에**
/// 같은 이름으로 복사한다.
///
/// 받는 쪽은 이 파일들을 자기 워크스페이스의 요청함 폴더에 넣기만 하면 된다 — 큐가
/// 이미지의 상대 경로를 요청함 폴더 기준으로 찾으므로 나란히 있으면 그대로 맞는다.
///
/// 이미지를 먼저 복사하고 요청 파일을 **마지막에** 쓴다. 사용자가 저장 위치로 받는
/// 쪽의 요청함 폴더를 곧바로 고를 수 있는데, 그러면 큐 감시자가 깨어 두 쓰기 사이에
/// 패스가 돈다 — 요청 파일이 먼저 놓이면 아직 없는 이미지를 찾아 실패한다.
Future<ExportWriteResult> writeCommandExport({
  required String filePath,
  required ExportedCommands exported,
  required String workspaceRoot,
}) async {
  final dir = Directory(p.dirname(filePath));
  await dir.create(recursive: true);

  var images = 0;
  final cacheDir = thumbnailCacheDirPath(workspaceRoot);
  for (final key in exported.imageKeys) {
    final source = File(p.join(cacheDir, key));
    // 캐시 파일이 사라졌으면 그 항목만 건너뛴다 — 나머지 태그까지 못 내보낼 이유가
    // 없고, 받는 쪽은 그 이미지 명령만 실패로 되돌려 준다.
    if (!await source.exists()) continue;
    await source.copy(p.join(dir.path, key));
    images++;
  }

  await File(filePath).writeAsString(
    encodeCommandObjects([
      for (final c in exported.commands) commandToJson(c),
    ], asArray: true),
  );
  return ExportWriteResult(commands: exported.commands.length, images: images);
}
