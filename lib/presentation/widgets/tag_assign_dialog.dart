import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/assigned_tag.dart';
import '../../domain/entities/tag_definition.dart';
import '../providers/tag_provider.dart';
import 'tag_chip.dart';
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
  int? _addTagId;

  bool get _isSingle => widget.fileNodeIds.length == 1;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(tagRepositoryProvider);
    final definitions =
        ref.watch(tagDefinitionsProvider).valueOrNull ?? const [];
    final byFile =
        ref.watch(assignmentsByFileProvider).valueOrNull ?? const {};

    // 선택된 파일들에 걸린 부여 기록을 모은다.
    final selectedAssignments = <AssignedTag>[
      for (final id in widget.fileNodeIds) ...(byFile[id] ?? const []),
    ];

    return AlertDialog(
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
                _buildAddRow(definitions),
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
    final commonValue = distinctValues.length == 1 ? distinctValues.first : null;
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

  Widget _buildAddRow(List<TagDefinition> definitions) {
    _addTagId ??= definitions.first.id;
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            value: _addTagId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: '태그'),
            items: [
              for (final d in definitions)
                if (d.id != null)
                  DropdownMenuItem(value: d.id, child: Text(d.name)),
            ],
            onChanged: (v) => setState(() => _addTagId = v),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: () => _addSelected(definitions),
          child: const Text('부여'),
        ),
      ],
    );
  }

  // ── 액션 ──

  Future<void> _addSelected(List<TagDefinition> definitions) async {
    final id = _addTagId;
    if (id == null) return;
    final def = definitions.firstWhere((d) => d.id == id);
    String? value;
    if (def.hasValue) {
      final result = await promptTagValue(context, def);
      if (result == null) return; // 취소
      value = result.value;
    }
    await ref.read(tagRepositoryProvider)?.assignToFiles(
          fileNodeIds: widget.fileNodeIds,
          tagDefinitionId: id,
          value: value,
        );
  }

  Future<void> _editAssignment(AssignedTag a) async {
    final result =
        await promptTagValue(context, a.definition, initial: a.value);
    if (result == null) return;
    final assignmentId = a.assignment.id;
    if (assignmentId == null) return;
    await ref.read(tagRepositoryProvider)?.updateAssignmentValue(
          assignmentId: assignmentId,
          value: result.value,
        );
  }

  Future<void> _setValueForAll(TagDefinition def, {String? initial}) async {
    final result = await promptTagValue(context, def, initial: initial);
    if (result == null) return;
    final id = def.id;
    if (id == null) return;
    await ref.read(tagRepositoryProvider)?.assignToFiles(
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
    await ref.read(tagRepositoryProvider)?.unassignFromFiles(
          fileNodeIds: widget.fileNodeIds,
          tagDefinitionId: id,
        );
  }
}
