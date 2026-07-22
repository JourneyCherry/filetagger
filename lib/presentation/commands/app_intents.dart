/// 앱 명령의 Intent 정의.
///
/// 동작을 Intent 한 종류로만 표현하고, 실제 구현(핸들러)은 셸이 `Actions`로
/// 붙인다. 단축키·메뉴바·컨텍스트 메뉴·툴바가 모두 같은 Intent를 던지므로
/// 조작 경로가 늘어도 동작 정의는 한 곳에 남는다.
library;

import 'package:flutter/widgets.dart';

/// 관리할 폴더를 골라 연다.
class OpenFolderIntent extends Intent {
  const OpenFolderIntent();
}

/// 현재 워크스페이스를 닫고 최근 폴더 목록으로 돌아간다.
class CloseFolderIntent extends Intent {
  const CloseFolderIntent();
}

/// 현재 워크스페이스를 다시 스캔한다.
class RescanIntent extends Intent {
  const RescanIntent();
}

/// 표시 중인 항목을 모두 선택한다.
class SelectAllIntent extends Intent {
  const SelectAllIntent();
}

/// 선택을 모두 해제한다.
class ClearSelectionIntent extends Intent {
  const ClearSelectionIntent();
}

/// 선택한 항목들에 태그를 부여한다.
class AssignTagsIntent extends Intent {
  const AssignTagsIntent();
}

/// 연결 끊긴 노드의 원본 파일을 찾아 태그를 재연결한다.
class ReconnectIntent extends Intent {
  const ReconnectIntent();
}

/// 선택한 항목의 위치를 OS 파일 관리자에서 연다.
class RevealInFileManagerIntent extends Intent {
  const RevealInFileManagerIntent();
}

/// 선택한 항목을 활성화한다(폴더=펼침/접힘, 파일=프리뷰).
class ActivateNodeIntent extends Intent {
  const ActivateNodeIntent();
}

/// 도구모음의 필터 조건 줄을 보이거나 숨긴다.
class ToggleFilterBarIntent extends Intent {
  const ToggleFilterBarIntent();
}

/// 도구모음의 정렬 조건 줄을 보이거나 숨긴다.
class ToggleSortBarIntent extends Intent {
  const ToggleSortBarIntent();
}

/// 목록 행에서 태그를 바로 고칠 수 있게 하거나 되돌린다.
class ToggleListEditIntent extends Intent {
  const ToggleListEditIntent();
}

/// 목록을 폴더 계층으로 묶을지(그룹화) 켜고 끈다.
class ToggleGroupingIntent extends Intent {
  const ToggleGroupingIntent();
}

/// 태그 관리(생성·편집·삭제·표시 순서)를 연다.
class ManageTagsIntent extends Intent {
  const ManageTagsIntent();
}

/// 태그 칩의 표시 순서를 편집한다.
class TagDisplayOrderIntent extends Intent {
  const TagDisplayOrderIntent();
}

/// 프리뷰 창을 보이거나 숨긴다.
class TogglePreviewIntent extends Intent {
  const TogglePreviewIntent();
}

/// 목록에서 키보드 커서를 한 칸 위/아래로 옮기며 그 항목만 단일 선택한다(방향키).
class MoveCursorUpIntent extends Intent {
  const MoveCursorUpIntent();
}

class MoveCursorDownIntent extends Intent {
  const MoveCursorDownIntent();
}

/// 앵커에서 커서까지 범위를 위/아래로 넓히며 선택한다(Shift+방향키).
class ExtendSelectionUpIntent extends Intent {
  const ExtendSelectionUpIntent();
}

class ExtendSelectionDownIntent extends Intent {
  const ExtendSelectionDownIntent();
}

/// 선택을 건드리지 않고 커서만 위/아래로 옮긴다(Ctrl+방향키).
class MoveCursorUpNoSelectIntent extends Intent {
  const MoveCursorUpNoSelectIntent();
}

class MoveCursorDownNoSelectIntent extends Intent {
  const MoveCursorDownNoSelectIntent();
}

/// 커서 행 안에서 태그 칸을 좌/우로 옮긴다(방향키 좌우).
class MoveTagLeftIntent extends Intent {
  const MoveTagLeftIntent();
}

class MoveTagRightIntent extends Intent {
  const MoveTagRightIntent();
}

/// 커서 자리를 확정한다(Enter). 태그 칸이면 값 수정('+'이면 태그 추가), 행 레벨이면
/// 커서=선택일 때 활성(폴더 펼침/프리뷰), 아니면 그 항목을 선택으로 확정한다.
class ConfirmCursorIntent extends Intent {
  const ConfirmCursorIntent();
}

/// 커서가 가리키는 태그 부여를 제거한다(Delete).
class DeleteFocusedTagIntent extends Intent {
  const DeleteFocusedTagIntent();
}

/// 커서 항목을 다중 선택에 넣거나 뺀다(Ctrl+Enter). 이미 선택돼 있으면 해제한다.
class ToggleCursorSelectionIntent extends Intent {
  const ToggleCursorSelectionIntent();
}
