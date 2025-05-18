import 'package:filetagger/DataStructures/datas.dart';
import 'package:filetagger/DataStructures/error_code.dart';
import 'package:flutter/material.dart';

class TagDataProvider with ChangeNotifier {
  // ignore: prefer_final_fields
  Map<int, PathData> _pathData = {};
  // ignore: prefer_final_fields
  Map<int, TagData> _tagData = {};
  // ignore: prefer_final_fields
  Map<int, ValueData> _valueData = {};

  TagDataProvider();

  ErrorCode setPath(PathData data) {
    _pathData[data.pid] = data;
    _addNecessaryTag(data);

    notifyListeners();
    return ErrorCode.success;
  }

  ErrorCode deletePath(int pid) {
    final removedData = _pathData[pid];
    if (removedData == null) return ErrorCode.pathNotExist;
    // 경로에 값이 있으면 삭제 불가
    if (removedData.values.isNotEmpty) return ErrorCode.valueExist;

    _pathData.remove(removedData.pid);

    notifyListeners();
    return ErrorCode.success;
  }

  ErrorCode setTag(TagData tag) {
    _tagData[tag.tid] = tag;
    if (tag.necessary) {
      for (var path in _pathData.values) {
        // 태그 값이 존재하는지 확인. 하나라도 존재하면 생성하지 않음
        bool isExistTag = false;
        for (int vid in path.values) {
          final value = _valueData[vid];
          if (value == null) continue;
          if (value.tid == tag.tid) {
            isExistTag = true;
            break;
          }
        }
        if (!isExistTag) setDefaultValue(path, tag);
      }
    }

    notifyListeners();
    return ErrorCode.success;
  }

  ErrorCode deleteTag(int tid) {
    final removedData = _tagData[tid];
    if (removedData == null) return ErrorCode.tagNotExist;
    // 태그의 값이 존재하면 삭제 불가
    for (var value in _valueData.values) {
      if (value.tid == tid) return ErrorCode.valueExist;
    }

    _tagData.remove(removedData.tid);
    notifyListeners();

    return ErrorCode.success;
  }

  ErrorCode setValue(ValueData value) {
    var path = _pathData[value.pid];
    if (path == null) return ErrorCode.pathNotExist;
    var tag = _tagData[value.tid];
    if (tag == null) return ErrorCode.tagNotExist;

    _valueData[value.vid] = value;
    path.values.add(value.vid); //Set<int>이기 때문에 중복값이 존재하면 삽입하지 않음

    notifyListeners();
    return ErrorCode.success;
  }

  ErrorCode deleteValue(int vid) {
    var value = _valueData[vid];
    if (value == null) return ErrorCode.valueNotExist;
    var path = _pathData[value.pid];

    _valueData.remove(value.vid);
    if (path != null) path.values.remove(value.vid); //path가 존재하지 않아도 삭제는 가능

    notifyListeners();
    return ErrorCode.success;
  }

  void clear() {
    _pathData.clear();
    _tagData.clear();
    _valueData.clear();
    notifyListeners();
  }

  void _addNecessaryTag(PathData path) {
    // 태그 값 수량 계산
    Map<int, int> tagCount = _getTagCount(path.values);

    for (var tag in _tagData.values) {
      if (!tag.necessary) continue;
      if ((tagCount[tag.tid] ?? 0) == 0) {
        setDefaultValue(path, tag);
      }
    }
  }

  Map<int, int> _getTagCount(Set<int> values) {
    Map<int, int> tagCount = {};
    for (var vid in values) {
      final tid = _valueData[vid]?.tid ?? -1;
      if (tid >= 0) tagCount[tid] = (tagCount[tid] ?? 0) + 1;
    }

    return tagCount;
  }

  void setDefaultValue(PathData path, TagData tag) {
    if (!_pathData.containsKey(path.pid)) return;
    final newVid = getNewVID();
    _valueData[newVid] = ValueData(
      vid: newVid,
      pid: path.pid,
      tid: tag.tid,
      value: tag.defaultValue,
    );
    _pathData[path.pid]!.values.add(newVid);
  }

  int getNewPID() => _getNewID(_pathData);
  int getNewTID() => _getNewID(_tagData);
  int getNewVID() => _getNewID(_valueData);
  int _getNewID<T>(Map<int, T> data) {
    if (data.isEmpty) return 1;
    int newVid = data.keys.last + 1;
    final startVid = newVid;

    // 중복 회피 및 음수 회피
    while (data.containsKey(newVid) || newVid < 0) {
      newVid += 1;
      if (newVid == startVid) throw Exception("Full of Value ID");
      if (newVid < 0) newVid = 1;
    }

    return newVid;
  }
}
