import 'dart:io';

import 'package:filetagger/DataStructures/db_manager.dart';
import 'package:filetagger/DataStructures/directory_reader.dart';
import 'package:filetagger/DataStructures/types.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

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

      final tags = await DBManager().getTagsFromFile(pid);
      for (var tag in tags) {
        expect(Types.verify(tag.type, tag.value), true);
      }
    }

    DBManager().closeDatabase();
    File(filePath).delete();
  });
}

void main() {
  group('Directory Read Test', directoryTest);
  group('Sqflite Test', sqfliteTest);
}
