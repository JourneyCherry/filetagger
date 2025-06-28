import 'dart:async';
import 'dart:io';

import 'package:filetagger/DataStructures/datas.dart';
import 'package:filetagger/DataStructures/db_change_event_tracker.dart';
import 'package:filetagger/DataStructures/db_manager.dart';
import 'package:filetagger/DataStructures/error_code.dart';
import 'package:filetagger/DataStructures/directory_manager.dart';
import 'package:filetagger/DataStructures/types.dart';
import 'package:flutter/material.dart';

class PathTagValueProvider with ChangeNotifier {
  // 참조하는 싱글톤 객체
  final DBManager _dbManager = DBManager();
  final DirectoryManager _directoryManager = DirectoryManager();
  // 참조하는 객체
  final DBChangeEventTracker _dbEventTracker = DBChangeEventTracker();

  /// DirectoryManager의 파일 변경 이벤트 구독
  StreamSubscription<DirectoryChangeEvent>? _subscription;

  // Id 기록을 위한 변수
  int _curPid = 1;
  int _curTid = 1;
  int _curVid = 1;

  // 실제 데이터
  Map<int, PathData> _pathData = {};
  Map<int, TagData> _tagData = {};
  Map<int, ValueData> _valueData = {};

  // 빠른 접근을 위한 캐싱 데이터. 오직 _pathData에 있는 데이터에 대해서만 캐싱함.
  Map<String, int> _path2pid = {};

  /// Previe 또는 동시 수정/삭제를 위한 Selected Item 목록
  //ignore: prefer_final_fields
  Set<int> _selectedPIDSet = {};

  PathTagValueProvider();

  Future<ErrorCode> loadDirectory(String directory) async {
    ErrorCode ec;
    await _directoryManager.closeDirectory();
    await _dbManager.closeDatabase();
    if (_subscription != null) {
      _subscription!.cancel();
      _subscription = null;
    }

    clear(false);

    if (!await _dbManager.initializeDatabase(directory)) {
      return ErrorCode.dbNoConnection;
    }

    // DB로부터 데이터 읽기
    final pathResult = await _dbManager.getPaths();
    if (pathResult.isError) return pathResult.errorOrNull!;
    final tagResult = await _dbManager.getTag();
    if (tagResult.isError) return tagResult.errorOrNull!;
    final valueResult = await _dbManager.getValue();
    if (valueResult.isError) return valueResult.errorOrNull!;
    ec = initialize(
      pathList: pathResult.valueOrNull!,
      tagList: tagResult.valueOrNull!,
      valueList: valueResult.valueOrNull!,
    );
    if (ec != ErrorCode.success) return ec;

    // 디렉토리로부터 데이터 읽기
    _subscription = _directoryManager.onChange.listen(onDirectoryEvent);
    ec = await _directoryManager.openDirectory(directory);
    if (ec != ErrorCode.success) return ec;

    return ErrorCode.success;
  }

  ErrorCode initialize({
    required List<PathData> pathList,
    required List<TagData> tagList,
    required List<ValueData> valueList,
  }) {
    Map<int, PathData> pathData = {};
    Map<int, TagData> tagData = {};
    Map<int, ValueData> valueData = {};
    Map<String, int> path2pid = {};

    // Mapping
    for (PathData path in pathList) {
      if (path.pid <= 0) return ErrorCode.pathIDInvalid;
      if (pathData.containsKey(path.pid)) return ErrorCode.pathDuplicated;
      pathData[path.pid] = path;
      if (path2pid.containsKey(path.path)) return ErrorCode.pathDuplicated;
    }
    for (TagData tag in tagList) {
      if (tag.tid <= 0) return ErrorCode.tagIDInvalid;
      if (tagData.containsKey(tag.tid)) return ErrorCode.tagDuplicated;
      if (!Types.isParsable(tag.type, tag.defaultValue)) {
        return ErrorCode.valueValueInvalid;
      }
      tag.defaultValue = Types.parseString(tag.type, tag.defaultValue);
      tagData[tag.tid] = tag;
    }
    for (ValueData value in valueList) {
      if (value.pid <= 0) return ErrorCode.pathIDInvalid;
      if (value.tid <= 0) return ErrorCode.tagIDInvalid;
      if (value.vid <= 0) return ErrorCode.valueIDInvalid;
      if (valueData.containsKey(value.vid)) return ErrorCode.valueDuplicated;
      valueData[value.vid] = value;
    }

    // Check
    ErrorCode result;
    for (PathData path in pathData.values) {
      result = _verifyPath(path);
      if (result != ErrorCode.success) return result;
    }
    for (TagData tag in tagData.values) {
      result = _verifyTag(tag);
      if (result != ErrorCode.success) return result;
    }
    for (ValueData value in valueData.values) {
      result = verifyValue(value);
      if (result != ErrorCode.success) return result;
    }

    // Set Data
    _pathData = pathData;
    _tagData = tagData;
    _valueData = valueData;
    _path2pid = path2pid;

    // Notify and Return
    notifyListeners();
    return ErrorCode.success;
  }

