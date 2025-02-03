import 'dart:io';

import 'package:filetagger/DataStructures/datas.dart';
import 'package:filetagger/DataStructures/db_manager.dart';
import 'package:filetagger/DataStructures/directory_reader.dart';
import 'package:filetagger/DataStructures/path_manager.dart';
import 'package:filetagger/DataStructures/types.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void directoryTest() {
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
    final list = await DirectoryReader().readDirectory(tempDir.path);
    DirectoryReader().close();

    //내부 디렉토리를 읽으라는 설정이 되어있지 않으면 서브 디렉토리 내부 파일은 읽지 않음.
    expect(list.length, totalEntity);
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

    List<TagData> tags = [
      TagData.partial(
        tid: 0,
        name: 'label',
        type: ValueType.label,
      ),
      TagData.partial(
        tid: 1,
        name: 'numeric',
        type: ValueType.numeric,
        defaultValue: 1,
      ),
      TagData.partial(
        tid: 2,
        name: 'string',
        type: ValueType.string,
        defaultValue: 'str',
      ),
    ];

    for (int i = 0; i < tags.length; ++i) {
      final tid = DBManager().createTag(tags[i]);
      expect(tid, tags[i].tid);
    }

    final Map<String, List<(int, dynamic)>> data = {
      './a': [(0, null), (1, 3), (2, 'str')],
      './b': [(0, null)],
      './c': [(1, 5), (2, 'string')],
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
      final file = await DBManager().getFileFromId(item.$1);
      expect(file, isNotNull);
      final (:path, :pid, :recursive) = file!;
      expect(path, item.$2);
      expect(pid, 0);
      expect(recursive, false);

      final tags = await DBManager().getTagsFromFile(pid);
      for (var tag in tags) {
        expect(Types.verify(tag.type, tag.value), true);
      }
    }

    DBManager().closeDatabase();
    File(filePath).delete();
  });
}

void pathTest() {
  final curPath = File('.').absolute.path;
  test('PathManager Test', () {
    PathManager().setRootPath(curPath);
    expect(PathManager().getPath(curPath), '.');
    expect(
      PathManager().getParent(curPath),
      PathManager().getPath(File('.').parent.path),
    );
  });
}

void main() {
  group('Data Test', () => pathTest());
  group('File Test', () => directoryTest());
  group('DB Test', () => sqfliteTest());
}
