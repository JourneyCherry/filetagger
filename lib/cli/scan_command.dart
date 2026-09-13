/// `scan` — 관리 폴더를 훑어 인덱스를 맞춘다.
///
/// **콘솔에서 전체 스캔이 도는 자리는 여기 하나뿐이다.** 다른 명령은 몰래 훑지 않고,
/// 인덱스가 모르는 대상을 만나면 그렇게 보고하고 끝낸다(보류) — 태그 한 줄을 붙이려고
/// 폴더 전체를 훑는 것은 명령 한 번의 값이 아니고, 스크립트가 언제 훑을지는 스크립트가
/// 정할 일이다.
library;

import 'dart:io';

import '../data/repositories/drift_file_node_repository.dart';
import '../data/scanner/directory_scanner.dart';
import '../data/scanner/serial_workspace_scan.dart';
import '../data/settings/view_settings_store.dart';
import '../domain/entities/scan_progress.dart';
import '../domain/repositories/workspace_scanner.dart';
import 'cli_command.dart';
import 'cli_output.dart';

class ScanCommand extends CliCommand {
  ScanCommand(super.strings);

  @override
  String get name => 'scan';

  @override
  String get description => strings.scanDescription;

  @override
  String get invocation => '$executableName $name';

  @override
  Future<int> run() async {
    if (rest.isNotEmpty) usageException(strings.takesNoArguments(name));

    return withWorkspace((root, db) async {
      final scan = SerialWorkspaceScan(
        const DirectoryScanner(),
        DriftFileNodeRepository(db),
      );
      final mode = (await JsonViewSettingsStore(root).load()).rootManageMode;
      try {
        final result = await scan(
          root,
          rootManageMode: mode,
          onProgress: _progress,
        );
        _endProgress();

        if (asJson) {
          writeJson({
            _kRoot: root,
            _kNodes: result.nodes.length,
            _kUnreadableDirs: result.unreadableDirs,
            _kNestedWorkspaces: result.nestedFiletaggerDirs,
          });
        } else {
          stdout
            ..writeln('${strings.labelNodes}\t${result.nodes.length}')
            ..writeln(
              '${strings.labelUnreadableDirs}\t${result.unreadableDirs.length}',
            )
            ..writeln(
              '${strings.labelNestedWorkspaces}'
              '\t${result.nestedFiletaggerDirs.length}',
            );
        }
        return exitOk;
      } on WorkspaceUnreadableException {
        _endProgress();
        return fail(
          exitIoError,
          ConsoleFailure.workspaceUnreadable,
          strings.workspaceUnreadable(root),
          subject: root,
        );
      }
    });
  }

  /// 훑는 동안 한 줄을 제자리에서 고쳐 쓴다. **터미널일 때만** 낸다 — 파이프로
  /// 흘려보낼 때까지 진행 줄이 섞이면 받는 쪽이 결과와 구분하지 못한다.
  bool get _showProgress => !asJson && stderr.hasTerminal;

  void _progress(ScanProgress progress) {
    if (!_showProgress) return;
    // 수치는 늘기만 하므로 줄이 짧아지는 일이 없다 — 지우지 않고 덮어써도 된다.
    stderr.write(
      '\r${strings.labelScanning} ${progress.entriesSeen} · '
      '${strings.labelIndexed} ${progress.filesIndexed}',
    );
  }

  void _endProgress() {
    if (_showProgress) stderr.writeln();
  }
}

const String _kRoot = 'root';
const String _kNodes = 'nodes';
const String _kUnreadableDirs = 'unreadableDirs';
const String _kNestedWorkspaces = 'nestedWorkspaces';
