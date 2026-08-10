import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/build_info.dart';
import '../../core/constants.dart';

// 최근 폴더 목록·테마 영속화에 배선된 저장소. 설치판의 저장 위치는 `path_provider`
// (공식 flutter.dev 패키지)의 앱데이터 폴더(`getApplicationSupportDirectory`)로,
// 데스크톱 3종을 모두 지원한다. 포터블판은 실행 파일 옆에 둔다.

/// 머신 단위 전역 설정. 관리 폴더가 아니라 배포 형태별 설정 위치에 저장된다.
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
ThemeMode _themeModeByName(String? name) => ThemeMode.values.firstWhere(
  (m) => m.name == name,
  orElse: () => ThemeMode.system,
);

/// 전역 설정을 JSON 파일로 읽고 쓰는 저장소.
///
/// 저장이 한 번 실패하면(읽기 전용 매체·권한 없음) 이후로는 **디스크를 건드리지 않고
/// 인메모리로만 동작**한다. 매번 다시 시도해 봐야 같은 이유로 실패하고, 설정 변경이
/// 잦은 자리(테마·최근 폴더)에서 실패한 I/O를 반복하는 값이 없기 때문이다. 실패
/// 사실은 [saveDisabled]로 드러나 사용자에게 표시된다.
class AppSettingsStore {
  /// [channel]을 주면 그 배포 형태로 동작한다(테스트용). 기본은 이 빌드의 채널.
  AppSettingsStore({DistributionChannel? channel})
    : _channel = channel ?? distributionChannel;

  final DistributionChannel _channel;

  bool _saveDisabled = false;

  /// 저장을 포기한 상태인지(한 번 실패한 뒤로는 계속 참).
  bool get saveDisabled => _saveDisabled;

  /// 설정 파일을 둘 디렉토리. **배포 형태로 갈리는 유일한 자리다.**
  ///
  /// 포터블판은 실행 파일 옆에 두어 압축을 푼 폴더 하나만 들고 다니면 되게 하고,
  /// 설치판은 계정별 앱데이터에 둔다. 앱데이터로 몰래 폴백하지 않는다 — 포터블인데
  /// 설정이 PC에 남으면 조용한 배신이다.
  Future<Directory> settingsDirectory() async => switch (_channel) {
    DistributionChannel.portable => File(Platform.resolvedExecutable).parent,
    DistributionChannel.package => await getApplicationSupportDirectory(),
  };

  Future<File> _settingsFile() async =>
      File(p.join((await settingsDirectory()).path, settingsFileName));

  /// 저장된 설정을 읽는다. 파일이 없거나 읽지 못하면 기본값을 반환한다.
  Future<AppSettings> load() async {
    try {
      final file = await _settingsFile();
      if (!await file.exists()) return const AppSettings();
      final decoded = jsonDecode(await file.readAsString());
      return AppSettings.fromJson(decoded as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  /// 설정을 저장하고 성공 여부를 돌려준다. **예외를 던지지 않는다** — 설정이 남지
  /// 않는 것과 앱이 죽는 것은 다른 문제다.
  Future<bool> save(AppSettings settings) async {
    if (_saveDisabled) return false;
    try {
      final file = await _settingsFile();
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode(settings.toJson()));
      return true;
    } catch (_) {
      _saveDisabled = true;
      return false;
    }
  }
}
