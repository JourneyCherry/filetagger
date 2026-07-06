import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

import '../../core/constants.dart';
import '../scanner/hidden_entry.dart';

/// 관리 폴더 루트에 대한 `.filetagger/` 폴더 경로.
String filetaggerDirPath(String workspaceRoot) =>
    p.join(workspaceRoot, filetaggerDirName);

/// 관리 폴더 루트에 대한 태그 DB 파일 경로.
String databaseFilePath(String workspaceRoot) =>
    p.join(filetaggerDirPath(workspaceRoot), databaseFileName);

/// 주어진 관리 폴더 루트의 `.filetagger/` 안에 있는 DB로 지연 연결한다.
///
/// 폴더가 없으면 처음 열 때 생성하므로, 폴더를 여는 시점까지 실제
/// 파일시스템 접근을 미룬다.
LazyDatabase openWorkspaceDatabase(String workspaceRoot) {
  return LazyDatabase(() async {
    final dir = Directory(filetaggerDirPath(workspaceRoot));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    // 만들고 나서(혹은 이미 있던 폴더라도) OS 숨김으로 표시한다. Windows는 숨김
    // 속성을 실제로 설정해야 하고, POSIX는 dot-prefix라 이미 숨김이다. 이미 숨김
    // 이면 내부에서 건너뛴다.
    markPathHidden(dir.path);
    final file = File(databaseFilePath(workspaceRoot));
    return NativeDatabase.createInBackground(file);
  });
}
