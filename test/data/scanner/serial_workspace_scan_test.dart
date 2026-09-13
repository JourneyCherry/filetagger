import 'dart:async';

import 'package:filetagger/data/scanner/serial_workspace_scan.dart';
import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/folder_manage_mode.dart';
import 'package:filetagger/domain/entities/scan_progress.dart';
import 'package:filetagger/domain/entities/scan_result.dart';
import 'package:filetagger/domain/repositories/file_node_repository.dart';
import 'package:filetagger/domain/repositories/workspace_scanner.dart';
import 'package:flutter_test/flutter_test.dart';

/// 같은 프로세스 안에서 전체 스캔이 겹치지 않는지에 대한 가드레일. 겹쳐도 결과가
/// 틀리지는 않지만(정합 판정이 관측 도장을 본다) 같은 폴더를 두 번 훑는 것은 낭비다.
void main() {
  test('도는 스캔이 끝날 때까지 다음 스캔은 시작하지 않는다', () async {
    final scanner = _GatedScanner();
    final scan = SerialWorkspaceScan(scanner, _NoopNodes());

    final first = scan('/root');
    await pumpEventQueue();
    expect(scanner.started, 1, reason: '첫 스캔이 들어갔다');

    final second = scan('/root');
    await pumpEventQueue();
    expect(scanner.started, 1, reason: '앞 스캔이 도는 동안에는 들어가지 않는다');

    scanner.release();
    await first;
    await pumpEventQueue();
    expect(scanner.started, 2, reason: '앞 스캔이 끝나면 기다린 스캔이 들어간다');

    scanner.release();
    await second;
    expect(scanner.maxConcurrent, 1);
  });

  test('앞 스캔이 예외로 끝나도 기다린 스캔은 그대로 돈다', () async {
    // 취소는 예외로 끝난다 — 폴더를 닫고 곧바로 다시 열면 이 자리를 지난다. 앞 스캔의
    // 예외가 기다리던 쪽으로 새면 폴더를 열었는데 훑지 않는 일이 생긴다.
    final scanner = _GatedScanner(failWith: const ScanCancelledException());
    final scan = SerialWorkspaceScan(scanner, _NoopNodes());

    final first = scan('/root');
    await pumpEventQueue();
    final second = scan('/root');

    scanner.release();
    await expectLater(first, throwsA(isA<ScanCancelledException>()));
    // 기다리던 쪽이 자리를 받아 스캐너에 들어갈 틈을 준다.
    await pumpEventQueue();
    scanner.release();
    await expectLater(second, throwsA(isA<ScanCancelledException>()));
    expect(scanner.started, 2);
  });
}

/// 풀어 줄 때까지 결과를 내지 않는 스캐너. 동시에 몇 개가 들어와 있는지 센다.
class _GatedScanner implements WorkspaceScanner {
  _GatedScanner({this.failWith});

  final Object? failWith;
  final List<Completer<void>> _gates = [];

  int started = 0;
  int active = 0;
  int maxConcurrent = 0;

  void release() => _gates.removeAt(0).complete();

  @override
  Future<ScanResult> scan(
    String workspaceRoot, {
    Map<String, FileNode> priorIndex = const {},
    FolderManageMode rootManageMode = FolderManageMode.managed,
    void Function(ScanProgress progress)? onProgress,
    ScanCancellation? cancel,
  }) async {
    started++;
    active++;
    if (active > maxConcurrent) maxConcurrent = active;
    final gate = Completer<void>();
    _gates.add(gate);
    try {
      await gate.future;
      if (failWith case final error?) throw error;
      return const ScanResult(
        nodes: [],
        nestedFiletaggerDirs: [],
        unreadableDirs: [],
      );
    } finally {
      active--;
    }
  }
}

class _NoopNodes implements FileNodeRepository {
  @override
  Future<Map<String, FileNode>> indexByPath() async => const {};

  @override
  Future<void> applyPartialScan(List<FileNode> observed) async {}

  @override
  Future<void> applyScan(
    List<FileNode> scanned, {
    required FolderManageMode rootManageMode,
    required Set<String> priorPaths,
    required Set<String> unreadableDirs,
    required DateTime scanStartedAt,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
