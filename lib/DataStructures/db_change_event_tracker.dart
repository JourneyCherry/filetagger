import 'package:filetagger/DataStructures/datas.dart';

enum DBChangeEventType {
  set,
  delete,
}

class DBChangeEventKey {
  final DataType dataType;
  final int id;

  DBChangeEventKey({
    required this.dataType,
    required this.id,
  });
}

class DBChangeEventTracker {
  //ignore: prefer_final_fields
  Map<DBChangeEventKey, DBChangeEventType> _eventMap = {};

  DBChangeEventTracker();

  void setPath(PathData path) =>
      _eventMap[DBChangeEventKey(dataType: DataType.path, id: path.pid)] =
          DBChangeEventType.set;
  void setTag(TagData tag) =>
      _eventMap[DBChangeEventKey(dataType: DataType.tag, id: tag.tid)] =
          DBChangeEventType.set;
  void setValue(ValueData value) =>
      _eventMap[DBChangeEventKey(dataType: DataType.value, id: value.vid)] =
          DBChangeEventType.set;
  void deletePath(PathData path) =>
      _eventMap[DBChangeEventKey(dataType: DataType.path, id: path.pid)] =
          DBChangeEventType.delete;
  void deleteTag(TagData tag) =>
      _eventMap[DBChangeEventKey(dataType: DataType.tag, id: tag.tid)] =
          DBChangeEventType.delete;
  void deleteValue(ValueData value) =>
      _eventMap[DBChangeEventKey(dataType: DataType.value, id: value.vid)] =
          DBChangeEventType.delete;

  int get eventCount => _eventMap.length;
  void clearEvents() => _eventMap.clear();
  List<(DataType, int, DBChangeEventType)> drainEvents() {
    // 이벤트 목록 복사. map은 Lazy Iterable을 반환하므로, toList() 시점에 복사됨.
    final result = _eventMap.entries
        .map((entry) => (
              entry.key.dataType,
              entry.key.id,
              entry.value,
            ))
        .toList();

    // 다음 이벤트 수집을 위해 이벤트 맵 초기화
    _eventMap.clear();

    return result;
  }
}
