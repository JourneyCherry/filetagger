import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart'
    show LicenseEntry, LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding, runApp;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'data/platform/platform_app_version.dart';
import 'presentation/app.dart';

Future<void> main() async {
  // 플랫폼 메타데이터를 읽으려면 바인딩이 먼저 서 있어야 한다.
  WidgetsFlutterBinding.ensureInitialized();

  // 관리 폴더마다 별도 파일의 AppDatabase를 연다(현재 워크스페이스 + 흡수 시 잠깐
  // 여는 하위 워크스페이스). 서로 다른 실행기라 경합이 없으므로, 같은 실행기를
  // 공유할 때만 의미 있는 "다중 인스턴스" 경고를 끈다.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  LicenseRegistry.addLicense(_appLicense);

  // 빌드가 버전을 새겨 주지 않았으면 플랫폼 메타데이터에서 읽는다. 첫 프레임 전에
  // 끝내야 정보 창과 업데이트 확인이 처음부터 온전한 버전을 본다.
  await loadPlatformAppVersion();

  runApp(const ProviderScope(child: FileTaggerApp()));
}

/// 앱 자신의 라이선스를 라이선스 목록에 얹는다. 의존 패키지의 것은 빌드가 모아
/// 주지만 앱 자신의 것은 실리지 않는다. 목록을 열 때 비로소 읽히는 지연 생성자다.
Stream<LicenseEntry> _appLicense() async* {
  yield LicenseEntryWithLineBreaks([
    appDisplayName,
  ], await rootBundle.loadString(appLicenseAssetPath));
}
