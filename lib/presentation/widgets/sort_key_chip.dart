import 'package:flutter/material.dart';

import '../../domain/entities/file_sort.dart';
import '../../domain/entities/tag_definition.dart';
import '../../domain/usecases/sort_query_text.dart';
import 'filter_condition_chip.dart' show kDeletedTagChipText;
import 'tag_capsule.dart';

/// 정렬 단계 하나를 나타내는 캡슐(태그 + 방향). 도구모음의 정렬 칩과 텍스트 입력의
/// 캡슐이 같은 모양으로 보이도록 겉모습을 공통 [TagCapsule]에 맡기고, 여기선 정렬
/// 문법에 딸린 것(방향 아이콘·색)만 얹는다.
///
/// 방향은 구분선 오른쪽에 아이콘으로 둔다. 방향이 없는 태그(label)는 화살표 대신
/// 존재 정렬 아이콘을 보여준다. 순서 변경 손잡이·삭제 버튼은 [showHandle]/[dragIndex]·
/// [showDelete]/[onDelete]로 켠다(도구모음은 동작까지, 텍스트 입력 안 캡슐은 모양만).
class SortKeyChip extends StatelessWidget {
  const SortKeyChip({
    super.key,
    required this.sortKey,
    required this.definition,
    this.onTap,
    this.dragIndex,
    this.onDelete,
    this.margin = const EdgeInsets.only(right: 6),
  });

  final SortKey sortKey;

  /// 단계가 가리키는 태그. 정의가 사라졌으면 null.
  final TagDefinition? definition;

  /// null이면 누를 수 없는 캡슐(텍스트 안의 캡슐, 또는 방향이 없는 태그).
  final VoidCallback? onTap;

  /// 순서 변경 드래그 인덱스. null이면 손잡이 아이콘을 감춘다(자리는 유지).
  final int? dragIndex;

  /// 즉시 제거. null이면 x 아이콘을 감춘다(자리는 유지).
  final VoidCallback? onDelete;

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final colors = sortChipColors(context);
    final def = definition;
    final hasDirection = def != null && sortDirectionApplies(def.valueType);
    final ascending = sortKey.direction == SortDirection.ascending;

    return TagCapsule(
      background: colors.background,
      foreground: colors.foreground,
      name: def?.name ?? kDeletedTagChipText,
      value: Icon(
        !hasDirection
            ? Icons.check_circle_outline
            : (ascending ? Icons.arrow_upward : Icons.arrow_downward),
        size: kCapsuleIconSize,
        color: colors.foreground,
      ),
      onTap: onTap,
      dragIndex: dragIndex,
      onDelete: onDelete,
      margin: margin,
    );
  }
}

/// 정렬 캡슐의 배경·글자색. 필터 조건 캡슐과 달리 태그색을 쓰지 않는다 — 정렬은
/// 어떤 태그를 골랐는지보다 순서가 읽혀야 해서 한 색으로 묶는다.
({Color background, Color foreground}) sortChipColors(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return (
    background: scheme.secondaryContainer,
    foreground: scheme.onSecondaryContainer,
  );
}
