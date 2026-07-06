import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/file_filter.dart';
import '../../domain/entities/file_sort.dart';
import '../../domain/entities/tag_definition.dart';
import '../../domain/entities/tag_value_type.dart';
import '../providers/file_view_provider.dart';
import '../providers/system_tag_provider.dart';
import '../tag_visuals.dart';
import 'dialog_utils.dart';
import 'tag_picker.dart';

/// 파일 목록 위에 놓이는 필터·정렬 도구 모음.
///
/// 필터와 정렬을 각각 "태그처럼 추가·재배치하는 조건 칩"으로 다룬다. 필터는
/// 표시/제외 조건과 값 비교를, 정렬은 태그+방향을 칩 하나로 나타내며 드래그로
/// 순서를 바꾼다(정렬은 순서가 우선순위). 상태는 [file_view_provider]에 있다.
class FileToolbar extends ConsumerWidget {
  const FileToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 필터·정렬은 사용자 태그 + 시스템 태그를 모두 대상으로 고를 수 있다.
    final definitions = ref.watch(pickableTagDefinitionsProvider);
    final defsById = ref.watch(definitionsByIdProvider);
    final filter = ref.watch(fileFilterProvider);
    final sort = ref.watch(fileSortProvider);

    // 정렬에 아직 쓰지 않은 태그만 추가 후보(태그당 1단계). label도 포함한다.
    final sortCandidates = [
      for (final d in definitions)
        if (d.id != null && !sort.contains(d.id!)) d,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRow(
          context: context,
          label: '필터',
          isEmpty: filter.isEmpty,
          emptyHint: '조건 없음 · 모든 항목 표시',
          list: _buildFilterList(context, ref, filter, defsById),
          onAdd: definitions.isEmpty
              ? null
              : () => _openFilterDialog(context, ref, definitions),
          addTooltip: '필터 조건 추가',
        ),
        const SizedBox(height: 8),
        _buildRow(
          context: context,
          label: '정렬',
          isEmpty: sort.isEmpty,
          emptyHint: '기본(이름순)',
          list: _buildSortList(context, ref, sort, defsById),
          onAdd: sortCandidates.isEmpty
              ? null
              : () => _openSortDialog(context, ref, sortCandidates),
          addTooltip: '정렬 기준 추가',
        ),
      ],
    );
  }

  Widget _buildRow({
    required BuildContext context,
    required String label,
    required bool isEmpty,
    required String emptyHint,
    required Widget list,
    required VoidCallback? onAdd,
    required String addTooltip,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        Expanded(
          child: isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    emptyHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : SizedBox(height: 40, child: list),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: addTooltip,
          onPressed: onAdd,
        ),
      ],
    );
  }

  // ── 필터 ──

  Widget _buildFilterList(
    BuildContext context,
    WidgetRef ref,
    FileFilter filter,
    Map<int, TagDefinition> defsById,
  ) {
    return ReorderableListView.builder(
      scrollDirection: Axis.horizontal,
      buildDefaultDragHandles: false,
      itemCount: filter.conditions.length,
      onReorderItem: (oldIndex, newIndex) {
        ref
            .read(viewSettingsProvider.notifier)
            .updateFilter(filter.reorder(oldIndex, newIndex));
      },
      itemBuilder: (context, index) {
        final condition = filter.conditions[index];
        final def = defsById[condition.tagDefinitionId];
        return _FilterChip(
          key: ObjectKey(condition),
          index: index,
          condition: condition,
          definition: def,
          onTap: def == null
              ? null
              : () => _openFilterDialog(
                  context,
                  ref,
                  defsById.values.toList(),
                  editIndex: index,
                  initial: condition,
                ),
          onDelete: () => ref
              .read(viewSettingsProvider.notifier)
              .updateFilter(filter.removeAt(index)),
        );
      },
    );
  }

  Future<void> _openFilterDialog(
    BuildContext context,
    WidgetRef ref,
    List<TagDefinition> definitions, {
    int? editIndex,
    FilterCondition? initial,
  }) async {
    final result = await showDialog<FilterCondition>(
      context: context,
      builder: (_) =>
          _FilterConditionEditor(definitions: definitions, initial: initial),
    );
    if (result == null) return;
    final filter = ref.read(fileFilterProvider);
    ref
        .read(viewSettingsProvider.notifier)
        .updateFilter(
          editIndex == null
              ? filter.add(result)
              : filter.replaceAt(editIndex, result),
        );
  }

  // ── 정렬 ──

  Widget _buildSortList(
    BuildContext context,
    WidgetRef ref,
    FileSortOrder sort,
    Map<int, TagDefinition> defsById,
  ) {
    return ReorderableListView.builder(
      scrollDirection: Axis.horizontal,
      buildDefaultDragHandles: false,
      itemCount: sort.keys.length,
      onReorderItem: (oldIndex, newIndex) {
        ref
            .read(viewSettingsProvider.notifier)
            .updateSort(sort.reorder(oldIndex, newIndex));
      },
      itemBuilder: (context, index) {
        final key = sort.keys[index];
        final def = defsById[key.tagDefinitionId];
        return _SortChip(
          key: ObjectKey(key),
          index: index,
          sortKey: key,
          definition: def,
          // label은 존재 여부로만 정렬하므로 방향 토글이 의미 없다.
          onToggle: def?.valueType == TagValueType.label
              ? null
              : () => ref
                    .read(viewSettingsProvider.notifier)
                    .updateSort(sort.toggleAt(index)),
          onDelete: () => ref
              .read(viewSettingsProvider.notifier)
              .updateSort(sort.removeAt(index)),
        );
      },
    );
  }

  Future<void> _openSortDialog(
    BuildContext context,
    WidgetRef ref,
    List<TagDefinition> candidates,
  ) async {
    final result = await showDialog<SortKey>(
      context: context,
      builder: (_) => _SortKeyEditor(candidates: candidates),
    );
    if (result == null) return;
    ref
        .read(viewSettingsProvider.notifier)
        .updateSort(ref.read(fileSortProvider).add(result));
  }
}

