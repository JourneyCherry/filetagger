import 'package:filetagger/data/settings/app_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSettings 직렬화', () {
    test('최근 폴더 목록을 보존하며 왕복한다', () {
      const settings = AppSettings(recentFolders: ['/a', '/b']);
      final restored = AppSettings.fromJson(settings.toJson());
      expect(restored.recentFolders, settings.recentFolders);
    });

    test('빈/누락 JSON은 기본값으로 복원된다', () {
      expect(AppSettings.fromJson(const {}).recentFolders, isEmpty);
    });
  });
}
