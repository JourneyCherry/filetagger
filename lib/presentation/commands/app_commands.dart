/// 앱이 제공하는 명령의 카탈로그(라벨·아이콘·단축키·Intent).
///
/// 명령을 여기에 한 번만 정의하고, 메뉴바·컨텍스트 메뉴·툴바·단축키가 이 목록을
/// 소비한다. 조작 경로를 추가할 때 라벨·단축키가 서로 어긋나지 않게 하기 위함이다.
/// 실행 구현은 셸이 `CommandScope`에 핸들러로 넘긴다.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Icons;

import '../../core/platform.dart';
import 'app_intents.dart';

/// 명령의 안정적 식별자. 핸들러 배선과 메뉴 구성이 이 값으로 명령을 가리킨다.
enum AppCommandId {
  openFolder,
  closeFolder,
  rescan,
  selectAll,
  clearSelection,
  activateNode,
  assignTags,
  reconnect,
  revealInFileManager,
  manageTags,
  tagDisplayOrder,
  toggleFilterBar,
  toggleSortBar,
  toggleListEdit,
  toggleGrouping,
  togglePreview,
}

/// 명령 하나의 표시 정보와 던질 Intent.
class AppCommand {
  const AppCommand({
    required this.id,
    required this.label,
    required this.intent,
    this.icon,
    this.shortcut,
    this.requiresScopeFocus = false,
  });

  final AppCommandId id;

  /// 메뉴·툴팁에 보이는 이름.
  final String label;

  /// 이 명령이 던지는 Intent. 핸들러 배선의 키(런타임 타입)이기도 하다.
  final Intent intent;

  final IconData? icon;

  /// 이 명령을 부르는 단축키. 없으면 메뉴·버튼으로만 부른다. 메뉴바가 그대로
  /// 표기할 수 있도록 직렬화 가능한([MenuSerializableShortcut]) 활성자만 쓴다.
  final SingleActivator? shortcut;

  /// 앱 본문(명령 스코프)에 포커스가 있을 때만 단축키가 듣는지.
  ///
  /// Enter처럼 버튼 활성·텍스트 입력이 먼저 쓰는 키를 가로채지 않기 위한 표시다.
  /// 표시된 명령은 다른 위젯이 포커스를 쥐고 있으면 비활성이 되어, 키 이벤트가
  /// 위(기본 동작)로 그대로 흘러간다.
  final bool requiresScopeFocus;
}

/// 데스크톱 관용 보조키 조합(macOS는 Cmd, 그 외는 Ctrl).
SingleActivator _primary(LogicalKeyboardKey key) =>
    SingleActivator(key, control: !isMacOS, meta: isMacOS);

/// 전체 명령 카탈로그. 단축키는 플랫폼 보조키에 따라 정해지므로 상수가 아니다.
final List<AppCommand> appCommands = [
  AppCommand(
    id: AppCommandId.openFolder,
    label: '폴더 열기',
    intent: const OpenFolderIntent(),
    icon: Icons.folder_open,
    shortcut: _primary(LogicalKeyboardKey.keyO),
  ),
  const AppCommand(
    id: AppCommandId.closeFolder,
    label: '폴더 닫기',
    intent: CloseFolderIntent(),
    icon: Icons.close,
  ),
  const AppCommand(
    id: AppCommandId.rescan,
    label: '다시 스캔',
    intent: RescanIntent(),
    icon: Icons.refresh,
    shortcut: SingleActivator(LogicalKeyboardKey.f5),
  ),
  AppCommand(
    id: AppCommandId.selectAll,
    label: '전체 선택',
    intent: const SelectAllIntent(),
    icon: Icons.select_all,
    shortcut: _primary(LogicalKeyboardKey.keyA),
  ),
  const AppCommand(
    id: AppCommandId.clearSelection,
    label: '선택 해제',
    intent: ClearSelectionIntent(),
    shortcut: SingleActivator(LogicalKeyboardKey.escape),
  ),
  const AppCommand(
    id: AppCommandId.activateNode,
    label: '열기 / 펼치기',
    intent: ActivateNodeIntent(),
    shortcut: SingleActivator(LogicalKeyboardKey.enter),
    requiresScopeFocus: true,
  ),
  const AppCommand(
    id: AppCommandId.assignTags,
    label: '태그 부여',
    intent: AssignTagsIntent(),
    icon: Icons.sell_outlined,
  ),
  const AppCommand(
    id: AppCommandId.reconnect,
    label: '원본 파일 찾기',
    intent: ReconnectIntent(),
    icon: Icons.link,
  ),
  const AppCommand(
    id: AppCommandId.revealInFileManager,
    label: '탐색기에서 열기',
    intent: RevealInFileManagerIntent(),
    icon: Icons.open_in_new,
  ),
  const AppCommand(
    id: AppCommandId.manageTags,
    label: '태그 관리',
    intent: ManageTagsIntent(),
    icon: Icons.sell_outlined,
  ),
  const AppCommand(
    id: AppCommandId.tagDisplayOrder,
    label: '태그 표시 순서',
    intent: TagDisplayOrderIntent(),
    icon: Icons.reorder,
  ),
  const AppCommand(
    id: AppCommandId.toggleFilterBar,
    label: '필터 조건 보기',
    intent: ToggleFilterBarIntent(),
    icon: Icons.filter_alt_outlined,
  ),
  const AppCommand(
    id: AppCommandId.toggleSortBar,
    label: '정렬 조건 보기',
    intent: ToggleSortBarIntent(),
    icon: Icons.sort,
  ),
  const AppCommand(
    id: AppCommandId.toggleListEdit,
    label: '목록에서 수정 활성화',
    intent: ToggleListEditIntent(),
    icon: Icons.edit_note,
  ),
  const AppCommand(
    id: AppCommandId.toggleGrouping,
    label: '그룹 기준 보기',
    intent: ToggleGroupingIntent(),
    icon: Icons.account_tree_outlined,
  ),
  const AppCommand(
    id: AppCommandId.togglePreview,
    label: '프리뷰 보기',
    intent: TogglePreviewIntent(),
    icon: Icons.view_sidebar,
  ),
];

/// 식별자로 명령을 찾는다. 카탈로그에 없으면 프로그래밍 오류다.
AppCommand commandOf(AppCommandId id) =>
    appCommands.firstWhere((c) => c.id == id);

/// 단축키가 있는 명령들의 활성자 → Intent 매핑(`Shortcuts` 위젯용).
Map<ShortcutActivator, Intent> commandShortcuts() => {
  for (final c in appCommands)
    if (c.shortcut != null) c.shortcut!: c.intent,
};