/// 조건/정렬 칩 왼쪽의 드래그 손잡이(순서 변경용).
class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.index, required this.color});

  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ReorderableDragStartListener(
      index: index,
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Icon(Icons.drag_indicator, size: 16, color: color),
      ),
    );
  }
}

/// 칩 오른쪽의 즉시 삭제(x) 버튼. 부여 태그 칩의 삭제 아이콘과 같은 모양.
class _ChipDeleteButton extends StatelessWidget {
  const _ChipDeleteButton({required this.color, required this.onDelete});

  final Color color;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onDelete,
      radius: 16,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(Icons.cancel, size: 18, color: color),
      ),
    );
  }
}

/// 필터 조건 하나를 나타내는 칩. 제외 조건은 흐린 회색에 금지 아이콘,
/// 표시 조건은 태그색으로 채운다. 탭하면 편집, x로 즉시 제거한다.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    super.key,
    required this.index,
    required this.condition,
    required this.definition,
    required this.onTap,
    required this.onDelete,
  });

  final int index;
  final FilterCondition condition;
  final TagDefinition? definition;
  final VoidCallback? onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final def = definition;

    final Color background;
    final Color foreground;
    if (condition.exclude) {
      background = scheme.surfaceContainerHighest;
      foreground = scheme.onSurfaceVariant;
    } else if (def?.color != null) {
      background = Color(def!.color!);
      foreground = foregroundOn(background);
    } else {
      background = scheme.secondaryContainer;
      foreground = scheme.onSecondaryContainer;
    }

    final text = def == null ? '(삭제된 태그)' : conditionText(condition, def);

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: background,
        shape: const StadiumBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DragHandle(index: index, color: foreground),
                if (condition.exclude)
                  Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Icon(Icons.block, size: 14, color: foreground),
                  ),
                Text(text, style: TextStyle(color: foreground)),
                const SizedBox(width: 2),
                _ChipDeleteButton(color: foreground, onDelete: onDelete),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 정렬 단계 하나를 나타내는 칩(태그 + 방향). 탭하면 방향 토글, x로 제거한다.
/// label 태그는 방향이 없어 화살표 대신 존재 정렬 아이콘을 보여준다.
class _SortChip extends StatelessWidget {
  const _SortChip({
    super.key,
    required this.index,
    required this.sortKey,
    required this.definition,
    required this.onToggle,
    required this.onDelete,
  });

  final int index;
  final SortKey sortKey;
  final TagDefinition? definition;

