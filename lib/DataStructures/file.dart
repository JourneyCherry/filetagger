import 'package:filetagger/DataStructures/object.dart';
import 'package:path/path.dart' as p;

class TrackedFile extends TrackedObject {
  TrackedFile({
    required super.path,
  });

  @override
  String getName() => p.basename(path);
}
