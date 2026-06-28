import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

class FileTaggerApp extends StatelessWidget {
  const FileTaggerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Tagger',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