  /// null이면 방향 토글이 없는 정렬(label).
  final VoidCallback? onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = scheme.onSecondaryContainer;
    final name = definition?.name ?? '(삭제된 태그)';
    final ascending = sortKey.direction == SortDirection.ascending;
    final isLabel = definition?.valueType == TagValueType.label;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name, style: TextStyle(color: foreground)),
          const SizedBox(width: 2),
          Icon(
            isLabel
                ? Icons.check_circle_outline
                : (ascending ? Icons.arrow_upward : Icons.arrow_downward),
            size: 14,
            color: foreground,
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: scheme.secondaryContainer,
        shape: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DragHandle(index: index, color: foreground),
              if (onToggle != null)
                InkWell(
                  onTap: onToggle,
                  customBorder: const StadiumBorder(),
                  child: content,
                )
              else
                content,
              const SizedBox(width: 2),
              _ChipDeleteButton(color: foreground, onDelete: onDelete),
            ],
          ),
        ),
      ),
    );
  }
}

/// 필터 조건 칩에 표시할 문자열. 존재 조건은 태그 이름만, 값 조건은
/// "이름 연산 값"으로 보여준다(날짜는 보기 좋게 자름).
String conditionText(FilterCondition condition, TagDefinition def) {
  if (condition.operator == FilterOperator.exists) return def.name;
  final op = filterOperatorLabel(condition.operator);
  final operand = def.valueType == TagValueType.date
      ? (formatTagValue(TagValueType.date, condition.operand) ??
            condition.operand ??
            '')
      : (condition.operand ?? '');
  return '${def.name} $op $operand';
}

/// 태그 하나에 대한 필터 조건(태그·표시/제외·연산·값)을 편집하는 다이얼로그.
class _FilterConditionEditor extends StatefulWidget {
  const _FilterConditionEditor({required this.definitions, this.initial});

  final List<TagDefinition> definitions;
  final FilterCondition? initial;

  @override
  State<_FilterConditionEditor> createState() => _FilterConditionEditorState();
}

class _FilterConditionEditorState extends State<_FilterConditionEditor> {
  int? _tagId;
  late bool _exclude;
  FilterOperator _operator = FilterOperator.exists;
  final TextEditingController _operand = TextEditingController();
  DateTime? _date;
  String? _error;

