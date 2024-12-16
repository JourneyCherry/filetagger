import 'package:filetagger/DataStructures/types.dart';

class TagInfoData {
  int tid;
  String name;
  ValueType type;
  dynamic defaultValue;
  bool duplicable;
  bool necessary;

  TagInfoData({
    required this.tid,
    required this.name,
    required this.type,
    this.defaultValue,
    this.duplicable = false,
    this.necessary = false,
  });
}

class ValueData {
  int vid;
  int pid;
  int tid;
  dynamic value;

  ValueData({
    required this.vid,
    required this.pid,
    required this.tid,
    this.value,
  });
}

class PathData {
  int pid;
  String path;
  int ppid;
  bool recursive;
  List<int> tags;

  PathData({
    required this.pid,
    required this.path,
    required this.ppid,
    this.recursive = false,
    this.tags = const [],
  });
}

class GlobalData {
  Map<int, PathData> pathData = {};
  Map<int, TagInfoData> tagData = {};
  Map<int, ValueData> valueData = {};
  Set<String> trackingPath = {};

  GlobalData();

  String? getPathName(int? pid) => pathData[pid]?.path;
  String? getTagName(int? tid) => tagData[tid]?.name;
  String? getTagValue(int? vid) => valueData[vid]?.value;
  int? getPath(String path) {
    for (var pData in pathData.values) {
      if (pData.path == path) return pData.pid;
    }
    return null;
  }

  void clear() {
    pathData.clear();
    tagData.clear();
    tagData.clear();
  }
}
