import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/assigned_tag.dart';
import '../../domain/entities/tag_definition.dart';
import '../../domain/entities/tag_value_type.dart';
import '../providers/file_node_provider.dart';
import '../providers/node_reveal_provider.dart';
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
    this.displayValue,
    this.onPressed,
    this.onDoubleTap,
    this.tooltip,
    this.onDeleted,
    this.dragIndex,
    this.unresolved = false,
  });

  final TagDefinition definition;
  final String? value;

  /// 값 표시를 이 문자열로 갈아끼운다(예: 링크는 저장값=id 대신 대상 이름을 보인다).
  /// null이면 [value]를 유형 규칙([formatTagValue])으로 포맷해 보인다.
  final String? displayValue;

  /// 지정하면 캡슐을 눌러 편집할 수 있고 호버 피드백이 생긴다.
  final VoidCallback? onPressed;

  /// 지정하면 캡슐을 더블탭(더블클릭)해 동작을 낸다(링크의 대상 이동 등).
  final VoidCallback? onDoubleTap;

  /// 포인터를 올리면 뜨는 툴팁(링크 대상 전체 경로 등).
  final String? tooltip;

  /// 지정하면 캡슐에 삭제(x) 버튼이 붙는다.
  final VoidCallback? onDeleted;

  /// 지정하면 캡슐 왼쪽에 순서 변경 드래그 손잡이가 켜진다(ReorderableListView 안에서).
  final int? dragIndex;

  /// 링크 값이 대상을 가리키지 못하는 상태(미해결 링크)임을 이름 앞 아이콘으로 알린다.
  /// 색·모양은 그대로 두고 표식만 얹어, 다른 캡슐과 나란히 놓여도 줄이 흐트러지지 않는다.
  final bool unresolved;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shown = displayValue ?? formatTagValue(definition.valueType, value);

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
      namePrefix: unresolved
          ? Icon(Icons.link_off, size: kCapsuleIconSize, color: foreground)
          : null,
      value: shown == null ? null : Text(shown),
      onTap: onPressed,
      onDoubleTap: onDoubleTap,
      tooltip: tooltip,
      onDelete: onDeleted,
      dragIndex: dragIndex,
    );
  }
}

/// 부여된 태그를 목록·프리뷰·부여 다이얼로그에 그리는 칩. 링크 태그면 저장값(대상
/// 노드 id)을 **대상 이름**으로 풀어 보이고, 더블탭(더블클릭)으로 그 노드로 이동한다
/// (툴팁에 대상 전체 경로). 나머지 유형은 [TagChip]과 동작이 같다.
///
/// 대상을 가리키지 못하는 링크(**미해결 링크**)는 표식을 달고, 같은 더블탭이 이동
/// 대신 **재연결**(값 편집 = 대상 다시 고르기)로 간다 — 갈 곳이 없어 비는 제스처를
/// 사용자가 할 일에 그대로 쓴다. 제거는 다른 칩과 같은 x다.
class AssignedTagChip extends ConsumerWidget {
  const AssignedTagChip({
    super.key,
    required this.tag,
    this.onPressed,
    this.onDeleted,
  });

  final AssignedTag tag;

  /// 값 편집(단일 탭). 링크도 값(대상)을 다시 고를 수 있다.
  final VoidCallback? onPressed;

  /// 부여 해제(x). 시스템 태그 등 제거 불가면 null.
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final def = tag.definition;
    // 이미지 태그는 값이 불투명한 캐시 키라 값 없이 이름만 보인다(썸네일은 노드에
    // 뜬다). 툴팁으로 커스텀 이미지임을 알린다.
    if (def.valueType == TagValueType.image) {
      return TagChip(
        definition: def,
        tooltip: '커스텀 이미지',
        onPressed: onPressed,
        onDeleted: onDeleted,
      );
    }
    if (def.valueType != TagValueType.link) {
      return TagChip(
        definition: def,
        value: tag.value,
        onPressed: onPressed,
        onDeleted: onDeleted,
      );
    }

    final raw = tag.value;
    final hasValue = raw != null && raw.isNotEmpty;
    // 가져오기가 미해결로 남긴 값은 노드 id가 아니라 원문이라 id 해석을 태우지 않는다.
    final target = (tag.valueUnresolved || !hasValue)
        ? null
        : ref.watch(fileNodesByIdProvider)[int.tryParse(raw)];
    final unresolved = hasValue && target == null;
    return TagChip(
      definition: def,
      // 미해결이라도 원문(경로·키워드 이름)이 있으면 그것을 보인다 — 사람이 읽을 수
      // 있어 무엇을 가리키려던 링크인지 알 수 있다. 떠 버린 id는 뜻이 없어 감춘다.
      displayValue: tag.valueUnresolved ? raw : (target?.name ?? '(없음)'),
      unresolved: unresolved,
      tooltip: unresolved ? _unresolvedHint : target?.path,
      onPressed: onPressed,
      // 갈 곳이 있으면 이동, 없으면 재연결. 재연결은 값 편집과 같은 경로다(대상을
      // 다시 고르면 저장소가 미해결 표식을 함께 내린다).
      onDoubleTap: unresolved
          ? onPressed
          : (target == null
                ? null
                : () => ref
                      .read(nodeRevealProvider.notifier)
                      .request(target.id!)),
      onDeleted: onDeleted,
    );
  }
}

const String _unresolvedHint = '가리키는 대상을 찾지 못했습니다. 더블클릭해 다시 연결하거나 x로 지웁니다.';
