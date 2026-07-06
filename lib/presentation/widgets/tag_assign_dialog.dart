import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/assigned_tag.dart';
import '../../domain/entities/tag_definition.dart';
import '../../domain/entities/tag_value_type.dart';
import '../providers/tag_provider.dart';
import '../tag_visuals.dart';
import 'dialog_utils.dart';
import 'tag_chip.dart';
import 'tag_picker.dart';
import 'tag_value_prompt.dart';

/// 선택한 파일들에 태그를 부여/편집/해제하는 모달 다이얼로그를 띄운다.
Future<void> showTagAssignDialog(
  BuildContext context, {
  required List<int> fileNodeIds,
  required String title,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _TagAssignDialog(fileNodeIds: fileNodeIds, title: title),
  );
}

class _TagAssignDialog extends ConsumerStatefulWidget {
  const _TagAssignDialog({required this.fileNodeIds, required this.title});

  final List<int> fileNodeIds;
  final String title;

  @override
  ConsumerState<_TagAssignDialog> createState() => _TagAssignDialogState();
}

class _TagAssignDialogState extends ConsumerState<_TagAssignDialog> {
  /// 부여할 태그 선택과 유형별 값 입력 상태.
  int? _addTagId;
  final TextEditingController _addValue = TextEditingController();
  DateTime? _addDate;
  String? _addError;

  bool get _isSingle => widget.fileNodeIds.length == 1;

