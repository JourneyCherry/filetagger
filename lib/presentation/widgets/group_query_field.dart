/// 그룹 기준을 **텍스트로 입력·수정**하는 필드.
///
/// 캡슐(글자 하나로 접힌 단계)의 동작은 [CapsuleTextField]에 있고, 여기엔 그룹
/// 문법에 딸린 것만 둔다 — 조각↔단계 변환, 그룹 칩 그리기, 자동완성 후보. 텍스트에
/// 놓인 왼→오 순서가 그대로 바깥→안쪽 중첩 순서이므로, 캡슐을 잘라 옮기는 것이 곧
/// 중첩 순서 재배치다.
library;

import 'package:flutter/material.dart';

import '../../domain/entities/file_grouping.dart';
import '../../domain/entities/tag_definition.dart';
import '../../domain/usecases/group_query_text.dart';
import '../common/capsule_text_field.dart';
import '../tag_visuals.dart';
import 'group_key_chip.dart';

/// 조각↔그룹 단계 변환과 그룹 칩 그리기. 태그 정의가 바뀌면 새로 만든다(불변).
class GroupCapsuleSyntax extends CapsuleSyntax<GroupKey> {
  GroupCapsuleSyntax(Iterable<TagDefinition> definitions)
    : definitions = List.unmodifiable(definitions),
      _byId = {
        for (final d in definitions)
          if (d.id != null) d.id!: d,
      };

  /// 이름으로 고를 수 있는 태그(사용자 + 시스템). 폴더 계층 정의는 문법이 자동으로
  /// 더하므로 여기 담지 않아도 된다.
  final List<TagDefinition> definitions;
  final Map<int, TagDefinition> _byId;

  /// 조각 하나가 통째로 단계여야 접는다 — 인용부호가 닫히지 않아 조각이 둘로
  /// 갈리는 문자열은 아직 확정되지 않은 입력이다.
  @override
  GroupKey? parse(String chunk) {
    final segments = parseGroupQuery(chunk, definitions: definitions);
    if (segments.length != 1) return null;
    final segment = segments.first;
    return segment is GroupQueryKey ? segment.key : null;
  }

  @override
  String? format(GroupKey item) {
    final def = switch (item) {
      FolderHierarchyGroupKey() => folderHierarchyDefinition,
      TagGroupKey(:final tagDefinitionId) => _byId[tagDefinitionId],
    };
    return def == null ? null : formatGroupKey(item, def);
  }

  @override
  bool isInvalid(String chunk) {
    final segments = parseGroupQuery(chunk, definitions: definitions);
    return segments.length == 1 && segments.first is GroupQueryFragment;
  }

  @override
  Widget chip(GroupKey item) => GroupKeyChip(
    groupKey: item,
    definition: switch (item) {
      FolderHierarchyGroupKey() => folderHierarchyDefinition,
      TagGroupKey(:final tagDefinitionId) => _byId[tagDefinitionId],
    },
    margin: EdgeInsets.zero,
    // 손잡이·x는 동작할 수 없어 아이콘을 감춘다(자리는 그대로라 도구모음 그룹 칩과
    // 같은 모양이 되어, 칩 줄↔텍스트 전환에서 캡슐이 튀지 않는다).
  );
}

/// 그룹을 텍스트로 편집하는 입력 필드. 태그 이름은 자동완성으로 고른다(폴더 계층도
/// 후보에 함께 온다). 그룹엔 값·방향이 없어 조각은 태그 이름뿐이다.
class GroupQueryField extends StatefulWidget {
  const GroupQueryField({
    super.key,
    required this.grouping,
    required this.definitions,
    required this.onChanged,
    this.focusNode,
    this.autofocus = false,
  });

  final FileGrouping grouping;

  /// 이름으로 고를 수 있는 태그(사용자 + 시스템).
  final List<TagDefinition> definitions;

  final ValueChanged<FileGrouping> onChanged;

  /// 밖에서 쥔 포커스 노드([CapsuleTextField.focusNode]).
  final FocusNode? focusNode;

  /// 나타나자마자 포커스를 가져올지([CapsuleTextField.autofocus]).
  final bool autofocus;

  @override
  State<GroupQueryField> createState() => _GroupQueryFieldState();
}

class _GroupQueryFieldState extends State<GroupQueryField> {
  late GroupCapsuleSyntax _syntax;

  @override
  void initState() {
    super.initState();
    _syntax = GroupCapsuleSyntax(widget.definitions);
  }

  @override
  void didUpdateWidget(GroupQueryField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.definitions, widget.definitions)) {
      setState(() => _syntax = GroupCapsuleSyntax(widget.definitions));
    }
  }

  /// 이미 접힌 단계는 후보에서 뺀다(태그당 한 단계, 폴더 키 최대 1회). 텍스트만
  /// 봐선 캡슐이 어느 키인지 알 수 없어, 확정된 단계를 받아 여기서 거른다.
  CapsuleCompletions _completionsAt(
    String text,
    int cursor,
    List<GroupKey> keys,
  ) {
    final usedTags = {
      for (final key in keys)
        if (key is TagGroupKey) key.tagDefinitionId,
    };
    final folderUsed = keys.any((k) => k is FolderHierarchyGroupKey);
    final completions = groupQueryCompletions(
      text,
      cursor,
      definitions: [
        for (final d in widget.definitions)
          if (!usedTags.contains(d.id)) d,
      ],
    );
    return CapsuleCompletions(
      replaceStart: completions.replaceStart,
      replaceEnd: completions.replaceEnd,
      items: [
        for (final item in completions.items)
          // 폴더 계층 정의는 문법이 후보에 늘 더하므로, 이미 쓰였으면 여기서 뺀다.
          if (!(folderUsed && item.definition.id == kFolderHierarchyGroupId))
            CapsuleCompletion(
              insertText: item.insertText,
              title: item.definition.name,
              description: item.definition.id == kFolderHierarchyGroupId
                  ? '경로 계층'
                  : tagValueTypeLabel(item.definition.valueType),
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CapsuleTextField<GroupKey>(
      syntax: _syntax,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      items: widget.grouping.keys,
      onChanged: (keys) => widget.onChanged(groupFromKeys(keys)),
      completionsAt: _completionsAt,
      hintText: '태그 이름으로 그룹 기준 입력',
    );
  }
}
