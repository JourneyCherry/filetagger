import 'package:flutter/material.dart';

import '../commands/app_commands.dart';
import '../commands/command_scope.dart';

/// 우클릭 지점([globalPosition])에 명령 카탈로그 기반 컨텍스트 메뉴를 띄운다.
///
/// [items]의 null은 구분선이다. 지금 실행할 수 없는 명령(핸들러 null)은 회색으로
/// 보이며, 라벨·아이콘은 카탈로그를 그대로 쓴다(툴바·메뉴바와 표기가 어긋나지 않음).
///
/// [extraItems]는 명령이 아닌(선택 상태를 체크로 보이는 등) 항목을 뒤에 이어 붙일
/// 때 쓴다. 값을 갖지 않고 스스로 `onTap`으로 처리하므로 명령 실행과 섞이지 않는다.
Future<void> showCommandContextMenu({
  required BuildContext context,
  required Offset globalPosition,
  required CommandHandlers handlers,
  required List<AppCommandId?> items,
  List<PopupMenuEntry<AppCommandId>> extraItems = const [],
}) async {
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final chosen = await showMenu<AppCommandId>(
    context: context,
    position: RelativeRect.fromRect(
      globalPosition & Size.zero,
      Offset.zero & overlay.size,
    ),
    items: [...commandMenuItems(items, handlers), ...extraItems],
  );
  if (chosen != null) handlers.handlerOf(chosen)?.call();
}

/// 명령 목록을 팝업 메뉴 항목으로 옮긴다(null=구분선). 컨텍스트 메뉴와 모바일
/// 오버플로 메뉴가 같은 표기를 쓰도록 여기 한 곳에서 만든다.
List<PopupMenuEntry<AppCommandId>> commandMenuItems(
  List<AppCommandId?> items,
  CommandHandlers handlers,
) => [
  for (final id in items)
    if (id == null) const PopupMenuDivider() else _commandItem(id, handlers),
];

PopupMenuItem<AppCommandId> _commandItem(
  AppCommandId id,
  CommandHandlers handlers,
) {
  final command = commandOf(id);
  return PopupMenuItem<AppCommandId>(
    value: id,
    enabled: handlers.isEnabled(id),
    child: Row(
      children: [
        SizedBox(
          width: 28,
          child: command.icon == null ? null : Icon(command.icon, size: 18),
        ),
        Text(command.label),
      ],
    ),
  );
}
