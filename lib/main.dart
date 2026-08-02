import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart'
    show LicenseEntry, LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart' show runApp;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'presentation/app.dart';

void main() {
  // 관리 폴더마다 별도 파일의 AppDatabase를 연다(현재 워크스페이스 + 흡수 시 잠깐
  // 여는 하위 워크스페이스). 서로 다른 실행기라 경합이 없으므로, 같은 실행기를
  // 공유할 때만 의미 있는 "다중 인스턴스" 경고를 끈다.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  LicenseRegistry.addLicense(_appLicense);
  runApp(const ProviderScope(child: FileTaggerApp()));
}

/// 앱 자신의 라이선스를 라이선스 목록에 얹는다. 의존 패키지의 것은 빌드가 모아
/// 주지만 앱 자신의 것은 실리지 않는다. 목록을 열 때 비로소 읽히는 지연 생성자다.
Stream<LicenseEntry> _appLicense() async* {
  yield LicenseEntryWithLineBreaks([
    appDisplayName,
  ], await rootBundle.loadString(appLicenseAssetPath));
}
