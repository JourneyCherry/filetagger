import 'package:filetagger/DataStructures/object.dart';
import 'package:path/path.dart' as p;

class TrackedFile extends TrackedObject {
  String path;
  TrackedFile(this.path);

  @override
  String getName() {
    String result = super.getName();
    if (result.isEmpty)
      result = p.basename(
          path); //path에서 확장자를 제외한 파일 이름만 추출. //TODO : 해당 함수는 현재 path 패키지가 동작중인 플랫폼에 맞춰 해석한다. 플랫폼 상관없이 경로를 파싱할 수 있는 다른 기능이 필요하다.
    return result;
  }
}
