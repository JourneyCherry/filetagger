import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings/app_settings_store.dart';
import '../tag_visuals.dart';

/// 머신 단위 전역 설정 저장소(배포 형태별 위치의 JSON).
final appSettingsStoreProvider = Provider<AppSettingsStore>(
  (ref) => AppSettingsStore(),
);

/// 전역 설정이 디스크에 남지 않고 인메모리로만 도는 중인지.
///
/// 저장소가 한 번 실패하면 재시도를 멈추므로 이 실행 동안 계속 참으로 남는다.
/// 상태표시줄이 이것을 보고 사용자에게 알린다 — 조용히 삼키면 최근 폴더가 안 남는
/// 이유를 알 수 없다.
final settingsSaveFailedProvider =
    NotifierProvider<SettingsSaveFailedNotifier, bool>(
      SettingsSaveFailedNotifier.new,
    );

class SettingsSaveFailedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void markFailed() => state = true;
}

/// 저장된 설정 위에 변경을 얹어 다시 저장한다.
///
/// 저장 직전 현재 설정을 다시 읽는 것은 같은 파일을 나눠 쓰는 다른 설정(테마·최근
/// 폴더)을 덮지 않기 위해서다. 실패는 예외로 번지지 않고 [settingsSaveFailedProvider]를
/// 켠다.
Future<void> _updateSettings(
  Ref ref,
  AppSettings Function(AppSettings) update,
) async {
  final store = ref.read(appSettingsStoreProvider);
  final saved = await store.save(update(await store.load()));
  if (!saved) ref.read(settingsSaveFailedProvider.notifier).markFailed();
}

/// 최근 연 관리 폴더 목록(최신이 앞).
///
/// 배포 형태별 설정 위치에 영속화된다(저장소는 [appSettingsStoreProvider]). 앱을
/// 켜면 저장된 목록을 불러오고, 폴더를 열거나 지울 때마다 다시 저장한다.
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
    // 화면은 먼저 갱신한다 — 저장에 실패해도 이번 실행 동안은 목록이 살아 있다.
    state = AsyncData(folders);
    await _updateSettings(ref, (s) => s.copyWith(recentFolders: folders));
  }
}

/// 태그 색으로 직접 골라 둔 색 목록(최신이 앞).
///
/// 프리셋 팔레트 옆에 함께 놓여 다음 태그에도 쓰인다. 폴더가 아니라 머신 단위 전역
/// 설정에 영속화되어 **어느 폴더를 열든 같은 목록이 따라온다** — 색 자체는 태그 정의에
/// 담겨 폴더와 함께 이동하므로, 여기 남는 것은 다음에 고르기 쉽게 하는 편집 도구의
/// 상태뿐이다.
final customTagColorsProvider =
    AsyncNotifierProvider<CustomTagColorsNotifier, List<int>>(
      CustomTagColorsNotifier.new,
    );

class CustomTagColorsNotifier extends AsyncNotifier<List<int>> {
  /// 목록에 유지할 최대 색 수. 넘으면 가장 오래전에 고른 것부터 버린다. 스와치가
  /// 팔레트와 나란히 놓이는 자리라 한없이 늘어나면 고르는 일이 되레 어려워진다.
  static const int _maxEntries = 14;

  AppSettingsStore get _store => ref.read(appSettingsStoreProvider);

  @override
  Future<List<int>> build() async => (await _store.load()).customTagColors;

  /// 고른 색을 목록 맨 앞으로 올린다(중복 제거).
  ///
  /// 프리셋 팔레트에 이미 있는 색은 담지 않는다 — 같은 스와치가 두 벌로 보이기만 한다.
  Future<void> touch(int argb) async {
    if (tagColorPalette.contains(argb)) return;
    final current = state.valueOrNull ?? const <int>[];
    final next = [argb, ...current.where((color) => color != argb)];
    await _persist(
      next.length > _maxEntries ? next.sublist(0, _maxEntries) : next,
    );
  }

  Future<void> _persist(List<int> colors) async {
    // 화면은 먼저 갱신한다 — 저장에 실패해도 이번 실행 동안은 목록이 살아 있다.
    state = AsyncData(colors);
    await _updateSettings(ref, (s) => s.copyWith(customTagColors: colors));
  }
}

/// 라이트/다크 테마 선택. 머신 단위 전역 설정으로 [appSettingsStoreProvider]에
/// 영속화된다. 기본값(시스템)은 OS 밝기를 따른다.
final themeModeProvider = AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  AppSettingsStore get _store => ref.read(appSettingsStoreProvider);

  @override
  Future<ThemeMode> build() async => (await _store.load()).themeMode;

  /// 테마 모드를 바꾸고 저장한다. 다른 전역 설정을 덮지 않도록 현재 값 위에 얹는다.
  Future<void> set(ThemeMode mode) async {
    state = AsyncData(mode);
    await _updateSettings(ref, (s) => s.copyWith(themeMode: mode));
  }
}
