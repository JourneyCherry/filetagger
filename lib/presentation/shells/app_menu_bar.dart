import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform.dart';
import '../../domain/entities/folder_manage_mode.dart';
import '../../domain/entities/view_mode.dart';
import '../commands/app_commands.dart';
import '../commands/command_scope.dart';
import '../help_topics.dart';
import '../providers/file_view_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/view_mode_selector.dart';
import 'menu_model.dart';

/// 네이티브 메뉴(macOS)에서 체크 항목의 라벨 앞에 붙일 표식.
const String _checkMark = '✓';

/// 네이티브 메뉴 항목은 체크 상태를 받지 않으므로 라벨에 표식을 얹어 대신한다.
String _platformLabel(String label, bool? checked) =>
    (checked ?? false) ? '$_checkMark $label' : label;

/// 앱 메뉴바. macOS는 OS 네이티브 메뉴로, Windows/Linux는 본문 위 앱 내 메뉴로
/// 그린다. 어느 쪽이든 [child]를 그대로 아래에 둔다.
class AppMenuBar extends ConsumerWidget {
  const AppMenuBar({
    super.key,
    required this.handlers,
    required this.onOpenRecent,
    required this.onSetRootRecursive,
    required this.onOpenHelpTab,
    required this.commandChecks,
    required this.child,
  });

  final CommandHandlers handlers;

  /// 켜짐/꺼짐을 오가는 명령('보기'의 토글들)의 현재 상태. 여기 실린 명령만 체크
  /// 표시 자리를 갖는다.
  final Map<AppCommandId, bool> commandChecks;

  /// 최근 폴더 하나를 여는 콜백. null이면 최근 목록 전체가 비활성(작업 중 등).
  final ValueChanged<String>? onOpenRecent;

  /// 루트 폴더를 재귀 관리할지 정하는 콜백. null이면 관리 방식 항목이 비활성
  /// (열린 워크스페이스 없음).
  final ValueChanged<bool>? onSetRootRecursive;

