import 'dart:io';

import 'package:filetagger/DataStructures/types.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DBManager {
  static const String fileName = '.tagdb';
  static const String fileTableName = 'files';
  static const String taginfoTableName = 'taginfo';
  static const String tagTableName = 'tags';
  final String dirPath;
  late Database _database;

  DBManager(this.dirPath);

  Future<void> initializeDatabase() async {
    final dbPath = p.join(dirPath, fileName);

    if (!await Directory(dirPath).exists()) {
      throw Exception('Directory Doesn\'t exists');
    }

    _database = await openDatabase(
      dbPath,
      version: 0,
      onCreate: (db, version) async {
        //외래키 활성화
        await db.execute('''
          PRAGMA foreign_keys = 1
        ''');
        await db.execute('''
          CREATE TABLE $fileTableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            path TEXT NOT NULL UNIQUE,
            pid INTEGER NOT NULL,
            recursive INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE $taginfoTableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            type INTEGER NOT NULL DEFAULT 0,
            default_value TEXT,
            duplicable INTEGER NOT NULL DEFAULT 0,
            necessary INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE $tagTableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pid INTEGER,
            tid INTEGER,
            value TEXT,
            FOREIGN KEY ( tid ) REFERENCES $taginfoTableName ( id ) ON DELETE CASCADE,
            FOREIGN KEY ( pid ) REFERENCES $fileTableName ( id ) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  Future<void> closeDatabase() async {
    await _database.close();
  }

  /// 파일 추가
  Future<bool> addFile(String filePath) async {
    final path = p.relative(filePath, from: dirPath);
    final parentPath = p.relative(Directory(path).parent.path, from: dirPath);
    return await _database.transaction((txn) async {
      int ppid = 0;
      if (parentPath != '.') {
        final parentResult = await _database.rawQuery('''
          SELECT id 
          FROM $fileTableName
          WHERE path = ?
        ''', [parentPath]);
        if (parentResult.isNotEmpty) {
          ppid = parentResult.first['id'] as int;
        }
      }
      final insertResult = await _database.rawInsert('''
        INSERT INTO $fileTableName(path, pid) 
        VALUES(?, ?)
      ''', [path, ppid]);
      if (insertResult == 0) {
        //중복 경로로 실패 한 경우
        return false;
      }

      //필수 태그 기본값으로 채워넣기
      final int pid = Sqflite.firstIntValue(
          await _database.rawQuery('SELECT last_insert_rowid()'))!;
      final tags = await _database.rawQuery('''
        SELECT id, default_value, necessary
        FROM $taginfoTableName
      ''');
      for (var tag in tags) {
        if (tag['necessary'] as int > 0) {
          await _database.rawInsert('''
            INSERT INTO $tagTableName ( pid, tid, value )
            VALUES( ?, ?, ? )
          ''', [pid, tag['id'] as int, tag['default_value']]);
        }
      }
      return true;
    });
  }

  /// 태그 종류 생성
  Future<bool> createTag({
    required String name,
    required int type,
    dynamic defaultValue,
    bool duplicable = false,
    bool necessary = false,
  }) async {
    try {
      await _database.execute('''
        INSERT INTO $taginfoTableName ( name, type, default_value, duplicable, necessary )
        VALUES( ?, ?, ?, ?, ? )
      ''', [name, type, defaultValue, duplicable, necessary]);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrintStack(stackTrace: st, label: e.toString());
      }
      return false;
    }
    return true;
  }

  /// 태그 종류 제거
  Future<void> removeTag(int id) async {
    await _database.execute('''
      DELETE FROM $taginfoTableName
      WHERE id = ?
    ''', [id]);
  }

  /// 파일에 태그 추가
  Future<bool> addTagValue({
    required int pid,
    required int tid,
    dynamic value,
  }) async {
    try {
      await _database.transaction((txn) async {
        final result = await _database.rawQuery('''
          SELECT default_value, duplicable
          FROM $taginfoTableName
          WHERE id = ?
        ''', [tid]);
        if (result.isEmpty) {
          throw Exception('there is no tag in (pid: $pid, tid: $tid)');
        }
        final bool duplicable = result.first['duplicable'] as bool;
        value ??= result.first['default_value'];
        if (!duplicable) {
          int count = Sqflite.firstIntValue(await _database.rawQuery('''
            SELECT COUNT(tid)
            FROM $tagTableName
            WHERE pid = ? AND tid = ?
          ''', [pid, tid]))!;
          if (count >= 1) return false;
        }
        await _database.execute('''
          INSERT INTO $tagTableName ( pid, tid, value )
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
    try {
      final int type = Sqflite.firstIntValue(await _database.rawQuery('''
        SELECT type
        FROM $taginfoTableName
        WHERE id IN (
          SELECT id
          FROM $tagTableName
          WHERE id = ?
        )
      ''', [id]))!;
      if (!Types.verify(type, value)) return false;
      await _database.rawUpdate('''
        UPDATE $tagTableName
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
    await _database.execute('''
      DELETE FROM $tagTableName
      WHERE id = ?
    ''', [id]);
  }
}
