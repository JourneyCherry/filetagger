import 'package:flutter/material.dart';

import 'tag_capsule.dart';

/// 저장된 조건 프리셋 하나를 나타내는 캡슐.
///
/// 겉모습은 다른 캡슐과 같은 [TagCapsule]에 맡긴다 — 같은 도구모음에 나란히 놓이므로
/// 두께·모양이 어긋나면 눈에 띈다. 프리셋은 태그가 아니라 색이 없어 중립 톤으로
/// 칠하고, 지금 걸린 조건과 똑같은 프리셋([active])만 강조색으로 뒤집어 "지금 보고
/// 있는 것이 이것"임을 보인다.
///
/// 이름 하나뿐이라 구분선·값이 없다. x는 다른 캡슐과 같은 자리에 놓이되, 눌러도 곧장
/// 지우지는 않는다 — 조건 칩과 달리 사용자가 만들어 둔 자산이라 [onDelete]가 확인을
/// 한 번 거친다.
class QueryPresetChip extends StatelessWidget {
  const QueryPresetChip({
    super.key,
    required this.name,
    required this.active,
    this.onTap,
    this.onDelete,
    this.tooltip,
    this.dragIndex,
    this.margin = const EdgeInsets.only(right: 6),
  });

  final String name;

  /// 지금 걸린 조건이 이 프리셋과 같은지(강조 표시).
  final bool active;

  /// 누르면 이 프리셋을 건다. null이면 누를 수 없는 캡슐.
  final VoidCallback? onTap;

  /// x를 누르면 부른다(지우기 확인은 호출부가 맡는다). null이면 x를 감춘다.
  final VoidCallback? onDelete;

  /// 포인터를 올리면 뜨는 조건 요약.
  final String? tooltip;

  /// 순서 변경 드래그 인덱스. null이면 손잡이 아이콘을 감춘다(자리는 유지).
  final int? dragIndex;

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TagCapsule(
      background: active ? scheme.primary : scheme.secondaryContainer,
      foreground: active ? scheme.onPrimary : scheme.onSecondaryContainer,
      name: name,
      onTap: onTap,
      onDelete: onDelete,
      tooltip: tooltip,
      dragIndex: dragIndex,
      margin: margin,
    );
  }
}
