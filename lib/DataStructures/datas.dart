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

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TagData &&
            runtimeType == other.runtimeType &&
            tid == other.tid &&
            name == other.name &&
            order == other.order;
  }

  @override
  int get hashCode => Object.hash(tid, name, order);

  /// 두 태그의 실제 데이터가 동일한지 확인하는 함수.
  /// tag id는 대상에서 제외한다.
  bool isSameData(TagData? target) {
    if (target == null) return false;
    if (name != target.name) return false;
    if (type != target.type) return false;
    if (order != target.order) return false;
    if (bgColor != target.bgColor) return false;
    if (txtColor != target.txtColor) return false;
    if (defaultValue != target.defaultValue) return false;
    if (duplicable != target.duplicable) return false;
    if (necessary != target.necessary) return false;
    return true;
  }

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

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ValueData &&
            runtimeType == other.runtimeType &&
            tid == other.tid &&
            vid == other.vid &&
            pid == other.pid;
  }

  @override
  int get hashCode => Object.hash(vid, tid, pid);

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
  Set<int> values;

  PathData({
    required this.pid,
    required this.path,
    required this.ppid,
    this.recursive = false,
    this.values = const {},
  }) {
    if (values.isEmpty) values = {}; // 수정 가능해야함.
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathData &&
            runtimeType == other.runtimeType &&
            pid == other.pid &&
            path == other.path;
  }

  @override
  int get hashCode => Object.hash(pid, path);

  PathData.copy(PathData other)
      : pid = other.pid,
        path = other.path,
        ppid = other.ppid,
        recursive = other.recursive,
        values = other.values.toSet();
}
