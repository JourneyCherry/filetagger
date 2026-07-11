import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform.dart';
import '../../domain/entities/file_filter.dart';
import '../../domain/entities/file_sort.dart';
import '../../domain/entities/tag_definition.dart';
import '../../domain/entities/tag_value_type.dart';
import '../common/capsule_text_field.dart';
import '../providers/file_view_provider.dart';
import '../providers/system_tag_provider.dart';
import '../tag_visuals.dart';
import 'dialog_utils.dart';
import 'filter_condition_chip.dart';
import 'filter_query_field.dart';
import 'sort_key_chip.dart';
import 'sort_query_field.dart';
import 'tag_picker.dart';

/// 조건 줄 하나의 높이. 조건 칩과 텍스트 입력이 같은 자리를 나눠 쓰므로, 어느 쪽을
/// 그리든 줄 높이가 흔들리지 않도록 한 값에서 가져다 쓴다.
const double _rowHeight = 40;

/// 파일 목록 위에 놓이는 필터·정렬 도구 모음.
///
/// 필터와 정렬을 각각 "태그처럼 추가·재배치하는 조건"으로 다룬다. 필터는 표시/제외
/// 조건과 값 비교를, 정렬은 태그+방향을 하나로 나타낸다(정렬은 순서가 우선순위).
/// 상태는 [file_view_provider]에 있다.
///
/// 데스크톱은 두 줄 모두 텍스트 입력([FilterQueryField]·[SortQueryField])을 늘 띄워
/// 두고, '+' 버튼의 다이얼로그가 그 위에 조건을 얹는다(두 경로가 같은 곳을 고친다).
/// 모바일은 텍스트 입력 대신 조건 칩과 다이얼로그로 편집한다. 어느 쪽이든 조건은
/// 같은 곳(`viewSettingsProvider`)에 저장된다.
class FileToolbar extends ConsumerWidget {
  const FileToolbar({super.key, this.showFilter = true, this.showSort = true});

  /// 필터 조건 줄을 그릴지. 데스크톱 '보기' 메뉴가 토글한다(조건 자체는 남는다).
  final bool showFilter;

