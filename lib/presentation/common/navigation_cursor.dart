import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 키보드 내비게이션의 "커서"(지금 방향키가 가리키는 자리). 선택([SelectionState])과
/// 분리된 별개 상태다 — Ctrl+상하로 선택을 건드리지 않고 커서만 옮기고, 좌우로 그 행
/// 안의 태그 칸을 오가기 위함이다.
///
/// [nodeId]는 커서가 놓인 행(세로 위치, 선택의 앵커 해석과 같은 방식으로 표시 순서의
/// 이웃을 찾는다). [tagColumn]은 그 행 안의 가로 위치:
///   - null      = 행 레벨(태그 미선택)
///   - 0..n-1    = 보이는 태그 칩(n = 그 행의 보이는 태그 수)
///   - n         = '+' 추가 슬롯(추가 어포던스가 있을 때만 닿는다)
class NavigationCursor {
  const NavigationCursor({this.nodeId, this.tagColumn});

  final int? nodeId;
  final int? tagColumn;

  bool get isEmpty => nodeId == null;
}

/// 표시 순서 id 목록에서 [current] 기준 [delta](+1 아래 / -1 위) 위치의 id.
///
/// 커서가 없거나([current]가 null) 목록에서 사라졌으면 진입점을 고른다 — 아래로면
/// 처음, 위로면 끝. 목록 끝에서 더 가려 하면 제자리(끝 항목)에 머문다. 다중값 그룹의
/// 중복 등장은 첫 등장을 기준으로 삼는다(선택의 범위 해석과 같은 근사).
int? stepNodeCursor(List<int> orderedIds, int? current, int delta) {
  if (orderedIds.isEmpty) return null;
  final idx = current == null ? -1 : orderedIds.indexOf(current);
  if (idx == -1) return delta > 0 ? orderedIds.first : orderedIds.last;
  final next = (idx + delta).clamp(0, orderedIds.length - 1);
  return orderedIds[next];
}

/// 태그 칸을 좌우로 옮긴다. [tagCount]는 그 행의 보이는 태그 수, [hasAdd]는 '+' 추가
/// 슬롯이 닿을 수 있는지(추가 어포던스가 보일 때만 true).
///
/// 정지 지점은 왼→오로 `[태그0..n-1] (+ 추가 슬롯)`. 오른쪽으로:
///   - null(행 레벨) → 0(태그도 슬롯도 없으면 그대로 null)
///   - i → i+1(마지막 정지에서 멈춤)
/// 왼쪽으로:
///   - null → null(행 왼쪽엔 갈 곳이 없다)
///   - 0 → null(행 레벨로 되돌아감)
///   - i → i-1
int? stepTagColumn(int? current, int tagCount, bool hasAdd, int delta) {
  final maxIndex = tagCount - 1 + (hasAdd ? 1 : 0);
  if (maxIndex < 0) return null; // 태그도 추가 슬롯도 없다.
  if (delta > 0) {
    if (current == null) return 0;
    return current >= maxIndex ? maxIndex : current + 1;
  }
  if (current == null || current <= 0) return null;
  return current - 1;
}

/// 격자(아이콘 보기)에서 커서를 옮긴다. [count]는 현재 계층의 표시 항목 수(헤더 포함),
/// [columns]는 한 줄의 칸 수. [horizontal]이면 ±1(row-major 연속), 아니면 ±[columns]
/// (한 줄 위/아래). [delta]는 +1(오른쪽/아래)·-1(왼쪽/위).
///
/// 커서가 없거나([current]<0) 범위를 벗어났으면 진입점을 고른다 — +면 처음, -면 끝.
/// 세로 이동이 목록 밖으로 나가면(마지막 줄 아래 등) 제자리에 머문다.
int stepGridCursor(
  int current,
  int count,
  int columns,
  int delta, {
  required bool horizontal,
}) {
  if (count <= 0) return -1;
  if (current < 0 || current >= count) return delta > 0 ? 0 : count - 1;
  if (horizontal) {
    final next = current + delta;
    return (next < 0 || next >= count) ? current : next;
  }
  final step = columns < 1 ? 1 : columns;
  final next = current + delta * step;
  return (next < 0 || next >= count) ? current : next;
}

/// [NavigationCursor]를 조작하는 컨트롤러. 워크스페이스·보기 모드가 바뀌면 화면이
/// [clear]로 초기화한다(커서는 목록 보기에서만 의미가 있다).
class NavigationCursorController extends Notifier<NavigationCursor> {
  @override
  NavigationCursor build() => const NavigationCursor();

  void clear() => state = const NavigationCursor();

  /// 커서를 [nodeId] 행으로 옮긴다. 세로 이동은 늘 태그 칸을 행 레벨로 되돌린다.
  void moveTo(int nodeId) => state = NavigationCursor(nodeId: nodeId);

  /// 현재 행 안에서 태그 칸만 바꾼다.
  void setTagColumn(int? column) =>
      state = NavigationCursor(nodeId: state.nodeId, tagColumn: column);
}

final navigationCursorProvider =
    NotifierProvider<NavigationCursorController, NavigationCursor>(
      NavigationCursorController.new,
    );
