/// 필터 조건을 **텍스트로 입력·수정**하는 필드.
///
/// 캡슐(글자 하나로 접힌 조건)의 동작은 [CapsuleTextField]에 있고, 여기엔 필터
/// 문법에 딸린 것만 둔다 — 조각↔조건 변환, 조건 칩 그리기, 자동완성 후보의 표시
/// 문구. 미완성·무효 조각은 접히지 않고 원문으로 남으며, 확정된 조건만 밖으로
/// 흘러간다.
library;

import 'package:flutter/material.dart';

import '../../domain/entities/file_filter.dart';
import '../../domain/entities/tag_definition.dart';
import '../../domain/usecases/filter_query_text.dart';
import '../common/capsule_text_field.dart';
import '../tag_visuals.dart';
import 'filter_condition_chip.dart';

/// 조각↔조건 변환과 조건 칩 그리기. 태그 정의가 바뀌면 새로 만든다(불변).
class FilterCapsuleSyntax extends CapsuleSyntax<FilterCondition> {
  FilterCapsuleSyntax(Iterable<TagDefinition> definitions)
    : definitions = List.unmodifiable(definitions),
      _byId = {
        for (final d in definitions)
          if (d.id != null) d.id!: d,
      };

  /// 이름으로 고를 수 있는 태그(사용자 + 시스템).
  final List<TagDefinition> definitions;
  final Map<int, TagDefinition> _byId;

  /// 조각 하나가 통째로 조건이어야 접는다 — 인용부호가 닫히지 않아 조각이 둘로
  /// 갈리는 문자열은 아직 확정되지 않은 입력이다.
  @override
  FilterCondition? parse(String chunk) {
    final segments = parseFilterQuery(chunk, definitions: definitions);
    if (segments.length != 1) return null;
    final segment = segments.first;
    return segment is FilterQueryCondition ? segment.condition : null;
  }

  @override
  String? format(FilterCondition item) {
    final def = _byId[item.tagDefinitionId];
    return def == null ? null : formatFilterCondition(item, def);
  }

  @override
  bool isInvalid(String chunk) {
    final segments = parseFilterQuery(chunk, definitions: definitions);
    return segments.length == 1 && segments.first is FilterQueryFragment;
  }

  @override
  Widget chip(FilterCondition item) => FilterConditionChip(
    condition: item,
    definition: _byId[item.tagDefinitionId],
    margin: EdgeInsets.zero,
    // 손잡이·x는 동작할 수 없어 아이콘을 감춘다(자리는 그대로라 도구모음 조건 칩과
    // 같은 모양이 되어, 칩 줄↔텍스트 전환에서 캡슐이 튀지 않는다).
  );
}

/// 필터 텍스트의 편집 상태를 쥔 컨트롤러.
class FilterQueryController extends CapsuleTextController<FilterCondition> {
  FilterQueryController({required Iterable<TagDefinition> definitions})
    : super(FilterCapsuleSyntax(definitions));

  set definitions(Iterable<TagDefinition> value) =>
      syntax = FilterCapsuleSyntax(value);

  /// 텍스트에 놓인 순서대로의, 확정된 조건들(미완성·무효 조각은 빠진다).
  List<FilterCondition> get conditions => items;

  /// 밖에서 정해진 필터로 텍스트를 갈아 끼운다(모든 조건이 캡슐로 접힌 상태).
  void setFilter(FileFilter filter) => setItems(filter.conditions);
}

/// 필터를 텍스트로 편집하는 입력 필드. 태그 이름·연산자는 자동완성으로 고른다.
class FilterQueryField extends StatefulWidget {
  const FilterQueryField({
    super.key,
    required this.filter,
    required this.definitions,
    required this.onChanged,
    this.focusNode,
    this.autofocus = false,
  });

  final FileFilter filter;

  /// 이름으로 고를 수 있는 태그(사용자 + 시스템).
  final List<TagDefinition> definitions;

  final ValueChanged<FileFilter> onChanged;

  /// 밖에서 쥔 포커스 노드([CapsuleTextField.focusNode]).
  final FocusNode? focusNode;

  /// 나타나자마자 포커스를 가져올지([CapsuleTextField.autofocus]).
  final bool autofocus;

  @override
  State<FilterQueryField> createState() => _FilterQueryFieldState();
}

class _FilterQueryFieldState extends State<FilterQueryField> {
  late FilterCapsuleSyntax _syntax;

  @override
  void initState() {
    super.initState();
    _syntax = FilterCapsuleSyntax(widget.definitions);
  }

  @override
  void didUpdateWidget(FilterQueryField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.definitions, widget.definitions)) {
      setState(() => _syntax = FilterCapsuleSyntax(widget.definitions));
    }
  }

  CapsuleCompletions _completionsAt(String text, int cursor) {
    final completions = filterQueryCompletions(
      text,
      cursor,
      definitions: widget.definitions,
    );
    return CapsuleCompletions(
      replaceStart: completions.replaceStart,
      replaceEnd: completions.replaceEnd,
      items: [
        for (final item in completions.items)
          CapsuleCompletion(
            insertText: item.insertText,
            title: _title(item),
            description: _description(item),
          ),
      ],
    );
  }

  static String _title(FilterQueryCompletion item) => switch (item) {
    FilterTagCompletion(:final definition) => definition.name,
    FilterOperatorCompletion(:final insertText) => insertText,
  };

  static String _description(FilterQueryCompletion item) => switch (item) {
    FilterTagCompletion(:final definition) => tagValueTypeLabel(
      definition.valueType,
    ),
    FilterOperatorCompletion(:final operator) => filterOperatorMenuLabel(
      operator,
    ),
  };

  @override
  Widget build(BuildContext context) {
    return CapsuleTextField<FilterCondition>(
      syntax: _syntax,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      items: widget.filter.conditions,
      onChanged: (conditions) =>
          widget.onChanged(FileFilter(conditions: conditions)),
      completionsAt: (text, cursor, _) => _completionsAt(text, cursor),
      hintText: '태그 이름으로 조건 입력',
    );
  }
}