  TagValueType? get _type => _defOf(_tagId)?.valueType;
  bool get _needsOperand => _operator != FilterOperator.exists;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _tagId = initial?.tagDefinitionId;
    _exclude = initial?.exclude ?? false;
    final type = _type;
    if (type != null) {
      final ops = operatorsForType(type);
      _operator = (initial != null && ops.contains(initial.operator))
          ? initial.operator
          : ops.first;
      if (type == TagValueType.date) {
        _date = DateTime.tryParse(initial?.operand ?? '');
      } else {
        _operand.text = initial?.operand ?? '';
      }
    }
  }

  @override
  void dispose() {
    _operand.dispose();
    super.dispose();
  }

  TagDefinition? _defOf(int? id) {
    if (id == null) return null;
    for (final d in widget.definitions) {
      if (d.id == id) return d;
    }
    return null;
  }

  void _onTagSelected(int id) {
    setState(() {
      _tagId = id;
      final ops = operatorsForType(_defOf(id)!.valueType);
      if (!ops.contains(_operator)) _operator = ops.first;
      _operand.clear();
      _date = null;
      _error = null;
    });
  }

  void _save() {
    if (_tagId == null) return;
    String? operand;
    if (_needsOperand) {
      if (_type == TagValueType.date) {
        if (_date == null) {
          setState(() => _error = '날짜를 선택하세요.');
          return;
        }
        operand = dateToStoredValue(_date!);
      } else {
        final text = _operand.text.trim();
        if (_type == TagValueType.number && num.tryParse(text) == null) {
          setState(() => _error = '숫자를 입력하세요.');
          return;
        }
        operand = text;
      }
    }
    Navigator.of(context).pop(
      FilterCondition(
        tagDefinitionId: _tagId!,
        operator: _operator,
        operand: operand,
        exclude: _exclude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final type = _type;
    return escDismissible(
      context,
      AlertDialog(
        title: Text(widget.initial == null ? '필터 조건 추가' : '필터 조건 편집'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TagPicker(
                definitions: widget.definitions,
                selectedId: _tagId,
                onSelected: _onTagSelected,
              ),
              if (type != null) ...[
                const SizedBox(height: 16),
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: false, label: Text('표시')),
                    ButtonSegment(value: true, label: Text('제외')),
                  ],
                  selected: {_exclude},
                  onSelectionChanged: (s) => setState(() => _exclude = s.first),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<FilterOperator>(
                  // 태그가 바뀌면 가능한 연산 목록도 바뀌므로, 폼필드를 새로
                  // 만들어(initialValue 재적용) 무효한 선택이 남지 않게 한다.
                  key: ValueKey(_tagId),
                  initialValue: _operator,
                  decoration: const InputDecoration(
                    labelText: '연산',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    for (final op in operatorsForType(type))
                      DropdownMenuItem(
                        value: op,
                        child: Text(_operatorMenuLabel(op)),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _operator = v);
                  },
                ),
                if (_needsOperand) ...[
                  const SizedBox(height: 16),
                  _buildOperandField(type),
                ],
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: _tagId == null ? null : _save,
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildOperandField(TagValueType type) {
    if (type == TagValueType.date) {
      final label = _date == null
          ? '날짜 선택'
          : (formatTagValue(TagValueType.date, dateToStoredValue(_date!)) ??
                '');
      return Row(
        children: [
          Expanded(child: Text(label)),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today, size: 16),
            label: const Text('선택'),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date ?? DateTime.now(),
                firstDate: DateTime(1970),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      );
    }

    final isNumber = type == TagValueType.number;
    return TextField(
      controller: _operand,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : TextInputType.text,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))]
          : null,
      decoration: InputDecoration(
        labelText: '값',
        border: const OutlineInputBorder(),
        isDense: true,
        errorText: _error,
      ),
      onSubmitted: (_) => _save(),
    );
  }

  String _operatorMenuLabel(FilterOperator op) {
    switch (op) {
      case FilterOperator.exists:
        return '있음 (존재)';
      case FilterOperator.equals:
        return '= 같음';
      case FilterOperator.notEquals:
        return '≠ 다름';
      case FilterOperator.lessThan:
        return '< 미만';
      case FilterOperator.lessOrEqual:
        return '≤ 이하';
      case FilterOperator.greaterThan:
        return '> 초과';
      case FilterOperator.greaterOrEqual:
        return '≥ 이상';
      case FilterOperator.contains:
        return '포함';
    }
  }
}

/// 정렬 기준(태그 + 방향)을 추가하는 다이얼로그. label 태그는 존재 여부로만
/// 정렬해 방향 선택을 숨긴다.
class _SortKeyEditor extends StatefulWidget {
  const _SortKeyEditor({required this.candidates});

  final List<TagDefinition> candidates;

  @override
  State<_SortKeyEditor> createState() => _SortKeyEditorState();
}

class _SortKeyEditorState extends State<_SortKeyEditor> {
  int? _tagId;
  SortDirection _direction = SortDirection.ascending;

  bool get _isLabel {
    final def = _tagId == null ? null : _defOf(_tagId!);
    return def?.valueType == TagValueType.label;
  }

  TagDefinition? _defOf(int id) {
    for (final d in widget.candidates) {
      if (d.id == id) return d;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return escDismissible(
      context,
      AlertDialog(
        title: const Text('정렬 기준 추가'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TagPicker(
                definitions: widget.candidates,
                selectedId: _tagId,
                onSelected: (id) => setState(() => _tagId = id),
              ),
              if (_tagId != null) ...[
                const SizedBox(height: 16),
                if (_isLabel)
                  Text(
                    '라벨 태그는 방향과 무관하게 부여된 항목을 위로 정렬합니다.',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else
                  SegmentedButton<SortDirection>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: SortDirection.ascending,
                        label: Text('오름차순'),
                        icon: Icon(Icons.arrow_upward, size: 16),
                      ),
                      ButtonSegment(
                        value: SortDirection.descending,
                        label: Text('내림차순'),
                        icon: Icon(Icons.arrow_downward, size: 16),
                      ),
                    ],
                    selected: {_direction},
                    onSelectionChanged: (s) =>
                        setState(() => _direction = s.first),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: _tagId == null
                ? null
                : () => Navigator.of(context).pop(
                    SortKey(
                      tagDefinitionId: _tagId!,
                      // label은 방향이 무의미하므로 오름차순으로 고정.
                      direction: _isLabel
                          ? SortDirection.ascending
                          : _direction,
                    ),
                  ),
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }
}
