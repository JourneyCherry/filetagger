import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../core/constants.dart';
import '../../l10n/app_localizations.dart';
import '../commands/app_commands.dart';
import '../commands/command_scope.dart';
import '../common/pointer_presence.dart';
import 'menu_model.dart';

/// 모바일 셸의 골격: AppBar(+선택 모드 컨텍스트 AppBar) · 본문 · FAB.
///
/// 데스크톱 셸과 같은 [CommandHandlers]를 다른 크롬에 붙인다. 메뉴바·상태표시줄
/// 대신 오버플로 메뉴와 FAB로 명령에 닿게 하고, 조건 편집(필터·정렬)은 시트로 뺀다.
/// 단축키는 [CommandScope]가 늘 등록하므로 하드웨어 키보드를 붙이면 그대로 듣는다.
class MobileShell extends StatelessWidget {
  const MobileShell({
    super.key,
    required this.handlers,
    required this.workspaceRoot,
    required this.selectionCount,
    required this.scanning,
    required this.backgroundScanning,
    required this.onOpenFilterSheet,
    required this.onCharacter,
    required this.body,
  });

  final CommandHandlers handlers;

  /// 열린 워크스페이스 경로. null이면 빈 상태(최근 폴더 목록)다.
  final String? workspaceRoot;

  /// 선택된 항목 수. 0보다 크면 컨텍스트 AppBar와 태그 부여 FAB로 바뀐다.
  final int selectionCount;

  final bool scanning;

  /// watcher가 트리거한 조용한 재스캔이 진행 중인지. 본문은 그대로 두고 진행 막대만
  /// 띄워, 목록이 저절로 바뀌는 이유를 알린다.
  final bool backgroundScanning;

  /// 필터·정렬 시트를 여는 콜백.
  final VoidCallback onOpenFilterSheet;

  /// 본문에 포커스가 있을 때 친 글자(목록의 빠른 탐색). 하드웨어 키보드를 붙였을 때만
  /// 불린다. 자세한 계약은 [CommandScope.onCharacter].
  final ValueChanged<String>? onCharacter;

  /// 목록·프리뷰(워크스페이스 있음) 또는 최근 폴더 목록(빈 상태).
  final Widget body;

  /// 오버플로 메뉴에 늘어놓을 항목들.
  static const List<MenuNode> _overflowCommands = [
    MenuCommand(AppCommandId.openFolder),
    MenuCommand(AppCommandId.rescan),
    MenuCommand(AppCommandId.closeFolder),
    MenuDivider(),
    MenuCommand(AppCommandId.tagDisplayOrder),
    MenuCommand(AppCommandId.togglePreview),
    MenuDivider(),
    MenuCommand(AppCommandId.manageTags),
    MenuDivider(),
    MenuCommand(AppCommandId.help),
    MenuCommand(AppCommandId.checkForUpdates),
    MenuCommand(AppCommandId.about),
  ];

  bool get _selecting => selectionCount > 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PointerPresenceDetector(
      child: CommandScope(
        handlers: handlers,
        onCharacter: onCharacter,
        child: Scaffold(
          appBar: _selecting ? _selectionAppBar(l10n) : _normalAppBar(l10n),
          floatingActionButton: _floatingAction(l10n),
          body: SafeArea(child: body),
        ),
      ),
    );
  }

  /// 스캔 중임을 AppBar 아래 가는 진행 막대로 알린다(전면 스피너는 본문이 맡는다).
  /// 조용한 재스캔도 같은 막대로 알린다 — 본문에는 아무 표시가 없기 때문이다.
  PreferredSizeWidget? get _progress => (scanning || backgroundScanning)
      ? const PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: LinearProgressIndicator(minHeight: 4),
        )
      : null;

  AppBar _normalAppBar(AppLocalizations l10n) {
    final root = workspaceRoot;
    return AppBar(
      title: Text(root == null ? appDisplayName : p.basename(root)),
      bottom: _progress,
      actions: [
        if (root != null) ...[
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: l10n.mobileFilterSort,
            onPressed: onOpenFilterSheet,
          ),
        ],
        _overflowMenu(l10n),
      ],
    );
  }

  /// 선택이 있을 때의 컨텍스트 AppBar. 닫기(해제) · 선택 수 · 일괄 액션을 보인다.
  AppBar _selectionAppBar(AppLocalizations l10n) {
    final reconnect = commandOf(AppCommandId.reconnect);
    final selectAll = commandOf(AppCommandId.selectAll);
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: commandOf(AppCommandId.clearSelection).label(l10n),
        onPressed: handlers.clearSelection,
      ),
      title: Text(l10n.mobileSelectedCount(selectionCount)),
      bottom: _progress,
      actions: [
        // 연결 끊긴 노드 하나면 태그 부여(FAB) 대신 원본 찾기로 안내한다.
        if (handlers.reconnect != null)
          IconButton(
            icon: Icon(reconnect.icon),
            tooltip: reconnect.label(l10n),
            onPressed: handlers.reconnect,
          ),
        IconButton(
          icon: Icon(selectAll.icon),
          tooltip: selectAll.label(l10n),
          onPressed: handlers.selectAll,
        ),
      ],
    );
  }

  Widget _overflowMenu(AppLocalizations l10n) {
    return MenuAnchor(
      menuChildren: [
        for (final node in _overflowCommands)
          materialMenuNode(
            node,
            l10n: l10n,
            handlers: handlers,
            showIcons: true,
          ),
      ],
      builder: (_, controller, _) => IconButton(
        icon: const Icon(Icons.more_vert),
        tooltip: l10n.mobileMore,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }

  /// 선택이 있으면 태그 부여, 빈 상태면 폴더 열기. 그 밖에는 FAB를 두지 않는다
  /// (목록만 보는 동안 마지막 행을 가리지 않도록).
  Widget? _floatingAction(AppLocalizations l10n) {
    if (_selecting) {
      final assign = commandOf(AppCommandId.assignTags);
      return FloatingActionButton(
        onPressed: handlers.assignTags,
        tooltip: assign.label(l10n),
        child: Icon(assign.icon),
      );
    }
    if (workspaceRoot == null) {
      final open = commandOf(AppCommandId.openFolder);
      return FloatingActionButton.extended(
        onPressed: handlers.openFolder,
        icon: Icon(open.icon),
        label: Text(open.label(l10n)),
      );
    }
    return null;
  }
}
