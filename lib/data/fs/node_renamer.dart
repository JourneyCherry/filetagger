import 'dart:io';

import 'package:path/path.dart' as p;

/// 파일/폴더 이름을 디스크에서 실제로 바꾸는 dart:io 어댑터. '파일 이름' 시스템
/// 태그(수정 가능)의 값 편집이 이 rename으로 반영된다. 인덱스(DB)의 경로 재기록은
/// 저장소(`FileNodeRepository.renameNode`)가 별도로 맡는다.
class NodeRenamer {
  const NodeRenamer();

  /// [oldRelPath]('/' 상대 경로)의 항목을 같은 부모 안에서 [newRelPath]로 옮긴다.
  /// 대상 이름이 이미 있으면 덮어쓰지 않고 [FileSystemException]을 던진다.
  Future<void> rename({
    required String workspaceRoot,
    required String oldRelPath,
    required String newRelPath,
    required bool isDirectory,
  }) async {
    final oldAbs = _absolute(workspaceRoot, oldRelPath);
    final newAbs = _absolute(workspaceRoot, newRelPath);
    if (oldAbs == newAbs) return;
    if (await FileSystemEntity.type(newAbs) != FileSystemEntityType.notFound) {
      throw FileSystemException('같은 이름의 항목이 이미 있습니다.', newAbs);
    }
    if (isDirectory) {
      await Directory(oldAbs).rename(newAbs);
    } else {
      await File(oldAbs).rename(newAbs);
    }
  }

  String _absolute(String workspaceRoot, String relPath) =>
      p.joinAll([workspaceRoot, ...relPath.split('/')]);
}

/// [oldPath]의 형제 자리에 이름만 [newName]으로 바꾼 '/' 상대 경로를 만든다.
/// 최상위 항목이면 이름 자체가 곧 경로다.
String siblingPath(String oldPath, String newName) {
  final slash = oldPath.lastIndexOf('/');
  return slash < 0 ? newName : '${oldPath.substring(0, slash + 1)}$newName';
}

/// 이름 변경으로 [path]가 어떻게 바뀌는지 계산한다(폴더 rename 시 하위 경로 접두
/// 치환 포함). 변경 대상이 아니면(무관한 경로) null. 순수 문자열 로직이라 그대로
/// 유닛테스트한다.
String? rewriteRenamedPath(String path, String oldPath, String newPath) {
  if (path == oldPath) return newPath;
  if (path.startsWith('$oldPath/')) {
    return '$newPath${path.substring(oldPath.length)}';
  }
  return null;
}
