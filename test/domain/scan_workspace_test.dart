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

  group('취소', () {
    test('취소로 끝난 스캔은 정합을 돌리지 않는다', () async {
      // 중간까지 훑은 목록으로 정합을 돌리면 아직 안 본 자리가 사라진 것으로
      // 판정된다. 미리 반영(관측한 것)은 남아도 틀리지 않다.
      final scanner = _FakeScanner(
        batches: [
          [file('a.txt')],
        ],
        result: const [],
        failWith: const ScanCancelledException(),
      );

      await expectLater(
        usecase(scanner)('/root'),
        throwsA(isA<ScanCancelledException>()),
      );
      expect(nodes.calls, ['partial:a.txt']);
    });

    test('취소 손잡이를 스캐너에 그대로 넘긴다', () async {
      final cancel = ScanCancellation();
      final scanner = _FakeScanner(batches: const [], result: const []);

      await usecase(scanner)('/root', cancel: cancel);

      expect(scanner.cancelSeen, same(cancel));
    });
  });

  group('사라짐 판정 기준 시각', () {
    test('훑기 전 시각을 초 단위로 내려 넘긴다', () async {
      // 관측 도장이 초 정밀도로 저장되므로, 같은 초에 찍힌 도장이 "내 시작 전"으로
      // 읽히지 않게 내려서 잡는다(의심스러운 한 초는 남기는 쪽으로 기운다).
      final before = DateTime.now();
      final scanner = _FakeScanner(batches: const [], result: [file('a.txt')]);

      await usecase(scanner)('/root');

      final seen = nodes.scanStartedAtSeen;
      expect(seen, isNotNull);
      expect(seen!.millisecond, 0);
      expect(seen.microsecond, 0);
      // 훑기 전에 찍어야 한다 — 훑는 동안 남이 본 노드를 내가 지우지 않으려는 기준이라,
      // 늦게 찍으면 그 사이의 관측이 기준 아래로 깔린다.
      expect(seen.isAfter(before), isFalse);
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
  _FakeScanner({required this.batches, required this.result, this.failWith});

  final List<List<FileNode>> batches;
  final List<FileNode> result;

  /// 보고를 다 내보낸 뒤 결과 대신 던질 것(취소·실패 재현용).
  final Object? failWith;

  /// 넘겨받은 취소 손잡이(그대로 전달되는지 본다).
  ScanCancellation? cancelSeen;

  @override
  Future<ScanResult> scan(
    String workspaceRoot, {
    Map<String, FileNode> priorIndex = const {},
    FolderManageMode rootManageMode = FolderManageMode.managed,
    void Function(ScanProgress progress)? onProgress,
    ScanCancellation? cancel,
  }) async {
    cancelSeen = cancel;
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
    if (failWith case final error?) throw error;
    return ScanResult(
      nodes: result,
      nestedFiletaggerDirs: const [],
      unreadableDirs: const [],
    );
  }
}

class _FakeNodes implements FileNodeRepository {
  final Map<String, FileNode> index = {};

  /// 저장이 불린 순서(미리 반영과 최종 반영의 앞뒤를 본다).
  final List<String> calls = [];

  /// 최종 반영이 받은 "스캔 시작 시점 경로".
  Set<String> priorPathsSeen = const {};

  /// 최종 반영이 받은 사라짐 판정 기준 시각.
  DateTime? scanStartedAtSeen;

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
    required Set<String> unreadableDirs,
    required DateTime scanStartedAt,
  }) async {
    priorPathsSeen = priorPaths;
    scanStartedAtSeen = scanStartedAt;
    calls.add('final:${scanned.length}');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
