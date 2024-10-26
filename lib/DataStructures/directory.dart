import 'package:filetagger/DataStructures/file.dart';

class TrackedDirectory extends TrackedFile {
  bool isRecursive = false;
  TrackedDirectory(super.path, [this.isRecursive = false]);
}
