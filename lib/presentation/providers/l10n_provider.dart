import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'settings_provider.dart';

/// provider 계산이 쓰는 번역본.
///
/// 위젯 트리 밖(Riverpod 계산 안)에서는 `AppLocalizations.of(context)`를 쓸 수 없다.
/// 그래서 **`MaterialApp`이 하는 것과 같은 결정을 여기서 되풀이한다** — 사용자가 고른
/// 언어가 있으면 그것, 없으면 OS가 알린 언어 목록을 지원 로케일에 맞춰 고른다.
///
/// 표시 언어가 바뀌면 이것을 watch하는 계산(시스템 태그 정의 등)이 함께 다시 돌아,
/// 이미 만들어 둔 이름이 옛 언어로 남아 있지 않게 한다.
final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  final chosen = ref.watch(appLocaleProvider).valueOrNull;
  final locale =
      chosen ??
      basicLocaleListResolution(
        PlatformDispatcher.instance.locales,
        AppLocalizations.supportedLocales,
      );
  return lookupAppLocalizations(locale);
});
