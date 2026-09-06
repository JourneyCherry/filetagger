/// 콘솔 도구의 설정을 **범위마다 파일 하나**로 읽고 쓴다.
///
/// **자리는 실행 파일 옆이다**(포터블 GUI와 같다). 이 도구는 PATH에 걸어 두고 부르는
/// 것이라, OS마다 다르고 사용자가 찾아가기 어려운 자리를 둘 값이 없다. GUI와 담는
/// 것도 겹치지 않는다.
///
/// **범위를 한 파일에 겹쳐 담지 않고 파일로 가른다.** 설치판(MSIX 등)에서는 설치
/// 폴더가 읽기 전용이라 계정별 설정만 쓸 수 있는 자리로 **옮겨 가야 하는데**, 한
/// 파일에 겹쳐 두면 그때 파일 하나가 두 자리에 있어야 한다. 갈라 두면 옮기는 것은
/// 계정별 파일 하나뿐이고 파일 안의 모양은 배포 형태와 무관하게 같다.
/// 덤으로 한 파일을 여럿이 나눠 쓰지 않게 되어, 한 자리를 고치며 남의 것을 다시
/// 적을 일도 없다.
///
/// **동기로 읽고 쓴다.** 언어는 명령 표면을 세우기 **전에** 정해져야 하는데, 표면을
/// 세우는 것은 러너를 짓는 동기 코드다. 파일 하나를 읽는 일이라 기다릴 것도 없다.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/constants.dart';

/// 설정이 놓이는 두 자리. **뒤가 앞을 덮는다**(계정별이 전역을 이긴다).
enum ConsoleSettingsScope {
  /// 이 기계에서 이 바이너리를 부르는 모두에게 걸리는 값.
  global,

  /// 지금 OS 계정에만 걸리는 값.
  user,
}

/// 콘솔 설정 한 벌. 파일 하나가 이것 하나를 담는다.
///
/// 값이 **부재**인 것과 비어 있는 것을 가른다 — 부재는 "이 범위는 정하지 않았다"는
/// 뜻이라 아래 범위(또는 환경)로 넘어간다.
class ConsoleSettings {
  const ConsoleSettings({this.languageCode, this.workspacePath});

  /// 콘솔이 낼 언어. null이면 이 범위에서 정하지 않은 것이다.
  final String? languageCode;

  /// 관리 폴더를 주지 않은 명령이 볼 폴더. null이면 이 범위에서 정하지 않은 것이다.
  final String? workspacePath;

  /// 정해진 것이 하나도 없는지. 참이면 파일을 남길 이유가 없다.
  bool get isEmpty => languageCode == null && workspacePath == null;

  ConsoleSettings copyWith({
    String? languageCode,
    bool clearLanguage = false,
    String? workspacePath,
    bool clearWorkspace = false,
  }) => ConsoleSettings(
    languageCode: clearLanguage ? null : (languageCode ?? this.languageCode),
    workspacePath: clearWorkspace
        ? null
        : (workspacePath ?? this.workspacePath),
  );

  Map<String, dynamic> toJson() => {
    if (languageCode != null) keyLanguage: languageCode,
    if (workspacePath != null) keyWorkspace: workspacePath,
  };

  /// 저장된 것을 되돌린다. **뜻이 서지 않는 값은 부재로 눕힌다** — 손으로 고치다
  /// 깨진 한 줄 때문에 명령이 서지 못하면 고칠 길이 콘솔 밖에만 남는다.
  factory ConsoleSettings.fromJson(Object? raw) {
    if (raw is! Map) return const ConsoleSettings();
    return ConsoleSettings(
      languageCode: _text(raw[keyLanguage]),
      workspacePath: _text(raw[keyWorkspace]),
    );
  }

  static String? _text(Object? value) =>
      (value is String && value.isNotEmpty) ? value : null;

