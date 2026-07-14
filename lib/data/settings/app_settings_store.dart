import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants.dart';

// 최근 폴더 목록 영속화에 배선된 저장소. 저장 위치는 `path_provider`(공식
// flutter.dev 패키지)의 앱데이터 폴더(`getApplicationSupportDirectory`)로, 데스크톱
// 3종을 모두 지원한다. 포터블 배포 시 실행 파일 옆 저장 분기는 인스톨러 도입과
// 함께 검토한다(백로그).

/// 머신 단위 전역 설정. 관리 폴더가 아니라 OS 앱데이터 폴더에 저장된다.
class AppSettings {
  const AppSettings({
    this.recentFolders = const [],
    this.themeMode = ThemeMode.system,
  });

  /// 최근 연 관리 폴더 경로 목록(최신이 앞).
  final List<String> recentFolders;

  /// 라이트/다크 테마 선택. 기본값(시스템)은 OS 밝기 설정을 그대로 따른다.
  final ThemeMode themeMode;

  AppSettings copyWith({List<String>? recentFolders, ThemeMode? themeMode}) =>
      AppSettings(
        recentFolders: recentFolders ?? this.recentFolders,
        themeMode: themeMode ?? this.themeMode,
      );

  Map<String, dynamic> toJson() => {
    'recentFolders': recentFolders,
    'themeMode': themeMode.name,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    recentFolders: (json['recentFolders'] as List?)?.cast<String>() ?? const [],
    themeMode: _themeModeByName(json['themeMode'] as String?),
  );
}

/// 저장된 이름을 [ThemeMode]로 되돌린다. 알 수 없는 값·누락은 시스템 기본으로 눕힌다.
ThemeMode _themeModeByName(String? name) => ThemeMode.values
    .firstWhere((m) => m.name == name, orElse: () => ThemeMode.system);

/// 전역 설정을 JSON 파일로 읽고 쓰는 저장소.
class AppSettingsStore {
  Future<File> _settingsFile() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, settingsFileName));
  }

  /// 저장된 설정을 읽는다. 파일이 없거나 손상되면 기본값을 반환한다.
  Future<AppSettings> load() async {
    final file = await _settingsFile();
    if (!await file.exists()) return const AppSettings();
    try {
      final decoded = jsonDecode(await file.readAsString());
      return AppSettings.fromJson(decoded as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> save(AppSettings settings) async {
    final file = await _settingsFile();
    await file.create(recursive: true);
    await file.writeAsString(jsonEncode(settings.toJson()));
  }
}
