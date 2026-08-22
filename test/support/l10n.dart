/// 테스트가 쓰는 번역본. 화면을 세우지 않는 테스트도 이름·문구를 필요로 하므로
/// 위젯 트리 없이 곧바로 얻는 길을 둔다.
///
/// 기본은 원문(템플릿) 로케일이다. 번역이 빠진 키는 원문으로 되돌아가므로, 로케일을
/// 바꿔 가며 도는 테스트는 **누락된 번역을 잡지 못한다** — 그 검사는 문구가 서로
/// 다른지를 함께 보는 쪽이 맡는다.
library;

import 'package:filetagger/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// 원문(한국어) 번역본.
AppLocalizations get koL10n => lookupAppLocalizations(const Locale('ko'));

/// 지원하는 모든 로케일의 번역본(언어를 가리지 않는 검사용).
List<AppLocalizations> get allL10n => [
  for (final locale in AppLocalizations.supportedLocales)
    lookupAppLocalizations(locale),
];
