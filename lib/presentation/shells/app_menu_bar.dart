import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform.dart';
import '../../domain/entities/folder_manage_mode.dart';
import '../../domain/entities/view_mode.dart';
import '../commands/app_commands.dart';
import '../commands/command_scope.dart';
import '../providers/file_view_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/view_mode_selector.dart';

/// 네이티브 메뉴(macOS)에서 체크 항목의 라벨 앞에 붙일 표식.
const String _checkMark = '✓';

/// 네이티브 메뉴 항목은 체크 상태를 받지 않으므로 라벨에 표식을 얹어 대신한다.
String _platformLabel(String label, bool? checked) =>
    (checked ?? false) ? '$_checkMark $label' : label;

/// 체크 표시 아이콘의 크기(메뉴 라벨 글자와 어울리게 줄인다).
const double _checkIconSize = 18;

/// 체크 상태를 갖는 항목의 앞 아이콘. [checked]가 null이면(토글이 아닌 항목) 자리를
/// 아예 두지 않고, false면 자리만 비워 같은 메뉴의 켜진 항목과 라벨을 맞춘다.
Widget? _checkIcon(bool? checked) => checked == null
    ? null
    : Icon(checked ? Icons.check : null, size: _checkIconSize);

/// 메뉴 트리의 한 항목.
///
/// 메뉴 구성을 데이터로 한 번만 적어 두고, 플랫폼별 렌더러가 이를 읽어 각각
/// OS 네이티브 메뉴(macOS)와 앱 내 메뉴(그 외)를 그린다. 라벨·단축키·활성 여부는
/// 명령 카탈로그가 단일 출처다.
sealed class MenuNode {
  const MenuNode();
}

/// 명령 카탈로그의 명령 하나를 그대로 항목으로 보인다.
class MenuCommand extends MenuNode {
  const MenuCommand(this.id);

  final AppCommandId id;
}

/// 라벨·동작을 직접 주는 항목(최근 폴더처럼 카탈로그에 없는 동적 목록).
class MenuAction extends MenuNode {
  const MenuAction(this.label, this.onSelected);

  final String label;

  /// null이면 비활성.
  final VoidCallback? onSelected;
}

/// 현재 선택 여부를 체크로 보이는 항목(라디오·토글 성격의 설정).
class MenuChecked extends MenuNode {
  const MenuChecked(this.label, {required this.checked, this.onSelected});

  final String label;
  final bool checked;

  /// null이면 비활성.
  final VoidCallback? onSelected;
}

/// 하위 메뉴.
class MenuSubmenu extends MenuNode {
  const MenuSubmenu(this.label, this.children);

  final String label;
  final List<MenuNode> children;
}

/// 항목 사이의 구분선.
class MenuDivider extends MenuNode {
  const MenuDivider();
}

/// 앱 메뉴바. macOS는 OS 네이티브 메뉴로, Windows/Linux는 본문 위 앱 내 메뉴로
/// 그린다. 어느 쪽이든 [child]를 그대로 아래에 둔다.
class AppMenuBar extends ConsumerWidget {
  const AppMenuBar({
    super.key,
    required this.handlers,
    required this.onOpenRecent,
    required this.onSetRootRecursive,
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

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentFoldersProvider).valueOrNull ?? const [];
    final menus = _buildMenus(
      recent,
      ref.watch(rootManageModeProvider),
      ref.watch(viewModeProvider),
      ref.read(viewSettingsProvider.notifier).updateViewMode,
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
  ) {
    return [
      MenuSubmenu('파일', [
        const MenuCommand(AppCommandId.openFolder),
        MenuSubmenu('최근 연 폴더', _recentItems(recentFolders)),
        const MenuDivider(),
        const MenuCommand(AppCommandId.rescan),
        const MenuCommand(AppCommandId.closeFolder),
      ]),
      MenuSubmenu('편집', [
        const MenuCommand(AppCommandId.selectAll),
        const MenuCommand(AppCommandId.clearSelection),
        const MenuDivider(),
        const MenuCommand(AppCommandId.assignTags),
        const MenuCommand(AppCommandId.reconnect),
        const MenuCommand(AppCommandId.revealInFileManager),
        const MenuDivider(),
        MenuSubmenu('루트 폴더 관리 방식', _rootManageItems(rootMode)),
      ]),
      MenuSubmenu('보기', [
        MenuSubmenu('보기 모드', _viewModeItems(viewMode, onSelectViewMode)),
        const MenuDivider(),
        const MenuCommand(AppCommandId.togglePreview),
        const MenuDivider(),
        const MenuCommand(AppCommandId.toggleGrouping),
        const MenuCommand(AppCommandId.toggleFilterBar),
        const MenuCommand(AppCommandId.toggleSortBar),
        const MenuCommand(AppCommandId.toggleListEdit),
      ]),
      const MenuSubmenu('태그', [MenuCommand(AppCommandId.manageTags)]),
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

  // ── Material 렌더(Windows/Linux) ──

  Widget _materialNode(MenuNode node) {
    switch (node) {
      case MenuSubmenu(:final label, :final children):
        return SubmenuButton(
          menuChildren: [for (final child in children) _materialNode(child)],
          child: Text(label),
        );
      case MenuCommand(:final id):
        final command = commandOf(id);
        // 메뉴바는 라벨·단축키와, 토글 명령이면 체크만 보인다(아이콘은 툴바의 몫).
        return MenuItemButton(
          onPressed: handlers.handlerOf(id),
          shortcut: command.shortcut,
          leadingIcon: _checkIcon(commandChecks[id]),
          child: Text(command.label),
        );
      case MenuAction(:final label, :final onSelected):
        return MenuItemButton(onPressed: onSelected, child: Text(label));
      case MenuChecked(:final label, :final checked, :final onSelected):
        return MenuItemButton(
          onPressed: onSelected,
          leadingIcon: _checkIcon(checked),
          child: Text(label),
        );
      case MenuDivider():
        return const Divider();
    }
  }

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
        case MenuChecked(:final label, :final checked, :final onSelected):
          current.add(
            PlatformMenuItem(
              label: _platformLabel(label, checked),
              onSelected: onSelected,
            ),
          );
      }
    }
    flush();
    return groups;
  }
}
