import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/file_grouping.dart';
import '../../domain/entities/query_preset.dart';
import '../../domain/entities/tag_definition.dart';
import '../../domain/usecases/filter_query_text.dart';
import '../../domain/usecases/group_query_text.dart';
import '../../domain/usecases/sort_query_text.dart';
import '../providers/file_view_provider.dart';
import '../providers/query_preset_provider.dart';
import '../tag_visuals.dart';
import 'dialog_utils.dart';
import 'filter_condition_chip.dart';
import 'group_key_chip.dart';
import 'query_preset_chip.dart';
import 'sort_key_chip.dart';
import 'tag_chip.dart';

/// 도구모음 맨 위 줄에 저장된 프리셋을 캡슐로 늘어놓는다.
///
/// 탭하면 그 프리셋을 통째로 걸고(지금 걸린 조건과 이름·썸네일 출처는 모두
/// 지워진다), 손잡이 드래그로 순서를 바꾸며, x로 지운다. 이름 변경·덮어쓰기는
/// 우클릭(모바일은 길게 누르기) 메뉴에 둔다. 지우기는 어느 길로 오든 확인을 한 번
/// 거친다 — 조건 칩과 달리 사용자가 만들어 둔 자산이라 한 번의 오조작으로 사라지면
/// 되돌릴 수 없다.
class QueryPresetRow extends ConsumerWidget {
  const QueryPresetRow({super.key, required this.presets});

  final List<QueryPreset> presets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defsById = ref.watch(definitionsByIdProvider);
    final active = ref.watch(activeQueryPresetProvider);

