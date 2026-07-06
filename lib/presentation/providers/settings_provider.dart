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
    // 저장 실패는 조용히 무시한다(다음 변경 때 다시 시도된다).
    await _store.save(AppSettings(recentFolders: folders));
  }
}
