import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/tag_definition.dart';
import '../providers/file_view_provider.dart';
import '../providers/tag_provider.dart';
import '../tag_visuals.dart';
import 'dialog_utils.dart';
import 'tag_chip.dart';

/// 목록의 **이름 칸에 보일 값의 출처 우선순위**를 편집하는 다이얼로그.
///
/// 썸네일 태그와 같은 얼개다 — 한 노드는 이 순서로 훑어 **처음으로 글자를 낸 태그**의
/// 값을 이름 자리에 보이고, 어느 태그도 못 내면 노드 이름(파일 이름)으로 폴백한다.
/// 그래서 기본은 늘 맨 아래에 있는 셈이라 목록에 두지 않는다. 편집은 즉시 저장된다.
///
/// 후보에는 **값을 글자로 낼 수 있는 태그만** 낸다(썸네일 태그가 이미지를 낼 수 있는
/// 태그만 내는 것과 같은 방식). 골라도 늘 폴백하는 태그를 목록에 세울 수 있으면
/// "골랐는데 아무 일도 일어나지 않는" 자리가 생긴다.
Future<void> showNameTagDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _NameTagDialog());

class _NameTagDialog extends ConsumerStatefulWidget {
  const _NameTagDialog();

  @override
  ConsumerState<_NameTagDialog> createState() => _NameTagDialogState();
}

class _NameTagDialogState extends ConsumerState<_NameTagDialog> {
  /// 우선순위 목록(앞이 높음). 태그 id만 담는다 — 노드 이름은 늘 맨 아래(암묵적).
  late final List<int> _order = [...ref.read(nameSourcesProvider)];

  void _save() =>
      ref.read(viewSettingsProvider.notifier).updateNameSources(_order);

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _order.removeAt(oldIndex);
      _order.insert(newIndex, item);
    });
    _save();
  }

  void _remove(int tagId) {
    setState(() => _order.remove(tagId));
    _save();
  }

  void _add(int tagId) {
    setState(() => _order.add(tagId));
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final defs = ref.watch(tagDefinitionsProvider).valueOrNull ?? const [];
    final byId = {
      for (final d in defs)
        if (d.id != null) d.id!: d,
    };
    final candidates = [
      for (final d in defs)
        if (canNameSourceShowText(d.valueType) &&
            d.id != null &&
            !_order.contains(d.id))
          d,
    ];

    return escDismissible(
      context,
      AlertDialog(
        title: const Text('이름 태그'),
        content: dialogContentBox(
          context,
          width: 400,
          height: 460,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '목록의 이름 자리에 보일 값의 우선순위입니다. 위에서 아래로 훑어 처음으로 '
                '글자를 내는 태그의 값을 씁니다. 어느 태그도 못 내면 파일 이름을 씁니다. '
                '이 설정은 조건 프리셋에 함께 담겨, 프리셋을 부르면 같이 바뀝니다.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _order.isEmpty
                    ? Center(
                        child: Text(
                          '지정한 태그가 없습니다. 아래에서 태그를 추가하세요.\n'
                          '(비우면 파일 이름을 그대로 씁니다.)',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      )
                    : ReorderableListView.builder(
                        buildDefaultDragHandles: false,
                        itemCount: _order.length,
                        onReorderItem: _reorder,
                        itemBuilder: (context, i) => _priorityTile(i, byId),
                      ),
              ),
              if (candidates.isNotEmpty) ...[
                const Divider(height: 24),
                Text('추가할 태그', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                SizedBox(
                  height: 96,
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final d in candidates)
                          ActionChip(
                            avatar: const Icon(Icons.add, size: 16),
                            label: Text(d.name),
                            onPressed: () => _add(d.id!),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _priorityTile(int index, Map<int, TagDefinition> byId) {
    final tagId = _order[index];
    final def = byId[tagId];
    return ListTile(
      key: ValueKey('name-$tagId'),
      leading: ReorderableDragStartListener(
        index: index,
        child: const Icon(Icons.drag_handle),
      ),
      title: def == null
          ? Text('(없는 태그 $tagId)')
          : Align(
              alignment: Alignment.centerLeft,
              child: TagChip(definition: def),
            ),
      trailing: IconButton(
        tooltip: '목록에서 빼기',
        icon: const Icon(Icons.close),
        onPressed: () => _remove(tagId),
      ),
    );
  }
}
