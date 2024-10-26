import 'package:filetagger/DataStructures/object.dart';

class TrackedFile extends TrackedObject {
  String path;
  TrackedFile(this.path);

  @override
  String getName() {
    String result = super.getName();
    if (result.isEmpty) result = path; //TODO : path에서 확장자를 제외한 파일 이름만 추출.
    return result;
  }
}