  /// 도움말을 특정 탭으로 여는 콜백. 어느 탭에 있는지 모르고 찾는 사람을 위해 탭을
  /// 메뉴에 늘어놓되, 여는 것은 늘 같은 한 다이얼로그다.
  final ValueChanged<HelpTab>? onOpenHelpTab;

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentFoldersProvider).valueOrNull ?? const [];
    final menus = _buildMenus(
      recent,
      ref.watch(rootManageModeProvider),
      ref.watch(viewModeProvider),
      ref.read(viewSettingsProvider.notifier).updateViewMode,
      ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.system,
      ref.read(themeModeProvider.notifier).set,
    );

    if (isMacOS) {
      return PlatformMenuBar(
        menus: [for (final menu in menus) _platformSubmenu(menu)],
        child: child,
      );
    }
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: MenuBar(
            style: const MenuStyle(
              elevation: WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(Colors.transparent),
            ),
            children: [for (final menu in menus) _materialNode(menu)],
          ),
        ),
        const Divider(),
        Expanded(child: child),
      ],
    );
  }

  /// 메뉴바의 최상위 메뉴들. 최근 폴더·루트 관리 방식은 상태에 따라 달라져 여기서
  /// 조립한다.
  List<MenuSubmenu> _buildMenus(
    List<String> recentFolders,
    FolderManageMode rootMode,
    ViewMode viewMode,
    ValueChanged<ViewMode> onSelectViewMode,
    ThemeMode themeMode,
    ValueChanged<ThemeMode> onSelectThemeMode,
  ) {
    return [
      MenuSubmenu('파일', [
        const MenuCommand(AppCommandId.openFolder),
        MenuSubmenu('최근 연 폴더', _recentItems(recentFolders)),
        const MenuDivider(),
        const MenuCommand(AppCommandId.rescan),
        const MenuCommand(AppCommandId.closeFolder),
        const MenuDivider(),
        const MenuCommand(AppCommandId.exportSelection),
        const MenuDivider(),
        const MenuCommand(AppCommandId.exitApp),
      ]),
      MenuSubmenu('편집', [
        const MenuCommand(AppCommandId.selectAll),
        const MenuCommand(AppCommandId.clearSelection),
        const MenuDivider(),
        const MenuCommand(AppCommandId.assignTags),
        const MenuCommand(AppCommandId.reconnect),
        const MenuCommand(AppCommandId.revealInFileManager),
        const MenuDivider(),
        const MenuSubmenu('키워드', [
          MenuCommand(AppCommandId.createKeyword),
          MenuCommand(AppCommandId.editKeyword),
          MenuCommand(AppCommandId.deleteKeyword),
        ]),
        const MenuDivider(),
        MenuSubmenu('루트 폴더 관리 방식', _rootManageItems(rootMode)),
      ]),
      MenuSubmenu('보기', [
        MenuSubmenu('보기 모드', _viewModeItems(viewMode, onSelectViewMode)),
        MenuSubmenu('테마', _themeItems(themeMode, onSelectThemeMode)),
        const MenuDivider(),
        const MenuCommand(AppCommandId.togglePreview),
        const MenuDivider(),
        const MenuCommand(AppCommandId.togglePresetBar),
        const MenuCommand(AppCommandId.toggleGrouping),
        const MenuCommand(AppCommandId.toggleFilterBar),
        const MenuCommand(AppCommandId.toggleSortBar),
        const MenuCommand(AppCommandId.toggleListEdit),
      ]),
      MenuSubmenu('태그', [
        const MenuCommand(AppCommandId.manageTags),
        const MenuCommand(AppCommandId.manageNameTags),
        const MenuCommand(AppCommandId.manageThumbnailTags),
      ]),
      MenuSubmenu('도움말', [
        const MenuCommand(AppCommandId.help),
        MenuSubmenu('항목별 보기', _helpTabItems()),
        const MenuDivider(),
        const MenuCommand(AppCommandId.checkForUpdates),
        const MenuCommand(AppCommandId.about),
      ]),
    ];
  }

  /// 파일 목록 보기 모드 선택지(목록/아이콘/자세히). 현재 모드를 체크로 보인다.
  /// 세그먼트 버튼과 라벨·순서를 [viewModeChoices]에서 함께 가져온다.
  List<MenuNode> _viewModeItems(
    ViewMode current,
    ValueChanged<ViewMode> onSelect,
  ) {
    return [
      for (final choice in viewModeChoices)
        MenuChecked(
          choice.label,
          checked: choice.mode == current,
          onSelected: () => onSelect(choice.mode),
          shortcut: commandOf(_viewModeCommandId(choice.mode)).shortcut,
        ),
    ];
  }

  /// 보기 모드 라디오 항목에 힌트로 얹을, 같은 전환을 부르는 명령의 식별자.
  AppCommandId _viewModeCommandId(ViewMode mode) => switch (mode) {
    ViewMode.list => AppCommandId.viewModeList,
    ViewMode.icon => AppCommandId.viewModeIcon,
    ViewMode.detail => AppCommandId.viewModeDetail,
  };

  /// 라이트/다크 테마 선택지(시스템/밝게/어둡게). 현재 모드를 체크로 보인다.
  List<MenuNode> _themeItems(
    ThemeMode current,
    ValueChanged<ThemeMode> onSelect,
  ) {
    const labels = {
      ThemeMode.system: '시스템 설정',
      ThemeMode.light: '밝게',
      ThemeMode.dark: '어둡게',
    };
    return [
      for (final entry in labels.entries)
        MenuChecked(
          entry.value,
          checked: entry.key == current,
          onSelected: () => onSelect(entry.key),
        ),
    ];
  }

  /// 루트 폴더의 관리 방식 선택지(재귀 여부). 루트는 불투명이 없어 두 갈래다.
  List<MenuNode> _rootManageItems(FolderManageMode rootMode) {
    final recursive = rootMode == FolderManageMode.managedRecursive;
    final onSet = onSetRootRecursive;
    return [
      MenuChecked(
        '직속 항목만 관리',
        checked: !recursive,
        onSelected: onSet == null ? null : () => onSet(false),
      ),
      MenuChecked(
        '전체 재귀 관리',
        checked: recursive,
        onSelected: onSet == null ? null : () => onSet(true),
      ),
    ];
  }

  /// 도움말의 각 탭으로 바로 가는 항목. 탭 이름·순서는 [HelpTab]이 단일 출처다.
  ///
  /// 도움말 메뉴에 펼쳐 두지 않고 하위 메뉴로 접는다 — 탭이 늘어도 메뉴가 길어지지 않고,
  /// 도움말 메뉴의 첫 층은 성격이 다른 항목(버전 정보 등)의 자리로 남는다.
  List<MenuNode> _helpTabItems() {
    final open = onOpenHelpTab;
    return [
      for (final tab in HelpTab.values)
        MenuAction(tab.label, open == null ? null : () => open(tab)),
    ];
  }

  List<MenuNode> _recentItems(List<String> recentFolders) {
    if (recentFolders.isEmpty) return const [MenuAction('없음', null)];
    return [
      for (final folder in recentFolders)
        MenuAction(
          folder,
          onOpenRecent == null ? null : () => onOpenRecent!(folder),
        ),
    ];
  }

  /// 메뉴바는 라벨·단축키와, 토글 명령이면 체크만 보인다(아이콘은 툴바의 몫).
  Widget _materialNode(MenuNode node) =>
      materialMenuNode(node, handlers: handlers, commandChecks: commandChecks);

  // ── PlatformMenuBar 렌더(macOS) ──

  PlatformMenu _platformSubmenu(MenuSubmenu submenu) {
    return PlatformMenu(
      label: submenu.label,
      menus: _platformGroups(submenu.children),
    );
  }

  /// 네이티브 메뉴는 구분선을 항목이 아니라 **그룹 경계**로 표현한다. 구분선을
  /// 기준으로 항목들을 잘라 그룹으로 묶는다.
  List<PlatformMenuItem> _platformGroups(List<MenuNode> nodes) {
    final groups = <PlatformMenuItem>[];
    var current = <PlatformMenuItem>[];

    void flush() {
      if (current.isEmpty) return;
      groups.add(PlatformMenuItemGroup(members: current));
      current = [];
    }

    for (final node in nodes) {
      switch (node) {
        case MenuDivider():
          flush();
        case MenuSubmenu():
          current.add(_platformSubmenu(node));
        case MenuCommand(:final id):
          final command = commandOf(id);
          current.add(
            PlatformMenuItem(
              label: _platformLabel(command.label, commandChecks[id]),
              shortcut: command.shortcut,
              onSelected: handlers.handlerOf(id),
            ),
          );
        case MenuAction(:final label, :final onSelected):
          current.add(PlatformMenuItem(label: label, onSelected: onSelected));
        case MenuChecked(
          :final label,
          :final checked,
          :final onSelected,
          :final shortcut,
        ):
          current.add(
            PlatformMenuItem(
              label: _platformLabel(label, checked),
              shortcut: shortcut,
              onSelected: onSelected,
            ),
          );
      }
    }
    flush();
    return groups;
  }
}
