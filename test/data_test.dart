import 'dart:io';

import 'package:filetagger/DataStructures/datas.dart';
import 'package:filetagger/DataStructures/db_manager.dart';
import 'package:filetagger/DataStructures/directory_reader.dart';
import 'package:filetagger/DataStructures/path_manager.dart';
import 'package:filetagger/DataStructures/types.dart';
import 'package:flutter/material.dart';
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
  final List<PathData> paths = [
    PathData(pid: 1, path: './a', ppid: 0),
    PathData(pid: 2, path: './b', ppid: 0),
    PathData(pid: 3, path: './c', ppid: 0),
  ];
  List<TagData> tags = [
    TagData.partial(tid: 1, name: 'label', type: ValueType.label),
    TagData.partial(
        tid: 2, name: 'numeric', type: ValueType.numeric, defaultValue: 1),
    TagData.partial(
        tid: 3, name: 'string', type: ValueType.string, defaultValue: 'str'),
  ];
  List<ValueData> values = [
    ValueData.partial(vid: 1, tid: 2, pid: 1, value: 123),
    ValueData.partial(vid: 2, tid: 2, pid: 3, value: 5),
    ValueData.partial(vid: 3, tid: 1, pid: 3),
  ];

  setUpAll(() async {
    File dbfile = File(DBManager.dbMgrFileName);
    if (await dbfile.exists()) {
      await dbfile.delete();
    }
  });

  tearDownAll(() async {
    File dbfile = File(DBManager.dbMgrFileName);
    if (await dbfile.exists()) {
      await dbfile.delete();
    }
  });

  test('Sqflite Open Test', () async {
    await DBManager().initializeDatabase();
    expect(await File(DBManager.dbMgrFileName).exists(), true);
  });

  test('Path Insertion Test', () async {
    // 데이터 삽입 테스트
    // 정상적으로 pid가 발급 되는지 확인
    for (PathData path in paths) {
      int? pid = await DBManager().createPath(path.path);
      expect(pid, path.pid);
    }
  });

  test('Tag Insertion Test', () async {
    for (TagData tag in tags) {
      final newTag = await DBManager().createTag(tag);
      expect(newTag, tag);
    }
  });

  test('Value Insertion Test', () async {
    for (ValueData value in values) {
      final newValue = await DBManager().createValue(value);
      expect(newValue, value);
    }
  });

  test('Tag Necessary Test', () async {
    TagData ncsTag = TagData.partial(
      type: ValueType.string,
      name: 'ncsTag',
      defaultValue: 'ncs',
      necessary: true,
    );
    TagData? newTag = await DBManager().createTag(ncsTag);
    expect(newTag, isNotNull);
    ncsTag = newTag!;
    tags.add(ncsTag);

    final Map<int, ValueData>? result = await DBManager().getValues();
    expect(result, isNotNull);
    for (ValueData value in result!.values) {
      if (value.tid != ncsTag.tid) continue;
      expect(value.value, ncsTag.defaultValue);
      values.add(value);
    }
  });

  test('Tag Duplicable Test', () async {
    TagData dupTag = TagData.partial(
      type: ValueType.label,
      name: 'dupTag',
      duplicable: true,
    );
    TagData? newTag = await DBManager().createTag(dupTag);
    expect(newTag, isNotNull);
    dupTag = newTag!;
    tags.add(dupTag);

    const int dupCount = 3;

    //Duplicable Tag
    for (int i = 0; i < dupCount; ++i) {
      ValueData? newValue = await DBManager().createValue(ValueData.partial(
        tid: dupTag.tid,
        pid: 1,
      ));
      expect(newValue, isNotNull);

      values.add(newValue!);
    }

    //UnDuplicable Tag
    {
      ValueData? newValue = await DBManager().createValue(ValueData.partial(
        tid: 1,
        pid: 2,
      ));
      expect(newValue, isNotNull);

      values.add(newValue!);
    }
    for (int i = 0; i < dupCount; ++i) {
      ValueData? newValue = await DBManager().createValue(ValueData.partial(
        tid: 1,
        pid: 2,
      ));
      expect(newValue, isNull);
    }
  });

  test('Path Data Test', () async {
    final Map<int, PathData>? result = await DBManager().getPaths();
    expect(result, isNotNull);
    expect(result!.length, paths.length);
    for (PathData path in paths) {
      expect(result.containsKey(path.pid), isTrue);
      expect(result[path.pid], path);
    }
  });
  test('Tag Data Test', () async {
    final Map<int, TagData>? result = await DBManager().getTags();
    expect(result, isNotNull);
    expect(result!.length, tags.length);
    for (TagData tag in tags) {
      expect(result.containsKey(tag.tid), isTrue);
      expect(result[tag.tid], tag);
    }
  });
  test('Value Data Test', () async {
    final Map<int, ValueData>? result = await DBManager().getValues();
    expect(result, isNotNull);
    expect(result!.length, values.length);
    for (ValueData value in values) {
      expect(result.containsKey(value.vid), isTrue);
      expect(result[value.vid], value);
    }
  });

  test('Sqflite Close Test', () {
    DBManager().closeDatabase();
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

void typeTest() {
  test('Data Convert Test', () {
    expect(Types.bool2int(true), 1);
    expect(Types.bool2int(false), 0);

    expect(Types.int2bool(1), true);
    expect(Types.int2bool(0), false);
    expect(Types.int2bool(2), false);
    expect(Types.int2bool(null), false);

    expect(Types.color2int(Colors.black), 0xFF000000);
    expect(Types.color2int(Colors.lightBlue), 0xFF03A9F4);

    dynamic value;
    String? str;
    expect(Types.verify(ValueType.label, value), true);
    expect(Types.verify(ValueType.numeric, value), false);
    expect(Types.verify(ValueType.string, value), false);
    expect(Types.verify(ValueType.datetime, value), false);
    expect(Types.isParsable(ValueType.label, str), true);
    expect(Types.isParsable(ValueType.numeric, str), false);
    expect(Types.isParsable(ValueType.string, str), true);
    expect(Types.isParsable(ValueType.datetime, str), false);
    expect(Types.parseString(ValueType.label, str), value);
    expect(Types.parseString(ValueType.numeric, str), 0); //기본값
    expect(Types.parseString(ValueType.string, str), ''); //기본값
    expect(Types.parseString(ValueType.datetime, str), DateTime.now()); //기본값

    value = 123;
    str = value.toString();
    expect(Types.verify(ValueType.label, value), false);
    expect(Types.verify(ValueType.numeric, value), true);
    expect(Types.verify(ValueType.string, value), false);
    expect(Types.verify(ValueType.datetime, value), false);
    expect(Types.isParsable(ValueType.label, str), false);
    expect(Types.isParsable(ValueType.numeric, str), true);
    expect(Types.isParsable(ValueType.string, str), true); //예외
    expect(Types.isParsable(ValueType.datetime, str), false);
    expect(Types.parseString(ValueType.label, str), null);
    expect(Types.parseString(ValueType.numeric, str), value);
    expect(Types.parseString(ValueType.string, str), str);
    expect(Types.parseString(ValueType.datetime, str), DateTime.now()); //기본값

    value = 'text';
    str = value.toString();
    expect(Types.verify(ValueType.label, value), false);
    expect(Types.verify(ValueType.numeric, value), false);
    expect(Types.verify(ValueType.string, value), true);
    expect(Types.verify(ValueType.datetime, value), false);
    expect(Types.isParsable(ValueType.label, str), false);
    expect(Types.isParsable(ValueType.numeric, str), false);
    expect(Types.isParsable(ValueType.string, str), true);
    expect(Types.isParsable(ValueType.datetime, str), false);
    expect(Types.parseString(ValueType.label, str), null);
    expect(Types.parseString(ValueType.numeric, str), 0); //기본값
    expect(Types.parseString(ValueType.string, str), value);
    expect(Types.parseString(ValueType.datetime, str), DateTime.now()); //기본값

    value = DateTime(2025, 3, 2, 15, 45, 59); //2025년 3월 2일 15시 45분 59초
    str = value.toString();
    expect(Types.verify(ValueType.label, value), false);
    expect(Types.verify(ValueType.numeric, value), false);
    expect(Types.verify(ValueType.string, value), false);
    expect(Types.verify(ValueType.datetime, value), true);
    expect(Types.isParsable(ValueType.label, str), false);
    expect(Types.isParsable(ValueType.numeric, str), false);
    expect(Types.isParsable(ValueType.string, str), true); //예외
    expect(Types.isParsable(ValueType.datetime, str), true);
    expect(Types.parseString(ValueType.label, str), null);
    expect(Types.parseString(ValueType.numeric, str), 0); //기본값
    expect(Types.parseString(ValueType.string, str), str);
    expect(Types.parseString(ValueType.datetime, str), value);
  });
}

void main() {
  group('Data Test', () => pathTest());
  group('File Test', () => directoryTest());
  group('Type Test', () => typeTest());
  group('DB Test', () => sqfliteTest());
}
