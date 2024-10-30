import 'dart:io';

import 'package:filetagger/DataStructures/file.dart';
import 'package:path/path.dart' as p;

class TrackedDirectory extends TrackedFile {
  bool
      isRecursiveTracking; //하위 디렉토리를 추적하는지 여부. true면 이 디렉토리만, false면 하위 디렉토리 모두 개별 trackedobject를 갖는다.
  TrackedDirectory({
    required super.path,
    this.isRecursiveTracking = false,
  });

  @override
  String getName() => p.basename(path);

  Stream<FileSystemEntity> getSubdirectory() => Directory(path).list(
        //디렉토리 내부 파일/디렉토리/링크 async 반환.
        //FileSystemEntity.path : 경로
        //FileSystemEntity is File : 파일
        //FileSystemEntity is Directory : 디렉토리
        //FileSystemEntity is Link : 링크
        recursive: false,
        followLinks: false,
      );
}
