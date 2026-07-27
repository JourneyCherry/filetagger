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
  manageThumbnailTags,
  tagDisplayOrder,
  help,
  exitApp,
  toggleFilterBar,
  toggleSortBar,
  toggleListEdit,
  toggleGrouping,
  togglePresetBar,
  togglePreview,
  moveCursorUp,
  moveCursorDown,
  extendSelectionUp,
  extendSelectionDown,
  moveCursorUpNoSelect,
  moveCursorDownNoSelect,
  moveTagLeft,
  moveTagRight,
  confirmCursor,
  toggleCursorSelection,
  deleteFocusedTag,
  editFocusedTag,
  viewModeList,
  viewModeIcon,
  viewModeDetail,
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

/// 위 보조키에 Shift를 더한 조합(둘째 층 명령용).
SingleActivator _primaryShift(LogicalKeyboardKey key) =>
    SingleActivator(key, control: !isMacOS, meta: isMacOS, shift: true);

/// 전체 명령 카탈로그. 단축키는 플랫폼 보조키에 따라 정해지므로 상수가 아니다.
final List<AppCommand> appCommands = [
  AppCommand(
    id: AppCommandId.openFolder,
    label: '폴더 열기',
    intent: const OpenFolderIntent(),
    icon: Icons.folder_open,
    shortcut: _primary(LogicalKeyboardKey.keyO),
  ),
  AppCommand(
    id: AppCommandId.closeFolder,
    label: '폴더 닫기',
    intent: const CloseFolderIntent(),
    icon: Icons.close,
    shortcut: _primary(LogicalKeyboardKey.keyW),
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
  AppCommand(
    id: AppCommandId.activateNode,
    label: '열기 / 펼치기',
    intent: const ActivateNodeIntent(),
    // Enter는 커서·선택 상태를 함께 해석하는 confirmCursor가 쥐므로, 조건 없이 늘
    // 선택 항목을 토글(폴더 펼침·접힘, 파일 열기)하는 전용키를 따로 둔다.
    shortcut: _primary(LogicalKeyboardKey.keyM),
    requiresScopeFocus: true,
  ),
  AppCommand(
    id: AppCommandId.assignTags,
    label: '태그 부여',
    intent: const AssignTagsIntent(),
    icon: Icons.sell_outlined,
    // Delete가 커서 태그를 제거하는 것과 짝을 이룬다(Insert=부여).
    shortcut: _primary(LogicalKeyboardKey.insert),
  ),
  AppCommand(
    id: AppCommandId.reconnect,
    label: '원본 파일 찾기',
    intent: const ReconnectIntent(),
    icon: Icons.link,
    shortcut: _primaryShift(LogicalKeyboardKey.keyL),
  ),
  AppCommand(
    id: AppCommandId.revealInFileManager,
    label: '탐색기에서 열기',
    intent: const RevealInFileManagerIntent(),
    icon: Icons.open_in_new,
    shortcut: _primaryShift(LogicalKeyboardKey.keyR),
  ),
  AppCommand(
    id: AppCommandId.manageTags,
    label: '태그 관리',
    intent: const ManageTagsIntent(),
    icon: Icons.sell_outlined,
    shortcut: _primary(LogicalKeyboardKey.keyT),
  ),
  AppCommand(
    id: AppCommandId.manageThumbnailTags,
    label: '썸네일 태그…',
    intent: const ManageThumbnailTagsIntent(),
    icon: Icons.image_outlined,
    shortcut: _primaryShift(LogicalKeyboardKey.keyT),
  ),
  const AppCommand(
    id: AppCommandId.help,
    label: '도움말 보기',
    intent: HelpIntent(),
    icon: Icons.help_outline,
    // 도움말의 관용 키. 워크스페이스가 없어도 볼 수 있어야 하므로 늘 활성이다.
    shortcut: SingleActivator(LogicalKeyboardKey.f1),
  ),
  const AppCommand(
    id: AppCommandId.exitApp,
    label: '프로그램 종료',
    intent: ExitAppIntent(),
    icon: Icons.power_settings_new,
    // 단축키 없음: 시스템 종료(Alt+F4 등)가 그 자리를 이미 쓴다.
  ),
  AppCommand(
    id: AppCommandId.tagDisplayOrder,
    label: '태그 표시 순서',
    intent: const TagDisplayOrderIntent(),
    icon: Icons.reorder,
    shortcut: _primaryShift(LogicalKeyboardKey.keyO),
  ),
  AppCommand(
    id: AppCommandId.toggleFilterBar,
    label: '필터 조건 보기',
    intent: const ToggleFilterBarIntent(),
    icon: Icons.filter_alt_outlined,
    shortcut: _primary(LogicalKeyboardKey.keyF),
  ),
  AppCommand(
    id: AppCommandId.toggleSortBar,
    label: '정렬 조건 보기',
    intent: const ToggleSortBarIntent(),
    icon: Icons.sort,
    shortcut: _primaryShift(LogicalKeyboardKey.keyS),
  ),
  AppCommand(
    id: AppCommandId.toggleListEdit,
    label: '목록에서 수정 활성화',
    intent: const ToggleListEditIntent(),
    icon: Icons.edit_note,
    shortcut: _primaryShift(LogicalKeyboardKey.keyE),
  ),
  AppCommand(
    id: AppCommandId.toggleGrouping,
    label: '그룹 기준 보기',
    intent: const ToggleGroupingIntent(),
    icon: Icons.account_tree_outlined,
    shortcut: _primary(LogicalKeyboardKey.keyG),
  ),
  AppCommand(
    id: AppCommandId.togglePresetBar,
    label: '프리셋 보기',
    intent: const TogglePresetBarIntent(),
    icon: Icons.bookmarks_outlined,
    // 프리뷰(Ctrl+P)의 둘째 층. 조건 줄 토글들과 같은 결로 보조키 하나를 나눠 쓴다.
    shortcut: _primaryShift(LogicalKeyboardKey.keyP),
  ),
  AppCommand(
    id: AppCommandId.togglePreview,
    label: '프리뷰 보기',
    intent: const TogglePreviewIntent(),
    icon: Icons.view_sidebar,
    shortcut: _primary(LogicalKeyboardKey.keyP),
  ),
  // 아래는 목록의 키보드 내비게이션 전용(메뉴에 노출하지 않는다). 모두 본문 스코프가
  // 포커스를 쥔 때만 들어 필터·정렬 텍스트 입력의 방향키·Delete·Enter를 가로채지 않는다.
  const AppCommand(
    id: AppCommandId.moveCursorUp,
    label: '커서 위로',
    intent: MoveCursorUpIntent(),
    shortcut: SingleActivator(LogicalKeyboardKey.arrowUp),
    requiresScopeFocus: true,
  ),
  const AppCommand(
    id: AppCommandId.moveCursorDown,
    label: '커서 아래로',
    intent: MoveCursorDownIntent(),
    shortcut: SingleActivator(LogicalKeyboardKey.arrowDown),
    requiresScopeFocus: true,
  ),
  const AppCommand(
    id: AppCommandId.extendSelectionUp,
    label: '범위 위로',
    intent: ExtendSelectionUpIntent(),
    shortcut: SingleActivator(LogicalKeyboardKey.arrowUp, shift: true),
    requiresScopeFocus: true,
  ),
  const AppCommand(
    id: AppCommandId.extendSelectionDown,
    label: '범위 아래로',
    intent: ExtendSelectionDownIntent(),
    shortcut: SingleActivator(LogicalKeyboardKey.arrowDown, shift: true),
    requiresScopeFocus: true,
  ),
  const AppCommand(
    id: AppCommandId.moveCursorUpNoSelect,
    label: '커서만 위로',
    intent: MoveCursorUpNoSelectIntent(),
    shortcut: SingleActivator(LogicalKeyboardKey.arrowUp, control: true),
    requiresScopeFocus: true,
  ),
  const AppCommand(
    id: AppCommandId.moveCursorDownNoSelect,
    label: '커서만 아래로',
    intent: MoveCursorDownNoSelectIntent(),
    shortcut: SingleActivator(LogicalKeyboardKey.arrowDown, control: true),
    requiresScopeFocus: true,
  ),
  const AppCommand(
    id: AppCommandId.moveTagLeft,
    label: '태그 왼쪽',
    intent: MoveTagLeftIntent(),
    shortcut: SingleActivator(LogicalKeyboardKey.arrowLeft),
    requiresScopeFocus: true,
  ),
  const AppCommand(
    id: AppCommandId.moveTagRight,
    label: '태그 오른쪽',
    intent: MoveTagRightIntent(),
    shortcut: SingleActivator(LogicalKeyboardKey.arrowRight),
    requiresScopeFocus: true,
  ),
  const AppCommand(
    id: AppCommandId.confirmCursor,
    label: '확정 / 열기',
    intent: ConfirmCursorIntent(),
    shortcut: SingleActivator(LogicalKeyboardKey.enter),
    requiresScopeFocus: true,
  ),
  const AppCommand(
    id: AppCommandId.toggleCursorSelection,
    label: '커서 선택 토글',
    intent: ToggleCursorSelectionIntent(),
    shortcut: SingleActivator(LogicalKeyboardKey.enter, control: true),
    requiresScopeFocus: true,
  ),
  const AppCommand(
    id: AppCommandId.deleteFocusedTag,
    label: '태그 제거',
    intent: DeleteFocusedTagIntent(),
    shortcut: SingleActivator(LogicalKeyboardKey.delete),
    requiresScopeFocus: true,
  ),
  AppCommand(
    id: AppCommandId.editFocusedTag,
    label: '태그값 수정',
    intent: const EditFocusedTagIntent(),
    // Delete(태그 제거)와 대칭인, 커서가 가리키는 태그값 수정.
    shortcut: _primary(LogicalKeyboardKey.keyE),
    requiresScopeFocus: true,
  ),
  // 보기 모드 전환. 메뉴엔 라디오로 이미 있어 여기선 단축키만 얹는다(브라우저·탐색기
  // 관용대로 숫자키). 언제든 바꿀 수 있어야 하므로 본문 포커스에 매이지 않는다.
  AppCommand(
    id: AppCommandId.viewModeList,
    label: '보기 모드: 목록',
    intent: const SetViewModeListIntent(),
    shortcut: _primary(LogicalKeyboardKey.digit1),
  ),
  AppCommand(
    id: AppCommandId.viewModeIcon,
    label: '보기 모드: 아이콘',
    intent: const SetViewModeIconIntent(),
    shortcut: _primary(LogicalKeyboardKey.digit2),
  ),
  AppCommand(
    id: AppCommandId.viewModeDetail,
    label: '보기 모드: 자세히',
    intent: const SetViewModeDetailIntent(),
    shortcut: _primary(LogicalKeyboardKey.digit3),
  ),
];

/// 식별자로 명령을 찾는다. 카탈로그에 없으면 프로그래밍 오류다.
AppCommand commandOf(AppCommandId id) =>
    appCommands.firstWhere((c) => c.id == id);

/// 단축키를 사람이 읽는 표기로 만든다.
///
/// 메뉴바는 프레임워크가 알아서 그리므로, 그 밖의 자리(도움말 등)에서 힌트를 보일 때만
/// 쓴다. 조합 키 이름은 플랫폼 관용을 따른다.
String shortcutLabel(SingleActivator shortcut) => [
  if (shortcut.control) 'Ctrl',
  if (shortcut.meta) isMacOS ? 'Cmd' : 'Win',
  if (shortcut.alt) 'Alt',
  if (shortcut.shift) 'Shift',
  shortcut.trigger.keyLabel,
].join('+');

/// 단축키가 있는 명령들의 활성자 → Intent 매핑(`Shortcuts` 위젯용).
Map<ShortcutActivator, Intent> commandShortcuts() => {
  for (final c in appCommands)
    if (c.shortcut != null) c.shortcut!: c.intent,
};
