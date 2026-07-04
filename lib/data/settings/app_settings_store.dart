import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants.dart';

// NOTE(installer): 이 파일은 현재 앱에 배선되어 있지 않다(참고 구현). 최근 폴더
// 영속화는 인스톨러 도입 후 설치 디렉토리 저장 방식으로 재구현 예정이며, 그
// 전까지 recentFoldersProvider는 세션 메모리로만 동작한다. 직렬화 로직은 테스트로
// 계속 검증된다.

/// 머신 단위 전역 설정. 관리 폴더가 아니라 OS 앱데이터 폴더에 저장된다.
class AppSettings {
  const AppSettings({this.recentFolders = const []});

  /// 최근 연 관리 폴더 경로 목록(최신이 앞).
  final List<String> recentFolders;

  AppSettings copyWith({List<String>? recentFolders}) =>
      AppSettings(recentFolders: recentFolders ?? this.recentFolders);

  Map<String, dynamic> toJson() => {'recentFolders': recentFolders};

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        recentFolders:
            (json['recentFolders'] as List?)?.cast<String>() ?? const [],
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
