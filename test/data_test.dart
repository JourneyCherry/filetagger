import 'dart:io';

import 'package:filetagger/DataStructures/db_manager.dart';
import 'package:filetagger/DataStructures/directory_reader.dart';
import 'package:filetagger/DataStructures/object.dart';
import 'package:filetagger/DataStructures/tag.dart';
import 'package:filetagger/DataStructures/tag_manager.dart';
import 'package:filetagger/DataStructures/types.dart';
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
  test('tag test', () {
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

  test('object test', () {
    testMap.forEach((key, value) => expect(value.name, key.name));
  });
}

void directoryTest() {
  //TODO : 임시 디렉토리를 만들어 DirectoryReader()가 정상적으로 파일을 읽는지 확인
  late Directory tempDir;
  const int fileCount = 5;
  const int subDirCount = 1;
  const int totalEntity = fileCount + subDirCount;

  setUp(() async {
    //임시 디렉토리 및 파일 생성
    tempDir = await Directory.systemTemp.createTemp('directory_test_');

    for (int i = 0; i < fileCount; ++i) {
      await File(p.join(tempDir.path, 'file$i.txt'))
          .writeAsString('Test Content $i');
    }

    Directory subDir = await tempDir.createTemp('subdir_test_');

    for (int i = 0; i < fileCount; ++i) {
      await File(p.join(subDir.path, 'file$i.txt'))
          .writeAsString('Test Content $i');
    }
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('DirectoryReader Test', () async {
    final stream = DirectoryReader().readDirectory(tempDir.path);
    int count = 0;
    stream.listen((_) => ++count);

    DirectoryReader().clear();

    await DirectoryReader().waitForIdle();

    expect(DirectoryReader().isClosed(), true);
    expect(
        count, totalEntity); //내부 디렉토리를 읽으라는 설정이 되어있지 않으면 서브 디렉토리 내부 파일은 읽지 않음.
  }, timeout: const Timeout(Duration(seconds: 5)));
}

void sqfliteTest() {
  test('Sqflite Test', () async {
    final filePath = './.tagdb';

    if (await File(filePath).exists()) {
      await File(filePath).delete();
    }

    await DBManager().initializeDatabase();
    expect(await File(filePath).exists(), true);

    final labelId = await DBManager().createTag(
      name: 'label',
      type: ValueType.label,
    );
    expect(labelId, isNotNull);
    final numId = await DBManager().createTag(
      name: 'numeric',
      type: ValueType.numeric,
      defaultValue: 0,
    );
    expect(numId, isNotNull);
    final strId = await DBManager().createTag(
      name: 'string',
      type: ValueType.string,
      defaultValue: '',
    );

    final Map<String, List<(int, dynamic)>> data = {
      './a': [(labelId!, null), (numId!, 3), (strId!, 'str')],
      './b': [(labelId, null)],
      './c': [(numId, 5), (strId, 'string')],
    };

    List<(int, String)> fileData = [];
    for (var kvp in data.entries) {
      final pid = await DBManager().addFile(kvp.key);
      expect(pid, isNotNull);
      for (var item in kvp.value) {
        expect(
          await DBManager().addTagValue(
            pid: pid!,
            tid: item.$1,
            value: item.$2,
          ),
          true,
        );
      }
      fileData.add((pid!, kvp.key));
    }

    for (var item in fileData) {
      final (:path, :pid, :recursive) =
          await DBManager().getFileFromId(item.$1);
      expect(path, item.$2);
      expect(pid, 0);
      expect(recursive, false);

      final tags = await DBManager().getTagValueFromId(pid);
      for (var tag in tags) {
        expect(Types.verify(tag.type, tag.value), true);
      }
    }

    DBManager().closeDatabase();
    File(filePath).delete();
  });
}

void main() {
  group('Tag Unit Test', tagTest);
  group('Object Unit Test', objectTest);
  group('Directory Read Test', directoryTest);
  group('Sqflite Test', sqfliteTest);
}
