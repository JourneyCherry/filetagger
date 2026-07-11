import 'package:flutter/material.dart';

import '../../domain/entities/tag_definition.dart';
import '../tag_visuals.dart';
import 'tag_capsule.dart';

/// 태그를 배경색이 채워진 캡슐로 표시한다. 값 태그는 이름과 값을 구분선으로 나눠,
/// label은 이름만 보여준다. 글자색은 배경 대비 접근성 기준으로 자동 선택한다.
///
/// 겉모습은 공통 [TagCapsule]이 쥔다 — 알약 모양·테두리·구분선. [onPressed]가 있으면
/// 눌러 편집할 수 있고 호버 피드백이 생기며, [onDeleted]가 있으면 제거(x) 버튼이 붙는다.
/// 순서 편집 목록에 놓일 땐 [dragIndex]로 캡슐 안에 드래그 손잡이를 켠다.
class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.definition,
    this.value,
    this.onPressed,
    this.onDeleted,
    this.dragIndex,
  });

  final TagDefinition definition;
  final String? value;

  /// 지정하면 캡슐을 눌러 편집할 수 있고 호버 피드백이 생긴다.
  final VoidCallback? onPressed;

  /// 지정하면 캡슐에 삭제(x) 버튼이 붙는다.
  final VoidCallback? onDeleted;

  /// 지정하면 캡슐 왼쪽에 순서 변경 드래그 손잡이가 켜진다(ReorderableListView 안에서).
  final int? dragIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shown = formatTagValue(definition.valueType, value);

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

    return TagCapsule(
      background: background,
      foreground: foreground,
      name: definition.name,
      value: shown == null ? null : Text(shown),
      onTap: onPressed,
      onDelete: onDeleted,
      dragIndex: dragIndex,
    );
  }
}
