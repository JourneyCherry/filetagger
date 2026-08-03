import 'package:flutter/material.dart';

import '../../domain/entities/folder_manage_mode.dart';
import '../shells/menu_model.dart';

/// 폴더 관리 방식 메뉴의 선택지. 라디오(불투명/관리)와 토글(재귀)이 섞여 있어
/// 모드 자체가 아니라 '조작'으로 표현한다.
enum FolderManageAction { opaque, managed, toggleRecursive }

/// [resolved](상속까지 반영한 현재 모드)에서 [action]을 골랐을 때 적용할 새 모드.
/// 바뀔 게 없으면 null이며, 호출부는 아무 것도 하지 않는다.
FolderManageMode? nextManageMode(
  FolderManageMode resolved,
  FolderManageAction action,
) {
  final managedFamily = resolved != FolderManageMode.opaque;
  switch (action) {
    case FolderManageAction.opaque:
      return managedFamily ? FolderManageMode.opaque : null;
    case FolderManageAction.managed:
      // 이미 관리 계열이면 라디오는 무시한다(재귀 여부는 토글로 바꾼다).
      return managedFamily ? null : FolderManageMode.managed;
    case FolderManageAction.toggleRecursive:
      // 불투명일 땐 재귀가 의미 없다.
      if (!managedFamily) return null;
      return resolved == FolderManageMode.managedRecursive
          ? FolderManageMode.managed
          : FolderManageMode.managedRecursive;
  }
}

/// 폴더 관리 방식 항목들. 컨텍스트 메뉴의 하위 메뉴로 접어 넣는다 — 어느 대상에
/// 걸리는 항목인지는 그 하위 메뉴의 이름이 알린다(따로 머리말을 두지 않는다).
///
/// 체크 상태는 상속까지 반영한 [resolved]를 그대로 보여 준다. 고른 조작은
/// [onSelected]로 알린다.
List<MenuNode> folderManageMenuNodes({
  required FolderManageMode resolved,
  required ValueChanged<FolderManageAction> onSelected,
}) {
  final managedFamily = resolved != FolderManageMode.opaque;
  return [
    MenuChecked(
      '폴더만 관리 (내부 감춤)',
      checked: !managedFamily,
      onSelected: () => onSelected(FolderManageAction.opaque),
    ),
    MenuChecked(
      '내부 관리',
      checked: managedFamily,
      onSelected: () => onSelected(FolderManageAction.managed),
    ),
    MenuChecked(
      '재귀적으로 관리',
      checked: resolved == FolderManageMode.managedRecursive,
      // 폴더만 관리(불투명)일 땐 재귀가 의미 없어 고를 수 없다.
      onSelected: managedFamily
          ? () => onSelected(FolderManageAction.toggleRecursive)
          : null,
    ),
  ];
}