  /// 정렬 조건 줄을 그릴지. 데스크톱 '보기' 메뉴가 토글한다(조건 자체는 남는다).
  final bool showSort;

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
      // 바텀시트(모바일)처럼 높이가 느슨하게 주어지는 자리에서도 내용만큼만 차지한다.
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showFilter)
          _buildRow(
            context: context,
            label: '필터',
            content: _buildFilterContent(
              context,
              ref,
              filter,
              definitions,
              defsById,
            ),
            onAdd: definitions.isEmpty
                ? null
                : () => showFilterConditionDialog(context, ref, definitions),
            addTooltip: '필터 조건 추가',
          ),
        if (showFilter && showSort) const SizedBox(height: 8),
        if (showSort)
          _buildRow(
            context: context,
            label: '정렬',
            content: _buildSortContent(
              context,
              ref,
              sort,
              definitions,
              defsById,
            ),
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
    required Widget content,
    required VoidCallback? onAdd,
    required String addTooltip,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        Expanded(child: content),
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: addTooltip,
          onPressed: onAdd,
        ),
      ],
    );
  }

  /// 조건 칩 목록. 비어 있으면 목록 대신 안내 문구를 보여준다.
  Widget _buildListContent(
    BuildContext context, {
    required bool isEmpty,
    required String emptyHint,
    required Widget list,
  }) {
    if (!isEmpty) return SizedBox(height: _rowHeight, child: list);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        emptyHint,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  // ── 필터 ──

  /// 텍스트 입력은 데스크톱에서만 낸다 — 캡슐을 되펼치는 조작이 백스페이스/Delete를
  /// 전제하고, 자동완성 목록이 소프트 키보드와 자리를 다투기 때문이다. 모바일은
  /// 조건 칩과 다이얼로그로 편집한다.
  Widget _buildFilterContent(
    BuildContext context,
    WidgetRef ref,
    FileFilter filter,
    List<TagDefinition> definitions,
    Map<int, TagDefinition> defsById,
  ) {
    if (isDesktopPlatform && definitions.isNotEmpty) {
      return _EditableRow(
        hasChips: filter.conditions.isNotEmpty,
        chips: _buildFilterList(context, ref, filter, defsById),
        buildField: (focusNode, autofocus) => FilterQueryField(
          focusNode: focusNode,
          autofocus: autofocus,
          filter: filter,
          definitions: definitions,
          onChanged: ref.read(viewSettingsProvider.notifier).updateFilter,
        ),
      );
    }
    return _buildListContent(
      context,
      isEmpty: filter.isEmpty,
      emptyHint: '조건 없음 · 모든 항목 표시',
      list: _buildFilterList(context, ref, filter, defsById),
    );
  }

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
              : () => showFilterConditionDialog(
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

  // ── 정렬 ──

  /// 필터와 같은 이유로 텍스트 입력은 데스크톱에서만 낸다.
  Widget _buildSortContent(
    BuildContext context,
    WidgetRef ref,
    FileSortOrder sort,
    List<TagDefinition> definitions,
    Map<int, TagDefinition> defsById,
  ) {
    if (isDesktopPlatform && definitions.isNotEmpty) {
      return _EditableRow(
        hasChips: sort.keys.isNotEmpty,
        chips: _buildSortList(context, ref, sort, defsById),
        buildField: (focusNode, autofocus) => SortQueryField(
          focusNode: focusNode,
          autofocus: autofocus,
          sort: sort,
          definitions: definitions,
          onChanged: ref.read(viewSettingsProvider.notifier).updateSort,
        ),
      );
    }
    return _buildListContent(
      context,
      isEmpty: sort.isEmpty,
      emptyHint: '기본(이름순)',
      list: _buildSortList(context, ref, sort, defsById),
    );
  }

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

/// 데스크톱 조건 줄. 한 자리를 조건 칩과 텍스트 입력이 번갈아 쓴다.
///
/// 편집 중이 아닐 때는 칩을 그려 손잡이 드래그(순서 변경)·탭(편집)·x(삭제)를 받고,
/// 빈 곳을 누르면 그 자리에 텍스트 입력이 들어서며 포커스를 가져간다. 포커스를 잃으면
/// 다시 칩으로 돌아온다(그 길목에서 접히지 못한 원문이 정리되므로 칩과 텍스트가 늘
/// 같은 것을 보여준다).
class _EditableRow extends StatefulWidget {
  const _EditableRow({
    required this.buildField,
    required this.chips,
    required this.hasChips,
  });

  final Widget Function(FocusNode focusNode, bool autofocus) buildField;
  final Widget chips;

  /// 그릴 칩이 있는지. 없으면 늘 텍스트 입력을 낸다(입력 안내 문구가 보이도록).
  final bool hasChips;

  @override
  State<_EditableRow> createState() => _EditableRowState();
}

class _EditableRowState extends State<_EditableRow> {
  final FocusNode _focus = FocusNode();

  /// 텍스트 입력이 이 자리를 쓰고 있는지. 칩을 눌러 들어오고, 포커스를 잃어 나간다.
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    _focus.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focus.hasFocus == _editing) return;
    setState(() => _editing = _focus.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final showChips = widget.hasChips && !_editing;
    return SizedBox(
      height: _rowHeight,
      child: showChips
          // 칩이 먼저 탭을 가져가고, 칩 사이·뒤의 빈 곳만 여기로 떨어진다.
          // 텍스트 입력과 같은 만큼 들여써, 칩↔텍스트 전환에서 캡슐 시작점이
          // 어긋나지 않게 한다.
          ? GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => setState(() => _editing = true),
              child: Padding(
                padding: const EdgeInsets.only(left: kCapsuleFieldInset),
                child: widget.chips,
              ),
            )
          : Align(
              alignment: Alignment.centerLeft,
              child: widget.buildField(_focus, _editing),
            ),
    );
  }
}

/// 필터 조건 편집기를 열어 조건을 추가하거나 [editIndex] 위치의 조건을 바꾼다.
///
/// 툴바의 '+' 버튼과 조건 칩 탭이 함께 쓰는 진입점이다.
Future<void> showFilterConditionDialog(
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

/// 도구모음에 놓인 필터 조건 칩. 겉모습은 텍스트 입력의 캡슐과 공유하고
/// ([FilterConditionChip]), 여기선 순서 변경 손잡이와 삭제 버튼을 켜 동작까지 붙인다.
/// 탭하면 편집, x로 즉시 제거한다.
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
    // 가로 목록이 아이템을 줄 높이만큼 세로로 늘리므로, 캡슐이 두꺼워지지 않도록
    // 제 높이대로 세로 가운데에 둔다(텍스트 입력 안의 캡슐과 같은 두께가 되도록).
    return Center(
      widthFactor: 1,
      child: FilterConditionChip(
        condition: condition,
        definition: definition,
        onTap: onTap,
        dragIndex: index,
        onDelete: onDelete,
      ),
    );
  }
}

/// 도구모음에 놓인 정렬 단계 칩. 겉모습은 텍스트 입력의 캡슐과 공유하고
/// ([SortKeyChip]), 여기선 순서 변경 손잡이와 삭제 버튼을 켜 동작까지 붙인다.
/// 탭하면 방향 토글, x로 즉시 제거한다.
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
    // 가로 목록이 아이템을 줄 높이만큼 세로로 늘리므로, 캡슐이 두꺼워지지 않도록
    // 제 높이대로 세로 가운데에 둔다(텍스트 입력 안의 캡슐과 같은 두께가 되도록).
    return Center(
      widthFactor: 1,
      child: SortKeyChip(
        sortKey: sortKey,
        definition: definition,
        onTap: onToggle,
        dragIndex: index,
        onDelete: onDelete,
      ),
    );
  }
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
                        child: Text(filterOperatorMenuLabel(op)),
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
