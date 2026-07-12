import 'package:flutter/material.dart';

import '../../domain/entities/file_grouping.dart';
import '../../domain/entities/tag_definition.dart';
import '../tag_visuals.dart';
import 'filter_condition_chip.dart' show kDeletedTagChipText;
import 'tag_capsule.dart';

/// 그룹 단계 하나를 나타내는 캡슐(태그 하나로 묶는 축). 도구모음의 그룹 칩과 텍스트
/// 입력의 캡슐이 같은 모양으로 보이도록 겉모습을 공통 [TagCapsule]에 맡기고, 여기선
/// 그룹 문법에 딸린 것(폴더 계층 키 해석·색)만 얹는다.
///
/// 그룹엔 비교할 값도 방향도 없어 캡슐은 이름만 보인다(구분선·값 없음). 폴더 계층
/// 키는 합성 정의([folderHierarchyDefinition])로 흘러 시스템 태그처럼 회색으로 뜬다.
/// 순서 변경 손잡이·삭제 버튼은 [dragIndex]·[onDelete]로 켠다(도구모음은 동작까지,
/// 텍스트 입력 안 캡슐은 모양만).
class GroupKeyChip extends StatelessWidget {
  const GroupKeyChip({
    super.key,
    required this.groupKey,
    required this.definition,
    this.onTap,
    this.dragIndex,
    this.onDelete,
    this.margin = const EdgeInsets.only(right: 6),
  });

  final GroupKey groupKey;

  /// 단계가 가리키는 태그. 정의가 사라졌으면 null(폴더 계층 키는 합성 정의로 대체).
  final TagDefinition? definition;

  /// null이면 누를 수 없는 캡슐(텍스트 안의 캡슐). 그룹은 탭할 편집거리가 없어
  /// 도구모음 칩도 대개 null이다.
  final VoidCallback? onTap;

  /// 순서 변경 드래그 인덱스. null이면 손잡이 아이콘을 감춘다(자리는 유지).
  final int? dragIndex;

  /// 즉시 제거. null이면 x 아이콘을 감춘다(자리는 유지).
  final VoidCallback? onDelete;

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    // 폴더 계층 키는 정의맵에 없으므로 합성 정의로 이름·색을 해석한다.
    final def = groupKey is FolderHierarchyGroupKey
        ? folderHierarchyDefinition
        : definition;
    final colors = groupChipColors(context, def);

    return TagCapsule(
      background: colors.background,
      foreground: colors.foreground,
      name: def?.name ?? kDeletedTagChipText,
      onTap: onTap,
      dragIndex: dragIndex,
      onDelete: onDelete,
      margin: margin,
    );
  }
}

/// 그룹 캡슐의 배경·글자색. 태그 칩과 같은 규칙(시스템=회색, 사용자색, 없으면
/// 보조색)을 써 어느 태그로 묶는지 눈에 익은 색으로 읽히게 한다.
({Color background, Color foreground}) groupChipColors(
  BuildContext context,
  TagDefinition? definition,
) {
  final scheme = Theme.of(context).colorScheme;
  if (definition == null) {
    return (
      background: scheme.surfaceContainerHighest,
      foreground: scheme.onSurfaceVariant,
    );
  }
  if (definition.isSystem) {
    final background = const Color(kSystemTagColor);
    return (background: background, foreground: foregroundOn(background));
  }
  final color = definition.color;
  if (color != null) {
    final background = Color(color);
    return (background: background, foreground: foregroundOn(background));
  }
  return (
    background: scheme.secondaryContainer,
    foreground: scheme.onSecondaryContainer,
  );
}
