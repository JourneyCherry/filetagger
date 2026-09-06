import 'dart:convert';
import 'dart:io';

import 'package:filetagger/core/constants.dart';
import 'package:filetagger/data/settings/console_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory temp;
  late ConsoleSettingsStore store;

  ConsoleSettingsStore storeFor(String account) =>
      ConsoleSettingsStore(directory: temp, accountName: account);

  setUp(() {
    temp = Directory.systemTemp.createTempSync('filetagger_cli_settings');
    store = storeFor('sunny');
  });

  tearDown(() => temp.deleteSync(recursive: true));

  test('범위마다 파일이 따로 있고 둘 다 실행 파일 옆이다', () {
    final global = store.fileOf(ConsoleSettingsScope.global)!;
    final user = store.fileOf(ConsoleSettingsScope.user)!;

    // 설치판에서 계정별만 쓸 수 있는 자리로 옮겨 가려면 파일이 갈라져 있어야 한다.
    expect(global.path, isNot(user.path));
    expect(p.dirname(global.path), temp.path);
    expect(p.dirname(user.path), temp.path);
    expect(p.basename(global.path), consoleSettingsFileName);
    // 한 폴더를 여러 계정이 나눠 쓰므로 계정별 파일은 이름으로 갈린다.
    expect(p.basename(user.path), contains('sunny'));
  });

  test('적은 것이 없으면 빈 설정이다', () {
    expect(store.load(ConsoleSettingsScope.global).languageCode, isNull);
    expect(store.load(ConsoleSettingsScope.user).languageCode, isNull);
  });

  test('적은 것을 그대로 되읽는다', () {
    expect(
      store.save(
        ConsoleSettingsScope.user,
        const ConsoleSettings(languageCode: 'en'),
      ),
      isTrue,
    );

    expect(store.load(ConsoleSettingsScope.user).languageCode, 'en');
    // 범위가 다르면 서로를 건드리지 않는다.
    expect(store.load(ConsoleSettingsScope.global).languageCode, isNull);
  });

  test('키가 여럿이어도 한 파일에 함께 담긴다', () {
    final folder = p.join(temp.path, '그림');
    store.save(
      ConsoleSettingsScope.user,
      ConsoleSettings(languageCode: 'en', workspacePath: folder),
    );

    final read = store.load(ConsoleSettingsScope.user);
    expect(read.languageCode, 'en');
    expect(read.workspacePath, folder);
  });

  test('한 키만 정해도 파일은 남는다', () {
    store.save(
      ConsoleSettingsScope.user,
      const ConsoleSettings(workspacePath: '어딘가'),
    );

    expect(store.fileOf(ConsoleSettingsScope.user)!.existsSync(), isTrue);
    expect(store.load(ConsoleSettingsScope.user).workspacePath, '어딘가');
  });

  test('파일 안은 설정 이름과 값뿐이다', () {
    store.save(
      ConsoleSettingsScope.global,
      const ConsoleSettings(languageCode: 'ko'),
    );

    // 파일이 곧 범위라 안에 자리를 또 적을 이유가 없다 — 배포 형태가 달라져도
    // 파일 안의 모양은 같다.
    final json =
        jsonDecode(
              store.fileOf(ConsoleSettingsScope.global)!.readAsStringSync(),
            )
            as Map<String, dynamic>;
    expect(json, {ConsoleSettings.keyLanguage: 'ko'});
  });

  test('계정이 다르면 서로의 값을 보지 않는다', () {
    storeFor('sunny').save(
      ConsoleSettingsScope.user,
      const ConsoleSettings(languageCode: 'en'),
    );

    expect(
      storeFor('other').load(ConsoleSettingsScope.user).languageCode,
      isNull,
    );
    expect(
      storeFor('sunny').load(ConsoleSettingsScope.user).languageCode,
      'en',
    );
  });

  test('한 자리를 고쳐도 나머지가 남는다', () {
    store.save(
      ConsoleSettingsScope.global,
      const ConsoleSettings(languageCode: 'ko'),
    );
    storeFor('other').save(
      ConsoleSettingsScope.user,
      const ConsoleSettings(languageCode: 'ko'),
    );

    store.save(
      ConsoleSettingsScope.user,
      const ConsoleSettings(languageCode: 'en'),
    );

    expect(store.load(ConsoleSettingsScope.global).languageCode, 'ko');
    expect(
      storeFor('other').load(ConsoleSettingsScope.user).languageCode,
      'ko',
    );
    expect(store.load(ConsoleSettingsScope.user).languageCode, 'en');
  });

  test('정해진 것이 하나도 없으면 그 파일을 지운다', () {
    store.save(
      ConsoleSettingsScope.global,
      const ConsoleSettings(languageCode: 'en'),
    );
    final file = store.fileOf(ConsoleSettingsScope.global)!;
    expect(file.existsSync(), isTrue);

    store.save(ConsoleSettingsScope.global, const ConsoleSettings());

    // 빈 껍데기만 남은 파일은 "여기서 무언가를 정했다"고 오해하게 만든다.
    expect(file.existsSync(), isFalse);
  });

  test('한 범위를 비워도 다른 범위의 파일은 남는다', () {
    store
      ..save(
        ConsoleSettingsScope.global,
        const ConsoleSettings(languageCode: 'ko'),
      )
      ..save(
        ConsoleSettingsScope.user,
        const ConsoleSettings(languageCode: 'en'),
      )
      ..save(ConsoleSettingsScope.user, const ConsoleSettings());

    expect(store.fileOf(ConsoleSettingsScope.user)!.existsSync(), isFalse);
    expect(store.load(ConsoleSettingsScope.global).languageCode, 'ko');
  });

  test('깨진 파일은 빈 설정으로 눕는다', () {
    store
        .fileOf(ConsoleSettingsScope.global)!
        .writeAsStringSync('{ 이건 JSON이 아니다');

    // 손으로 고치다 깨진 한 줄 때문에 명령이 서지 못하면 고칠 길이 콘솔 밖에만 남는다.
    expect(store.load(ConsoleSettingsScope.global).languageCode, isNull);
  });

  test('뜻이 서지 않는 값은 부재로 눕는다', () {
    store
        .fileOf(ConsoleSettingsScope.global)!
        .writeAsStringSync(
          jsonEncode({
            ConsoleSettings.keyLanguage: 3,
            ConsoleSettings.keyWorkspace: '',
          }),
        );

    final read = store.load(ConsoleSettingsScope.global);
    expect(read.languageCode, isNull);
    expect(read.workspacePath, isNull);
  });

  group('계정 이름', () {
    test('환경이 알려 주는 이름을 쓴다', () {
      expect(currentAccountName(environment: {'USERNAME': 'sunny'}), 'sunny');
      expect(currentAccountName(environment: {'USER': 'sunny'}), 'sunny');
      expect(currentAccountName(environment: {'LOGNAME': 'sunny'}), 'sunny');
    });

    test('환경이 비어 있으면 계정을 모른다', () {
      expect(currentAccountName(environment: const {}), isNull);
    });

    test('파일 자리를 옮길 수 있는 이름은 받지 않는다', () {
      // 이름이 곧 파일 이름의 일부가 된다.
      for (final bad in ['..', '.', 'a/b', r'a\b']) {
        expect(
          currentAccountName(environment: {'USER': bad}),
          isNull,
          reason: bad,
        );
      }
    });

    test('계정을 모르면 계정별 범위가 서지 않는다', () {
      // 환경이 이름을 알려 주지 않는 실행(빈 환경으로 뜬 서비스 계정 등).
      final blind = ConsoleSettingsStore(
        directory: temp,
        environment: const {},
      );

      expect(blind.accountName, isNull);
      expect(blind.fileOf(ConsoleSettingsScope.user), isNull);
      expect(blind.load(ConsoleSettingsScope.user).languageCode, isNull);
      expect(
        blind.save(
          ConsoleSettingsScope.user,
          const ConsoleSettings(languageCode: 'en'),
        ),
        isFalse,
      );
      // 전역은 계정과 무관하므로 그대로 선다.
      expect(
        blind.save(
          ConsoleSettingsScope.global,
          const ConsoleSettings(languageCode: 'en'),
        ),
        isTrue,
      );
    });
  });
}
