/// 정렬 기준을 **텍스트로 입력·수정**하는 필드.
///
/// 캡슐(글자 하나로 접힌 단계)의 동작은 [CapsuleTextField]에 있고, 여기엔 정렬
/// 문법에 딸린 것만 둔다 — 조각↔단계 변환, 정렬 칩 그리기, 자동완성 후보. 텍스트에
/// 놓인 왼→오 순서가 그대로 정렬 우선순위이므로, 캡슐을 잘라 옮기는 것이 곧
/// 우선순위 재배치다.
library;

import 'package:flutter/material.dart';

import '../../domain/entities/file_sort.dart';
import '../../domain/entities/tag_definition.dart';
import '../../domain/usecases/sort_query_text.dart';
import '../common/capsule_text_field.dart';
import '../tag_visuals.dart';
import 'sort_key_chip.dart';

/// 조각↔정렬 단계 변환과 정렬 칩 그리기. 태그 정의가 바뀌면 새로 만든다(불변).
class SortCapsuleSyntax extends CapsuleSyntax<SortKey> {
  SortCapsuleSyntax(Iterable<TagDefinition> definitions)
    : definitions = List.unmodifiable(definitions),
      _byId = {
        for (final d in definitions)
          if (d.id != null) d.id!: d,
      };

  /// 이름으로 고를 수 있는 태그(사용자 + 시스템).
  final List<TagDefinition> definitions;
  final Map<int, TagDefinition> _byId;

  /// 조각 하나가 통째로 단계여야 접는다 — 인용부호가 닫히지 않아 조각이 둘로
  /// 갈리는 문자열은 아직 확정되지 않은 입력이다.
  @override
  SortKey? parse(String chunk) {
    final segments = parseSortQuery(chunk, definitions: definitions);
    if (segments.length != 1) return null;
    final segment = segments.first;
    return segment is SortQueryKey ? segment.key : null;
  }

  @override
  String? format(SortKey item) {
    final def = _byId[item.tagDefinitionId];
    return def == null ? null : formatSortKey(item, def);
  }

  @override
  bool isInvalid(String chunk) {
    final segments = parseSortQuery(chunk, definitions: definitions);
    return segments.length == 1 && segments.first is SortQueryFragment;
  }

  @override
  Widget chip(SortKey item) => SortKeyChip(
    sortKey: item,
    definition: _byId[item.tagDefinitionId],
    margin: EdgeInsets.zero,
    // 손잡이·x는 동작할 수 없어 아이콘을 감춘다(자리는 그대로라 도구모음 정렬 칩과
    // 같은 모양이 되어, 칩 줄↔텍스트 전환에서 캡슐이 튀지 않는다).
  );
}

/// 정렬 텍스트의 편집 상태를 쥔 컨트롤러.
class SortQueryController extends CapsuleTextController<SortKey> {
  SortQueryController({required Iterable<TagDefinition> definitions})
    : super(SortCapsuleSyntax(definitions));

  set definitions(Iterable<TagDefinition> value) =>
      syntax = SortCapsuleSyntax(value);

  /// 텍스트에 놓인 순서대로의, 확정된 단계들(미완성·무효 조각은 빠진다).
  List<SortKey> get keys => items;

  /// 밖에서 정해진 정렬로 텍스트를 갈아 끼운다(모든 단계가 캡슐로 접힌 상태).
  void setSort(FileSortOrder sort) => setItems(sort.keys);
}

/// 정렬을 텍스트로 편집하는 입력 필드. 태그 이름은 자동완성으로 고르고, 방향은
/// 이름 앞에 접두사를 붙여 뒤집는다.
class SortQueryField extends StatefulWidget {
  const SortQueryField({
    super.key,
    required this.sort,
    required this.definitions,
    required this.onChanged,
    this.focusNode,
    this.autofocus = false,
  });

  final FileSortOrder sort;

  /// 이름으로 고를 수 있는 태그(사용자 + 시스템).
  final List<TagDefinition> definitions;

  final ValueChanged<FileSortOrder> onChanged;

  /// 밖에서 쥔 포커스 노드([CapsuleTextField.focusNode]).
  final FocusNode? focusNode;

  /// 나타나자마자 포커스를 가져올지([CapsuleTextField.autofocus]).
  final bool autofocus;

  @override
  State<SortQueryField> createState() => _SortQueryFieldState();
}

class _SortQueryFieldState extends State<SortQueryField> {
  late SortCapsuleSyntax _syntax;

  @override
  void initState() {
    super.initState();
    _syntax = SortCapsuleSyntax(widget.definitions);
  }

  @override
  void didUpdateWidget(SortQueryField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.definitions, widget.definitions)) {
      setState(() => _syntax = SortCapsuleSyntax(widget.definitions));
    }
  }

  /// 이미 접힌 단계의 태그는 후보에서 뺀다(태그당 한 단계). 텍스트만 봐선 캡슐이
  /// 어느 태그인지 알 수 없어, 확정된 단계를 받아 여기서 거른다.
  CapsuleCompletions _completionsAt(
    String text,
    int cursor,
    List<SortKey> keys,
  ) {
    final used = {for (final key in keys) key.tagDefinitionId};
    final completions = sortQueryCompletions(
      text,
      cursor,
      definitions: [
        for (final d in widget.definitions)
          if (!used.contains(d.id)) d,
      ],
    );
    return CapsuleCompletions(
      replaceStart: completions.replaceStart,
      replaceEnd: completions.replaceEnd,
      items: [
        for (final item in completions.items)
          CapsuleCompletion(
            insertText: item.insertText,
            title: item.definition.name,
            description: tagValueTypeLabel(item.definition.valueType),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CapsuleTextField<SortKey>(
      syntax: _syntax,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      items: widget.sort.keys,
      onChanged: (keys) => widget.onChanged(sortFromKeys(keys)),
      completionsAt: _completionsAt,
      hintText: '태그 이름으로 정렬 기준 입력',
    );
  }
}
