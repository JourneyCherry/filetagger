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

class TagData {
  int pid;
  int tid;
  dynamic value;

  TagData({
    required this.pid,
    required this.tid,
    this.value,
  });
}

class PathData {
  String path;
  int pid;
  List<TagData> tags;

  PathData({
    required this.path,
    required this.pid,
    this.tags = const [],
  });
}
