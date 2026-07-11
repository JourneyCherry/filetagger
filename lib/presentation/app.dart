import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme.dart';

class FileTaggerApp extends StatelessWidget {
  const FileTaggerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Tagger',
      theme: buildAppTheme(),
      home: const HomeScreen(),
    );
  }
}
