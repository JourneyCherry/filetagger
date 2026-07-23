/// 커스텀 이미지 태그의 **캐시 저장소**. 외부 이미지 파일을 `.filetagger/` 안에
/// 등록(내용 해시로 중복 제거, 큰 이미지는 축소)하고, 참조되지 않는 캐시를 청소한다.
///
/// 키 규약·축소 크기 계산 같은 순수 로직은 [thumbnail_cache]에 있고, 여기엔 파일
/// I/O와 dart:ui 디코딩(플랫폼 의존)만 둔다. 이미지 크기는 새 의존성 없이 헤더 파서
/// ([readImageDimensions])로 구하고, 축소·재인코딩만 dart:ui로 한다.
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path/path.dart' as p;

import '../../core/constants.dart';
import '../../core/file_types.dart';
import '../../domain/usecases/thumbnail_cache.dart';
import '../db/database_connection.dart';
import '../scanner/hidden_entry.dart';
import '../scanner/image_dimensions.dart';

/// 캐시 파일이 이보다 긴 변을 가지면 이 크기에 맞춰 축소해 저장한다(용량 절감).
/// 원본은 보관하지 않으므로 프리뷰 화질과 저장 용량의 절충점이다.
const int _maxThumbnailDimension = 1024;

/// GC가 이 시간 안에 수정된 캐시 파일은 지우지 않는다 — 막 등록해 아직 부여가
/// 반영되지 않은 파일이 실수로 청소되지 않도록 하는 유예다.
const Duration _gcGrace = Duration(minutes: 1);

/// 워크스페이스 루트에 대한 캐시 폴더 절대 경로.
String thumbnailCacheDirPath(String workspaceRoot) =>
    p.join(filetaggerDirPath(workspaceRoot), thumbnailCacheDirName);

/// 외부 이미지 [sourcePath]를 [workspaceRoot]의 캐시에 등록하고 **캐시 키**(파일명)를
/// 돌려준다. 이미지가 아니거나 읽지 못하면 null.
///
/// - 중복 제거: 원본 내용 해시를 키로 써 같은 이미지는 한 파일만 둔다.
/// - 축소: 가장 긴 변이 상한을 넘으면 비율을 유지해 줄여 PNG로 저장한다(용량 절감).
///   상한 이하면 원본 바이트를 형식 그대로 보관한다.
Future<String?> registerThumbnailImage(
  String workspaceRoot,
  String sourcePath,
) async {
  final Uint8List bytes;
  try {
    bytes = await File(sourcePath).readAsBytes();
  } on FileSystemException {
    return null;
  }

  final dims = readImageDimensions(bytes);
  final srcExt = _extensionOf(sourcePath);
  final knownExt = imageFileExtensions.contains(srcExt);
  // 헤더 파서가 크기를 못 읽고 확장자도 이미지가 아니면 이미지로 보지 않는다.
  if (dims == null && !knownExt) return null;

  Uint8List outBytes = bytes;
  var ext = knownExt ? srcExt : 'png';

  if (dims != null) {
    final parts = dims.split('x');
    final w = int.tryParse(parts[0]) ?? 0;
    final h = int.tryParse(parts[1]) ?? 0;
    final target = downscaleTargetSize(w, h, _maxThumbnailDimension);
    if (target != null) {
      final scaled = await _downscaleToPng(bytes, target.$1, target.$2);
      if (scaled != null) {
        outBytes = scaled;
        ext = 'png';
      }
    }
  }

  // 키는 항상 원본 내용 해시 기준이라, 축소 여부·형식과 무관하게 같은 원본이면 같은
  // 키로 접혀 중복 저장되지 않는다.
  final key = '${_fnv1a64Hex(bytes)}.$ext';

  final dir = Directory(thumbnailCacheDirPath(workspaceRoot));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  // `.filetagger/` 자체가 숨김이지만, 캐시 폴더도 명시적으로 숨겨 둔다(Windows).
  markPathHidden(dir.path);

  final dest = File(p.join(dir.path, key));
  if (!await dest.exists()) {
    await dest.writeAsBytes(outBytes, flush: true);
  }
  return key;
}

/// [referencedKeys]에 없는 캐시 파일을 지운다(부여가 사라진 이미지 청소). 방금 등록해
/// 아직 부여로 반영되지 않았을 수 있는 최근 파일은 유예([_gcGrace]) 동안 보호한다.
/// 폴더가 없으면 아무 것도 하지 않는다.
Future<void> gcThumbnails(
  String workspaceRoot,
  Set<String> referencedKeys,
) async {
  final dir = Directory(thumbnailCacheDirPath(workspaceRoot));
  if (!await dir.exists()) return;
  final now = DateTime.now();
  try {
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (referencedKeys.contains(name)) continue;
      try {
        final stat = await entity.stat();
        if (now.difference(stat.modified) < _gcGrace) continue;
        await entity.delete();
      } on FileSystemException {
        // 잠금 등으로 못 지우면 다음 청소에 다시 시도한다.
      }
    }
  } on FileSystemException {
    // 폴더 목록을 못 읽으면 조용히 지나간다.
  }
}

/// [srcKeys]의 캐시 파일을 원본 워크스페이스에서 대상 워크스페이스로 복사한다(중첩
/// 병합 흡수용). 키는 내용 해시라 대상에 이미 있으면 건너뛴다(자동 중복 제거).
Future<void> copyThumbnailCache({
  required String fromRoot,
  required String toRoot,
  required Set<String> keys,
}) async {
  if (keys.isEmpty) return;
  final srcDir = thumbnailCacheDirPath(fromRoot);
  final dstDir = Directory(thumbnailCacheDirPath(toRoot));
  await dstDir.create(recursive: true);
  markPathHidden(dstDir.path);
  for (final key in keys) {
    final src = File(p.join(srcDir, key));
    final dst = File(p.join(dstDir.path, key));
    try {
      if (await src.exists() && !await dst.exists()) {
        await src.copy(dst.path);
      }
    } on FileSystemException {
      // 개별 복사 실패는 건너뛴다(그 노드는 기본 썸네일로 폴백).
    }
  }
}

String _extensionOf(String path) {
  final dot = path.lastIndexOf('.');
  if (dot < 0 || dot == path.length - 1) return '';
  return path.substring(dot + 1).toLowerCase();
}

/// [bytes]를 [tw]x[th]로 축소해 PNG 바이트로 인코딩한다. dart:ui 디코더로 목표
/// 크기에 맞춰 디코딩하므로 원본 전체를 메모리에 펼치지 않는다. 실패 시 null.
Future<Uint8List?> _downscaleToPng(Uint8List bytes, int tw, int th) async {
  try {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: tw,
      targetHeight: th,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    codec.dispose();
    return data?.buffer.asUint8List();
  } catch (_) {
    return null;
  }
}

/// 바이트열의 FNV-1a(64비트) 해시를 16진 문자열로. 스캐너의 32비트 해시와 같은
/// 방침(암호 강도 불필요)이되, 내용 주소로 쓰는 만큼 충돌을 더 줄이려 64비트를 쓴다.
String _fnv1a64Hex(List<int> bytes) {
  var hash = 0xcbf29ce484222325; // FNV offset basis (64비트).
  const prime = 0x100000001b3; // FNV prime (64비트).
  for (final b in bytes) {
    hash ^= b;
    hash = hash * prime; // 네이티브 64비트에서 자연히 2^64로 감싼다.
  }
  return hash.toUnsigned(64).toRadixString(16).padLeft(16, '0');
}
