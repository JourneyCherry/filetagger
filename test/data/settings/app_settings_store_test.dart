import 'dart:io';

import 'package:filetagger/core/build_info.dart';
import 'package:filetagger/core/constants.dart';
import 'package:filetagger/data/settings/app_settings_store.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// 설정 디렉토리만 갈아 끼운 저장소. 실제 파일 I/O는 그대로 탄다.
class _StoreIn extends AppSettingsStore {
  _StoreIn(this.dir);

  final Directory dir;
  int directoryLookups = 0;

  @override
  Future<Directory> settingsDirectory() async {
    directoryLookups++;
    return dir;
  }
}

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('filetagger_settings_test');
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  group('설정 위치', () {
    test('포터블 빌드는 실행 파일 옆에 둔다', () async {
      final store = AppSettingsStore(channel: DistributionChannel.portable);
      expect(
        (await store.settingsDirectory()).path,
        p.dirname(Platform.resolvedExecutable),
      );
    });
  });

  group('읽고 쓰기', () {
    test('저장한 설정을 그대로 되읽는다', () async {
      final store = _StoreIn(temp);
      final saved = await store.save(
        const AppSettings(recentFolders: ['/a'], themeMode: ThemeMode.dark),
      );

      expect(saved, isTrue);
      final loaded = await _StoreIn(temp).load();
      expect(loaded.recentFolders, ['/a']);
      expect(loaded.themeMode, ThemeMode.dark);
    });

    test('파일이 없으면 기본값을 준다', () async {
      expect((await _StoreIn(temp).load()).recentFolders, isEmpty);
    });

    test('내용이 깨져 있어도 기본값으로 눕는다', () async {
      await File(p.join(temp.path, settingsFileName)).writeAsString('{ 깨진');
      expect((await _StoreIn(temp).load()).themeMode, ThemeMode.system);
    });
  });

  group('저장 실패', () {
    /// 디렉토리 자리에 파일을 두어 그 아래에 쓰지 못하게 만든다.
    Future<_StoreIn> blockedStore() async {
      final blocker = File(p.join(temp.path, 'blocked'));
      await blocker.writeAsString('');
      return _StoreIn(Directory(blocker.path));
    }

    test('예외를 던지지 않고 실패를 돌려준다', () async {
      final store = await blockedStore();
      expect(await store.save(const AppSettings()), isFalse);
      expect(store.saveDisabled, isTrue);
    });

    test('1회 실패 뒤에는 디스크를 다시 건드리지 않는다', () async {
      final store = await blockedStore();
      await store.save(const AppSettings());
      final lookupsAfterFailure = store.directoryLookups;

      expect(await store.save(const AppSettings()), isFalse);
      expect(store.directoryLookups, lookupsAfterFailure);
    });

    test('저장이 막혀도 읽기는 계속 된다', () async {
      final store = await blockedStore();
      await store.save(const AppSettings());
      expect((await store.load()).recentFolders, isEmpty);
    });
  });
}
