import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/tag_definition.dart';
import '../../domain/entities/tag_value_type.dart';
import '../providers/tag_provider.dart';
import '../tag_visuals.dart';

/// 태그 종류(TagDefinition)를 생성·편집·삭제하는 전용 관리 화면.
class TagManagementScreen extends ConsumerWidget {
  const TagManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final definitions = ref.watch(tagDefinitionsProvider);
    final repo = ref.watch(tagRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('태그 관리')),
      floatingActionButton: repo == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openEditor(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('새 태그'),
            ),
      body: repo == null
          ? const Center(child: Text('폴더를 먼저 열어주세요.'))
          : definitions.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('태그를 불러오지 못했습니다: $e')),
              data: (items) => items.isEmpty
                  ? const Center(child: Text('아직 만든 태그가 없습니다.'))
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) =>
                          _DefinitionTile(items[index]),
                    ),
            ),
    );
  }
}

class _DefinitionTile extends ConsumerWidget {
  const _DefinitionTile(this.definition);

  final TagDefinition definition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitle = [
      tagValueTypeLabel(definition.valueType),
      if (definition.allowMultiple) '다중 부여',
    ].join(' · ');

    return ListTile(
      leading: CircleAvatar(
        radius: 12,
        backgroundColor: tagColorOf(definition.color, context),
      ),
      title: Text(definition.name),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: '편집',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _openEditor(context, ref, existing: definition),
          ),
          IconButton(
            tooltip: '삭제',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref, definition),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TagDefinition definition,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('태그 삭제'),
        content: Text('‘${definition.name}’ 태그와 이 태그의 모든 부여 기록이 '
            '삭제됩니다. 계속할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final id = definition.id;
    if (id != null) {
      await ref.read(tagRepositoryProvider)?.deleteDefinition(id);
    }
  }
}

/// 태그 정의 생성/편집 다이얼로그를 띄운다. [existing]이 있으면 편집 모드.
Future<void> _openEditor(
  BuildContext context,
  WidgetRef ref, {
  TagDefinition? existing,
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) => _DefinitionEditorDialog(existing: existing),
  );
}

class _DefinitionEditorDialog extends ConsumerStatefulWidget {
  const _DefinitionEditorDialog({this.existing});

  final TagDefinition? existing;

  @override
  ConsumerState<_DefinitionEditorDialog> createState() =>
      _DefinitionEditorDialogState();
}

class _DefinitionEditorDialogState
    extends ConsumerState<_DefinitionEditorDialog> {
  late final TextEditingController _name;
  late TagValueType _valueType;
  late int? _color;
  late bool _allowMultiple;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _valueType = e?.valueType ?? TagValueType.label;
    _color = e?.color;
    _allowMultiple = e?.allowMultiple ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '이름을 입력해주세요.');
      return;
    }
    final repo = ref.read(tagRepositoryProvider);
    if (repo == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_isEdit) {
        await repo.updateDefinition(
          widget.existing!.copyWith(
            name: name,
            valueType: _valueType,
            color: _color,
            clearColor: _color == null,
            allowMultiple: _allowMultiple,
          ),
        );
      } else {
        await repo.createDefinition(
          name: name,
          valueType: _valueType,
          color: _color,
          allowMultiple: _allowMultiple,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      // 이름 유니크 제약 위반 등.
      if (mounted) {
        setState(() => _error = '저장하지 못했습니다(이름이 중복일 수 있습니다).');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? '태그 편집' : '새 태그'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(labelText: '이름'),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TagValueType>(
              value: _valueType,
              decoration: const InputDecoration(labelText: '값 유형'),
              items: [
                for (final t in TagValueType.values)
                  DropdownMenuItem(
                    value: t,
                    child: Text(tagValueTypeLabel(t)),
                  ),
              ],
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _valueType = v ?? _valueType),
            ),
            const SizedBox(height: 16),
            const Text('색상'),
            const SizedBox(height: 8),
            _ColorPicker(
              selected: _color,
              onChanged: (c) => setState(() => _color = c),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('다중 부여 허용'),
              subtitle: const Text('한 파일에 이 태그를 여러 번 붙일 수 있게 합니다.'),
              value: _allowMultiple,
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _allowMultiple = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('저장'),
        ),
      ],
    );
  }
}

/// 프리셋 팔레트 + '색 없음'을 고르는 작은 스와치 그리드.
class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.selected, required this.onChanged});

  final int? selected;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _swatch(
          context,
          color: null,
          isSelected: selected == null,
          onTap: () => onChanged(null),
        ),
        for (final argb in tagColorPalette)
          _swatch(
            context,
            color: argb,
            isSelected: selected == argb,
            onTap: () => onChanged(argb),
          ),
      ],
    );
  }

  Widget _swatch(
    BuildContext context, {
    required int? color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final border = isSelected
        ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3)
        : Border.all(color: Theme.of(context).dividerColor);
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color == null ? null : Color(color),
          border: border,
        ),
        child: color == null
            ? const Icon(Icons.block, size: 18)
            : (isSelected ? const Icon(Icons.check, size: 18) : null),
      ),
    );
  }
}
