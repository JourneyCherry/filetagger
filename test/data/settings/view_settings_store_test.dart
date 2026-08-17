import 'dart:convert';
import 'dart:io';

import 'package:filetagger/core/constants.dart';
import 'package:filetagger/data/settings/view_settings_store.dart';
import 'package:filetagger/domain/entities/view_mode.dart';
import 'package:filetagger/domain/entities/workspace_view_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('viewsettings'));
  tearDown(() => root.deleteSync(recursive: true));

  File settingsFile() =>
      File(p.join(root.path, filetaggerDirName, viewSettingsFileName));

  test('저장한 설정을 그대로 다시 읽는다', () async {
    final store = JsonViewSettingsStore(root.path);
    await store.save(
      const WorkspaceViewSettings(
        viewMode: ViewMode.icon,
        nameSources: [7, 3],
        subtitleSources: [2, 9],
      ),
    );
    final loaded = await JsonViewSettingsStore(root.path).load();
    expect(loaded.viewMode, ViewMode.icon);
    expect(loaded.nameSources, [7, 3]);
    // 이름과 따로 저장된다(둘이 섞이면 한쪽을 고칠 때 다른 쪽이 따라 바뀐다).
    expect(loaded.subtitleSources, [2, 9]);
  });

  test('파일이 없으면 기본값', () async {
    expect(
      await JsonViewSettingsStore(root.path).load(),
      isA<WorkspaceViewSettings>().having(
        (s) => s.viewMode,
        'viewMode',
        ViewMode.list,
      ),
    );
  });

  test('연달아 저장하면 마지막 값만 남고 파일이 섞이지 않는다', () async {
    final store = JsonViewSettingsStore(root.path);
    // zoom 휠처럼 쓰기가 끝나기 전에 다음 값이 몰려 드는 상황.
    final saves = [
      for (final mode in ViewMode.values)
        store.save(WorkspaceViewSettings(viewMode: mode)),
    ];
    await Future.wait(saves);

    final decoded =
        jsonDecode(await settingsFile().readAsString()) as Map<String, dynamic>;
    expect(decoded['viewMode'], ViewMode.values.last.name);
    expect((await store.load()).viewMode, ViewMode.values.last);
  });
}
