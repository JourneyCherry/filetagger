/// 태그 종류(TagDefinition)를 만들고 고치고 합치고 지우는 다이얼로그 모음.
///
/// 데스크톱의 태그 관리 다이얼로그와 모바일의 태그 관리 화면이 같은 편집기를
/// 쓰도록 진입점을 여기 한 곳에 모은다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/tag_definition.dart';
import '../../domain/entities/tag_value_type.dart';
import '../../domain/usecases/merge_tags.dart';
import '../providers/file_view_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/tag_provider.dart';
import '../tag_visuals.dart';
import 'color_picker_dialog.dart';

/// 태그 칩의 목록·프리뷰 표시 여부를 켜고 끄는 눈 모양 토글. 시스템 태그·사용자
/// 태그가 같은 모양(눈 뜸=표시, 눈 감김=감춤)을 쓰도록 한 곳에 둔다. 감춰도 값은
/// 필터·정렬·그룹에 그대로 참여하고, 이 토글은 칩 렌더링에만 관여한다.
class TagVisibilityToggle extends StatelessWidget {
  const TagVisibilityToggle({
    super.key,
    required this.visible,
    required this.onChanged,
  });

  final bool visible;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: visible ? '목록에서 감추기' : '목록에 표시하기',
      icon: Icon(
        visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
      onPressed: () => onChanged(!visible),
    );
  }
}

/// 사용자 태그 한 종류에 붙는 조작 버튼 묶음(합치기 · 편집 · 삭제 · 표시 토글).
/// 관리 화면의 행과 관리 다이얼로그의 행이 같은 조작·표기를 공유한다.
///
/// [showDelete]를 끄면 삭제 버튼을 감춘다 — 삭제를 태그 캡슐 안의 x로 옮긴 자리에서
/// 중복을 없애기 위함이다(그 자리는 [confirmTagDelete]를 직접 부른다).
class TagDefinitionActions extends ConsumerWidget {
  const TagDefinitionActions({
    super.key,
    required this.definition,
    this.showDelete = true,
  });

  final TagDefinition definition;
  final bool showDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 이 태그로 흡수할 수 있는 다른 태그(값 유형·다중 허용이 같은)가 있을 때만 연다.
    final allDefs = ref.watch(tagDefinitionsProvider).valueOrNull ?? const [];
    final canMerge = mergeTargetsFor(definition, allDefs).isNotEmpty;
    final id = definition.id;
    // 목록·프리뷰 칩 표시 여부. 감춰도 값은 필터·정렬·그룹에 그대로 참여한다.
    final visible =
        id == null ||
        !ref.watch(viewSettingsProvider).hiddenTagIds.contains(id);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: canMerge ? '다른 태그를 여기에 합치기' : '합칠 수 있는 태그가 없습니다',
          icon: const Icon(Icons.merge_outlined),
          onPressed: canMerge ? () => openTagMerge(context, definition) : null,
        ),
        IconButton(
          tooltip: '편집',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => openTagEditor(context, existing: definition),
        ),
        if (showDelete)
          IconButton(
            tooltip: '삭제',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => confirmTagDelete(context, ref, definition),
          ),
        // 표시 토글은 시스템 태그 행과 같은 자리(가장 오른쪽)에 두어 위치를 통일한다.
        TagVisibilityToggle(
          visible: visible,
          onChanged: id == null
              ? (_) {}
              : (on) => ref
                    .read(viewSettingsProvider.notifier)
                    .updateUserTagVisibility(id, on),
        ),
      ],
    );
  }
}

/// 태그 정의 생성/편집 다이얼로그를 띄운다. [existing]이 있으면 편집 모드.
Future<void> openTagEditor(
  BuildContext context, {
  TagDefinition? existing,
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) => _DefinitionEditorDialog(existing: existing),
  );
}

/// 태그 합치기 다이얼로그를 띄운다. 사용자가 고른 태그들의 부여 기록을 [target]으로
/// 옮기고 고른 태그들의 정의를 제거한다([target]의 이름·색이 남음).
Future<void> openTagMerge(BuildContext context, TagDefinition target) async {
  await showDialog<void>(
    context: context,
    builder: (context) => _MergeDialog(target: target),
  );
}

