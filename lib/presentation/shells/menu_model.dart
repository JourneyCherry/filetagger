/// 메뉴 구성을 적어 두는 **데이터 모델**과 그 Material 렌더. 메뉴바·컨텍스트 메뉴·
/// 모바일 오버플로가 이 한 모델을 공유해, 같은 조작이 어느 경로로 뜨든 라벨·활성
/// 여부가 어긋나지 않는다.
///
/// 라벨·단축키·활성 여부의 단일 출처는 명령 카탈로그다([MenuCommand]). 카탈로그에 없는
/// 동적 항목(최근 폴더)과 상태를 체크로 보이는 항목(관리 방식 등)만 라벨을 직접 준다.
///
/// 렌더도 [materialMenuNode] 하나로 모은다 — 하위 메뉴의 호버 펼침·바깥 클릭·키보드
/// 이동을 프레임워크(`SubmenuButton`)가 쥐게 하기 위함이다. macOS 네이티브 메뉴만
/// 위젯이 아니라 별도 렌더를 갖는다([AppMenuBar]).
library;

import 'package:flutter/material.dart';

import '../commands/app_commands.dart';
import '../commands/command_scope.dart';

/// 메뉴 트리의 한 항목.
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
  const MenuChecked(
    this.label, {
    required this.checked,
    this.onSelected,
    this.shortcut,
  });

  final String label;
  final bool checked;

  /// null이면 비활성.
  final VoidCallback? onSelected;

  /// 같은 동작을 부르는 단축키(표기용). 명령 카탈로그에 대응 명령이 있는 라디오
  /// 항목이 힌트를 보이도록 얹는다.
  final SingleActivator? shortcut;
}

/// 하위 메뉴.
///
/// 성격이 같은 항목을 접어 첫 층을 짧게 유지한다. 그 안에 **지금 쓸 수 없는 항목이
/// 섞여 있어도 자리는 남긴다** — 우클릭한 대상에 따라 항목이 사라졌다 나타나면 어디에
/// 무엇이 있는지 외울 수 없기 때문이다(회색으로 두어 "여기 있으나 지금은 안 된다"를
/// 보인다).
class MenuSubmenu extends MenuNode {
  const MenuSubmenu(this.label, this.children);

  final String label;
  final List<MenuNode> children;
}

/// 항목 사이의 구분선.
class MenuDivider extends MenuNode {
  const MenuDivider();
}

/// 체크 표시 아이콘의 크기(메뉴 라벨 글자와 어울리게 줄인다).
const double _iconSize = 18;

/// 체크 상태를 갖는 항목의 앞 아이콘. [checked]가 null이면(토글이 아닌 항목) 자리를
/// 아예 두지 않고, false면 자리만 비워 같은 메뉴의 켜진 항목과 라벨을 맞춘다.
Widget? _checkIcon(bool? checked) => checked == null
    ? null
    : Icon(checked ? Icons.check : null, size: _iconSize);

/// [node]를 Material 메뉴 위젯으로 그린다(`MenuBar`·`MenuAnchor` 안에 그대로 넣는다).
///
/// 하위 메뉴는 `SubmenuButton`이라 **호버로 펼쳐지고, 바깥으로 나가면 닫히며, 방향키로
/// 오갈 수 있다** — 그 동작을 직접 만들지 않는 것이 이 렌더를 하나로 모은 이유다.
///
/// [commandChecks]에 실린 명령만 체크 표시 자리를 갖는다(켜짐/꺼짐을 오가는 명령).
/// [showIcons]는 명령의 아이콘을 앞에 보일지다 — 메뉴바는 끄고(아이콘은 툴바의 몫),
/// 컨텍스트 메뉴·오버플로는 켠다(길이가 짧아 아이콘이 훑기에 도움이 된다).
Widget materialMenuNode(
  MenuNode node, {
  required CommandHandlers handlers,
  Map<AppCommandId, bool> commandChecks = const {},
  bool showIcons = false,
}) {
  Widget child(MenuNode n) => materialMenuNode(
    n,
    handlers: handlers,
    commandChecks: commandChecks,
    showIcons: showIcons,
  );

  switch (node) {
    case MenuSubmenu(:final label, :final children):
      return SubmenuButton(
        menuChildren: [for (final c in children) child(c)],
        child: Text(label),
      );
    case MenuCommand(:final id):
      final command = commandOf(id);
      final checked = commandChecks[id];
      return MenuItemButton(
        onPressed: handlers.handlerOf(id),
        shortcut: command.shortcut,
        // 체크를 보이는 명령은 체크가 그 자리를 쓰고, 나머지만 아이콘을 받는다.
        leadingIcon: checked != null
            ? _checkIcon(checked)
            : (showIcons && command.icon != null
                  ? Icon(command.icon, size: _iconSize)
                  : null),
        child: Text(command.label),
      );
    case MenuAction(:final label, :final onSelected):
      return MenuItemButton(onPressed: onSelected, child: Text(label));
    case MenuChecked(
      :final label,
      :final checked,
      :final onSelected,
      :final shortcut,
    ):
      return MenuItemButton(
        onPressed: onSelected,
        shortcut: shortcut,
        leadingIcon: _checkIcon(checked),
        child: Text(label),
      );
    case MenuDivider():
      return const Divider();
  }
}
