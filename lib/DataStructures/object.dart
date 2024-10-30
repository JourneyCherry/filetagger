import 'package:filetagger/DataStructures/tag.dart';

abstract class TrackedObject {
  String path;
  List<TrackedTag> tags;
  TrackedObject({
    required this.path,
  }) : tags = [];
  TrackedObject.tagged({
    required this.path,
    required this.tags,
  });

  String getName();
  String getPath() => path;
}
