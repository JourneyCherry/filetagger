import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings/app_settings_store.dart';

/// 머신 단위 전역 설정 저장소(OS 앱데이터 폴더의 JSON).
final appSettingsStoreProvider = Provider<AppSettingsStore>(
  (ref) => AppSettingsStore(),
);

/// 최근 연 관리 폴더 목록(최신이 앞).
///
/// OS 앱데이터 폴더에 영속화된다(저장소는 [appSettingsStoreProvider]). 앱을 켜면
/// 저장된 목록을 불러오고, 폴더를 열거나 지울 때마다 다시 저장한다.
final recentFoldersProvider =
    AsyncNotifierProvider<RecentFoldersNotifier, List<String>>(
      RecentFoldersNotifier.new,
    );

class RecentFoldersNotifier extends AsyncNotifier<List<String>> {
  /// 최근 목록에 유지할 최대 폴더 수. 넘으면 가장 오래된 것부터 버린다.
  static const int _maxEntries = 20;

  AppSettingsStore get _store => ref.read(appSettingsStoreProvider);

  @override
  Future<List<String>> build() async {
    final settings = await _store.load();
    return settings.recentFolders;
  }

  /// 폴더를 최근 목록 맨 앞으로 올린다(중복 제거).
  Future<void> touch(String folderPath) async {
    final current = state.valueOrNull ?? const <String>[];
    final next = [folderPath, ...current.where((path) => path != folderPath)];
    await _persist(
      next.length > _maxEntries ? next.sublist(0, _maxEntries) : next,
    );
  }

  /// 폴더를 최근 목록에서 제거한다.
  Future<void> remove(String folderPath) async {
    final current = state.valueOrNull ?? const <String>[];
    await _persist(current.where((path) => path != folderPath).toList());
  }

  Future<void> _persist(List<String> folders) async {
    state = AsyncData(folders);
    // 저장 실패는 조용히 무시한다(다음 변경 때 다시 시도된다). 저장 직전 현재 설정을
    // 다시 읽어 그 위에 얹는다 — 같은 파일을 나눠 쓰는 다른 설정(테마 등)을 덮지 않는다.
    final current = await _store.load();
    await _store.save(current.copyWith(recentFolders: folders));
  }
}

/// 라이트/다크 테마 선택. 머신 단위 전역 설정으로 [appSettingsStoreProvider]에
/// 영속화된다. 기본값(시스템)은 OS 밝기를 따른다.
final themeModeProvider =
    AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  AppSettingsStore get _store => ref.read(appSettingsStoreProvider);

  @override
  Future<ThemeMode> build() async => (await _store.load()).themeMode;

  /// 테마 모드를 바꾸고 저장한다. 다른 전역 설정을 덮지 않도록 현재 값 위에 얹는다.
  Future<void> set(ThemeMode mode) async {
    state = AsyncData(mode);
    final current = await _store.load();
    await _store.save(current.copyWith(themeMode: mode));
  }
}