  void onDirectoryEvent(DirectoryChangeEvent event) {
    switch (event.type) {
      case FileSystemEvent.create:
        //새 파일이 생성된 경우, 목록에 존재하면 무시, 없으면 기본값으로 추가
        if (_path2pid.containsKey(event.path)) break;
        final newPid = getNewPID();
        final newPath = PathData(pid: newPid, path: event.path, ppid: 0);
        _path2pid[event.path] = newPid;
        _pathData[newPid] = newPath;
        break;
      case FileSystemEvent.delete:
        // 파일이 삭제된 경우, 아무런 동작 하지 않음.
        // 태그값이 존재하면 보존해야 하고, 태그값이 없으면 db에 저장될 때 자동 prune
        break;
      case FileSystemEvent.modify:
        //TODO : 파일 메타데이터를 읽는 경우, 추가 필요
        break;
      case FileSystemEvent.move:
        //TODO : 실제 파일을 이동했을 때, 어떤 데이터가 들어오는지 확인 필요
        break;
    }
  }

  ErrorCode setPath(PathData data) {
    // Check
    ErrorCode verifyResult = _verifyPath(data);
    if (verifyResult != ErrorCode.success) return verifyResult;

    // Set Data
    _pathData[data.pid] = data;
    _path2pid[data.path] = data.pid;
    _addNecessaryTag(data);
    _dbEventTracker.setPath(data);

    // Notify and Return
    notifyListeners();
    return ErrorCode.success;
  }

  ErrorCode deletePath(int pid) {
    final path = _pathData[pid];

    // Check
    if (path == null) return ErrorCode.pathNotExist;
    // 경로에 값이 있으면 삭제 불가
    if (path.values.isNotEmpty) return ErrorCode.valueExist;
    if (!_path2pid.containsKey(path.path)) {
      return ErrorCode.pathNotExist;
    }
    //if (_path2pid[_pathData[pid]!.path] != pid) return ErrorCode.pathIDInvalid; //이미 잘못 들어간 데이터는 무시

    // Set Data
    _path2pid.remove(path.path);
    _pathData.remove(pid);
    _dbEventTracker.deletePath(path);

    // Notify and Return
    notifyListeners();
    return ErrorCode.success;
  }

  ErrorCode setTag(TagData tag) {
    // Check
    ErrorCode verifyResult = _verifyTag(tag);
    if (verifyResult != ErrorCode.success) return verifyResult;

    // Set Data
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
    _dbEventTracker.setTag(tag);

    // Notify and Return
    notifyListeners();
    return ErrorCode.success;
  }

  ErrorCode deleteTag(int tid) {
    final tag = _tagData[tid];

    // Check
    if (tag == null) return ErrorCode.tagNotExist;
    for (var value in _valueData.values) {
      // 태그의 값이 존재하면 삭제 불가
      if (value.tid == tid) return ErrorCode.valueExist;
    }

    // Set Data
    _tagData.remove(tag.tid);
    _dbEventTracker.deleteTag(tag);

    // Notify and Return
    notifyListeners();
    return ErrorCode.success;
  }

  ErrorCode setValue(ValueData value) {
    // Check
    ErrorCode verifyResult = verifyValue(value);
    if (verifyResult != ErrorCode.success) return verifyResult;

    // Set Data
    _valueData[value.vid] = value;
    _pathData[value.pid]!
        .values
        .add(value.vid); //Set<int>이기 때문에 중복값이 존재하면 삽입하지 않음
    _dbEventTracker.setValue(value);

    // Notify and Return
    notifyListeners();
    return ErrorCode.success;
  }

  ErrorCode deleteValue(int vid) {
    // Check
    final value = _valueData[vid];
    if (value == null) return ErrorCode.valueNotExist;
    final path = _pathData[value.pid];

    // Set Data
    _valueData.remove(value.vid);
    if (path != null) path.values.remove(value.vid); //path가 존재하지 않아도 삭제는 가능
    _dbEventTracker.deleteValue(value);

    // Notify and Return
    notifyListeners();
    return ErrorCode.success;
  }

