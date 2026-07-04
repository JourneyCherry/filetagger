import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 최근 연 관리 폴더 목록(최신이 앞).
///
/// TODO(installer): 현재는 **세션 메모리로만** 유지한다. 영속화는 인스톨러
/// 도입 후 설치 디렉토리에 저장하는 방식으로 재구현할 예정이라, 그때까지 OS
/// 앱데이터에 쓰지 않는다. 영속화 구현 참고본은 `data/settings/
/// app_settings_store.dart`에 남겨 두었다(현재 미배선).
final recentFoldersProvider =
    AsyncNotifierProvider<RecentFoldersNotifier, List<String>>(
  RecentFoldersNotifier.new,
);

class RecentFoldersNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async => const [];

  /// 폴더를 최근 목록 맨 앞으로 올린다(중복 제거).
  Future<void> touch(String folderPath) async {
    final current = state.valueOrNull ?? const <String>[];
    state = AsyncData([
      folderPath,
      ...current.where((path) => path != folderPath),
    ]);
  }

  /// 폴더를 최근 목록에서 제거한다.
  Future<void> remove(String folderPath) async {
    final current = state.valueOrNull ?? const <String>[];
    state = AsyncData(current.where((path) => path != folderPath).toList());
  }
}
