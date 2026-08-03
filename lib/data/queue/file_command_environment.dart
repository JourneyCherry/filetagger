import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/constants.dart';
import '../../domain/repositories/command_environment.dart';
import '../thumbnails/thumbnail_store.dart';

/// [CommandEnvironment]의 파일시스템 구현.
///
/// 이미지 등록은 커스텀 썸네일 태그가 쓰는 캐시 저장소를 그대로 재사용한다 —
/// 외부 앱이 넣은 이미지든 사용자가 고른 이미지든 같은 규약(내용 해시 중복 제거,
/// 상한 초과 시 축소)으로 다뤄야 캐시가 갈라지지 않는다.
class FileCommandEnvironment implements CommandEnvironment {
  const FileCommandEnvironment(this.workspaceRoot);

  final String workspaceRoot;

  @override
  Future<bool> targetExists(String relPath) async {
    // 태그는 폴더에도 붙으므로 둘 다 본다.
    final full = p.join(workspaceRoot, relPath);
    return await File(full).exists() || await Directory(full).exists();
  }

  /// 상대 경로가 가리키는 자리(요청 파일이 놓이는 큐 폴더).
  String get _queueDir =>
      p.join(workspaceRoot, filetaggerDirName, commandQueueDirName);

  @override
  Future<String?> registerImage(String externalPath) {
    // 상대 경로는 큐 폴더 기준이다 — 내보내기가 요청 파일 옆에 동봉한 이미지를
    // 가리키는 자리이며, 절대 경로(외부 앱이 제 위치를 아는 경우)는 그대로 쓴다.
    final full = p.isAbsolute(externalPath)
        ? externalPath
        : p.join(_queueDir, externalPath);
    return registerThumbnailImage(workspaceRoot, full);
  }
}
