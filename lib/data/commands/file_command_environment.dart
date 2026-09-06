import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/repositories/command_environment.dart';
import '../thumbnails/thumbnail_store.dart';

/// [CommandEnvironment]의 파일시스템 구현.
///
/// 이미지 등록은 커스텀 썸네일 태그가 쓰는 캐시 저장소를 그대로 재사용한다 —
/// 밖에서 들어온 이미지든 사용자가 고른 이미지든 같은 규약(내용 해시 중복 제거,
/// 상한 초과 시 축소)으로 다뤄야 캐시가 갈라지지 않는다.
class FileCommandEnvironment implements CommandEnvironment {
  const FileCommandEnvironment(
    this.workspaceRoot, {
    this.imageBaseDir,
    this.downscale,
  });

  final String workspaceRoot;

  /// 명령이 적어 온 **상대** 이미지 경로를 푸는 기준 자리.
  ///
  /// 명령이 어디서 왔는지로 갈린다 — 콘솔 인자로 왔으면 그 프로세스의 현재 디렉토리,
  /// 명령 파일에서 왔으면 그 파일이 놓인 폴더다(내보내기가 이미지를 파일 옆에 둔다).
  /// 상대 경로의 기준을 부르는 쪽이 정해 줘야 하는 이유가 이것이다. 주지 않으면
  /// 관리 폴더를 기준으로 삼는다.
  final String? imageBaseDir;

  /// 큰 이미지를 줄일 축소기. 플랫폼 디코더에 기대므로 호출부가 넘긴다 — 없으면
  /// 원본을 그대로 보관한다([registerThumbnailImage] 참고).
  final ImageDownscaler? downscale;

  @override
  Future<bool> targetExists(String relPath) async {
    // 태그는 폴더에도 붙으므로 둘 다 본다.
    final full = p.join(workspaceRoot, relPath);
    return await File(full).exists() || await Directory(full).exists();
  }

  @override
  Future<String?> registerImage(String externalPath) {
    final full = p.isAbsolute(externalPath)
        ? externalPath
        : p.join(imageBaseDir ?? workspaceRoot, externalPath);
    return registerThumbnailImage(workspaceRoot, full, downscale: downscale);
  }
}
