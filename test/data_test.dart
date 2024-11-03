import 'package:filetagger/DataStructures/object.dart';
import 'package:filetagger/DataStructures/tag.dart';
import 'package:filetagger/DataStructures/tag_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void tagTest() {
  String tagName = 'testTag';
  TagManager().makeTag(
    name: tagName,
    type: TagType.tagonly,
  );
  List<TrackedTag> tags = [
    TrackedTag(name: tagName),
  ];
  test('initializer test', () {
    for (var tag in tags) {
      expect(tag.name, tagName);
    }
  });
}

class PathTester {
  final String path;
  final String name;
  final bool isDir;
  PathTester({
    required this.path,
    required this.name,
    this.isDir = false,
  });
}

void objectTest() {
  bool isPosix = p.context.style == p.Style.posix;
  bool isWindows = p.context.style == p.Style.windows;
  bool isWeb = p.context.style == p.Style.url;
  Map<PathTester, TrackedObject> testMap = {
    if (isPosix)
      PathTester(
        // Linux Style File Path
        path: './local/test.txt',
        name: 'test.txt',
        isDir: false,
      ): (key) => TrackedObject.makeFile(path: key.path),
    if (isWindows)
      PathTester(
        // Windows Style File Path
        path: r'./ProgramFiles(x86)/FileTagger/test.txt',
        name: 'test.txt',
        isDir: false,
      ): (key) => TrackedObject.makeFile(path: key.path),
    if (isPosix)
      PathTester(
        // Linux Style Directory Path
        path: './local/',
        name: 'local',
        isDir: true,
      ): (key) => TrackedObject.makeDir(path: key.path),
    if (isWindows)
      PathTester(
        // Window Style Directory Path
        path: r'./Program Files(x86)/FileTagger/',
        name: 'FileTagger',
        isDir: true,
      ): (key) => TrackedObject.makeDir(path: key.path),
    if (isWeb)
      PathTester(
        path: "host.name/test/file.txt",
        name: "file.txt",
        isDir: false,
      ): (key) => TrackedObject.makeFile(path: key.path),
    if (isWeb)
      PathTester(
        path: "host.name/test/",
        name: "test",
        isDir: true,
      ): (key) => TrackedObject.makeDir(path: key.path),
  }.map((key, valueFunc) => MapEntry(key, valueFunc(key)));

  test('initializer test', () {
    testMap.forEach((key, value) => expect(value.name, key.name));
  });
}

void main() {
  group('Tag Unit Test', tagTest);
  group('Object Unit Test', objectTest);
}
