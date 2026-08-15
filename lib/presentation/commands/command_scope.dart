import 'package:flutter/widgets.dart';

import '../common/type_ahead.dart';
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
    this.openNode,
    this.toggleExpand,
    this.assignTags,
    this.reconnect,
    this.revealInFileManager,
    this.exportSelection,
    this.manageTags,
    this.manageThumbnailTags,
    this.manageNameTags,
    this.tagDisplayOrder,
    this.createKeyword,
    this.editKeyword,
    this.deleteKeyword,
    this.help,
    this.checkForUpdates,
    this.about,
    this.exitApp,
    this.toggleFilterBar,
    this.toggleSortBar,
    this.toggleListEdit,
    this.toggleGrouping,
    this.togglePresetBar,
    this.togglePreview,
    this.moveCursorUp,
    this.moveCursorDown,
    this.extendSelectionUp,
    this.extendSelectionDown,
    this.moveCursorUpNoSelect,
    this.moveCursorDownNoSelect,
    this.cursorLeft,
    this.cursorRight,
    this.toggleTagFocus,
    this.confirmCursor,
    this.toggleCursorSelection,
    this.deleteFocusedTag,
    this.editFocusedTag,
    this.viewModeList,
    this.viewModeIcon,
    this.viewModeDetail,
  });

  final VoidCallback? openFolder;
  final VoidCallback? closeFolder;
  final VoidCallback? rescan;
  final VoidCallback? selectAll;
  final VoidCallback? clearSelection;
  final VoidCallback? openNode;
  final VoidCallback? toggleExpand;
  final VoidCallback? assignTags;
  final VoidCallback? reconnect;
  final VoidCallback? revealInFileManager;
  final VoidCallback? exportSelection;
  final VoidCallback? manageTags;
  final VoidCallback? manageThumbnailTags;
  final VoidCallback? manageNameTags;
  final VoidCallback? tagDisplayOrder;
  final VoidCallback? createKeyword;
  final VoidCallback? editKeyword;
  final VoidCallback? deleteKeyword;
  final VoidCallback? help;
  final VoidCallback? checkForUpdates;
  final VoidCallback? about;
  final VoidCallback? exitApp;
  final VoidCallback? toggleFilterBar;
  final VoidCallback? toggleSortBar;
  final VoidCallback? toggleListEdit;
  final VoidCallback? toggleGrouping;
  final VoidCallback? togglePresetBar;
  final VoidCallback? togglePreview;
  final VoidCallback? moveCursorUp;
  final VoidCallback? moveCursorDown;
  final VoidCallback? extendSelectionUp;
  final VoidCallback? extendSelectionDown;
  final VoidCallback? moveCursorUpNoSelect;
  final VoidCallback? moveCursorDownNoSelect;
  final VoidCallback? cursorLeft;
  final VoidCallback? cursorRight;
  final VoidCallback? toggleTagFocus;
  final VoidCallback? confirmCursor;
  final VoidCallback? toggleCursorSelection;
  final VoidCallback? deleteFocusedTag;
  final VoidCallback? editFocusedTag;
  final VoidCallback? viewModeList;
  final VoidCallback? viewModeIcon;
  final VoidCallback? viewModeDetail;

  /// [id]의 실행 함수. 비활성이면 null.
  VoidCallback? handlerOf(AppCommandId id) => switch (id) {
    AppCommandId.openFolder => openFolder,
    AppCommandId.closeFolder => closeFolder,
    AppCommandId.rescan => rescan,
    AppCommandId.selectAll => selectAll,
    AppCommandId.clearSelection => clearSelection,
    AppCommandId.openNode => openNode,
    AppCommandId.toggleExpand => toggleExpand,
    AppCommandId.assignTags => assignTags,
    AppCommandId.reconnect => reconnect,
    AppCommandId.revealInFileManager => revealInFileManager,
    AppCommandId.exportSelection => exportSelection,
    AppCommandId.manageTags => manageTags,
    AppCommandId.manageThumbnailTags => manageThumbnailTags,
    AppCommandId.manageNameTags => manageNameTags,
    AppCommandId.tagDisplayOrder => tagDisplayOrder,
    AppCommandId.createKeyword => createKeyword,
    AppCommandId.editKeyword => editKeyword,
    AppCommandId.deleteKeyword => deleteKeyword,
    AppCommandId.help => help,
    AppCommandId.checkForUpdates => checkForUpdates,
    AppCommandId.about => about,
    AppCommandId.exitApp => exitApp,
    AppCommandId.toggleFilterBar => toggleFilterBar,
    AppCommandId.toggleSortBar => toggleSortBar,
    AppCommandId.toggleListEdit => toggleListEdit,
    AppCommandId.toggleGrouping => toggleGrouping,
    AppCommandId.togglePresetBar => togglePresetBar,
    AppCommandId.togglePreview => togglePreview,
    AppCommandId.moveCursorUp => moveCursorUp,
    AppCommandId.moveCursorDown => moveCursorDown,
    AppCommandId.extendSelectionUp => extendSelectionUp,
    AppCommandId.extendSelectionDown => extendSelectionDown,
    AppCommandId.moveCursorUpNoSelect => moveCursorUpNoSelect,
    AppCommandId.moveCursorDownNoSelect => moveCursorDownNoSelect,
    AppCommandId.cursorLeft => cursorLeft,
    AppCommandId.cursorRight => cursorRight,
    AppCommandId.toggleTagFocus => toggleTagFocus,
    AppCommandId.confirmCursor => confirmCursor,
    AppCommandId.toggleCursorSelection => toggleCursorSelection,
    AppCommandId.deleteFocusedTag => deleteFocusedTag,
    AppCommandId.editFocusedTag => editFocusedTag,
    AppCommandId.viewModeList => viewModeList,
    AppCommandId.viewModeIcon => viewModeIcon,
    AppCommandId.viewModeDetail => viewModeDetail,
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
    this.onCharacter,
    this.autofocus = true,
  });

  final CommandHandlers handlers;

  /// 본문 스코프가 포커스를 쥔 채로 친 **글자**(단축키가 아닌 문자 입력)를 받는다.
  /// 목록의 빠른 탐색이 이 통로를 쓴다 — 텍스트 입력이나 버튼이 포커스를 쥐고 있으면
  /// 불리지 않아, 필터 줄에 친 글자가 목록으로 새지 않는다.
  final ValueChanged<String>? onCharacter;

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

  /// 글자 입력만 [CommandScope.onCharacter]로 넘기고 나머지는 그대로 흘려보낸다.
  /// 이 핸들러는 포커스 노드에 달려 있어 위(`Shortcuts`)보다 **먼저** 불리므로,
  /// 단축키 조합을 삼키지 않도록 [typeAheadCharacter]의 판정에 전부 맡긴다.
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final onCharacter = widget.onCharacter;
    if (onCharacter == null) return KeyEventResult.ignored;
    final character = typeAheadCharacter(node, event);
    if (character == null) return KeyEventResult.ignored;
    onCharacter(character);
    return KeyEventResult.handled;
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
          onKeyEvent: _onKeyEvent,
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
