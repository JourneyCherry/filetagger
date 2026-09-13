import '../entities/folder_manage_mode.dart';
import '../entities/scan_progress.dart';
import '../entities/scan_result.dart';
import '../repositories/file_node_repository.dart';
import '../repositories/workspace_scanner.dart';

/// 워크스페이스를 스캔해 인덱스를 증분 갱신하고, 병합 후보 등 스캔 결과를
/// 그대로 돌려준다. 스캐너·저장소 구현에 의존하지 않는 순수 오케스트레이션.
class ScanWorkspace {
  const ScanWorkspace(this._scanner, this._repository);

  final WorkspaceScanner _scanner;
  final FileNodeRepository _repository;

  /// [rootManageMode]는 루트 폴더의 관리 방식이다(뷰 설정에 저장된 값). 루트부터
  /// 상속이 시작되므로 스캔마다 넘긴다(기본은 직속 내용만 인덱싱하는 [managed]).
  ///
  /// 스캔이 내놓는 노드는 **다 끝나기를 기다리지 않고 관측되는 대로 인덱스에 미리
  /// 반영한다** — 큰 폴더에서 읽은 만큼 목록에 먼저 보이게 하기 위함이다. 사라진
  /// 노드 정리·이동 재연결처럼 전체를 봐야 서는 판단만 마지막에 한 번 한다.
  ///
  /// [onProgress]는 화면이 "작업 중"임을 보이는 데 쓰라고 스캐너의 진행 보고를
  /// 그대로 전달한다(저장 단계는 보고하지 않는다).
  ///
  /// 스캐너가 루트를 나열하지 못하면 예외가 그대로 올라가고 **정합은 돌지 않는다** —
  /// 아무것도 관측하지 못한 결과로 정합을 돌리면 인덱스가 통째로 사라진 것으로
  /// 판정된다. 하위 폴더를 못 읽은 것은 결과에 실려 와 정합이 그 서브트리를 뺀다.
  ///
  /// [cancel]로 도중에 그만두게 할 수 있다. 취소도 예외로 끝나므로 **정합은 마찬가지로
  /// 돌지 않는다** — 중간까지 훑은 목록으로 정합을 돌리면 아직 안 본 자리가 사라진
  /// 것으로 판정된다. 이미 미리 반영된 노드는 그대로 남는데, 그것은 실제로 관측한
  /// 것이라 남아도 틀리지 않다(다음 스캔이 정합을 맞춘다).
  Future<ScanResult> call(
    String workspaceRoot, {
    FolderManageMode rootManageMode = FolderManageMode.managed,
    void Function(ScanProgress progress)? onProgress,
    ScanCancellation? cancel,
  }) async {
    // 사라짐 판정의 기준 시각. **훑기 전에** 찍어 둔다 — 이 뒤에 관측 도장이 찍힌
    // 노드는 누군가 나보다 나중에 그것을 보았다는 뜻이라, 내가 못 봤다고 해서 사라진
    // 것으로 읽으면 안 된다([FileNodeRepository.applyScan]).
    final scanStartedAt = _flooredToSecond(DateTime.now());

    // 직전 인덱스를 넘겨, 크기·수정시각이 그대로인 파일은 저장된 해시를 재사용해
    // 재해시(파일 재읽기)를 건너뛰게 하고, 폴더 관리 방식(override)도 이어받게 한다.
    final priorIndex = await _repository.indexByPath();

    // 미리 반영은 보고가 오는 대로 시작하되 **서로 앞지르지 못하게** 한 줄로 잇는다.
    // 뒤엉키면 같은 경로를 동시에 쓰게 되고, 마지막 정합 계산이 아직 반영되지 않은
    // 노드를 못 본 채 돌 수도 있다.
    var applied = Future<void>.value();
    final result = await _scanner.scan(
      workspaceRoot,
      priorIndex: priorIndex,
      rootManageMode: rootManageMode,
      cancel: cancel,
      onProgress: (progress) {
        onProgress?.call(progress);
        if (progress.newNodes.isEmpty) return;
        applied = applied
            .then((_) => _repository.applyPartialScan(progress.newNodes))
            // 미리 반영은 어디까지나 먼저 보여 주기 위한 것이라, 실패해도 스캔을
            // 접지 않는다 — 최종 정합은 아래 applyScan이 다시 맞춘다.
            .catchError((_) {});
      },
    );
    await applied;

    await _repository.applyScan(
      result.nodes,
      rootManageMode: rootManageMode,
      // 이동 재연결의 "처음 본 경로" 판정 기준. 미리 반영한 노드가 이미 저장되어
      // 있으므로 저장된 것이 아니라 스캔 시작 시점을 기준으로 삼아야 한다.
      priorPaths: priorIndex.keys.toSet(),
      unreadableDirs: result.unreadableDirs.toSet(),
      scanStartedAt: scanStartedAt,
    );
    return result;
  }

  /// 초 미만을 버린 시각. **관측 도장은 초 정밀도로 저장되므로**(이동 추적이 수정
  /// 시각을 초 단위로 비교하는 것과 같은 이유), 기준 시각을 그대로 쓰면 같은 초에
  /// 찍힌 도장이 "내 시작 전"으로 읽힌다. 내려서 잡아 **의심스러운 한 초는 남기는
  /// 쪽으로** 기운다 — 잘못 남기면 다음 스캔이 정리하지만, 잘못 지우면 태그가 함께
  /// 사라진다.
  static DateTime _flooredToSecond(DateTime t) =>
      DateTime.fromMillisecondsSinceEpoch(
        (t.millisecondsSinceEpoch ~/ 1000) * 1000,
        isUtc: t.isUtc,
      );
}