/// 태그를 삭제한다. 부여된 파일이 있으면 값이 함께 사라진다고 경고 후 확인받는다.
/// 액션 버튼 묶음과, 삭제를 캡슐 안 x로 옮긴 자리가 함께 부른다.
Future<void> confirmTagDelete(
  BuildContext context,
  WidgetRef ref,
  TagDefinition definition,
) async {
  final id = definition.id;
  if (id == null) return;
  final repo = ref.read(tagRepositoryProvider);
  if (repo == null) return;

  // 이 태그가 부여된 파일 수. 하나도 없으면 잃을 게 없으니 곧바로 삭제한다.
  final assignedNodes = ref.read(nodeCountByTagProvider).valueOrNull?[id] ?? 0;
  if (assignedNodes == 0) {
    await repo.deleteDefinition(id);
    return;
  }

  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => _DeleteConfirmDialog(
      tagName: definition.name,
      assignedNodes: assignedNodes,
    ),
  );
  if (ok != true) return;
  await repo.deleteDefinition(id);
}

/// 태그 삭제 확인 다이얼로그. 부여된 파일이 있을 때만 뜨며, 그 값이 함께 제거됨을
/// 경고 스타일(경고 아이콘·색)로 강조한다.
class _DeleteConfirmDialog extends StatelessWidget {
  const _DeleteConfirmDialog({
    required this.tagName,
    required this.assignedNodes,
  });

  final String tagName;
  final int assignedNodes;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: scheme.error),
      title: const Text('태그 삭제'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('‘$tagName’ 태그를 삭제합니다.'),
          const SizedBox(height: 12),
          Text(
            '$assignedNodes개 파일에 부여된 이 태그의 값이 모두 함께 제거되며, '
            '되돌릴 수 없습니다.',
            style: TextStyle(color: scheme.error),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('삭제'),
        ),
      ],
    );
  }
}

/// 태그 합치기 다이얼로그. 사용자가 고른 태그들(source)의 부여 기록을 [target]으로
/// 옮기고 그 정의들을 제거한다(target의 이름·색이 남음). 흡수 후보는 값 유형·다중
/// 부여 허용이 target과 같은 다른 사용자 태그로 한정되며, 여러 개를 동시에 고를 수 있다.
class _MergeDialog extends ConsumerStatefulWidget {
  const _MergeDialog({required this.target});

  final TagDefinition target;

  @override
  ConsumerState<_MergeDialog> createState() => _MergeDialogState();
}

class _MergeDialogState extends ConsumerState<_MergeDialog> {
  final Set<int> _selected = {};
  bool _saving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final target = widget.target;
    final allDefs = ref.watch(tagDefinitionsProvider).valueOrNull ?? const [];
    final sources = mergeTargetsFor(target, allDefs);
    // 목록에서 후보가 사라졌으면(다른 곳에서 삭제/편집) 선택에서 걸러낸다.
    final sourceIds = {for (final s in sources) s.id};
    final selectedValid = _selected.where(sourceIds.contains).toSet();

