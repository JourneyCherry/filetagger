/// 명령이 손댈 **관리 폴더**를 정한다.
///
/// 우선순위는 넷이다: **명령줄 옵션 > 계정별 설정 > 전역 설정 > 현재 디렉토리.**
/// 언어와 같은 차례이고 마지막 자리만 다르다 — 아무도 정하지 않았을 때 기댈 곳이
/// 언어는 OS 로케일이고, 관리 폴더는 명령을 부른 자리다.
///
/// **설정에 적힌 값도 절대 경로로 편다.** 설정은 어느 자리에서 불러도 같은 폴더를
/// 가리켜야 하는데, 상대 경로로 남겨 두면 부른 자리마다 다른 곳을 가리킨다.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import '../data/settings/console_settings_store.dart';

/// 고른 관리 폴더가 어디서 왔는지.
enum ConsoleWorkspaceSource {
  /// 명령줄에 직접 적었다.
  option,

  /// OS 계정별 설정에 적혀 있다.
  user,

  /// 실행 파일 옆 전역 설정에 적혀 있다.
  global,

  /// 아무 데도 적히지 않아 명령을 부른 자리를 따랐다.
  currentDirectory,
}

/// 정해진 관리 폴더와 그것이 온 자리.
class ConsoleWorkspace {
  const ConsoleWorkspace({required this.path, required this.source});

  /// 절대 경로로 편 관리 폴더.
  final String path;

  /// 어느 자리가 이겼는지.
  final ConsoleWorkspaceSource source;
}

/// 우선순위를 밟아 관리 폴더를 정한다.
///
/// [option]은 명령줄에서 받은 값, [store]는 두 범위의 설정, [currentDirectory]는
/// 마지막 폴백이자 상대 경로를 푸는 기준(기본은 프로세스의 현재 디렉토리)이다.
ConsoleWorkspace resolveConsoleWorkspace({
  String? option,
  ConsoleSettingsStore? store,
  String? currentDirectory,
}) {
  final settings = store ?? ConsoleSettingsStore();
  final here = currentDirectory ?? Directory.current.path;
  final candidates = <ConsoleWorkspaceSource, String?>{
    ConsoleWorkspaceSource.option: option,
    ConsoleWorkspaceSource.user: settings
        .load(ConsoleSettingsScope.user)
        .workspacePath,
    ConsoleWorkspaceSource.global: settings
        .load(ConsoleSettingsScope.global)
        .workspacePath,
  };
  for (final entry in candidates.entries) {
    final raw = entry.value;
    if (raw == null || raw.isEmpty) continue;
    return ConsoleWorkspace(path: _absolute(raw, here), source: entry.key);
  }
  return ConsoleWorkspace(
    path: _absolute(here, here),
    source: ConsoleWorkspaceSource.currentDirectory,
  );
}

/// 설정에 적어 둘 꼴로 다듬는다 — 적는 자리에서 한 번 펴 두면, 이후 어느 자리에서
/// 불러도 같은 폴더를 가리킨다.
String normalizeWorkspacePath(String raw) =>
    _absolute(raw, Directory.current.path);

String _absolute(String raw, String from) =>
    p.normalize(p.isAbsolute(raw) ? raw : p.join(from, raw));
