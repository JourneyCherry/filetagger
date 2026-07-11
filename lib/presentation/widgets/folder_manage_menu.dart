import 'package:flutter/material.dart';

import '../../domain/entities/folder_manage_mode.dart';

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

/// 폴더 관리 방식 항목들. 컨텍스트 메뉴(명령 카탈로그 항목들) 뒤에 이어 붙인다.
/// 어느 대상에 걸리는 항목인지 드러나도록 머리말을 앞세운다.
///
/// 체크 상태는 상속까지 반영한 [resolved]를 그대로 보여 준다. 값을 갖지 않는
/// 항목이라 메뉴가 돌려주는 선택 결과(명령 식별자)에 섞이지 않고, 고른 조작은
/// [onSelected]로만 알린다.
List<PopupMenuEntry<T>> folderManageMenuItems<T>({
  required FolderManageMode resolved,
  required ValueChanged<FolderManageAction> onSelected,
}) {
  final managedFamily = resolved != FolderManageMode.opaque;
  return [
    _MenuSectionHeader<T>('폴더 관리 옵션'),
    CheckedPopupMenuItem<T>(
      checked: !managedFamily,
      onTap: () => onSelected(FolderManageAction.opaque),
      child: const Text('폴더만 관리 (내부 감춤)'),
    ),
    CheckedPopupMenuItem<T>(
      checked: managedFamily,
      onTap: () => onSelected(FolderManageAction.managed),
      child: const Text('내부 관리'),
    ),
    CheckedPopupMenuItem<T>(
      checked: resolved == FolderManageMode.managedRecursive,
      // 폴더만 관리(불투명)일 땐 재귀를 켤 수 없다.
      enabled: managedFamily,
      onTap: () => onSelected(FolderManageAction.toggleRecursive),
      child: const Text('재귀적으로 관리'),
    ),
  ];
}

/// 팝업 메뉴 안에서 뒤따르는 항목들이 무엇에 걸리는지 알리는 머리말.
///
/// 고를 수 없는 표시 전용 줄이다(전통적 메뉴의 그룹 제목). 값을 대표하지 않아
/// 키보드 이동·선택 결과에 끼어들지 않는다.
class _MenuSectionHeader<T> extends PopupMenuEntry<T> {
  const _MenuSectionHeader(this.label);

  /// 머리말 한 줄이 차지하는 높이(항목보다 낮게 둔다).
  static const double _height = 28;

  final String label;

  @override
  double get height => _height;

  @override
  bool represents(T? value) => false;

  @override
  State<_MenuSectionHeader<T>> createState() => _MenuSectionHeaderState<T>();
}

class _MenuSectionHeaderState<T> extends State<_MenuSectionHeader<T>> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: _MenuSectionHeader._height,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        widget.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
