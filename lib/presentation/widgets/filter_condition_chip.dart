import 'package:flutter/material.dart';

import '../../domain/entities/file_filter.dart';
import '../../domain/entities/tag_definition.dart';
import '../../domain/entities/tag_value_type.dart';
import '../tag_visuals.dart';
import 'tag_capsule.dart';

/// 정의가 사라진 태그를 가리키는 조건의 표시 문구.
const String kDeletedTagChipText = '(삭제된 태그)';

/// 필터 조건 하나를 나타내는 캡슐. 도구모음의 조건 칩과 텍스트 입력의 캡슐이 같은
/// 모양으로 보이도록 겉모습을 공통 [TagCapsule]에 맡기고, 여기선 필터 문법에 딸린
/// 것(제외 아이콘·이름/조건 나누기·색)만 얹는다.
///
/// 제외 조건은 흐린 회색에 금지 아이콘, 표시 조건은 태그색으로 채운다. 순서 변경
/// 손잡이·삭제 버튼은 [showHandle]/[dragIndex]·[showDelete]/[onDelete]로 켠다(도구모음은
/// 동작까지, 텍스트 입력 안 캡슐은 모양만).
class FilterConditionChip extends StatelessWidget {
  const FilterConditionChip({
    super.key,
    required this.condition,
    required this.definition,
    this.onTap,
    this.dragIndex,
    this.onDelete,
    this.margin = const EdgeInsets.only(right: 6),
  });

  final FilterCondition condition;

  /// 조건이 가리키는 태그. 정의가 사라졌으면 null.
  final TagDefinition? definition;

  /// null이면 누를 수 없는 캡슐(텍스트 안의 캡슐).
  final VoidCallback? onTap;

  /// 순서 변경 드래그 인덱스. null이면 손잡이 아이콘을 감춘다(자리는 유지).
  final int? dragIndex;

  /// 즉시 제거. null이면 x 아이콘을 감춘다(자리는 유지).
  final VoidCallback? onDelete;

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final colors = filterChipColors(context, condition, definition);
    final def = definition;
    final value = def == null ? null : conditionValueText(condition, def);

    return TagCapsule(
      background: colors.background,
      foreground: colors.foreground,
      name: def == null ? kDeletedTagChipText : def.name,
      namePrefix: condition.exclude
          ? Icon(Icons.block, size: kCapsuleIconSize, color: colors.foreground)
          : null,
      value: value == null ? null : Text(value),
      onTap: onTap,
      dragIndex: dragIndex,
      onDelete: onDelete,
      margin: margin,
    );
  }
}

/// 조건 캡슐의 배경·글자색. 캡슐에 얹는 조각(제외 아이콘 등)이 같은 색을 쓰도록
/// 함께 공개한다.
({Color background, Color foreground}) filterChipColors(
  BuildContext context,
  FilterCondition condition,
  TagDefinition? definition,
) {
  final scheme = Theme.of(context).colorScheme;
  if (condition.exclude) {
    return (
      background: scheme.surfaceContainerHighest,
      foreground: scheme.onSurfaceVariant,
    );
  }
  final color = definition?.color;
  if (color != null) {
    final background = Color(color);
    return (background: background, foreground: foregroundOn(background));
  }
  return (
    background: scheme.secondaryContainer,
    foreground: scheme.onSecondaryContainer,
  );
}

/// 필터 조건 캡슐의 구분선 오른쪽에 놓을 조건 문자열("연산 값"). 존재 조건은 값이
/// 없어 null을 돌려 구분선도 생략한다(날짜는 보기 좋게 자름).
///
/// 텍스트 입력의 조각 표현(`formatFilterCondition`)과는 목적이 다르다 — 이쪽은
/// 키보드로 칠 수 없는 기호를 쓰는 **표시용**이고, 그쪽은 되펼쳐 고칠 수 있는
/// **입력용**이다.
String? conditionValueText(FilterCondition condition, TagDefinition def) {
  if (condition.operator == FilterOperator.exists) return null;
  final op = filterOperatorLabel(condition.operator);
  final operand = def.valueType == TagValueType.date
      ? (formatTagValue(TagValueType.date, condition.operand) ??
            condition.operand ??
            '')
      : (condition.operand ?? '');
  return '$op $operand';
}
