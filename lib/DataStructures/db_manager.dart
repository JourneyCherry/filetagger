import 'dart:io';

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
            necessary INTEGER NOT NULL DEFAULT 0
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

  /// 파일 추가
  Future<int?> addFile(String filePath) async {
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
      final insertResult = await txn.rawInsert('''
        INSERT INTO $_fileTableName(path, pid) 
        VALUES(?, ?)
      ''', [path, ppid]);
      if (insertResult == 0) {
        //중복 경로로 실패 한 경우
        return null;
      }

      //필수 태그 기본값으로 채워넣기
      final int pid = Sqflite.firstIntValue(
          await txn.rawQuery('SELECT last_insert_rowid()'))!;
      final tags = await txn.rawQuery('''
        SELECT id, default_value, necessary
        FROM $_taginfoTableName
      ''');
      for (var tag in tags) {
        if (tag['necessary'] as int > 0) {
          await txn.rawInsert('''
            INSERT INTO $_tagTableName ( pid, tid, value )
            VALUES( ?, ?, ? )
          ''', [pid, tag['id'] as int, tag['default_value']]);
        }
      }
      return pid;
    });
  }

  Future<void> removeFile(int startId) async {
    if (_database == null) return;
    await _database!.transaction((txn) async {
      List<int> q = [startId]; //모든 서브 디렉토리의 파일도 같이 삭제되어야 한다.
      while (q.isNotEmpty) {
        int id = q.first;
        q.removeAt(0);
        final result = await txn.rawQuery('''
          SELECT id
          FROM $_fileTableName
          WHERE pid = ?
        ''', [id]);
        for (var child in result) {
          q.insert(q.length, child['id'] as int);
        }
        await txn.rawDelete('''
          DELETE FROM $_fileTableName
          WHERE id = ?
        ''', [id]);
      }
    });
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

  Future<
      ({
        String? path,
        int pid,
        bool recursive,
      })?> getFileFromId(int id) async {
    if (_database == null) return null;
    final result = await _database!.rawQuery('''
      SELECT path, pid, recursive
      FROM $_fileTableName
      WHERE id = ?
    ''', [id]);
    if (result.isEmpty) return null;
    final path = result.first['path'] as String;
    final pid = result.first['pid'] as int;
    final recursive = Types.int2bool(result.first['recursive']);
    return (
      path: path,
      pid: pid,
      recursive: recursive,
    );
  }

  /// 태그 종류 생성
  Future<int?> createTag({
    required String name,
    required ValueType type,
    dynamic defaultValue,
    bool duplicable = false,
    bool necessary = false,
  }) async {
    if (_database == null) return null;
    //디폴트 값은 타입이 일치해야 한다.
    if (!Types.verify(type, defaultValue)) return null;
    try {
      await _database!.execute('''
        INSERT INTO $_taginfoTableName ( name, type, default_value, duplicable, necessary )
        VALUES( ?, ?, ?, ?, ? )
      ''', [
        name,
        type.index,
        defaultValue,
        Types.bool2int(duplicable),
        Types.bool2int(necessary),
      ]);
      return Sqflite.firstIntValue(
          await _database!.rawQuery('SELECT last_insert_rowid()'))!;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrintStack(stackTrace: st, label: e.toString());
      }
      return null;
    }
  }

  /// 태그 종류 제거
  Future<void> removeTag(int id) async {
    if (_database == null) return;
    await _database!.execute('''
      DELETE FROM $_taginfoTableName
      WHERE id = ?
    ''', [id]);
  }

  Future<Map<int, TagInfoData>?> getTags() async {
    if (_database == null) return null;

    Map<int, TagInfoData> map = {};
    final result = await _database!.rawQuery('''
      SELECT id, name, type, default_value, duplicable, necessary
      FROM $_taginfoTableName
    ''');
    for (var row in result) {
      final tid = row['id'] as int;
      map[tid] = TagInfoData(
        tid: tid,
        name: row['name'] as String,
        type: row['type'] as ValueType,
        defaultValue: row['default_value'],
        duplicable: Types.int2bool(row['duplicable']),
        necessary: Types.int2bool(row['necessary']),
      );
    }

    return map;
  }

  Future<
      ({
        String? name,
        ValueType type,
        dynamic defaultValue,
        bool duplicable,
        bool necessary,
      })?> getTagFromId(int id) async {
    if (_database == null) return null;
    final result = await _database!.rawQuery('''
      SELECT name, type, default_value, duplicable, necessary
      FROM $_taginfoTableName
      WHERE id = ?
    ''', [id]);
    if (result.isEmpty) return null;
    final name = result.first['name'] as String;
    final type = result.first['type'] as ValueType;
    final defaultValue = result.first['default_value'];
    final duplicable = Types.int2bool(result.first['duplicable']);
    final necessary = Types.int2bool(result.first['necessary']);
    return (
      name: name,
      type: type,
      defaultValue: defaultValue,
      duplicable: duplicable,
      necessary: necessary,
    );
  }

  /// 파일에 태그 추가
  Future<bool> addTagValue({
    required int pid,
    required int tid,
    dynamic value,
  }) async {
    if (_database == null) return false;
    try {
      await _database!.transaction((txn) async {
        final result = await txn.rawQuery('''
          SELECT default_value, duplicable
          FROM $_taginfoTableName
          WHERE id = ?
        ''', [tid]);
        if (result.isEmpty) {
          throw Exception('there is no tag in (pid: $pid, tid: $tid)');
        }
        final bool duplicable = Types.int2bool(result.first['duplicable']);
        value ??= result.first['default_value'];
        if (!duplicable) {
          int count = Sqflite.firstIntValue(await txn.rawQuery('''
            SELECT COUNT(tid)
            FROM $_tagTableName
            WHERE pid = ? AND tid = ?
          ''', [pid, tid]))!;
          if (count >= 1) return false;
        }
        await txn.execute('''
          INSERT INTO $_tagTableName ( pid, tid, value )
          VALUES ( ?, ?, ? )
        ''', [pid, tid, value]);
      });
    } catch (e, st) {
      if (kDebugMode) {
        debugPrintStack(stackTrace: st, label: e.toString());
      }
      return false;
    }
    return true;
  }

  /// 파일에 연결된 태그 값 변경
  Future<bool> setTagValue(int id, dynamic value) async {
    if (_database == null) return false;
    try {
      final ValueType type =
          ValueType.values[Sqflite.firstIntValue(await _database!.rawQuery('''
        SELECT type
        FROM $_taginfoTableName
        WHERE id IN (
          SELECT id
          FROM $_tagTableName
          WHERE id = ?
        )
      ''', [id]))!];
      if (!Types.verify(type, value)) return false;
      await _database!.rawUpdate('''
        UPDATE $_tagTableName
        SET value = ?
        WHERE id = ?
      ''', [value, id]);
    } catch (e, st) {
      if (kDebugMode) debugPrintStack(stackTrace: st, label: e.toString());
      return false;
    }
    return true;
  }

  /// 파일에 연결된 태그 제거
  Future<void> deleteTagValue(int id) async {
    if (_database == null) return;
    await _database!.execute('''
      DELETE FROM $_tagTableName
      WHERE id = ?
    ''', [id]);
  }

  Future<Map<int, ValueData>?> getValues() async {
    if (_database == null) return null;
    final result = await _database!.rawQuery('''
      SELECT id, pid, tid, value
      FROM $_tagTableName
    ''');
    Map<int, ValueData> map = {};
    for (var value in result) {
      final vid = value['id'] as int;
      map[vid] = ValueData(
        vid: vid,
        pid: value['pid'] as int,
        tid: value['tid'] as int,
        value: value['value'],
      );
    }
    return map;
  }

  /// 대상 파일(id)에 대한 모든 태그 값 가져오기
  Future<List<({int id, ValueType type, dynamic value})>> getTagsFromFile(
    int pid,
  ) async {
    if (_database == null) return [];
    final result = await _database!.rawQuery('''
      SELECT tag.id as id, info.type as type, tag.value as value
      FROM $_taginfoTableName as info
      RIGHT JOIN $_tagTableName as tag
      ON info.id = tag.tid
      WHERE tag.pid = ?
    ''', [pid]);
    List<({int id, ValueType type, dynamic value})> list = [];
    for (var tag in result) {
      list.add((
        id: tag['id'] as int,
        type: tag['type'] as ValueType,
        value: tag['value'],
      ));
    }
    return list;
  }
}
