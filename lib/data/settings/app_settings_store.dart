import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants.dart';

// 최근 폴더 목록 영속화에 배선된 저장소. 저장 위치는 `path_provider`(공식
// flutter.dev 패키지)의 앱데이터 폴더(`getApplicationSupportDirectory`)로, 데스크톱
// 3종을 모두 지원한다. 포터블 배포 시 실행 파일 옆 저장 분기는 인스톨러 도입과
// 함께 검토한다(백로그).

/// 머신 단위 전역 설정. 관리 폴더가 아니라 OS 앱데이터 폴더에 저장된다.
class AppSettings {
  const AppSettings({this.recentFolders = const []});

  /// 최근 연 관리 폴더 경로 목록(최신이 앞).
  final List<String> recentFolders;

  AppSettings copyWith({List<String>? recentFolders}) =>
      AppSettings(recentFolders: recentFolders ?? this.recentFolders);

  Map<String, dynamic> toJson() => {'recentFolders': recentFolders};

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    recentFolders: (json['recentFolders'] as List?)?.cast<String>() ?? const [],
  );
}

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
