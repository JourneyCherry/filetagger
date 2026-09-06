import 'dart:io';

import 'package:filetagger/cli/console_workspace.dart';
import 'package:filetagger/data/settings/console_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory temp;
  late ConsoleSettingsStore store;
  late String here;

  void write(ConsoleSettingsScope scope, String path) =>
      store.save(scope, ConsoleSettings(workspacePath: path));

  setUp(() {
    temp = Directory.systemTemp.createTempSync('filetagger_cli_workspace');
    store = ConsoleSettingsStore(directory: temp, accountName: 'sunny');
    here = p.join(temp.path, '부른자리');
  });

  tearDown(() => temp.deleteSync(recursive: true));

  test('아무 데도 적히지 않으면 명령을 부른 자리를 본다', () {
    final resolved = resolveConsoleWorkspace(
      store: store,
      currentDirectory: here,
    );

    expect(resolved.source, ConsoleWorkspaceSource.currentDirectory);
    expect(resolved.path, here);
  });

  test('전역에 적어 두면 부른 자리 대신 그곳을 본다', () {
    final saved = p.join(temp.path, '그림');
    write(ConsoleSettingsScope.global, saved);

    final resolved = resolveConsoleWorkspace(
      store: store,
      currentDirectory: here,
    );

    expect(resolved.source, ConsoleWorkspaceSource.global);
    expect(resolved.path, saved);
  });

  test('계정별이 전역을 덮는다', () {
    write(ConsoleSettingsScope.global, p.join(temp.path, '모두'));
    final mine = p.join(temp.path, '나만');
    write(ConsoleSettingsScope.user, mine);

    final resolved = resolveConsoleWorkspace(
      store: store,
      currentDirectory: here,
    );

    expect(resolved.source, ConsoleWorkspaceSource.user);
    expect(resolved.path, mine);
  });

  test('명령줄에 적은 것이 설정을 이긴다', () {
    write(ConsoleSettingsScope.user, p.join(temp.path, '설정'));
    final asked = p.join(temp.path, '이번만');

    final resolved = resolveConsoleWorkspace(
      option: asked,
      store: store,
      currentDirectory: here,
    );

    expect(resolved.source, ConsoleWorkspaceSource.option);
    expect(resolved.path, asked);
  });

  test('상대 경로는 부른 자리를 기준으로 편다', () {
    // 손으로 고친 설정 파일에는 상대 경로가 들어올 수 있다.
    write(ConsoleSettingsScope.user, '옆폴더');

    expect(
      resolveConsoleWorkspace(store: store, currentDirectory: here).path,
      p.join(here, '옆폴더'),
    );
    expect(
      resolveConsoleWorkspace(
        option: '옆폴더',
        store: store,
        currentDirectory: here,
      ).path,
      p.join(here, '옆폴더'),
    );
  });

  test('적어 둘 값은 절대 경로로 펴 둔다', () {
    // 어느 자리에서 불러도 같은 폴더를 가리켜야 한다.
    expect(p.isAbsolute(normalizeWorkspacePath('그림')), isTrue);

    final already = p.join(temp.path, '그림');
    expect(normalizeWorkspacePath(already), already);
  });
}
