import 'package:filetagger/data/settings/app_settings_store.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:filetagger/presentation/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 파일 I/O 없이 메모리에 설정을 담는 가짜 저장소.
class _FakeStore extends AppSettingsStore {
  _FakeStore(this.settings, {this.writable = true});

  AppSettings settings;
  int saveCount = 0;

  /// 거짓이면 저장이 실패하는 매체를 흉내 낸다(읽기 전용·권한 없음).
  final bool writable;

  @override
  Future<AppSettings> load() async => settings;

  @override
  Future<bool> save(AppSettings s) async {
    if (!writable) return false;
    settings = s;
    saveCount++;
    return true;
  }
}

ProviderContainer _containerWith(_FakeStore store) {
  final container = ProviderContainer(
    overrides: [appSettingsStoreProvider.overrideWithValue(store)],
  );
  return container;
}

void main() {
  test('저장된 최근 폴더를 앱 시작 시 불러온다', () async {
    final store = _FakeStore(const AppSettings(recentFolders: ['/a', '/b']));
    final container = _containerWith(store);
    addTearDown(container.dispose);

    final loaded = await container.read(recentFoldersProvider.future);
    expect(loaded, ['/a', '/b']);
  });

  test('touch는 맨 앞으로 올리고 중복을 제거하며 저장한다', () async {
    final store = _FakeStore(const AppSettings(recentFolders: ['/a', '/b']));
    final container = _containerWith(store);
    addTearDown(container.dispose);

    await container.read(recentFoldersProvider.future);
    await container.read(recentFoldersProvider.notifier).touch('/b');

    expect(container.read(recentFoldersProvider).valueOrNull, ['/b', '/a']);
    // 디스크에도 반영된다.
    expect(store.settings.recentFolders, ['/b', '/a']);
    expect(store.saveCount, 1);
  });

  test('remove는 목록에서 지우고 저장한다', () async {
    final store = _FakeStore(const AppSettings(recentFolders: ['/a', '/b']));
    final container = _containerWith(store);
    addTearDown(container.dispose);

    await container.read(recentFoldersProvider.future);
    await container.read(recentFoldersProvider.notifier).remove('/a');

    expect(container.read(recentFoldersProvider).valueOrNull, ['/b']);
    expect(store.settings.recentFolders, ['/b']);
  });

  test('저장이 실패해도 목록은 이번 실행 동안 살아 있고, 실패가 표시된다', () async {
    final store = _FakeStore(const AppSettings(), writable: false);
    final container = _containerWith(store);
    addTearDown(container.dispose);

    await container.read(recentFoldersProvider.future);
    expect(container.read(settingsSaveFailedProvider), isFalse);

    // 저장이 실패해도 예외로 번지지 않는다.
    await container.read(recentFoldersProvider.notifier).touch('/a');

    expect(container.read(recentFoldersProvider).valueOrNull, ['/a']);
    expect(container.read(settingsSaveFailedProvider), isTrue);
  });

  test('테마 저장 실패도 같은 표시를 켠다', () async {
    final store = _FakeStore(const AppSettings(), writable: false);
    final container = _containerWith(store);
    addTearDown(container.dispose);

    await container.read(themeModeProvider.future);
    await container.read(themeModeProvider.notifier).set(ThemeMode.dark);

    expect(container.read(themeModeProvider).valueOrNull, ThemeMode.dark);
    expect(container.read(settingsSaveFailedProvider), isTrue);
  });

  test('목록이 상한을 넘으면 오래된 폴더부터 버린다', () async {
    final store = _FakeStore(const AppSettings());
    final container = _containerWith(store);
    addTearDown(container.dispose);

    await container.read(recentFoldersProvider.future);
    final notifier = container.read(recentFoldersProvider.notifier);
    for (var i = 0; i < 25; i++) {
      await notifier.touch('/folder$i');
    }

    final folders = container.read(recentFoldersProvider).valueOrNull!;
    expect(folders.length, lessThanOrEqualTo(20));
    // 가장 최근에 연 폴더가 맨 앞이다.
    expect(folders.first, '/folder24');
  });
}
