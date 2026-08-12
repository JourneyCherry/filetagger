import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import 'providers/settings_provider.dart';
import 'providers/update_provider.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

class FileTaggerApp extends ConsumerWidget {
  const FileTaggerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
