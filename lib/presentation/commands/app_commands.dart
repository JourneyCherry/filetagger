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
import '../../l10n/app_localizations.dart';
import 'app_intents.dart';

/// 명령의 안정적 식별자. 핸들러 배선과 메뉴 구성이 이 값으로 명령을 가리킨다.
enum AppCommandId {
  openFolder,
  closeFolder,
  rescan,
  selectAll,
  clearSelection,
  openNode,
  toggleExpand,
  assignTags,
  reconnect,
  revealInFileManager,
  exportSelection,
  manageTags,
  manageThumbnailTags,
  manageNameTags,
  manageSubtitleTags,
  tagDisplayOrder,
  createKeyword,
  editKeyword,
  deleteKeyword,
  help,
  checkForUpdates,
  about,
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
  cursorLeft,
  cursorRight,
  toggleTagFocus,
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

  /// 메뉴·툴팁에 보이는 이름. 로케일이 정해지는 자리에서 풀어야 하므로 문자열이
  /// 아니라 **번역본을 받아 이름을 내는 함수**다 — 카탈로그가 앱 시작에 한 번
  /// 만들어지는 데 반해 표시 언어는 실행 중에도 바뀐다.
  final String Function(AppLocalizations) label;

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
    label: (l) => l.cmdOpenFolder,
    intent: const OpenFolderIntent(),
    icon: Icons.folder_open,
    shortcut: _primary(LogicalKeyboardKey.keyO),
  ),
  AppCommand(
    id: AppCommandId.closeFolder,
    label: (l) => l.cmdCloseFolder,
    intent: const CloseFolderIntent(),
    icon: Icons.close,
    shortcut: _primary(LogicalKeyboardKey.keyW),
  ),
  AppCommand(
    id: AppCommandId.rescan,
    label: (l) => l.cmdRescan,
    intent: const RescanIntent(),
    icon: Icons.refresh,
    shortcut: const SingleActivator(LogicalKeyboardKey.f5),
  ),
  AppCommand(
    id: AppCommandId.selectAll,
    label: (l) => l.cmdSelectAll,
    intent: const SelectAllIntent(),
    icon: Icons.select_all,
    shortcut: _primary(LogicalKeyboardKey.keyA),
  ),
  AppCommand(
    id: AppCommandId.clearSelection,
    label: (l) => l.cmdClearSelection,
    intent: const ClearSelectionIntent(),
    shortcut: const SingleActivator(LogicalKeyboardKey.escape),
  ),
  // 열기는 OS에 넘기는 조작이다(파일=확장자에 연결된 앱, 폴더=파일 관리자). 앱 안에서
  // 계층을 여닫는 펼치기와 성격이 달라 명령을 가른다. 단축키는 두지 않는다 — 행 레벨
  // Enter가 곧 열기이고, 그 Enter는 커서·선택 상태를 함께 해석하는 confirmCursor가 쥔다.
  AppCommand(
    id: AppCommandId.openNode,
    label: (l) => l.cmdOpenNode,
    intent: const OpenNodeIntent(),
    icon: Icons.launch,
  ),
  AppCommand(
    id: AppCommandId.toggleExpand,
    label: (l) => l.cmdToggleExpand,
    intent: const ToggleExpandIntent(),
    icon: Icons.unfold_more,
    // 방향이 정해진 좌우 방향키와 별개로, 커서 위치와 무관하게 늘 뒤집는 전용키다.
    shortcut: _primary(LogicalKeyboardKey.keyM),
    requiresScopeFocus: true,
  ),
  AppCommand(
    id: AppCommandId.assignTags,
    label: (l) => l.cmdAssignTags,
    intent: const AssignTagsIntent(),
    icon: Icons.sell_outlined,
    // Delete가 커서 태그를 제거하는 것과 짝을 이룬다(Insert=부여).
    shortcut: _primary(LogicalKeyboardKey.insert),
  ),
  AppCommand(
    id: AppCommandId.reconnect,
    label: (l) => l.cmdReconnect,
    intent: const ReconnectIntent(),
    icon: Icons.link,
    shortcut: _primaryShift(LogicalKeyboardKey.keyL),
  ),
  AppCommand(
    id: AppCommandId.revealInFileManager,
    label: (l) => l.cmdRevealInFileManager,
    intent: const RevealInFileManagerIntent(),
    icon: Icons.open_in_new,
    shortcut: _primaryShift(LogicalKeyboardKey.keyR),
  ),
  // 고른 항목의 태그를 요청함 파일로 내보낸다. 단축키는 두지 않는다 — 가끔 쓰는
  // 조작이라 남은 조합을 차지하기보다 메뉴·컨텍스트 메뉴로만 부른다(키워드 명령과 같은 결).
  AppCommand(
    id: AppCommandId.exportSelection,
    label: (l) => l.cmdExportSelection,
    intent: const ExportSelectionIntent(),
    icon: Icons.ios_share,
  ),
  AppCommand(
    id: AppCommandId.manageTags,
    label: (l) => l.cmdManageTags,
    intent: const ManageTagsIntent(),
    icon: Icons.sell_outlined,
    shortcut: _primary(LogicalKeyboardKey.keyT),
  ),
  AppCommand(
    id: AppCommandId.manageThumbnailTags,
    label: (l) => l.cmdManageThumbnailTags,
    intent: const ManageThumbnailTagsIntent(),
    icon: Icons.image_outlined,
    shortcut: _primaryShift(LogicalKeyboardKey.keyT),
  ),
  AppCommand(
    id: AppCommandId.manageNameTags,
    label: (l) => l.cmdManageNameTags,
    intent: const ManageNameTagsIntent(),
    icon: Icons.text_fields,
    // 태그 설정 셋은 같은 층(Shift)에 두되, T 자리는 썸네일이 이미 썼으므로 이름의
    // 머리글자를 쓴다.
    shortcut: _primaryShift(LogicalKeyboardKey.keyN),
  ),
  // 부제 태그는 이름 태그와 한 벌이지만 단축키를 두지 않는다 — 한 번 정해 두면 그대로
  // 두는 설정이라 메뉴로 충분하고, 남은 조합을 더 쓰지 않는 편이 낫다.
  AppCommand(
    id: AppCommandId.manageSubtitleTags,
    label: (l) => l.cmdManageSubtitleTags,
    intent: const ManageSubtitleTagsIntent(),
    icon: Icons.short_text,
  ),
  // 키워드(디스크에 남지 않는 노드) 만들기·고치기·지우기. 단축키는 두지 않는다 —
  // 가끔 쓰는 조작이라 남은 조합을 쓰기보다 메뉴·컨텍스트 메뉴로만 부른다.
  AppCommand(
    id: AppCommandId.createKeyword,
    label: (l) => l.cmdCreateKeyword,
    intent: const CreateKeywordIntent(),
    icon: Icons.sell_outlined,
  ),
  AppCommand(
    id: AppCommandId.editKeyword,
    label: (l) => l.cmdEditKeyword,
    intent: const EditKeywordIntent(),
    icon: Icons.edit_outlined,
  ),
  AppCommand(
    id: AppCommandId.deleteKeyword,
    label: (l) => l.cmdDeleteKeyword,
    intent: const DeleteKeywordIntent(),
    icon: Icons.delete_outline,
  ),
  AppCommand(
    id: AppCommandId.help,
    label: (l) => l.cmdHelp,
    intent: const HelpIntent(),
    icon: Icons.help_outline,
    // 도움말의 관용 키. 워크스페이스가 없어도 볼 수 있어야 하므로 늘 활성이다.
    shortcut: const SingleActivator(LogicalKeyboardKey.f1),
  ),
  AppCommand(
    id: AppCommandId.checkForUpdates,
    label: (l) => l.cmdCheckForUpdates,
    intent: const CheckForUpdatesIntent(),
    icon: Icons.system_update_alt,
    // 단축키 없음: 앱을 켤 때 자동으로 한 번 도는 일을 사용자가 다시 시키는
    // 자리라, 키를 차지할 만큼 자주 쓰이지 않는다.
  ),
  AppCommand(
    id: AppCommandId.about,
    label: (l) => l.cmdAbout,
    intent: const AboutIntent(),
    icon: Icons.info_outline,
    // 단축키 없음: 가끔 한 번 여는 자리라 키를 차지할 이유가 없다. 도움말과 달리
    // 워크스페이스와도 무관하게 늘 활성이다.
  ),
  AppCommand(
    id: AppCommandId.exitApp,
    label: (l) => l.cmdExitApp,
    intent: const ExitAppIntent(),
    icon: Icons.power_settings_new,
    // 단축키 없음: 시스템 종료(Alt+F4 등)가 그 자리를 이미 쓴다.
  ),
  AppCommand(
    id: AppCommandId.tagDisplayOrder,
    label: (l) => l.cmdTagDisplayOrder,
    intent: const TagDisplayOrderIntent(),
    icon: Icons.reorder,
    shortcut: _primaryShift(LogicalKeyboardKey.keyO),
  ),
  AppCommand(
    id: AppCommandId.toggleFilterBar,
    label: (l) => l.cmdToggleFilterBar,
    intent: const ToggleFilterBarIntent(),
    icon: Icons.filter_alt_outlined,
    shortcut: _primary(LogicalKeyboardKey.keyF),
  ),
  AppCommand(
    id: AppCommandId.toggleSortBar,
    label: (l) => l.cmdToggleSortBar,
    intent: const ToggleSortBarIntent(),
    icon: Icons.sort,
    shortcut: _primaryShift(LogicalKeyboardKey.keyS),
  ),
  AppCommand(
    id: AppCommandId.toggleListEdit,
    label: (l) => l.cmdToggleListEdit,
    intent: const ToggleListEditIntent(),
    icon: Icons.edit_note,
    shortcut: _primaryShift(LogicalKeyboardKey.keyE),
  ),
  AppCommand(
    id: AppCommandId.toggleGrouping,
    label: (l) => l.cmdToggleGrouping,
    intent: const ToggleGroupingIntent(),
    icon: Icons.account_tree_outlined,
    shortcut: _primary(LogicalKeyboardKey.keyG),
  ),
  AppCommand(
    id: AppCommandId.togglePresetBar,
    label: (l) => l.cmdTogglePresetBar,
    intent: const TogglePresetBarIntent(),
    icon: Icons.bookmarks_outlined,
    // 프리뷰(Ctrl+P)의 둘째 층. 조건 줄 토글들과 같은 결로 보조키 하나를 나눠 쓴다.
    shortcut: _primaryShift(LogicalKeyboardKey.keyP),
  ),
  AppCommand(
    id: AppCommandId.togglePreview,
    label: (l) => l.cmdTogglePreview,
    intent: const TogglePreviewIntent(),
    icon: Icons.view_sidebar,
    shortcut: _primary(LogicalKeyboardKey.keyP),
  ),
  // 아래는 목록의 키보드 내비게이션 전용(메뉴에 노출하지 않는다). 모두 본문 스코프가
  // 포커스를 쥔 때만 들어 필터·정렬 텍스트 입력의 방향키·Delete·Enter를 가로채지 않는다.
  AppCommand(
    id: AppCommandId.moveCursorUp,
    label: (l) => l.cmdMoveCursorUp,
    intent: const MoveCursorUpIntent(),
    shortcut: const SingleActivator(LogicalKeyboardKey.arrowUp),
    requiresScopeFocus: true,
  ),
  AppCommand(
    id: AppCommandId.moveCursorDown,
    label: (l) => l.cmdMoveCursorDown,
    intent: const MoveCursorDownIntent(),
    shortcut: const SingleActivator(LogicalKeyboardKey.arrowDown),
    requiresScopeFocus: true,
  ),
  AppCommand(
    id: AppCommandId.extendSelectionUp,
    label: (l) => l.cmdExtendSelectionUp,
    intent: const ExtendSelectionUpIntent(),
    shortcut: const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true),
    requiresScopeFocus: true,
  ),
  AppCommand(
    id: AppCommandId.extendSelectionDown,
    label: (l) => l.cmdExtendSelectionDown,
    intent: const ExtendSelectionDownIntent(),
    shortcut: const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true),
    requiresScopeFocus: true,
  ),
  AppCommand(
    id: AppCommandId.moveCursorUpNoSelect,
    label: (l) => l.cmdMoveCursorUpNoSelect,
    intent: const MoveCursorUpNoSelectIntent(),
    shortcut: const SingleActivator(LogicalKeyboardKey.arrowUp, control: true),
    requiresScopeFocus: true,
  ),
  AppCommand(
    id: AppCommandId.moveCursorDownNoSelect,
    label: (l) => l.cmdMoveCursorDownNoSelect,
    intent: const MoveCursorDownNoSelectIntent(),
    shortcut: const SingleActivator(
      LogicalKeyboardKey.arrowDown,
      control: true,
    ),
    requiresScopeFocus: true,
  ),
  // 좌우는 Enter처럼 커서 위치로 뜻이 갈린다: 행 레벨이면 트리 관용의 접기/펼치기,
  // 태그 칸에 들어가 있으면 칸 이동. 같은 키에 두 명령을 걸 수 없어 한 명령이 갈래를
  // 정한다. 왼쪽은 접을 것이 없으면 상위 행으로 올라가 계층을 거슬러 오른다.
  AppCommand(
    id: AppCommandId.cursorLeft,
    label: (l) => l.cmdCursorLeft,
    intent: const CursorLeftIntent(),
    shortcut: const SingleActivator(LogicalKeyboardKey.arrowLeft),
    requiresScopeFocus: true,
  ),
  AppCommand(
    id: AppCommandId.cursorRight,
    label: (l) => l.cmdCursorRight,
    intent: const CursorRightIntent(),
    shortcut: const SingleActivator(LogicalKeyboardKey.arrowRight),
    requiresScopeFocus: true,
  ),
  // 좌우가 펼침을 맡으므로 태그 칸으로 들어가는 문을 따로 낸다. '목록에서 수정'이
  // 켜져 있고 고른 것이 여럿이 아닐 때만 활성이라, 그 밖에는 단축키를 소비하지 않아
  // Tab의 평소 포커스 이동이 그대로 산다.
  AppCommand(
    id: AppCommandId.toggleTagFocus,
    label: (l) => l.cmdToggleTagFocus,
    intent: const ToggleTagFocusIntent(),
    shortcut: const SingleActivator(LogicalKeyboardKey.tab),
    requiresScopeFocus: true,
  ),
  AppCommand(
    id: AppCommandId.confirmCursor,
    label: (l) => l.cmdConfirmCursor,
    intent: const ConfirmCursorIntent(),
    shortcut: const SingleActivator(LogicalKeyboardKey.enter),
    requiresScopeFocus: true,
  ),
  AppCommand(
    id: AppCommandId.toggleCursorSelection,
    label: (l) => l.cmdToggleCursorSelection,
    intent: const ToggleCursorSelectionIntent(),
    shortcut: const SingleActivator(LogicalKeyboardKey.enter, control: true),
    requiresScopeFocus: true,
  ),
  AppCommand(
    id: AppCommandId.deleteFocusedTag,
    label: (l) => l.cmdDeleteFocusedTag,
    intent: const DeleteFocusedTagIntent(),
    shortcut: const SingleActivator(LogicalKeyboardKey.delete),
    requiresScopeFocus: true,
  ),
  AppCommand(
    id: AppCommandId.editFocusedTag,
    label: (l) => l.cmdEditFocusedTag,
    intent: const EditFocusedTagIntent(),
    // Delete(태그 제거)와 대칭인, 커서가 가리키는 태그값 수정.
    shortcut: _primary(LogicalKeyboardKey.keyE),
    requiresScopeFocus: true,
  ),
  // 보기 모드 전환. 메뉴엔 라디오로 이미 있어 여기선 단축키만 얹는다(브라우저·탐색기
  // 관용대로 숫자키). 언제든 바꿀 수 있어야 하므로 본문 포커스에 매이지 않는다.
  AppCommand(
    id: AppCommandId.viewModeList,
    label: (l) => l.cmdViewModeList,
    intent: const SetViewModeListIntent(),
    shortcut: _primary(LogicalKeyboardKey.digit1),
  ),
  AppCommand(
    id: AppCommandId.viewModeIcon,
    label: (l) => l.cmdViewModeIcon,
    intent: const SetViewModeIconIntent(),
    shortcut: _primary(LogicalKeyboardKey.digit2),
  ),
  AppCommand(
    id: AppCommandId.viewModeDetail,
    label: (l) => l.cmdViewModeDetail,
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