  @override
  void dispose() {
    _addValue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(tagRepositoryProvider);
    final definitions =
        ref.watch(tagDefinitionsProvider).valueOrNull ?? const [];
    final byFile = ref.watch(assignmentsByFileProvider).valueOrNull ?? const {};

    // 선택된 파일들에 걸린 부여 기록을 모은다.
    final selectedAssignments = <AssignedTag>[
      for (final id in widget.fileNodeIds) ...(byFile[id] ?? const []),
    ];

    return escDismissible(
      context,
      AlertDialog(
        title: Text(widget.title),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('부여된 태그', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                if (selectedAssignments.isEmpty)
                  const Text('아직 부여된 태그가 없습니다.')
                else if (_isSingle)
                  _buildSingleFileTags(selectedAssignments)
                else
                  _buildMultiFileTags(selectedAssignments),
                const Divider(height: 32),
                Text('태그 추가', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                if (definitions.isEmpty)
                  const Text('먼저 태그 관리에서 태그를 만들어주세요.')
                else
                  _buildAddSection(definitions),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: repo == null ? null : () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  /// 단일 선택: 부여 기록을 하나씩(다중 부여 포함) 나열하고 개별 편집/해제.
  Widget _buildSingleFileTags(List<AssignedTag> assignments) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final a in assignments)
          TagChip(
            definition: a.definition,
            value: a.value,
            onPressed: a.definition.hasValue ? () => _editAssignment(a) : null,
            onDeleted: () => _unassignOne(a),
          ),
      ],
    );
  }

  /// 다중 선택: 태그 정의별로 묶어 공통/혼합 상태를 보여주고 일괄 수정/해제.
  Widget _buildMultiFileTags(List<AssignedTag> assignments) {
    final total = widget.fileNodeIds.length;
    final byDef = <int, List<AssignedTag>>{};
    for (final a in assignments) {
      byDef.putIfAbsent(a.tagDefinitionId, () => []).add(a);
    }

    return Column(
      children: [
        for (final entry in byDef.entries)
          _buildDefinitionGroup(entry.value, total),
      ],
    );
  }

  Widget _buildDefinitionGroup(List<AssignedTag> group, int totalFiles) {
    final def = group.first.definition;
    final fileCount = group.map((a) => a.fileNodeId).toSet().length;
    final distinctValues = group.map((a) => a.value).toSet();
    final commonValue = distinctValues.length == 1
        ? distinctValues.first
        : null;
    final mixedValue = def.hasValue && distinctValues.length > 1;

    final subtitleParts = <String>[
      '$fileCount/$totalFiles 파일',
      if (mixedValue) '값 혼합',
    ];

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Align(
        alignment: Alignment.centerLeft,
        child: TagChip(definition: def, value: mixedValue ? null : commonValue),
      ),
      subtitle: Text(subtitleParts.join(' · ')),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (def.hasValue && !def.allowMultiple)
            IconButton(
              tooltip: '값을 모두 이 값으로 설정',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _setValueForAll(def, initial: commonValue),
            ),
          IconButton(
            tooltip: '모두 해제',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _unassignAll(def),
          ),
        ],
      ),
    );
  }

  /// 태그 추가: 검색 콤보박스로 태그를 고르고, 선택한 태그 유형에 맞는 값 입력을
  /// 바로 아래에 인라인으로 노출한 뒤 '부여'로 일괄 부여한다.
  Widget _buildAddSection(List<TagDefinition> definitions) {
    final def = _addTagId == null ? null : _defOf(definitions, _addTagId!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TagPicker(
          definitions: definitions,
          selectedId: _addTagId,
          onSelected: (id) => setState(() {
            _addTagId = id;
            _addValue.clear();
            _addDate = null;
            _addError = null;
          }),
        ),
        if (def != null && def.hasValue) ...[
          const SizedBox(height: 12),
          _buildAddValueField(def),
        ],
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: def == null ? null : () => _addSelected(def),
            child: const Text('부여'),
          ),
        ),
      ],
    );
  }

  Widget _buildAddValueField(TagDefinition def) {
    if (def.valueType == TagValueType.date) {
      final label = _addDate == null
          ? '오늘 (미선택)'
          : (formatTagValue(TagValueType.date, dateToStoredValue(_addDate!)) ??
                '');
      return Row(
        children: [
          Expanded(child: Text(label)),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today, size: 16),
            label: const Text('날짜 선택'),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _addDate ?? DateTime.now(),
                firstDate: DateTime(1970),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _addDate = picked);
            },
          ),
        ],
      );
    }

    final isNumber = def.valueType == TagValueType.number;
    return TextField(
      controller: _addValue,
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
        errorText: _addError,
        helperText: isNumber ? '비워두면 기본값이 채워집니다.' : '빈 값도 저장할 수 있습니다.',
      ),
      onSubmitted: (_) => _addSelected(def),
    );
  }

  // ── 액션 ──

  TagDefinition? _defOf(List<TagDefinition> definitions, int id) {
    for (final d in definitions) {
      if (d.id == id) return d;
    }
    return null;
  }

  Future<void> _addSelected(TagDefinition def) async {
    final id = def.id;
    if (id == null) return;
    String? value;
    if (def.hasValue) {
      switch (def.valueType) {
        case TagValueType.date:
          // 미선택이면 오늘 날짜로 부여한다.
          value = dateToStoredValue(_addDate ?? DateTime.now());
        case TagValueType.number:
          final text = _addValue.text.trim();
          if (text.isEmpty) {
            value = '0'; // 미입력 시 기본값(빈 값 방지).
          } else if (num.tryParse(text) == null) {
            setState(() => _addError = '숫자를 입력하세요.');
            return;
          } else {
            value = text;
          }
        case TagValueType.text:
          value = _addValue.text.trim(); // 빈 문자열도 유효.
        case TagValueType.label:
          value = null;
      }
    }
    await ref
        .read(tagRepositoryProvider)
        ?.assignToFiles(
          fileNodeIds: widget.fileNodeIds,
          tagDefinitionId: id,
          value: value,
        );
    setState(() {
      _addValue.clear();
      _addDate = null;
      _addError = null;
    });
  }

  Future<void> _editAssignment(AssignedTag a) async {
    final result = await promptTagValue(
      context,
      a.definition,
      initial: a.value,
    );
    if (result == null) return;
    final assignmentId = a.assignment.id;
    if (assignmentId == null) return;
    await ref
        .read(tagRepositoryProvider)
        ?.updateAssignmentValue(
          assignmentId: assignmentId,
          value: result.value,
        );
  }

  Future<void> _setValueForAll(TagDefinition def, {String? initial}) async {
    final result = await promptTagValue(context, def, initial: initial);
    if (result == null) return;
    final id = def.id;
    if (id == null) return;
    await ref
        .read(tagRepositoryProvider)
        ?.assignToFiles(
          fileNodeIds: widget.fileNodeIds,
          tagDefinitionId: id,
          value: result.value,
        );
  }

  Future<void> _unassignOne(AssignedTag a) async {
    final assignmentId = a.assignment.id;
    if (assignmentId == null) return;
    await ref.read(tagRepositoryProvider)?.unassign(assignmentId);
  }

  Future<void> _unassignAll(TagDefinition def) async {
    final id = def.id;
    if (id == null) return;
    await ref
        .read(tagRepositoryProvider)
        ?.unassignFromFiles(
          fileNodeIds: widget.fileNodeIds,
          tagDefinitionId: id,
        );
  }
}