  void clear([bool notify = true]) {
    _pathData.clear();
    _tagData.clear();
    _valueData.clear();
    _dbEventTracker.clearEvents();
    if (notify) notifyListeners();
  }

  Future<ErrorCode> applyDB() async {
    final eventList = _dbEventTracker.drainEvents();
    ErrorCode ec;
    for (var (dataType, id, eventType) in eventList) {
      dynamic data;
      switch (dataType) {
        case DataType.path:
          data = _pathData[id];
          break;
        case DataType.tag:
          data = _tagData[id];
          break;
        case DataType.value:
          data = _valueData[id];
          break;
      }
      switch (eventType) {
        case DBChangeEventType.set:
          ec = await _dbManager.setData(data);
          if (ec != ErrorCode.success) return ec;
          break;
        case DBChangeEventType.delete:
          ec = await _dbManager.removeData(dataType, id);
          if (ec != ErrorCode.success) return ec;
          break;
      }
    }

    return ErrorCode.success;
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

  ErrorCode _verifyPath(PathData? path) {
    if (path == null) return ErrorCode.pathNotExist;
    if (path.pid <= 0) return ErrorCode.pathIDInvalid;
    if (path.ppid > 0 && !_pathData.containsKey(path.ppid)) {
      // 부모 경로가 있는 경우 검증
      return ErrorCode.pathNotExist;
    }
    if (_pathData.containsKey(path.pid)) {
      if (!_path2pid.containsKey(path.path)) return ErrorCode.pathNotExist;
      if (_path2pid[path.path] != path.pid) return ErrorCode.pathExist;
    } else {
      if (_path2pid.containsKey(path.path)) return ErrorCode.pathDuplicated;
    }
    return ErrorCode.success;
  }

  ErrorCode _verifyTag(TagData? tag) {
    if (tag == null) return ErrorCode.tagNotExist;
    if (tag.tid <= 0) return ErrorCode.tagIDInvalid;
    if (!ValueType.values.contains(tag.type)) return ErrorCode.tagTypeInvalid;
    if (!Types.verify(tag.type, tag.defaultValue)) {
      return ErrorCode.valueValueInvalid;
    }
    return ErrorCode.success;
  }

  ErrorCode verifyValue(ValueData? value) {
    if (value == null) return ErrorCode.valueNotExist;
    if (!_pathData.containsKey(value.pid)) return ErrorCode.pathNotExist;
    final tag = _tagData[value.tid];
    if (tag == null) return ErrorCode.tagNotExist;
    if (!Types.verify(tag.type, value.value)) {
      if (!Types.isParsable(tag.type, value.value)) {
        return ErrorCode.valueValueInvalid;
      }
      value.value = Types.parseString(tag.type, value.value);
    }

    return ErrorCode.success;
  }

  int getNewPID() => _curPid = _getNewID(_curPid, _pathData);
  int getNewTID() => _curTid = _getNewID(_curTid, _tagData);
  int getNewVID() => _curVid = _getNewID(_curVid, _valueData);
  int _getNewID<T>(int curId, Map<int, T> data) {
    final startVid = curId;

    // 중복 회피 및 음수 회피
    while (data.containsKey(curId) || curId <= 0) {
      curId += 1;
      if (curId == startVid) throw Exception("Full of Value ID");
      if (curId < 0) curId = 1;
    }

    return curId;
  }

  int? getPid(String path) => _path2pid[path];
  PathData? getPathData(int pid) => _pathData[pid];
  TagData? getTagData(int tid) => _tagData[tid];
  ValueData? getValueData(int vid) => _valueData[vid];

  List<int> getPIDList() => _pathData.keys.toList();
  List<PathData> getPathAll() => _pathData.values.toList();
  List<TagData> getTagAll() => _tagData.values.toList();
  List<ValueData> getValueAll() => _valueData.values.toList();

  int getTagCount() => _tagData.length;

  // Select 관련 함수들
  bool isSelectedPID(int pid) => _selectedPIDSet.contains(pid);
  void selectPID(int pid, {bool isMultipleSelect = false}) {
    if (!isMultipleSelect) _selectedPIDSet.clear();
    _selectedPIDSet.add(pid);
  }

  void unselectPID(int pid) => _selectedPIDSet.remove(pid);
  void clearSelectedPID() => _selectedPIDSet.clear();
}