    return AlertDialog(
      title: Text('‘${target.name}’에 합치기'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '아래에서 고른 태그의 부여 기록을 ‘${target.name}’ 태그로 옮기고, 고른 '
              '태그들은 제거합니다. ‘${target.name}’의 이름과 색이 유지됩니다.',
            ),
            const SizedBox(height: 12),
            for (final s in sources)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: _selected.contains(s.id),
                onChanged: _saving
                    ? null
                    : (on) => setState(() {
                        if (on == true) {
                          _selected.add(s.id!);
                        } else {
                          _selected.remove(s.id);
                        }
                      }),
                secondary: CircleAvatar(
                  radius: 10,
                  backgroundColor: tagColorOf(s.color, context),
                ),
                title: Text(s.name),
              ),
            if (!target.allowMultiple) ...[
              const SizedBox(height: 8),
              Text(
                '같은 파일에 두 태그가 모두 있으면 ‘${target.name}’의 값을 유지하고 '
                '합쳐지는 태그 쪽 값은 버립니다.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
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
          onPressed: _saving || selectedValid.isEmpty
              ? null
              : () => _merge(selectedValid),
          child: const Text('합치기'),
        ),
      ],
    );
  }

  Future<void> _merge(Set<int> sourceIds) async {
    final targetId = widget.target.id;
    if (targetId == null || sourceIds.isEmpty) return;
    final repo = ref.read(tagRepositoryProvider);
    if (repo == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await repo.mergeDefinitions(
        targetId: targetId,
        sourceIds: sourceIds.toList(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _error = '합치지 못했습니다: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
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
              initialValue: _valueType,
              decoration: const InputDecoration(labelText: '값 유형'),
              items: [
                for (final t in TagValueType.values)
                  DropdownMenuItem(value: t, child: Text(tagValueTypeLabel(t))),
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

/// 스와치 안에 넣는 표식(막음·선택 표시·직접 고르기)의 크기.
const double _swatchIconSize = 18;

/// 프리셋 팔레트 + 직접 골라 둔 색 + '색 없음' + '직접 고르기'를 늘어놓는 스와치 그리드.
///
/// 팔레트는 자주 쓰는 색으로 가는 지름길이고, 그 뒤에 이 사용자가 직접 골랐던 색이
/// 이어 붙어 다음 태그에도 한 번에 쓰인다([customTagColorsProvider] — 폴더가 아니라
/// 사람에게 붙는 목록이다). 마지막 스와치가 임의의 색으로 가는 길을 연다. 저장 형식은
/// 셋이 같아(불투명 ARGB 정수) 고른 경로가 값에 남지 않는다.
class _ColorPicker extends ConsumerWidget {
  const _ColorPicker({required this.selected, required this.onChanged});

  final int? selected;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 아직 못 읽었으면 팔레트만 보인다 — 목록이 뜨는 것을 기다리느라 색을 못 고를
    // 이유가 없다.
    final saved =
        ref.watch(customTagColorsProvider).valueOrNull ?? const <int>[];
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
        for (final argb in [...tagColorPalette, ...saved])
          _swatch(
            context,
            color: argb,
            isSelected: selected == argb,
            onTap: () => onChanged(argb),
          ),
        _customSwatch(context, ref, saved),
      ],
    );
  }

  /// 임의의 색으로 가는 자리. 지금 고른 색이 앞의 어느 스와치에도 없으면(예전에 고른
  /// 색이 목록에서 밀려난 태그) 그 색을 담아 선택된 것으로 보여, 어느 것도 눌리지
  /// 않은 것처럼 보이지 않게 한다.
  Widget _customSwatch(BuildContext context, WidgetRef ref, List<int> saved) {
    final unlisted =
        selected != null &&
            !tagColorPalette.contains(selected) &&
            !saved.contains(selected)
        ? selected
        : null;
    return Tooltip(
      message: '직접 고르기',
      child: _swatch(
        context,
        color: unlisted,
        isSelected: unlisted != null,
        icon: Icons.colorize,
        onTap: () async {
          final picked = await showColorPickerDialog(
            context,
            initialColor: selected,
          );
          if (picked == null) return;
          onChanged(picked);
          // 고른 색은 다음 태그에도 쓰이도록 목록 맨 앞으로 올린다.
          await ref.read(customTagColorsProvider.notifier).touch(picked);
        },
      ),
    );
  }

  Widget _swatch(
    BuildContext context, {
    required int? color,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
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
        child: icon != null
            ? Icon(
                icon,
                size: _swatchIconSize,
                color: color == null ? null : foregroundOn(Color(color)),
              )
            : color == null
            ? const Icon(Icons.block, size: _swatchIconSize)
            : (isSelected
                  ? Icon(
                      Icons.check,
                      size: _swatchIconSize,
                      color: foregroundOn(Color(color)),
                    )
                  : null),
      ),
    );
  }
}
