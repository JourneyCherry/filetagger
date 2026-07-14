import 'package:filetagger/data/settings/app_settings_store.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSettings 직렬화', () {
    test('최근 폴더 목록을 보존하며 왕복한다', () {
      const settings = AppSettings(recentFolders: ['/a', '/b']);
      final restored = AppSettings.fromJson(settings.toJson());
      expect(restored.recentFolders, settings.recentFolders);
    });

    test('테마 모드를 보존하며 왕복한다', () {
      const settings = AppSettings(themeMode: ThemeMode.dark);
      final restored = AppSettings.fromJson(settings.toJson());
      expect(restored.themeMode, ThemeMode.dark);
    });

    test('빈/누락 JSON은 기본값으로 복원된다', () {
      final restored = AppSettings.fromJson(const {});
      expect(restored.recentFolders, isEmpty);
      expect(restored.themeMode, ThemeMode.system);
    });

    test('알 수 없는 테마 이름은 시스템으로 눕힌다', () {
      final restored = AppSettings.fromJson(const {'themeMode': '???'});
      expect(restored.themeMode, ThemeMode.system);
    });
  });

  group('AppSettings.copyWith', () {
    test('한 필드만 갈고 나머지는 보존한다', () {
      const settings = AppSettings(
        recentFolders: ['/a'],
        themeMode: ThemeMode.dark,
      );
      // 최근 폴더만 바꿔도 테마는 그대로다(저장 시 서로 덮지 않게 하는 근거).
      final next = settings.copyWith(recentFolders: ['/a', '/b']);
      expect(next.recentFolders, ['/a', '/b']);
      expect(next.themeMode, ThemeMode.dark);
    });
  });
}
