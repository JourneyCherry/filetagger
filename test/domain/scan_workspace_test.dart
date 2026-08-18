import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/folder_manage_mode.dart';
import 'package:filetagger/domain/entities/node_kind.dart';
import 'package:filetagger/domain/entities/scan_progress.dart';
import 'package:filetagger/domain/entities/scan_result.dart';
import 'package:filetagger/domain/repositories/file_node_repository.dart';
import 'package:filetagger/domain/repositories/workspace_scanner.dart';
import 'package:filetagger/domain/usecases/scan_workspace.dart';
import 'package:flutter_test/flutter_test.dart';

FileNode file(String path) => FileNode(path: path, kind: NodeKind.file);

void main() {
  late _FakeNodes nodes;

  setUp(() => nodes = _FakeNodes());

  ScanWorkspace usecase(_FakeScanner scanner) => ScanWorkspace(scanner, nodes);

  group('부분 결과 미리 반영', () {
    test('스캔이 끝나기 전에 관측된 노드를 먼저 반영한다', () async {
      final scanner = _FakeScanner(
        batches: [
          [file('a.txt')],
          [file('b.txt'), file('c.txt')],
        ],
        result: [file('a.txt'), file('b.txt'), file('c.txt')],
      );

      await usecase(scanner)('/root');

      // 미리 반영이 최종 반영보다 앞서야 한다 — 뒤에 오면 목록에 먼저 보이지 않는다.
      expect(nodes.calls, ['partial:a.txt', 'partial:b.txt,c.txt', 'final:3']);
    });

    test('노드가 실리지 않은 보고는 저장을 부르지 않는다', () async {
      final scanner = _FakeScanner(batches: [[], []], result: [file('a.txt')]);

      await usecase(scanner)('/root');

      expect(nodes.calls, ['final:1']);
    });

    test('미리 반영이 실패해도 스캔은 끝까지 간다', () async {
      nodes.failPartial = true;
      final scanner = _FakeScanner(
        batches: [
          [file('a.txt')],
        ],
        result: [file('a.txt')],
      );

      await usecase(scanner)('/root');

      // 최종 반영은 그대로 돌아 정합을 맞춘다.
      expect(nodes.calls, contains('final:1'));
    });
  });

  group('이동 재연결 기준 경로', () {
    test('스캔 시작 시점의 경로를 넘긴다(미리 반영한 노드는 빼고)', () async {
      nodes.index['old.txt'] = file('old.txt');
      final scanner = _FakeScanner(
        batches: [
          [file('new.txt')],
        ],
        result: [file('new.txt')],
      );

      await usecase(scanner)('/root');

      // 미리 반영된 new.txt가 섞이면 "처음 본 경로"가 하나도 없게 되어 이동
      // 재연결이 통째로 죽는다.
      expect(nodes.priorPathsSeen, {'old.txt'});
    });
  });
}

/// 보고를 정해진 순서로 내보내는 스캐너. 보고 사이마다 이벤트 루프를 한 번 양보해,
/// 실제처럼 저장이 스캔 도중에 끼어들 수 있게 한다.
class _FakeScanner implements WorkspaceScanner {
  _FakeScanner({required this.batches, required this.result});

  final List<List<FileNode>> batches;
  final List<FileNode> result;

  @override
  Future<ScanResult> scan(
    String workspaceRoot, {
    Map<String, FileNode> priorIndex = const {},
    FolderManageMode rootManageMode = FolderManageMode.managed,
    void Function(ScanProgress progress)? onProgress,
  }) async {
    for (final batch in batches) {
      onProgress?.call(
        ScanProgress(
          entriesSeen: batch.length,
          filesIndexed: batch.length,
          currentPath: '',
          newNodes: batch,
        ),
      );
      await Future<void>.delayed(Duration.zero);
    }
    return ScanResult(nodes: result, nestedFiletaggerDirs: const []);
  }
}

class _FakeNodes implements FileNodeRepository {
  final Map<String, FileNode> index = {};

  /// 저장이 불린 순서(미리 반영과 최종 반영의 앞뒤를 본다).
  final List<String> calls = [];

  /// 최종 반영이 받은 "스캔 시작 시점 경로".
  Set<String> priorPathsSeen = const {};

  bool failPartial = false;

  @override
  Future<Map<String, FileNode>> indexByPath() async => index;

  @override
  Future<void> applyPartialScan(List<FileNode> observed) async {
    if (failPartial) throw StateError('부분 반영 실패');
    calls.add('partial:${observed.map((n) => n.path).join(',')}');
  }

  @override
  Future<void> applyScan(
    List<FileNode> scanned, {
    required FolderManageMode rootManageMode,
    required Set<String> priorPaths,
  }) async {
    priorPathsSeen = priorPaths;
    calls.add('final:${scanned.length}');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
