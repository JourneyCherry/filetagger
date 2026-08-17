import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 키보드 내비게이션의 "커서"(지금 방향키가 가리키는 자리). 선택([SelectionState])과
/// 분리된 별개 상태다 — Ctrl+상하로 선택을 건드리지 않고 커서만 옮기고, 좌우로 그 행
/// 안의 태그 칸을 오가기 위함이다.
///
/// 커서가 놓인 행은 [nodeId](파일·폴더 노드) **또는** [headerKey](그룹 헤더) 하나로
/// 가리킨다 — 헤더는 실재하지 않는 합성 노드라 선택 대상이 아니고, 그래서 노드 id로는
/// 가리킬 수 없다. 대신 그 행의 펼침 키를 쓴다. 둘은 동시에 차지 않는다.
///
/// [tagColumn]은 노드 행 안의 가로 위치다(헤더 행에는 태그 칸이 없다):
///   - null      = 행 레벨(태그 미선택)
///   - 0..n-1    = 보이는 태그 칩(n = 그 행의 보이는 태그 수)
///   - n         = '+' 추가 슬롯(추가 어포던스가 있을 때만 닿는다)
class NavigationCursor {
  const NavigationCursor({
    this.nodeId,
    this.headerKey,
    this.tagColumn,
    this.revealSerial = 0,
  });

  final int? nodeId;

  /// 커서가 그룹 헤더 행에 있을 때 그 행의 펼침 키. 노드 행이면 null.
  final String? headerKey;

  final int? tagColumn;

  /// **커서 행을 화면에 드러내 달라**는 요청을 세는 번호. 값 자체엔 뜻이 없고, 이 번호가
  /// 오르면 목록이 그 행을 뷰포트 안으로 끌어온다.
  ///
  /// 자리를 옮기는 것과 드러내는 것을 나눠 두는 까닭은 둘이 늘 함께 오지 않아서다 —
  /// 펼치기·접기는 커서를 그대로 둔 채 목록 모양만 바꿔 커서 행을 화면 밖으로 밀어낼 수
  /// 있고([NavigationCursorController.requestReveal]), 태그 칸을 좌우로 옮기는 것은
  /// 행이 그대로라 드러낼 일이 없다.
  final int revealSerial;

  bool get isEmpty => nodeId == null && headerKey == null;
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

/// 목록의 표시 **행**을 [delta]칸 옮긴다(진입점 고르기·끝에서 머무르기 규칙은
/// [stepGridCursor]의 가로 이동과 같다). 세로 이동이 노드가 아니라 행 단위라야
/// 선택 대상이 아닌 그룹 헤더 행도 커서가 지나갈 수 있다.
int stepRowCursor(int current, int count, int delta) =>
    stepGridCursor(current, count, 1, delta, horizontal: true);

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

  /// 커서를 비운다. 드러내기 번호는 이어 간다 — 되돌아가며 값이 겹치면 이미 처리한
  /// 요청을 새 요청으로 잘못 읽는다.
  void clear() => state = NavigationCursor(revealSerial: state.revealSerial);

  /// 커서를 [nodeId] 행으로 옮긴다. 세로 이동은 늘 태그 칸을 행 레벨로 되돌린다.
  void moveTo(int nodeId) => state = NavigationCursor(
    nodeId: nodeId,
    revealSerial: state.revealSerial + 1,
  );

  /// 커서를 [headerKey]가 가리키는 그룹 헤더 행으로 옮긴다. 헤더는 선택 대상이
  /// 아니라 커서만 놓이고, 태그 칸도 없어 행 레벨뿐이다.
  void moveToHeader(String headerKey) => state = NavigationCursor(
    headerKey: headerKey,
    revealSerial: state.revealSerial + 1,
  );

  /// 현재 행 안에서 태그 칸만 바꾼다(행이 그대로라 드러낼 일이 없다).
  void setTagColumn(int? column) => state = NavigationCursor(
    nodeId: state.nodeId,
    tagColumn: column,
    revealSerial: state.revealSerial,
  );

  /// 커서는 그대로 둔 채 **그 행을 다시 드러내 달라**고 알린다. 펼치기·접기처럼 커서는
  /// 움직이지 않았는데 목록 모양이 바뀌어 커서 행이 화면 밖으로 밀릴 수 있는 자리에서
  /// 쓴다. 이미 온전히 보이는 행이면 목록이 아무 일도 하지 않는다.
  void requestReveal() => state = NavigationCursor(
    nodeId: state.nodeId,
    headerKey: state.headerKey,
    tagColumn: state.tagColumn,
    revealSerial: state.revealSerial + 1,
  );
}

final navigationCursorProvider =
    NotifierProvider<NavigationCursorController, NavigationCursor>(
      NavigationCursorController.new,
    );
