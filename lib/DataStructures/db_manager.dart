import 'dart:io';
import 'dart:ui';

import 'package:filetagger/DataStructures/datas.dart';
import 'package:filetagger/DataStructures/error_code.dart';
import 'package:filetagger/DataStructures/types.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DBManager {
  static const String dbMgrFileName = '.tagdb';
  static const String _pathTableName = 'path_table';
  static const String _tagTableName = 'tag_table';
  static const String _valueTableName = 'value_table';
  Database? _database;

  static final DBManager _instance = DBManager._internal();
  factory DBManager() {
    return _instance;
  }
  DBManager._internal() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  Future<bool> initializeDatabase([String path = '.']) async {
    if (!await Directory(path).exists()) return false;
    final dbPath = p.join(Directory(path).absolute.path, dbMgrFileName);

    closeDatabase();

    _database = await openDatabase(
      dbPath,
      version: 1,
      onConfigure: (db) async => await db.execute('''
            PRAGMA journal_mode = WAL;
            PRAGMA busy_timeout = 5000;
          '''), //외래키 활성화
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_pathTableName (
            pid INTEGER PRIMARY KEY,
            path TEXT NOT NULL UNIQUE,
            ppid INTEGER NOT NULL DEFAULT 0,
            recursive INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE $_tagTableName (
            tid INTEGER PRIMARY KEY,
            name TEXT NOT NULL UNIQUE,
            type INTEGER NOT NULL DEFAULT 0,
            default_value TEXT,
            duplicable INTEGER NOT NULL DEFAULT 0,
            necessary INTEGER NOT NULL DEFAULT 0,
            sort_order INTEGER NOT NULL,
            bg_color INTEGER NOT NULL,
            txt_color INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE $_valueTableName (
            vid INTEGER PRIMARY KEY,
            pid INTEGER NOT NULL,
            tid INTEGER NOT NULL,
            value TEXT
          )
        ''');
      },
    );

    return true;
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  bool isAvailable() {
    if (_database == null) return false;
    return _database!.isOpen;
  }

  Future<Result<List<PathData>>> getPaths() async {
    if (!isAvailable()) return Result.error(ErrorCode.dbNoConnection);
    final paths = await _database!.query(_pathTableName);
    List<PathData> result = List.from(paths.map((Map<String, Object?> columns) {
      PathData path = PathData(
        pid: columns['pid'] as int,
        path: columns['path'] as String,
        ppid: columns['ppid'] as int,
        recursive: Types.int2bool(columns['recursive'] as int),
      );

      return path;
    }));

    return Result.ok(result);
  }

  Future<ErrorCode> setPath(PathData path) async {
    if (_database == null) return ErrorCode.dbNoConnection;
    return await _database!.transaction((txn) async {
      final updatedRowCount = await txn.update(
        _pathTableName,
        {
          'path': path.path,
          'ppid': path.ppid,
          'recursive': path.recursive,
        },
        where: 'pid = ?',
        whereArgs: [path.pid],
      );
      if (updatedRowCount == 0) {
        await txn.insert(
          _pathTableName,
          {
            'pid': path.pid,
            'path': path.path,
            'ppid': path.ppid,
            'recursive': path.recursive,
          },
        );
      }

      return ErrorCode.success;
    });
  }

  Future<ErrorCode> removePath(int pid) async {
    if (!isAvailable()) return ErrorCode.dbNoConnection;
    await _database!.delete(
      _pathTableName,
      where: 'id = ?',
      whereArgs: [pid],
    );

    return ErrorCode.success;
  }

  // 태그 가져오기. 단, defaultValue는 항상 String이다.
  Future<Result<List<TagData>>> getTag() async {
    if (!isAvailable()) return Result.error(ErrorCode.dbNoConnection);
    final tags = await _database!.query(_tagTableName);
    List<TagData> result = List.from(tags.map((Map<String, Object?> columns) {
      TagData tag = TagData(
        tid: columns['tid'] as int,
        name: columns['name'] as String,
        type: ValueType.values[columns['type'] as int],
        defaultValue: columns['default_value'] as String?,
        duplicable: Types.int2bool(columns['duplicable'] as int),
        necessary: Types.int2bool(columns['necessary'] as int),
        order: columns['sort_order'] as int,
        bgColor: Color(columns['bg_color'] as int),
        txtColor: Color(columns['txt_color'] as int),
      );

      return tag;
    }));

    return Result.ok(result);
  }

  Future<ErrorCode> setTag(TagData tag) async {
    if (!isAvailable()) return ErrorCode.dbNoConnection;
    return await _database!.transaction((txn) async {
      final updatedRowCount = await _database!.update(
        _tagTableName,
        {
          'name': tag.name,
          'type': tag.type.index,
          'default_value': tag.defaultValue,
          'duplicable': Types.bool2int(tag.duplicable),
          'necessary': Types.bool2int(tag.necessary),
          'sort_order': tag.order,
          'bg_color': Types.color2int(tag.bgColor),
          'txt_color': Types.color2int(tag.txtColor),
        },
        where: 'id = ?',
        whereArgs: [tag.tid],
      );
      if (updatedRowCount == 0) {
        await _database!.insert(
          _tagTableName,
          {
            'tid': tag.tid,
            'name': tag.name,
            'default_value': tag.defaultValue,
            'duplicable': Types.bool2int(tag.duplicable),
            'necessary': Types.bool2int(tag.necessary),
            'sort_order': tag.order,
            'bg_color': Types.color2int(tag.bgColor),
            'txt_color': Types.color2int(tag.txtColor),
          },
        );
      }
      return ErrorCode.success;
    });
  }

  /// 태그 종류 제거
  Future<ErrorCode> removeTag(int tid) async {
    if (!isAvailable()) return ErrorCode.dbNoConnection;
    await _database!.delete(
      _tagTableName,
      where: 'id = ?',
      whereArgs: [tid],
    );

    return ErrorCode.success;
  }

  // 값 목록 가져오기. 단, value는 항상 String이다.
  Future<Result<List<ValueData>>> getValue() async {
    if (!isAvailable()) return Result.error(ErrorCode.dbNoConnection);
    final tags = await _database!.query(_valueTableName);
    List<ValueData> result = List.from(tags.map((Map<String, Object?> columns) {
      ValueData tag = ValueData(
        vid: columns['vid'] as int,
        tid: columns['tid'] as int,
        pid: columns['pid'] as int,
        value: columns['value'] as String?,
      );

      return tag;
    }));

    return Result.ok(result);
  }

  /// 파일에 연결된 태그 값 변경(연결된 파일, 태그 타입도 변경 가능)
  Future<ErrorCode> setValue(ValueData value) async {
    if (!isAvailable()) return ErrorCode.dbNoConnection;
    return await _database!.transaction((txn) async {
      final updatedRowCount = await _database!.update(
        _valueTableName,
        {
          'tid': value.tid,
          'pid': value.pid,
          'value': value.value,
        },
        where: 'vid = ?',
        whereArgs: [value.vid],
      );
      if (updatedRowCount == 0) {
        await _database!.insert(
          _valueTableName,
          {
            'vid': value.vid,
            'tid': value.tid,
            'pid': value.pid,
            'value': value.value,
          },
        );
      }
      return ErrorCode.success;
    });
  }

  /// 파일에 연결된 태그 제거
  Future<ErrorCode> removeValue(int vid) async {
    if (!isAvailable()) return ErrorCode.dbNoConnection;
    await _database!.delete(
      _valueTableName,
      where: 'vid = ?',
      whereArgs: [vid],
    );

    return ErrorCode.success;
  }

  Future<ErrorCode> setData(dynamic data) async {
    if (data is PathData) return setPath(data);
    if (data is TagData) return setTag(data);
    if (data is ValueData) return setValue(data);

    return ErrorCode.unknownDataType;
  }

  Future<ErrorCode> removeData(DataType type, int id) async {
    switch (type) {
      case DataType.path:
        return removePath(id);
      case DataType.tag:
        return removeTag(id);
      case DataType.value:
        return removeValue(id);
    }
  }
}