  /// 설정 파일에 적히는 키. 사람이 열어 고치는 파일이라 이름이 곧 계약이다.
  ///
  /// **이름을 명령줄 옵션과 맞춘다** — 무엇의 기본값인지 이름만 보고 알 수 있게.
  static const String keyLanguage = 'lang';
  static const String keyWorkspace = 'workspace';

  /// 콘솔이 다루는 설정 키 전부. `config`가 모르는 키를 걸러 내는 데 쓴다.
  static const List<String> keys = [keyLanguage, keyWorkspace];
}

/// 범위별 설정 파일을 읽고 쓴다.
class ConsoleSettingsStore {
  /// [directory]를 주면 그 자리의 파일을 쓴다(테스트용). 기본은 실행 파일 옆이다.
  /// [accountName]·[environment]는 계정을 무엇으로 부를지 갈아 끼우는 자리다.
  ConsoleSettingsStore({
    Directory? directory,
    String? accountName,
    Map<String, String>? environment,
  }) : _directory = directory ?? File(Platform.resolvedExecutable).parent,
       accountName =
           accountName ?? currentAccountName(environment: environment);

  final Directory _directory;

  /// 지금 OS 계정의 이름. 알 수 없으면 null이고, 그때는 계정별 범위가 서지 않는다.
  final String? accountName;

  /// [scope]의 설정 파일. 계정을 모르면 계정별 파일은 지을 수 없어 null이다.
  File? fileOf(ConsoleSettingsScope scope) {
    final name = switch (scope) {
      ConsoleSettingsScope.global => consoleSettingsFileName,
      ConsoleSettingsScope.user =>
        accountName == null
            ? null
            : consoleAccountSettingsFileName(accountName!),
    };
    return name == null ? null : File(p.join(_directory.path, name));
  }

  /// [scope]에 적힌 설정. 파일이 없거나 읽지 못하면 빈 설정이다.
  ConsoleSettings load(ConsoleSettingsScope scope) {
    final file = fileOf(scope);
    if (file == null) return const ConsoleSettings();
    try {
      if (!file.existsSync()) return const ConsoleSettings();
      return ConsoleSettings.fromJson(jsonDecode(file.readAsStringSync()));
    } catch (_) {
      return const ConsoleSettings();
    }
  }

  /// [scope]에 설정을 적고 성공 여부를 돌려준다. **예외를 던지지 않는다** — 적지
  /// 못한 것은 명령 하나의 판정이지 프로세스가 죽을 일이 아니다.
  ///
  /// 정해진 것이 하나도 남지 않으면 파일을 **지운다**. 빈 껍데기만 남은 파일은
  /// "여기서 무언가를 정했다"고 오해하게 만든다.
  bool save(ConsoleSettingsScope scope, ConsoleSettings settings) {
    final file = fileOf(scope);
    if (file == null) return false;
    try {
      if (settings.isEmpty) {
        if (file.existsSync()) file.deleteSync();
        return true;
      }
      file.parent.createSync(recursive: true);
      // 사람이 열어 고치는 파일이라 들여쓰기해 쓴다.
      file.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(settings.toJson()),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// 지금 OS 계정의 이름. 환경이 알려 주지 않거나 파일 이름에 넣을 수 없으면 null이다.
///
/// 계정을 가리키는 데 이름을 쓰는 것은, 진짜 계정 식별자(SID·uid)를 얻으려면 네이티브
/// 호출이 필요한데 **한 기계 안에서는 이름도 유일**하기 때문이다 — 이 파일들이
/// 놓이는 범위가 그 기계 하나다.
String? currentAccountName({Map<String, String>? environment}) {
  final env = environment ?? Platform.environment;
  for (final name in const ['USERNAME', 'USER', 'LOGNAME']) {
    final value = env[name];
    if (value == null || value.isEmpty) continue;
    // 이름이 곧 파일 이름의 일부가 되므로, 자리를 옮길 수 있는 이름은 받지 않는다.
    if (value == '.' || value == '..') continue;
    if (value.contains('/') || value.contains(r'\')) continue;
    return value;
  }
  return null;
}
