import 'package:filetagger/DataStructures/tag.dart';

class TrackedObject {
  List<TrackedTag> tags;
  TrackedObject() : tags = [];
  TrackedObject.tagged(this.tags);

  String getName() {
    //TODO : 이름 표시 태그가 있는지 확인
    return "";
  }
}
