/// 콘솔이 낼 언어를 정한다 — **명령이 돌기 전에** 서야 하는 결정이다.
///
/// 명령 설명과 옵션 도움말은 표면을 **세울 때** 파서에 박히므로, 언어는 파싱보다
/// 먼저 정해져야 한다. 그래서 `--lang`을 파서에 맡기지 않고 인자를 미리 훑어 읽는다
/// — 옵션을 표면에 **등록도 하는** 것은 사용법에 보이고 파서가 모르는 옵션이라고
/// 거절하지 않게 하려는 것이지, 값을 거기서 받으려는 것이 아니다.
///
/// 우선순위는 넷이다: **명령줄 옵션 > 계정별 설정 > 전역 설정 > OS 로케일.**
library;

import 'dart:io';

import '../data/settings/console_settings_store.dart';
import '../l10n/console_strings.dart';

/// 언어를 정하는 옵션 이름.
const String optLang = 'lang';

/// 고른 언어가 어디서 왔는지.
enum ConsoleLanguageSource {
  /// 명령줄에 직접 적었다.
  option,

  /// OS 계정별 설정에 적혀 있다.
  user,

  /// 실행 파일 옆 전역 설정에 적혀 있다.
  global,

  /// 아무 데도 적히지 않아 OS 설정을 따랐다.
  system,
}

/// 정해진 언어와 그것이 온 자리.
class ConsoleLanguage {
  const ConsoleLanguage({
    required this.strings,
    required this.source,
    required this.raw,
  });

  /// 그 언어의 문구. 표를 갖지 않은 언어면 템플릿 언어로 눕은 뒤다.
  final ConsoleStrings strings;

  /// 어느 자리가 이겼는지.
  final ConsoleLanguageSource source;

  /// 그 자리에 적혀 있던 값. 눕기 전의 원문이다.
  final String raw;

  /// 적힌 값을 낼 문구가 없어 템플릿 언어로 누웠는지.
  bool get fellBack => consoleLanguageOf(raw) != strings.languageCode;
}

/// 우선순위를 밟아 언어를 정한다.
///
/// [option]은 명령줄에서 미리 훑어 읽은 값이고, [store]는 두 범위의 설정,
/// [systemLocaleName]은 마지막 폴백(기본은 OS가 알린 로케일)이다.
ConsoleLanguage resolveConsoleLanguage({
  String? option,
  ConsoleSettingsStore? store,
  String? systemLocaleName,
}) {
  final settings = store ?? ConsoleSettingsStore();
  final candidates = <ConsoleLanguageSource, String?>{
    ConsoleLanguageSource.option: option,
    ConsoleLanguageSource.user: settings
        .load(ConsoleSettingsScope.user)
        .languageCode,
    ConsoleLanguageSource.global: settings
        .load(ConsoleSettingsScope.global)
        .languageCode,
    ConsoleLanguageSource.system: systemLocaleName ?? Platform.localeName,
  };
  for (final entry in candidates.entries) {
    final raw = entry.value;
    if (raw == null || raw.isEmpty) continue;
    return ConsoleLanguage(
      strings: consoleStringsFor(raw),
      source: entry.key,
      raw: raw,
    );
  }
  // OS조차 로케일을 알리지 않는 자리가 있다(환경이 비어 있는 서비스 계정 등).
  return ConsoleLanguage(
    strings: consoleStringsFor(consoleTemplateLanguageCode),
    source: ConsoleLanguageSource.system,
    raw: consoleTemplateLanguageCode,
  );
}

/// 인자에서 `--lang`의 값을 미리 훑어 읽는다. 없으면 null.
///
/// `--lang xx`와 `--lang=xx` 두 꼴을 받고, 옵션의 끝을 알리는 `--`를 만나면 멈춘다.
/// **자리를 가리지 않는다** — 잎 명령에도 붙는 옵션이라 하위 명령 뒤에 올 수 있고,
/// 자리가 잘못됐다면 뒤이어 도는 파서가 제 몫으로 거절한다.
String? languageOptionIn(List<String> args) {
  const prefix = '--$optLang';
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--') return null;
    if (arg == prefix) {
      final next = i + 1;
      return next < args.length ? args[next] : null;
    }
    if (arg.startsWith('$prefix=')) return arg.substring(prefix.length + 1);
  }
  return null;
}
