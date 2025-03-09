import 'dart:io';
import 'dart:ui';

import 'package:filetagger/DataStructures/datas.dart';
import 'package:filetagger/DataStructures/path_manager.dart';
import 'package:filetagger/DataStructures/types.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DBManager {
  static const String dbMgrFileName = '.tagdb';
  static const String _fileTableName = 'files';
  static const String _taginfoTableName = 'taginfo';
  static const String _tagTableName = 'tags';
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
      onConfigure: (db) async =>
          await db.execute('PRAGMA foreign_keys = 1'), //외래키 활성화
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_fileTableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            path TEXT NOT NULL UNIQUE,
            pid INTEGER NOT NULL,
            recursive INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE $_taginfoTableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
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
          CREATE TABLE $_tagTableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pid INTEGER,
            tid INTEGER,
            value TEXT,
            FOREIGN KEY ( tid ) REFERENCES $_taginfoTableName ( id ) ON DELETE CASCADE,
            FOREIGN KEY ( pid ) REFERENCES $_fileTableName ( id ) ON DELETE CASCADE
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

  /// 파일 추가
  Future<PathData?> createPath(String filePath) async {
    //p.relative()는 동일 경로만 '.'을, 그 외에는 ./를 접두어로 붙이지 않는다.
    final path = PathManager().getPath(filePath);
    final parentPath = PathManager().getParent(filePath);
    if (_database == null) return null;
    return await _database!.transaction((txn) async {
      int ppid = 0;
      if (parentPath != '.') {
        final parentResult = await txn.rawQuery('''
          SELECT id 
          FROM $_fileTableName
          WHERE path = ?
        ''', ['./$parentPath']);
        if (parentResult.isNotEmpty) {
          ppid = parentResult.first['id'] as int;
        }
      }
      final int pid = await txn.insert(_fileTableName, {
        'path': path,
        'pid': ppid,
      });
      if (pid == 0) {
        //데이터 삽입에 실패 한 경우
        return null;
      }
      return PathData(
        pid: pid,
        path: filePath,
        ppid: ppid,
        recursive: false,
      );
    });
  }

  Future<PathData?> updatePath(PathData path) async {
    if (_database == null) return null;
    path.ppid = 0;
    final parentPath = PathManager().getParent(path.path);
    return await _database!.transaction((txn) async {
      if (parentPath != '.') {
        final parentResult = await txn.query(
          _fileTableName,
          columns: ['id'],
          where: 'path = ?',
          whereArgs: [parentPath],
        );
        if (parentResult.isNotEmpty) {
          path.ppid = parentResult.first['id'] as int;
        }
      }
      final updatedCount = await txn.update(
        _fileTableName,
        {
          'path': path.path,
          'ppid': path.ppid,
          'recursive': path.recursive,
        },
        where: 'pid = ?',
        whereArgs: [path.pid],
      );

      if (updatedCount != 0) return null;
      return path;
    });
  }

  Future<void> deleteFile(int pid) async {
    if (_database == null) return;
    await _database!.delete(
      _fileTableName,
      where: 'id = ?',
      whereArgs: [pid],
    );
  }

  Future<Map<int, PathData>?> getPaths() async {
    if (_database == null) return null;

    Map<int, PathData> map = {};
    final query = await _database!.rawQuery('''
      SELECT id, path, pid, recursive
      FROM $_fileTableName
    ''');
    for (var row in query) {
      final pid = row['id'] as int;
      map[pid] = PathData(
        pid: pid,
        path: row['path'] as String,
        ppid: row['pid'] as int,
        recursive: Types.int2bool(row['recursive']),
      );
    }
    return map;
  }

  /// 태그 종류 생성
  Future<TagData?> createTag(TagData tag) async {
    if (_database == null) return null;
    //디폴트 값은 타입이 일치해야 한다.
    if (!Types.verify(tag.type, tag.defaultValue)) return null;
    try {
      final insertedId = await _database!.insert(_taginfoTableName, {
        'name': tag.name,
        'type': tag.type.index,
        'default_value': tag.defaultValue,
        'duplicable': Types.bool2int(tag.duplicable),
        'necessary': Types.bool2int(tag.necessary),
        'sort_order': tag.order,
        'bg_color': Types.color2int(tag.bgColor),
        'txt_color': Types.color2int(tag.txtColor),
      });
      if (insertedId == 0) return null;
      tag.tid = insertedId;
      return tag;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrintStack(stackTrace: st, label: e.toString());
      }
      return null;
    }
  }

  Future<TagData?> updateTag(TagData tag) async {
    if (_database == null) return null;
    //디폴트 값은 타입이 일치해야 한다.
    if (!Types.verify(tag.type, tag.defaultValue)) return null;

    try {
      final updatedRows = await _database!.update(
        _taginfoTableName,
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

      if (updatedRows != 1) return null;
      return tag;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrintStack(stackTrace: st, label: e.toString());
      }
      return null;
    }
  }

  /// 태그 종류 제거
  Future<void> deleteTag(int id) async {
    if (_database == null) return;
    await _database!.delete(
      _taginfoTableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<int, TagData>?> getTags() async {
    if (_database == null) return null;

    Map<int, TagData> map = {};
    final result = await _database!.rawQuery('''
      SELECT id, name, type, default_value, duplicable, necessary, sort_order, bg_color, txt_color
      FROM $_taginfoTableName
    ''');
    for (var row in result) {
      final tid = row['id'] as int;
      map[tid] = TagData(
        tid: tid,
        name: row['name'] as String,
        type: ValueType.values[row['type'] as int],
        defaultValue: row['default_value'],
        duplicable: Types.int2bool(row['duplicable']),
        necessary: Types.int2bool(row['necessary']),
        order: row['sort_order'] as int,
        bgColor: Color(row['bg_color'] as int),
        txtColor: Color(row['txt_color'] as int),
      );
    }

    return map;
  }

  /// 파일에 태그 추가
  Future<ValueData?> createValue(ValueData value) async {
    if (_database == null) return null;
    try {
      final insertedId = await _database!.transaction((txn) async {
        final result = await txn.rawQuery('''
          SELECT type, default_value, duplicable
          FROM $_taginfoTableName
          WHERE id = ?
        ''', [value.tid]);
        if (result.isEmpty) {
          //해당 tid의 존재여부 확인
          throw Exception('there is no tag with (tid: ${value.tid})');
        }
        final row = result.first;
        final bool duplicable = Types.int2bool(row['duplicable']);
        final int countValue = await countDuplicatedValue(
          txn: txn,
          pid: value.pid,
          tid: value.tid,
        );
        if (!duplicable && countValue > 0) {
          // 중복 불가능한 태그로 이미 값이 존재하면 추가 불가능
          return 0;
        }
        ValueType valueType = ValueType.values[row['type'] as int];
        if (!Types.verify(valueType, value.value)) {
          //입력한 값이 태그 타입과 맞지 않으면 기본값으로 설정
          value.value =
              Types.parseString(valueType, row['default_value'] as String?);
        }
        return await txn.insert(_tagTableName, {
          'pid': value.pid,
          'tid': value.tid,
          'value': value.value,
        });
      });
      if (insertedId == 0) return null;
      value.vid = insertedId;
      return value;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrintStack(stackTrace: st, label: e.toString());
      }
      return null;
    }
  }

  /// 파일에 연결된 태그 값 변경(연결된 파일, 태그 타입도 변경 가능)
  Future<ValueData?> updateValue(ValueData value) async {
    if (_database == null) return null;
    try {
      final tagQuery = await _database!.query(
        _taginfoTableName,
        columns: ['type'],
        where: 'id = ?',
        whereArgs: [value.tid],
      );
      if (tagQuery.isEmpty) throw Exception('No Tag found: ${value.tid}');
      final ValueType type = ValueType.values[Sqflite.firstIntValue(tagQuery)!];
      if (!Types.verify(type, value.value)) return null;
      final updatedRows = await _database!.update(
        _tagTableName,
        {
          'value': value.value,
          'tid': value.tid,
          'pid': value.pid,
        },
        where: 'id = ?',
        whereArgs: [value.vid],
      );
      if (updatedRows != 1) return null;
      return value;
    } catch (e, st) {
      if (kDebugMode) debugPrintStack(stackTrace: st, label: e.toString());
      return null;
    }
  }

  /// 파일에 연결된 태그 제거
  Future<void> deleteValue(int vid) async {
    if (_database == null) return;
    await _database!.delete(
      _tagTableName,
      where: 'id = ?',
      whereArgs: [vid],
    );
  }

  Future<Map<int, ValueData>?> getValues() async {
    if (_database == null) return null;
    final queryResult = await _database!.rawQuery('''
      SELECT 
        vt.id as 'id', 
        vt.pid as 'pid', 
        vt.tid as 'tid', 
        vt.value as 'value', 
        tt.type as 'type'
      FROM $_tagTableName as vt
      LEFT JOIN $_taginfoTableName as tt
      ON vt.tid = tt.id
    ''');

    Map<int, ValueData> result = {};
    for (var row in queryResult) {
      result[row['id'] as int] = ValueData(
        vid: row['id'] as int,
        pid: row['pid'] as int,
        tid: row['tid'] as int,
        value: Types.parseString(
          ValueType.values[row['type'] as int],
          row['value'] as String?,
        ),
      );
    }
    return result;
  }

  Future<int> countDuplicatedValue({
    required DatabaseExecutor txn,
    required int pid,
    required int tid,
  }) async {
    final countResult = await txn.query(
      _tagTableName,
      columns: ['COUNT(1)'],
      where: 'pid = ? AND tid = ?',
      whereArgs: [pid, tid],
    );
    return Sqflite.firstIntValue(countResult) ?? 0;
  }

  Future<List<ValueData>> checkNecessaryTag(TagData tag) async {
    if (!tag.necessary) return [];
    if (_database == null) return [];

    List<ValueData> newValues = [];

    final isSuccess = await _database!.transaction((txn) async {
      final tid = tag.tid;
      final paths = await txn.query(_fileTableName, columns: ['id']);
      for (Map<String, Object?> path in paths) {
        final pid = path['id'] as int;
        if (await countDuplicatedValue(txn: txn, pid: pid, tid: tid) == 0) {
          final newVID = await txn.insert(_tagTableName, {
            'tid': tid,
            'pid': pid,
            'value': tag.defaultValue?.toString() ?? '',
          });
          newValues.add(ValueData(
            vid: newVID,
            pid: pid,
            tid: tid,
            value: tag.defaultValue,
          ));
        }
      }
      return true;
    });

    if (isSuccess) return newValues;
    return [];
  }
}
