import 'package:filetagger/DataStructures/types.dart';
import 'package:flutter/material.dart';

class TagData {
  int tid;
  String name;
  ValueType type;
  int order;
  Color bgColor;
  Color txtColor;
  dynamic defaultValue;
  bool duplicable;
  bool necessary;

  TagData({
    required this.tid,
    required this.name,
    required this.type,
    required this.order,
    required this.bgColor,
    required this.txtColor,
    required this.defaultValue,
    required this.duplicable,
    required this.necessary,
  });

  TagData.copy(TagData other)
      : tid = other.tid,
        name = other.name,
        type = other.type,
        order = other.order,
        bgColor = other.bgColor,
        txtColor = other.txtColor,
        defaultValue = other.defaultValue,
        duplicable = other.duplicable,
        necessary = other.necessary;

  TagData.empty()
      : tid = -1,
        name = 'New Tag',
        type = ValueType.label,
        order = -1,
        bgColor = Colors.blue,
        txtColor = Colors.white,
        defaultValue = null,
        duplicable = false,
        necessary = false;

  TagData.partial({
    this.tid = -1,
    this.name = 'New Tag',
    this.type = ValueType.label,
    this.order = -1,
    this.bgColor = Colors.blue,
    this.txtColor = Colors.white,
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

  ValueData.copy(ValueData other)
      : vid = other.vid,
        pid = other.pid,
        tid = other.tid,
        value = other.value;

  ValueData.empty()
      : vid = -1,
        tid = -1,
        pid = -1,
        value = null;

  ValueData.partial({
    this.tid = -1,
    this.vid = -1,
    this.pid = -1,
    this.value,
  });
}

class PathData {
  int pid;
  String path;
  int ppid;
  bool recursive;
  List<int> values;

  PathData({
    required this.pid,
    required this.path,
    required this.ppid,
    this.recursive = false,
    this.values = const [],
  });

  PathData.copy(PathData other)
      : pid = other.pid,
        path = other.path,
        ppid = other.ppid,
        recursive = other.recursive,
        values = other.values.toList();
}

class GlobalData {
  Map<int, PathData> pathData = {};
  Map<int, TagData> tagData = {};
  Map<int, ValueData> valueData = {};
  Set<String> trackingPath = {};

  GlobalData();

  PathData? getPath(int pid) => pathData[pid];
  TagData? getTag(int tid) => tagData[tid];
  ValueData? getValue(int vid) => valueData[vid];
  int? getDataFromPath(String path) {
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
