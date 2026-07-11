import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 파일 목록의 다중 선택 상태(선택된 노드 id 집합 + 범위 선택 앵커).
///
/// 선택 "데이터"만 담고, 입력 해석(데스크톱 보조키 vs 모바일 선택 모드+체크박스)은
/// 셸이 맡는다. 두 방식이 같은 메서드(단일/토글/범위/전체/해제)를 호출해 한 상태를
/// 공유한다.
class SelectionState {
  const SelectionState({this.selectedIds = const {}, this.anchorId});

  /// 선택된 노드 id들.
  final Set<int> selectedIds;

  /// 범위 선택(Shift)의 기준점. 없으면 null.
  final int? anchorId;

  bool get isEmpty => selectedIds.isEmpty;
  bool get isNotEmpty => selectedIds.isNotEmpty;
  int get length => selectedIds.length;
  bool contains(int id) => selectedIds.contains(id);

  /// 선택이 정확히 하나면 그 id, 아니면 null.
  int? get singleOrNull => selectedIds.length == 1 ? selectedIds.first : null;
}

/// [SelectionState]를 조작하는 Riverpod 컨트롤러. 워크스페이스가 바뀔 때 등
/// 화면이 [clear]를 호출해 초기화한다(자동 dispose는 provider 생명주기에 맡긴다).
class SelectionController extends Notifier<SelectionState> {
  @override
  SelectionState build() => const SelectionState();

  /// 모두 해제한다.
  void clear() => state = const SelectionState();

  /// 단일 선택(클릭/탭). 기존 선택을 지우고 이 노드만 선택한 뒤 앵커로 삼는다.
  void selectSingle(int id) =>
      state = SelectionState(selectedIds: {id}, anchorId: id);

  /// 개별 토글(Ctrl/Cmd, 체크박스). 앵커를 이 노드로 옮긴다.
  void toggle(int id) {
    final next = Set<int>.of(state.selectedIds);
    if (!next.remove(id)) next.add(id);
    state = SelectionState(selectedIds: next, anchorId: id);
  }

  /// 범위 선택(Shift). [orderedIds]는 표시 순서의 id 목록. 앵커가 없거나 목록에서
  /// 사라졌으면 단일 선택으로 대체한다(앵커도 이 노드로 재설정). 앵커는 유지한다.
  void selectRange(List<int> orderedIds, int id) {
    final anchor = state.anchorId;
    final anchorIndex = anchor == null ? -1 : orderedIds.indexOf(anchor);
    final index = orderedIds.indexOf(id);
    if (anchorIndex == -1 || index == -1) {
      state = SelectionState(selectedIds: {id}, anchorId: id);
      return;
    }
    final lo = math.min(anchorIndex, index);
    final hi = math.max(anchorIndex, index);
    state = SelectionState(
      selectedIds: {for (var i = lo; i <= hi; i++) orderedIds[i]},
      anchorId: anchor,
    );
  }

  /// 표시 중인 전체([orderedIds])를 선택한다(Ctrl+A 등). 앵커는 마지막 항목.
  void selectAll(List<int> orderedIds) {
    if (orderedIds.isEmpty) {
      clear();
      return;
    }
    state = SelectionState(
      selectedIds: orderedIds.toSet(),
      anchorId: orderedIds.last,
    );
  }
}

final selectionControllerProvider =
    NotifierProvider<SelectionController, SelectionState>(
      SelectionController.new,
    );
