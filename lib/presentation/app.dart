import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

class FileTaggerApp extends ConsumerWidget {
  const FileTaggerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 저장된 선택을 읽는 동안(첫 프레임)엔 시스템 밝기를 따른다.
    final themeMode =
        ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.system;
    return MaterialApp(
      title: 'File Tagger',
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: themeMode,
      home: const HomeScreen(),
    );
  }
}