    return ReorderableListView.builder(
      scrollDirection: Axis.horizontal,
      buildDefaultDragHandles: false,
      itemCount: presets.length,
      onReorderItem: (oldIndex, newIndex) =>
          ref.read(queryPresetsProvider.notifier).reorder(oldIndex, newIndex),
      itemBuilder: (context, index) {
        final preset = presets[index];
        // 가로 목록이 아이템을 줄 높이만큼 세로로 늘리므로, 캡슐이 두꺼워지지 않도록
        // 제 높이대로 세로 가운데에 둔다(다른 조건 줄의 캡슐과 같은 두께가 되도록).
        return Center(
          key: ObjectKey(preset),
          widthFactor: 1,
          child: GestureDetector(
            onSecondaryTapDown: (details) =>
                _showMenu(context, ref, index, details.globalPosition),
            onLongPressStart: (details) =>
                _showMenu(context, ref, index, details.globalPosition),
            child: QueryPresetChip(
              name: preset.name,
              active: index == active,
              tooltip: presetSummary(preset, defsById),
              dragIndex: index,
              onTap: () => _apply(context, ref, preset),
              onDelete: () => _delete(context, ref, index),
            ),
          ),
        );
      },
    );
  }

  /// 프리셋을 걸고, 태그가 사라져 걸 수 없던 조각이 있으면 알린다.
  void _apply(BuildContext context, WidgetRef ref, QueryPreset preset) {
    final dropped = ref.read(viewSettingsProvider.notifier).applyPreset(preset);
    if (dropped == 0 || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('없는 태그를 가리키는 항목 $dropped개는 빼고 불러왔습니다.')),
    );
  }

  Future<void> _showMenu(
    BuildContext context,
    WidgetRef ref,
    int index,
    Offset globalPosition,
  ) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final chosen = await showMenu<_PresetMenuAction>(
      context: context,
      position: RelativeRect.fromRect(
        globalPosition & Size.zero,
        Offset.zero & overlay.size,
      ),
      items: [
        for (final action in _PresetMenuAction.values)
          PopupMenuItem(
            value: action,
            child: Row(
              children: [
                SizedBox(width: 28, child: Icon(action.icon, size: 18)),
                Text(action.label),
              ],
            ),
          ),
      ],
    );
    if (chosen == null || !context.mounted) return;
    final notifier = ref.read(queryPresetsProvider.notifier);
    switch (chosen) {
      case _PresetMenuAction.rename:
        final name = await showPresetNameDialog(
          context,
          title: '프리셋 이름 변경',
          initial: presets[index].name,
          confirmLabel: '변경',
        );
        if (name == null) return;
        notifier.renameAt(index, name);
      case _PresetMenuAction.overwrite:
        notifier.overwriteAt(index);
      case _PresetMenuAction.delete:
        await _delete(context, ref, index);
    }
  }

  /// 확인을 받고 [index] 프리셋을 지운다(캡슐의 x와 메뉴가 함께 쓰는 한 길).
  Future<void> _delete(BuildContext context, WidgetRef ref, int index) async {
    final confirmed = await _confirmDelete(context, presets[index].name);
    if (confirmed) ref.read(queryPresetsProvider.notifier).removeAt(index);
  }

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => escDismissible(
        dialogContext,
        AlertDialog(
          title: const Text('프리셋 삭제'),
          content: Text("'$name' 프리셋을 지웁니다. 지금 걸린 조건은 그대로 남습니다."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('삭제'),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }
}

/// 프리셋 캡슐의 컨텍스트 메뉴 항목.
enum _PresetMenuAction {
  rename('이름 변경…', Icons.edit_outlined),
  overwrite('현재 조건·표시로 덮어쓰기', Icons.save_as_outlined),
  delete('삭제', Icons.delete_outline);

  const _PresetMenuAction(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// 프리셋이 담은 것을 한눈에 보는 여러 줄 요약(툴팁용). 조건 줄의 텍스트 표현을
/// 그대로 쓴다 — 텍스트 입력에서 보던 것과 같은 문법으로 보인다.
///
/// 이름·썸네일 출처도 함께 적는다. 눌렀을 때 조건만 바뀌는 것이 아니므로, 무엇이
/// 갈아끼워지는지 미리 보이지 않으면 표시가 바뀐 이유를 알 수 없다.
String presetSummary(QueryPreset preset, Map<int, TagDefinition> defsById) {
  final filter = formatFilterQuery(preset.filter, defsById);
  final sort = formatSortQuery(preset.sort, defsById);
  final group = formatGroupQuery(preset.grouping, defsById);
  return [
    '필터: ${filter.isEmpty ? '없음' : filter}',
    '정렬: ${sort.isEmpty ? '기본(이름순)' : sort}',
    '그룹: ${group.isEmpty ? '묶지 않음' : group}',
    '이름: ${_sourceNames(preset.nameSources, defsById) ?? '파일 이름'}',
    '썸네일: ${_sourceNames(preset.thumbnailSources, defsById) ?? '기본'}',
  ].join('\n');
}

/// 출처 우선순위를 태그 이름으로 늘어놓는다(앞이 높음). 비면 null — 호출부가 그
/// 자리의 기본값 이름을 적는다.
String? _sourceNames(List<int> sources, Map<int, TagDefinition> defsById) {
  if (sources.isEmpty) return null;
  return [for (final id in sources) defsById[id]?.name ?? '?'].join(' › ');
}

/// 지금 걸린 조건을 이름 붙여 저장하는 다이얼로그를 연다.
///
/// 같은 이름이 이미 있으면 그 자리에서 덮어쓴다(확인 버튼 라벨로 미리 알린다) —
/// 이름이 프리셋을 가리키는 유일한 수단이라 같은 이름 둘을 허용하지 않는다.
Future<void> showQueryPresetSaveDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final active = ref.read(activeQueryPresetProvider);
  final presets = ref.read(queryPresetsProvider);
  final name = await showDialog<String>(
    context: context,
    builder: (_) => _PresetSaveDialog(
      // 이미 그 프리셋을 걸고 조건을 손본 참이면 같은 이름을 미리 채워, 갱신이
      // 이름을 다시 치지 않고 끝난다.
      initialName: active == null ? '' : presets[active].name,
    ),
  );
  if (name == null) return;
  ref.read(queryPresetsProvider.notifier).saveCurrent(name);
}

/// 이름 하나만 받는 다이얼로그(이름 변경). 빈 이름은 확인이 눌리지 않는다.
Future<String?> showPresetNameDialog(
  BuildContext context, {
  required String title,
  required String initial,
  required String confirmLabel,
}) => showDialog<String>(
  context: context,
  builder: (_) =>
      _PresetNameDialog(title: title, initial: initial, confirm: confirmLabel),
);

class _PresetNameDialog extends StatefulWidget {
  const _PresetNameDialog({
    required this.title,
    required this.initial,
    required this.confirm,
  });

  final String title;
  final String initial;
  final String confirm;

  @override
  State<_PresetNameDialog> createState() => _PresetNameDialogState();
}

class _PresetNameDialogState extends State<_PresetNameDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String get _trimmed => _name.text.trim();

  void _save() {
    if (_trimmed.isEmpty) return;
    Navigator.of(context).pop(_trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return escDismissible(
      context,
      AlertDialog(
        title: Text(widget.title),
        content: dialogContentBox(
          context,
          width: 360,
          child: TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '이름',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _save(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: _trimmed.isEmpty ? null : _save,
            child: Text(widget.confirm),
          ),
        ],
      ),
    );
  }
}

/// 이름 입력 + 저장될 조건 미리보기. 미리보기는 도구모음과 같은 캡슐을 표시 전용으로
/// (손잡이·x 없이) 그려, 저장되는 것이 지금 보고 있는 그 조건임을 확인시켜 준다.
class _PresetSaveDialog extends ConsumerStatefulWidget {
  const _PresetSaveDialog({required this.initialName});

  final String initialName;

  @override
  ConsumerState<_PresetSaveDialog> createState() => _PresetSaveDialogState();
}

class _PresetSaveDialogState extends ConsumerState<_PresetSaveDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initialName,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String get _trimmed => _name.text.trim();

  void _save() {
    if (_trimmed.isEmpty) return;
    Navigator.of(context).pop(_trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final defsById = ref.watch(definitionsByIdProvider);
    final filter = ref.watch(fileFilterProvider);
    final sort = ref.watch(fileSortProvider);
    final grouping = ref.watch(groupingProvider);
    final nameSources = ref.watch(nameSourcesProvider);
    final thumbnailSources = ref.watch(thumbnailSourcesProvider);
    final overwrites =
        ref.read(queryPresetsProvider.notifier).indexOfName(_trimmed) != null;

    return escDismissible(
      context,
      AlertDialog(
        title: const Text('현재 조건·표시를 프리셋으로 저장'),
        content: dialogContentBox(
          context,
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: '이름',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  helperText: overwrites ? '같은 이름의 프리셋을 덮어씁니다.' : null,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 16),
              _preview('필터', [
                for (final c in filter.conditions)
                  FilterConditionChip(
                    condition: c,
                    definition: defsById[c.tagDefinitionId],
                  ),
              ]),
              _preview('정렬', [
                for (final k in sort.keys)
                  SortKeyChip(
                    sortKey: k,
                    definition: defsById[k.tagDefinitionId],
                  ),
              ]),
              _preview('그룹', [
                for (final k in grouping.keys)
                  GroupKeyChip(
                    groupKey: k,
                    definition: k is TagGroupKey
                        ? defsById[k.tagDefinitionId]
                        : null,
                  ),
              ]),
              _preview(
                '이름',
                _sourceChips(nameSources, defsById),
                emptyLabel: '파일 이름',
              ),
              _preview(
                '썸네일',
                _sourceChips(thumbnailSources, defsById),
                emptyLabel: '기본',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: _trimmed.isEmpty ? null : _save,
            child: Text(overwrites ? '덮어쓰기' : '저장'),
          ),
        ],
      ),
    );
  }

  /// 미리보기 한 줄(라벨 + 캡슐들). 빈 줄은 설명 대신 짧은 표식만 둔다 — 여기서 볼
  /// 것은 "무엇이 저장되는가"이지 빈 줄의 뜻이 아니다(그 설명은 조건 줄이 맡는다).
  ///
  /// 표시 출처 줄만은 [emptyLabel]로 그 자리의 기본값을 적는다. 조건과 달리 "비었다"가
  /// 곧 "무엇으로 보인다"를 뜻해, 빈 표식만으로는 불러온 뒤 무엇이 될지 알 수 없다.
  Widget _preview(String label, List<Widget> chips, {String? emptyLabel}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(label, style: theme.textTheme.labelLarge),
          ),
          Expanded(
            child: chips.isEmpty
                ? Text(
                    emptyLabel ?? kEmptyQueryLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : Wrap(spacing: 4, runSpacing: 4, children: chips),
          ),
        ],
      ),
    );
  }

  /// 출처 우선순위 줄의 캡슐들(앞이 높은 우선순위 그대로). 여기 오는 것은 지금 걸린
  /// 값이라 사라진 태그는 이미 정리된 뒤다(`_reconcile`).
  List<Widget> _sourceChips(
    List<int> sources,
    Map<int, TagDefinition> defsById,
  ) => [
    for (final id in sources)
      if (defsById[id] case final def?) TagChip(definition: def),
  ];
}
