import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings/app_settings_store.dart';

/// 전역 설정 저장소 핸들.
final appSettingsStoreProvider =
    Provider<AppSettingsStore>((ref) => AppSettingsStore());

/// 최근 연 관리 폴더 목록(최신이 앞). 디스크에서 비동기로 로드된다.
final recentFoldersProvider =
    AsyncNotifierProvider<RecentFoldersNotifier, List<String>>(
  RecentFoldersNotifier.new,
);

class RecentFoldersNotifier extends AsyncNotifier<List<String>> {
  AppSettingsStore get _store => ref.read(appSettingsStoreProvider);

  @override
  Future<List<String>> build() async {
    final settings = await _store.load();
    return settings.recentFolders;
  }

  /// 폴더를 최근 목록 맨 앞으로 올린다(중복 제거).
  Future<void> touch(String folderPath) async {
    final current = state.valueOrNull ?? const <String>[];
    final updated = [
      folderPath,
      ...current.where((path) => path != folderPath),
    ];
    await _store.save(AppSettings(recentFolders: updated));
    state = AsyncData(updated);
  }

  /// 폴더를 최근 목록에서 제거한다.
  Future<void> remove(String folderPath) async {
    final current = state.valueOrNull ?? const <String>[];
    final updated = current.where((path) => path != folderPath).toList();
    await _store.save(AppSettings(recentFolders: updated));
    state = AsyncData(updated);
  }
}
