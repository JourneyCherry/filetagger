import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/app.dart';

void main() {
  // 관리 폴더마다 별도 파일의 AppDatabase를 연다(현재 워크스페이스 + 흡수 시 잠깐
  // 여는 하위 워크스페이스). 서로 다른 실행기라 경합이 없으므로, 같은 실행기를
  // 공유할 때만 의미 있는 "다중 인스턴스" 경고를 끈다.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  runApp(const ProviderScope(child: FileTaggerApp()));
}
