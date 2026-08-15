import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import 'providers/database_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/update_provider.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

/// 종료 전 정리를 기다려 주는 한계. 이 안에 끝나지 않으면 그대로 종료한다.
const Duration _shutdownTimeout = Duration(seconds: 2);

class FileTaggerApp extends ConsumerStatefulWidget {
  const FileTaggerApp({super.key});

  @override
  ConsumerState<FileTaggerApp> createState() => _FileTaggerAppState();
}

class _FileTaggerAppState extends ConsumerState<FileTaggerApp> {
  /// 창 닫기·종료 명령이 들어왔을 때 정리할 틈을 얻는 통로(데스크톱 전용 신호다).
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onExitRequested: _onExitRequested);
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  /// 종료 전에 태그 DB를 닫는다.
  ///
  /// 닫지 않고 프로세스가 사라지면 sqlite의 WAL이 본 DB 파일로 합쳐지지 않은 채
  /// 남는다. **폴더를 통째로 복사·이동하면 태그가 따라간다**는 것이 이 앱의 전제라,
  /// 그 상태로 옮긴 폴더는 마지막 변경을 잃을 수 있다 — 종료는 그 정리를 할 수 있는
  /// 마지막 자리다(워크스페이스를 바꿀 때는 provider가 이미 닫는다).
  ///
  /// 정리가 늦거나 실패해도 **종료를 막지 않는다** — 창이 닫히지 않는 쪽이 훨씬 나쁘다.
  Future<AppExitResponse> _onExitRequested() async {
    try {
      await ref.read(databaseProvider)?.close().timeout(_shutdownTimeout);
    } catch (_) {
      // 종료 중이라 알릴 자리도, 되돌릴 것도 없다.
    }
    return AppExitResponse.exit;
  }

  @override
  Widget build(BuildContext context) {
    // 저장된 선택을 읽는 동안(첫 프레임)엔 시스템 밝기를 따른다.
    final themeMode =
        ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.system;
    // 앱을 켜면 업데이트 확인이 한 번 돈다 — 구독을 여는 것이 곧 실행이다. 셸이
    // 무엇이든(데스크톱/모바일) 확인이 시작되도록 최상위에서 연다. watch가 아니라
    // listen인 것은 확인 결과로 앱 전체를 다시 그리지 않기 위함이며, 결과를 읽는
    // 것은 상태표시줄과 확인 명령의 몫이다.
    ref.listen(updateCheckProvider, (_, _) {});
    return MaterialApp(
      title: appDisplayName,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: themeMode,
      home: const HomeScreen(),
    );
  }
}
