import 'dart:io';

import 'package:path/path.dart' as p;

class PathManager {
  static final PathManager _instance = PathManager._internal();

  factory PathManager() {
    return _instance;
  }

  PathManager._internal();

  String _rootPath = '.';

  void setRootPath(String path) {
    _rootPath = p.absolute(path); //root path는 절대 경로로 갖는다.
  }

  String getPath(String path) {
    String result = p.relative(path, from: _rootPath);
    //p.relative()는 '.' 이외엔 './' 접두사를 붙이지 않는다.
    if (!result.startsWith('.')) {
      result = './$result'; //TODO : 플랫폼에 따라 구분자가 달라져야 한다.
    }
    return result;
  }

  bool isChild(String path) {
    return p.isWithin(_rootPath, path);
  }

  String getParent(String path) {
    return getPath(File(path).parent.path);
  }
}
