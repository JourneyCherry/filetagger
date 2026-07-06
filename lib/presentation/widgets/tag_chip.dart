import 'package:flutter/material.dart';

import '../../domain/entities/tag_definition.dart';
import '../tag_visuals.dart';

/// 태그를 배경색이 채워진 칩으로 표시한다. 값 태그는 "이름: 값", label은
/// 이름만 보여준다. 글자색은 배경 대비 접근성 기준으로 자동 선택한다.
///
/// [onPressed]나 [onDeleted]가 있으면 상호작용 칩(InputChip)이 되어 호버·클릭
/// 피드백이 생기고, 없으면 표시 전용 칩(Chip)이 된다.
class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.definition,
    this.value,
    this.onPressed,
    this.onDeleted,
  });

  final TagDefinition definition;
  final String? value;

  /// 지정하면 칩을 눌러 편집할 수 있고 호버 피드백이 생긴다.
  final VoidCallback? onPressed;

  /// 지정하면 칩에 삭제(x) 버튼이 붙는다.
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shown = formatTagValue(definition.valueType, value);
    final label = shown == null
        ? definition.name
        : '${definition.name}: $shown';

    final Color background;
    final Color foreground;
    if (definition.isSystem) {
      // 시스템 태그는 사용자 색과 무관하게 늘 회색 고정.
      background = const Color(kSystemTagColor);
      foreground = foregroundOn(background);
    } else if (definition.color != null) {
      background = Color(definition.color!);
      foreground = foregroundOn(background);
    } else {
      background = scheme.secondaryContainer;
      foreground = scheme.onSecondaryContainer;
    }
    final labelWidget = Text(label, style: TextStyle(color: foreground));

    if (onPressed != null || onDeleted != null) {
      return InputChip(
        label: labelWidget,
        backgroundColor: background,
        onPressed: onPressed,
        onDeleted: onDeleted,
        deleteIconColor: foreground,
        side: BorderSide.none,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      );
    }
    return Chip(
      label: labelWidget,
      backgroundColor: background,
      side: BorderSide.none,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
