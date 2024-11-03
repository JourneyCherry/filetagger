import 'package:filetagger/DataStructures/container_event_handler_mixin.dart';
import 'package:filetagger/DataStructures/tag.dart';
import 'package:filetagger/DataStructures/tag_manager.dart';
import 'package:path/path.dart' as p;

enum ObjectType {
  file,
  directory,
}

class TrackedObject with ContainerEventHandlerMixin<TrackedTag, void> {
  final String _path;
  ObjectType type;
  bool isRecursive; //디렉토리 타입인 경우, 내부 파일들도 추적하는지 여부

  List<TrackedTag> tags = [];
  TrackedObject({
    required String path,
    this.type = ObjectType.file,
    this.isRecursive = false,
  })  : _path = p.relative(path),
        tags = [];

  TrackedObject.makeFile({
    required String path,
    List<TrackedTag>? tags,
  })  : _path = path,
        type = ObjectType.file,
        tags = tags ?? [],
        isRecursive = false;

  TrackedObject.makeDir({
    required String path,
    List<TrackedTag>? tags,
    this.isRecursive = false,
  })  : _path = path,
        type = ObjectType.directory,
        tags = tags ?? [];

  void addTag(TrackedTag tag) {
    var tagInfo = TagManager().getTagInfo(tag.name);
    if (tagInfo == null) {
      //태그 정보가 없는 경우
      return;
    }
    if (!tagInfo.isDuplicable) {
      //중복 값을 허용하지 않는 태그의 경우
      return;
    }
    tags.add(tag);
    invokeAdd(tag);
  }

  int removeTag({
    required bool Function(TrackedTag) predicate,
    bool removeAll = false,
  }) {
    //조건(Predicate)을 만족하는 태그를 삭제하는 메소드. removeAll이 false면 조건을 충족하는 가장 먼저 만나는 태그 하나만 삭제한다. 삭제된 태그 수를 리턴한다.
    List<TrackedTag> removed = [];
    for (int i = 0; i < tags.length; i++) {
      if (predicate(tags[i])) {
        removed.add(tags[i]);
        if (!removeAll) {
          break;
        }
      }
    }
    for (TrackedTag tag in removed) {
      tags.remove(tag);
    }
    if (removed.isNotEmpty) {
      invokeDel(null);
    }
    return removed.length;
  }

  String get path => _path;
  String get name => p.basename(_path);
}
