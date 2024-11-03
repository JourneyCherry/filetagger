import '../DataStructures/tag_manager.dart';

final class TrackedTag {
  String name;
  dynamic data;
  TrackedTag({
    required this.name,
    this.data,
  });

  bool verifyData() => verifyValue(name, data);

  static bool verifyValue(String tagName, dynamic value) {
    var tagInfo = TagManager().getTagInfo(tagName);
    if (tagInfo == null) {
      return false;
    }
    switch (tagInfo.type) {
      case TagType.tagonly:
        return (value == null);
      case TagType.numeric:
        return (value is int);
      case TagType.string:
        return (value is String);
      case TagType.date:
        return (value is DateTime);
      default:
        return false;
    }
  }
}
