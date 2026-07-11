import 'package:flutter/widgets.dart';

import 'app_commands.dart';

/// 명령별 실행 함수. null이면 그 명령은 비활성 — 단축키를 눌러도 아무 일이
/// 없고(상위로 흘려보냄), 메뉴·버튼은 회색으로 그린다.
class CommandHandlers {
  const CommandHandlers({
    this.openFolder,
    this.closeFolder,
    this.rescan,
    this.selectAll,
    this.clearSelection,
    this.activateNode,
    this.assignTags,
    this.reconnect,
    this.revealInFileManager,
    this.manageTags,
    this.tagDisplayOrder,
    this.toggleFilterBar,
    this.toggleSortBar,
    this.toggleListEdit,
    this.toggleGrouping,
    this.togglePreview,
  });

  final VoidCallback? openFolder;
  final VoidCallback? closeFolder;
  final VoidCallback? rescan;
  final VoidCallback? selectAll;
  final VoidCallback? clearSelection;
  final VoidCallback? activateNode;
  final VoidCallback? assignTags;
  final VoidCallback? reconnect;
  final VoidCallback? revealInFileManager;
  final VoidCallback? manageTags;
  final VoidCallback? tagDisplayOrder;
  final VoidCallback? toggleFilterBar;
  final VoidCallback? toggleSortBar;
  final VoidCallback? toggleListEdit;
  final VoidCallback? toggleGrouping;
  final VoidCallback? togglePreview;

  /// [id]의 실행 함수. 비활성이면 null.
  VoidCallback? handlerOf(AppCommandId id) => switch (id) {
    AppCommandId.openFolder => openFolder,
    AppCommandId.closeFolder => closeFolder,
    AppCommandId.rescan => rescan,
    AppCommandId.selectAll => selectAll,
    AppCommandId.clearSelection => clearSelection,
    AppCommandId.activateNode => activateNode,
    AppCommandId.assignTags => assignTags,
    AppCommandId.reconnect => reconnect,
    AppCommandId.revealInFileManager => revealInFileManager,
    AppCommandId.manageTags => manageTags,
    AppCommandId.tagDisplayOrder => tagDisplayOrder,
    AppCommandId.toggleFilterBar => toggleFilterBar,
    AppCommandId.toggleSortBar => toggleSortBar,
    AppCommandId.toggleListEdit => toggleListEdit,
    AppCommandId.toggleGrouping => toggleGrouping,
    AppCommandId.togglePreview => togglePreview,
  };

  /// 메뉴·버튼이 회색 처리 여부를 판단할 때 쓴다.
  bool isEnabled(AppCommandId id) => handlerOf(id) != null;
}

/// 명령 카탈로그를 `Shortcuts` + `Actions`로 한 번에 배선하는 스코프.
///
/// 셸(데스크톱/모바일)이 본문을 이걸로 감싸면 단축키와, 같은 Intent를 던지는
/// 메뉴·컨텍스트 메뉴·툴바가 모두 같은 핸들러로 모인다. 단축키는 하드웨어
/// 키보드가 없으면 불릴 일이 없으므로 플랫폼과 무관하게 늘 등록한다.
class CommandScope extends StatefulWidget {
  const CommandScope({
    super.key,
    required this.handlers,
    required this.child,
    this.autofocus = true,
  });

  final CommandHandlers handlers;

  /// 단축키가 곧바로 먹도록 스코프에 포커스를 준다.
  final bool autofocus;

  final Widget child;

  @override
  State<CommandScope> createState() => _CommandScopeState();
}

class _CommandScopeState extends State<CommandScope> {
  /// 본문 스코프의 포커스 노드. [AppCommand.requiresScopeFocus] 명령이 지금
  /// 포커스를 쥔 쪽인지 확인하는 기준이다.
  final FocusNode _scopeFocus = FocusNode(debugLabel: 'CommandScope');

  @override
  void dispose() {
    _scopeFocus.dispose();
    super.dispose();
  }

  /// 핸들러가 있는 명령만 Action으로 등록한다. 없는 명령의 Intent는 처리되지
  /// 않아 단축키가 상위(다른 스코프·기본 동작)로 흘러간다.
  Map<Type, Action<Intent>> _actions() {
    final actions = <Type, Action<Intent>>{};
    for (final command in appCommands) {
      final handler = widget.handlers.handlerOf(command.id);
      if (handler == null) continue;
      actions[command.intent.runtimeType] = command.requiresScopeFocus
          ? _ScopeFocusedAction(onPressed: handler, scope: _scopeFocus)
          : CallbackAction<Intent>(
              onInvoke: (_) {
                handler();
                return null;
              },
            );
    }
    return actions;
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: commandShortcuts(),
      child: Actions(
        actions: _actions(),
        child: Focus(
          focusNode: _scopeFocus,
          autofocus: widget.autofocus,
          child: widget.child,
        ),
      ),
    );
  }
}

/// 본문 스코프가 포커스를 쥐고 있을 때만 활성인 Action.
///
/// 비활성이면 `Shortcuts`가 키를 소비하지 않아, 버튼이 포커스를 가진 상태의
/// Enter(활성) 같은 기본 동작이 그대로 살아난다.
class _ScopeFocusedAction extends CallbackAction<Intent> {
  _ScopeFocusedAction({required VoidCallback onPressed, required this.scope})
    : super(
        onInvoke: (_) {
          onPressed();
          return null;
        },
      );

  final FocusNode scope;

  @override
  bool get isActionEnabled =>
      identical(FocusManager.instance.primaryFocus, scope);
}
