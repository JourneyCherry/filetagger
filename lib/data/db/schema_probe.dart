import 'dart:io';

import 'database_connection.dart';

/// 관리 폴더 [workspaceRoot]의 태거 DB 스키마 버전을 **DB를 열지 않고** 읽는다.
///
/// SQLite 파일 헤더의 user_version 필드(Drift가 스키마 버전으로 쓰는 값)를 파일
/// 앞부분만 읽어 해석한다. DB를 열면 구버전 파일이 자동 마이그레이션(=쓰기)되므로,
/// 흡수 가능 여부(버전 호환)를 판단하는 단계에서는 이 읽기 전용 경로를 쓴다.
///
/// 파일이 없거나 유효한 SQLite 헤더가 아니면 null.
Future<int?> readWorkspaceSchemaVersion(String workspaceRoot) async {
  final file = File(databaseFilePath(workspaceRoot));
  if (!await file.exists()) return null;

  final RandomAccessFile raf;
  try {
    raf = await file.open();
  } on FileSystemException {
    return null;
  }
  try {
    final header = await raf.read(_headerBytes);
    // user_version은 헤더 오프셋 60에 있는 4바이트다. 그만큼도 못 읽으면 무효.
    if (header.length < _userVersionOffset + 4) return null;
    // 매직 바이트로 SQLite 파일인지 확인한다("SQLite format 3\0").
    for (var i = 0; i < _magic.length; i++) {
      if (header[i] != _magic[i]) return null;
    }
    final o = _userVersionOffset;
    return (header[o] << 24) |
        (header[o + 1] << 16) |
        (header[o + 2] << 8) |
        header[o + 3];
  } on FileSystemException {
    return null;
  } finally {
    await raf.close();
  }
}

/// SQLite 파일 헤더의 매직 바이트열("SQLite format 3" + 널 종단).
final List<int> _magic = [...'SQLite format 3'.codeUnits, 0];

/// user_version 4바이트(big-endian)의 헤더 내 오프셋.
const int _userVersionOffset = 60;

/// 헤더 판별·버전 읽기에 필요한 앞부분 바이트 수.
const int _headerBytes = 100;
