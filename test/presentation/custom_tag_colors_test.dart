import 'package:filetagger/data/settings/app_settings_store.dart';
import 'package:filetagger/presentation/providers/settings_provider.dart';
import 'package:filetagger/presentation/tag_visuals.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 파일 I/O 없이 메모리에 설정을 담는 가짜 저장소.
class _FakeStore extends AppSettingsStore {
  _FakeStore(this.settings, {this.writable = true});

  AppSettings settings;

  /// 거짓이면 저장이 실패하는 매체를 흉내 낸다(읽기 전용·권한 없음).
  final bool writable;

  @override
  Future<AppSettings> load() async => settings;

  @override
  Future<bool> save(AppSettings s) async {
    if (!writable) return false;
    settings = s;
    return true;
  }
}

ProviderContainer _containerWith(_FakeStore store) => ProviderContainer(
  overrides: [appSettingsStoreProvider.overrideWithValue(store)],
);

/// 팔레트에 없는 것이 확실한 색들(거의 검정에 가까운 파랑 계열).
int _unlistedColor(int seed) => 0xFF000000 | seed;

void main() {
  test('저장된 색 목록을 앱 시작 시 불러온다', () async {
    final store = _FakeStore(
      const AppSettings(customTagColors: [0xFF102030, 0xFF405060]),
    );
    final container = _containerWith(store);
    addTearDown(container.dispose);

    final loaded = await container.read(customTagColorsProvider.future);
    expect(loaded, [0xFF102030, 0xFF405060]);
  });

  test('touch는 맨 앞으로 올리고 중복을 제거하며 저장한다', () async {
    final store = _FakeStore(
      const AppSettings(customTagColors: [0xFF102030, 0xFF405060]),
    );
    final container = _containerWith(store);
    addTearDown(container.dispose);

    await container.read(customTagColorsProvider.future);
    await container.read(customTagColorsProvider.notifier).touch(0xFF405060);

    expect(container.read(customTagColorsProvider).valueOrNull, [
      0xFF405060,
      0xFF102030,
    ]);
    // 디스크에도 반영된다.
    expect(store.settings.customTagColors, [0xFF405060, 0xFF102030]);
  });

  test('프리셋 팔레트에 이미 있는 색은 담지 않는다', () async {
    final store = _FakeStore(const AppSettings());
    final container = _containerWith(store);
    addTearDown(container.dispose);

    await container.read(customTagColorsProvider.future);
    await container
        .read(customTagColorsProvider.notifier)
        .touch(tagColorPalette.first);

    // 같은 스와치가 두 벌로 보이기만 하므로 목록이 그대로다.
    expect(container.read(customTagColorsProvider).valueOrNull, isEmpty);
    expect(store.settings.customTagColors, isEmpty);
  });

  test('목록이 상한을 넘으면 오래전에 고른 색부터 버린다', () async {
    final store = _FakeStore(const AppSettings());
    final container = _containerWith(store);
    addTearDown(container.dispose);

    await container.read(customTagColorsProvider.future);
    final notifier = container.read(customTagColorsProvider.notifier);
    const picks = 30;
    for (var i = 1; i <= picks; i++) {
      await notifier.touch(_unlistedColor(i));
    }

    final colors = container.read(customTagColorsProvider).valueOrNull!;
    expect(colors.length, lessThan(picks));
    // 가장 최근에 고른 색이 맨 앞이고, 가장 먼저 고른 색은 밀려났다.
    expect(colors.first, _unlistedColor(picks));
    expect(colors, isNot(contains(_unlistedColor(1))));
  });

  test('저장이 실패해도 목록은 이번 실행 동안 살아 있고, 실패가 표시된다', () async {
    final store = _FakeStore(const AppSettings(), writable: false);
    final container = _containerWith(store);
    addTearDown(container.dispose);

    await container.read(customTagColorsProvider.future);
    await container.read(customTagColorsProvider.notifier).touch(0xFF102030);

    expect(container.read(customTagColorsProvider).valueOrNull, [0xFF102030]);
    expect(container.read(settingsSaveFailedProvider), isTrue);
  });
}
