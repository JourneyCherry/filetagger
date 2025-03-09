import 'package:filetagger/DataStructures/datas.dart';
import 'package:filetagger/DataStructures/db_manager.dart';
import 'package:flutter/material.dart';

class TagDataProvider with ChangeNotifier {
  bool isLoading = false;
  Map<int, PathData> pathData = {};
  Map<int, TagData> tagData = {};
  Map<int, ValueData> valueData = {};

  TagDataProvider();

  void createPath(String path) async {
    try {
      isLoading = true;

      PathData? newPath = await DBManager().createPath(path);

      if (newPath == null) {
        throw Exception('failed to create path'); //TODO : Localization
      }

      //필수 태그 기본값으로 채워넣기
      tagData.forEach((_, tag) async {
        if (tag.necessary) {
          final newValue = await DBManager().createValue(ValueData.partial(
              tid: tag.tid, pid: newPath.pid, value: tag.defaultValue));
          if (newValue != null) {
            valueData[newValue.vid] = newValue;
          } else {
            throw Exception(
                'failed to create necessary tag(${tag.tid})'); //TODO : Localization
          }
        }
      });
      pathData[newPath.pid] = newPath;

      notifyListeners();
    } catch (_) {
      //TODO : 사용자에게 에러메시지 표시
    } finally {
      isLoading = false;
    }
  }

  void updatePath(PathData path) async {
    try {
      isLoading = true;

      final newPath = await DBManager().updatePath(path);
      if (newPath == null) {
        throw Exception(
            'failed to update path(${path.pid})'); //TODO : Localization
      }
      pathData[newPath.pid] = newPath;

      notifyListeners();
    } catch (_) {
      //TODO : 사용자에게 에러메시지 표시
    } finally {
      isLoading = false;
    }
  }

  void deletePath(int pid) async {
    try {
      isLoading = true;
      PathData? path = pathData[pid];
      if (path == null) return;

      Set<int> deletedPid = {};
      await DBManager().deleteFile(path.pid);
      deletedPid.add(path.pid);

      //디렉토리인 경우, 하위 파일/디렉토리 삭제
      pathData.forEach((_, p) async {
        if (p.ppid == path.pid) {
          await DBManager().deleteFile(p.pid);
          deletedPid.add(p.pid);
        }
      });

      pathData.removeWhere((pid, _) => deletedPid.contains(pid));
      valueData.removeWhere((_, value) => deletedPid.contains(value.pid));
    } catch (_) {
      //TODO : 사용자에게 에러메시지 표시
    } finally {
      isLoading = false;
    }
  }

  Future<TagData?> createTag(TagData tag) async {
    TagData? newTag;
    try {
      isLoading = true;

      newTag = await DBManager().createTag(tag);
      if (newTag == null) {
        throw Exception('failed to create tag'); //TODO : Localization
      }

      tagData[newTag.tid] = newTag;
    } catch (_) {
      //TODO : 사용자에게 에러메시지 표시
    } finally {
      isLoading = false;
    }
    return null;
  }

  Future<TagData?> updateTag(TagData tag) async {
    TagData? newTag;
    try {
      isLoading = true;

      //변경하려는 Tag가 duplicable하지 않은 경우, 중복된 태그값을 갖는 파일이 있는지 확인
      if (!tag.duplicable) {
        for (PathData path in pathData.values) {
          int count = 0;
          for (int vid in path.values) {
            if (valueData.containsKey(vid) && valueData[vid]!.tid == tag.tid) {
              count++;
            }
          }
          if (count > 1) {
            throw Exception(
                'Tag Property violation : it\'s not duplicable in file(${path.path})'); //TODO : Localization
          }
        }
      }

      newTag = await DBManager().updateTag(tag);
      if (newTag == null) {
        throw Exception(
            'failed to update Tag(${tag.tid})'); //TODO : Localization
      }
    } catch (_) {
      //TODO : 사용자에게 에러메시지 표시
    } finally {
      isLoading = false;
    }
    return null;
  }

  void deleteTag(int tid) async {
    try {
      isLoading = true;

      await DBManager().deleteTag(tid);

      //해당 태그의 값들 모두 삭제
      Set<int> deletedVid = {};
      for (ValueData value in valueData.values) {
        if (value.tid == tid) {
          await DBManager().deleteValue(value);
          pathData[value.pid]!.values.remove(value.vid);
          deletedVid.add(value.vid);
        }
      }
      valueData.removeWhere((vid, _) => deletedVid.contains(vid));
    } catch (_) {
      //TODO : 사용자에게 에러메시지 표시
    } finally {
      isLoading = false;
    }
  }

  Future<ValueData?> createValue(ValueData value) async {
    try {
      isLoading = true;
      ValueData? newValue = await DBManager().createValue(value);
      if (newValue == null) {
        throw Exception('failed to create value'); //TODO : Localization
      }
      valueData[newValue.vid] = newValue;
    } catch (_) {
      //TODO : 사용자에게 에러메시지 표시
    } finally {
      isLoading = false;
    }
    return null;
  }

  void updateValue(ValueData value) async {
    try {
      isLoading = true;

      //TODO : 추가하려는 PathData에 non-duplicable한 Tag의 value가 있는지 확인
      ValueData? newValue = await DBManager().updateValue(value);
      if (newValue == null) {
        throw Exception(
            'failed to update Value${value.vid}'); //TODO : Localization
      }

      valueData[newValue.vid] = newValue;
    } catch (_) {
      //TODO : 사용자에게 에러메시지 표시
    } finally {
      isLoading = false;
    }
  }

  Future<bool> deleteValue(int vid) async {
    return true;
  }

  void clear() {
    pathData.clear();
    tagData.clear();
    valueData.clear();
    notifyListeners();
  }
}
