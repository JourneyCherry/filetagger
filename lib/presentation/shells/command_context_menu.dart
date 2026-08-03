import 'dart:async';

import 'package:flutter/material.dart';

import '../commands/command_scope.dart';
import 'menu_model.dart';

/// 우클릭 지점([globalPosition])에 [MenuNode] 트리로 컨텍스트 메뉴를 띄운다.
/// 메뉴가 닫히면 완료된다.
///
/// 메뉴바와 **같은 모델·같은 렌더**를 쓴다([materialMenuNode]). 그래서 하위 메뉴가
/// 호버로 펼쳐지고 바깥으로 나가면 닫히는 등, 메뉴다운 동작을 직접 만들지 않는다.
///
/// `MenuAnchor`는 위젯 트리에 있어야 열 수 있으므로, 클릭 지점에 **크기 없는 앵커**를
/// 오버레이로 잠깐 띄우고 그 자리에서 연다. 메뉴가 닫히면 그 앵커도 함께 걷는다.
Future<void> showCommandContextMenu({
  required BuildContext context,
  required Offset globalPosition,
  required CommandHandlers handlers,
  required List<MenuNode> items,
}) {
  final overlay = Overlay.of(context);
  final box = overlay.context.findRenderObject() as RenderBox;
  final done = Completer<void>();
  late final OverlayEntry entry;
  var removed = false;

  // 닫힘은 바깥 클릭·Esc·항목 선택 어느 쪽으로도 오고, 겹쳐 올 수도 있어 한 번만 건다.
  void close() {
    if (removed) return;
    removed = true;
    entry.remove();
    done.complete();
  }

  entry = OverlayEntry(
    builder: (_) => _ContextMenuHost(
      position: box.globalToLocal(globalPosition),
      onClose: close,
      menuChildren: [
        for (final node in items)
          materialMenuNode(node, handlers: handlers, showIcons: true),
      ],
    ),
  );
  overlay.insert(entry);
  return done.future;
}

/// 클릭 지점에 놓이는 크기 없는 앵커. 첫 프레임 뒤에 스스로 메뉴를 연다.
class _ContextMenuHost extends StatefulWidget {
  const _ContextMenuHost({
    required this.position,
    required this.menuChildren,
    required this.onClose,
  });

  /// 오버레이 기준 좌표.
  final Offset position;

  final List<Widget> menuChildren;
  final VoidCallback onClose;

  @override
  State<_ContextMenuHost> createState() => _ContextMenuHostState();
}

class _ContextMenuHostState extends State<_ContextMenuHost> {
  final MenuController _controller = MenuController();

  @override
  void initState() {
    super.initState();
    // 앵커가 실제로 놓인 뒤라야 메뉴가 자리를 잡는다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.open();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: MenuAnchor(
        controller: _controller,
        menuChildren: widget.menuChildren,
        // 닫힘 콜백은 빌드 도중에 올 수 있어, 오버레이를 걷는 것은 프레임 뒤로 미룬다.
        onClose: () => WidgetsBinding.instance.addPostFrameCallback(
          (_) => widget.onClose(),
        ),
        child: const SizedBox.shrink(),
      ),
    );
  }
}
