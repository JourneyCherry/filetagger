import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform.dart';
import '../../domain/entities/folder_manage_mode.dart';
import '../../domain/entities/view_mode.dart';
import '../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final menus = _buildMenus(
      l10n,
      recent,
      ref.watch(rootManageModeProvider),
      ref.watch(viewModeProvider),
      ref.read(viewSettingsProvider.notifier).updateViewMode,
      ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.system,
      ref.read(themeModeProvider.notifier).set,
      ref.watch(appLocaleProvider).valueOrNull,
      ref.read(appLocaleProvider.notifier).set,
    );

    if (isMacOS) {
      return PlatformMenuBar(
        menus: [for (final menu in menus) _platformSubmenu(menu, l10n)],
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
            children: [for (final menu in menus) _materialNode(menu, l10n)],
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
    AppLocalizations l10n,
    List<String> recentFolders,
    FolderManageMode rootMode,
    ViewMode viewMode,
    ValueChanged<ViewMode> onSelectViewMode,
    ThemeMode themeMode,
    ValueChanged<ThemeMode> onSelectThemeMode,
    Locale? locale,
    ValueChanged<Locale?> onSelectLocale,
  ) {
    return [
      MenuSubmenu(l10n.menuFile, [
        const MenuCommand(AppCommandId.openFolder),
        MenuSubmenu(l10n.menuRecentFolders, _recentItems(l10n, recentFolders)),
        const MenuDivider(),
        const MenuCommand(AppCommandId.rescan),
        const MenuCommand(AppCommandId.closeFolder),
        const MenuDivider(),
        const MenuCommand(AppCommandId.exportSelection),
        const MenuDivider(),
        const MenuCommand(AppCommandId.exitApp),
      ]),
      MenuSubmenu(l10n.menuEdit, [
        const MenuCommand(AppCommandId.selectAll),
        const MenuCommand(AppCommandId.clearSelection),
        const MenuDivider(),
        const MenuCommand(AppCommandId.assignTags),
        const MenuCommand(AppCommandId.reconnect),
        const MenuDivider(),
        const MenuCommand(AppCommandId.openNode),
        const MenuCommand(AppCommandId.toggleExpand),
        const MenuCommand(AppCommandId.revealInFileManager),
        const MenuDivider(),
        MenuSubmenu(l10n.menuKeyword, const [
          MenuCommand(AppCommandId.createKeyword),
          MenuCommand(AppCommandId.editKeyword),
          MenuCommand(AppCommandId.deleteKeyword),
        ]),
        const MenuDivider(),
        MenuSubmenu(l10n.menuRootManageMode, _rootManageItems(l10n, rootMode)),
      ]),
      MenuSubmenu(l10n.menuView, [
        MenuSubmenu(
          l10n.menuViewMode,
          _viewModeItems(l10n, viewMode, onSelectViewMode),
        ),
        MenuSubmenu(
          l10n.menuTheme,
          _themeItems(l10n, themeMode, onSelectThemeMode),
        ),
        MenuSubmenu(
          l10n.menuLanguage,
          _languageItems(l10n, locale, onSelectLocale),
        ),
        const MenuDivider(),
        const MenuCommand(AppCommandId.togglePreview),
        const MenuDivider(),
        const MenuCommand(AppCommandId.togglePresetBar),
        const MenuCommand(AppCommandId.toggleGrouping),
        const MenuCommand(AppCommandId.toggleFilterBar),
        const MenuCommand(AppCommandId.toggleSortBar),
        const MenuCommand(AppCommandId.toggleListEdit),
      ]),
      MenuSubmenu(l10n.menuTag, [
        const MenuCommand(AppCommandId.manageTags),
        const MenuCommand(AppCommandId.manageNameTags),
        const MenuCommand(AppCommandId.manageSubtitleTags),
        const MenuCommand(AppCommandId.manageThumbnailTags),
      ]),
      MenuSubmenu(l10n.menuHelp, [
        const MenuCommand(AppCommandId.help),
        MenuSubmenu(l10n.menuHelpTopics, _helpTabItems(l10n)),
        const MenuDivider(),
        const MenuCommand(AppCommandId.checkForUpdates),
        const MenuCommand(AppCommandId.about),
      ]),
    ];
  }

  /// 파일 목록 보기 모드 선택지(목록/아이콘/자세히). 현재 모드를 체크로 보인다.
  /// 세그먼트 버튼과 라벨·순서를 [viewModeChoices]에서 함께 가져온다.
  List<MenuNode> _viewModeItems(
    AppLocalizations l10n,
    ViewMode current,
    ValueChanged<ViewMode> onSelect,
  ) {
    return [
      for (final choice in viewModeChoicesOf(l10n))
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
    AppLocalizations l10n,
    ThemeMode current,
    ValueChanged<ThemeMode> onSelect,
  ) {
    final labels = {
      ThemeMode.system: l10n.themeSystem,
      ThemeMode.light: l10n.themeLight,
      ThemeMode.dark: l10n.themeDark,
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

  /// 앱 표시 언어 선택지. 첫 항목(시스템 설정)은 OS 설정 언어를 따르는 갈래라 로케일
  /// 부재로 나타내고, 나머지는 지원 로케일을 그 언어의 자기 이름으로 늘어놓는다.
  List<MenuNode> _languageItems(
    AppLocalizations l10n,
    Locale? current,
    ValueChanged<Locale?> onSelect,
  ) {
    return [
      MenuChecked(
        l10n.languageSystem,
        checked: current == null,
        onSelected: () => onSelect(null),
      ),
      for (final locale in AppLocalizations.supportedLocales)
        MenuChecked(
          _languageName(l10n, locale),
          checked: locale.languageCode == current?.languageCode,
          onSelected: () => onSelect(locale),
        ),
    ];
  }

  /// 지원 로케일이 스스로를 부르는 이름. 목록에 없는 로케일이 늘면 언어 코드를 그대로
  /// 보여 항목이 조용히 사라지지 않게 한다.
  String _languageName(AppLocalizations l10n, Locale locale) =>
      switch (locale.languageCode) {
        'ko' => l10n.languageKorean,
        'en' => l10n.languageEnglish,
        _ => locale.languageCode,
      };

  /// 루트 폴더의 관리 방식 선택지(재귀 여부). 루트는 불투명이 없어 두 갈래다.
  List<MenuNode> _rootManageItems(
    AppLocalizations l10n,
    FolderManageMode rootMode,
  ) {
    final recursive = rootMode == FolderManageMode.managedRecursive;
    final onSet = onSetRootRecursive;
    return [
      MenuChecked(
        l10n.rootManageDirectOnly,
        checked: !recursive,
        onSelected: onSet == null ? null : () => onSet(false),
      ),
      MenuChecked(
        l10n.rootManageRecursive,
        checked: recursive,
        onSelected: onSet == null ? null : () => onSet(true),
      ),
    ];
  }

  /// 도움말의 각 탭으로 바로 가는 항목. 탭 이름·순서는 [HelpTab]이 단일 출처다.
  ///
  /// 도움말 메뉴에 펼쳐 두지 않고 하위 메뉴로 접는다 — 탭이 늘어도 메뉴가 길어지지 않고,
  /// 도움말 메뉴의 첫 층은 성격이 다른 항목(버전 정보 등)의 자리로 남는다.
  List<MenuNode> _helpTabItems(AppLocalizations l10n) {
    final open = onOpenHelpTab;
    return [
      for (final tab in HelpTab.values)
        MenuAction(tab.label(l10n), open == null ? null : () => open(tab)),
    ];
  }

  List<MenuNode> _recentItems(
    AppLocalizations l10n,
    List<String> recentFolders,
  ) {
    if (recentFolders.isEmpty) return [MenuAction(l10n.commonNone, null)];
    return [
      for (final folder in recentFolders)
        MenuAction(
          folder,
          onOpenRecent == null ? null : () => onOpenRecent!(folder),
        ),
    ];
  }

  /// 메뉴바는 라벨·단축키와, 토글 명령이면 체크만 보인다(아이콘은 툴바의 몫).
  Widget _materialNode(MenuNode node, AppLocalizations l10n) =>
      materialMenuNode(
        node,
        l10n: l10n,
        handlers: handlers,
        commandChecks: commandChecks,
      );

  // ── PlatformMenuBar 렌더(macOS) ──

  PlatformMenu _platformSubmenu(MenuSubmenu submenu, AppLocalizations l10n) {
    return PlatformMenu(
      label: submenu.label,
      menus: _platformGroups(submenu.children, l10n),
    );
  }

  /// 네이티브 메뉴는 구분선을 항목이 아니라 **그룹 경계**로 표현한다. 구분선을
  /// 기준으로 항목들을 잘라 그룹으로 묶는다.
  List<PlatformMenuItem> _platformGroups(
    List<MenuNode> nodes,
    AppLocalizations l10n,
  ) {
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
          current.add(_platformSubmenu(node, l10n));
        case MenuCommand(:final id):
          final command = commandOf(id);
          current.add(
            PlatformMenuItem(
              label: _platformLabel(command.label(l10n), commandChecks[id]),
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
