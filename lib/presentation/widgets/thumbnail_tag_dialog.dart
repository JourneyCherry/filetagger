import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/tag_definition.dart';
import '../../domain/entities/tag_value_type.dart';
import '../../domain/entities/workspace_view_settings.dart';
import '../providers/file_view_provider.dart';
import '../providers/tag_provider.dart';
import 'dialog_utils.dart';
import 'tag_chip.dart';

/// 노드 썸네일의 **출처 우선순위**를 편집하는 다이얼로그.
///
/// 링크 유형(대상 노드의 이미지)·이미지 유형(외부에서 등록한 커스텀 이미지) 사용자
/// 태그를 우선순위 목록에 담아 순서를 정한다. 한 노드는 이 순서로 훑어 처음으로
/// 썸네일을 낸 출처를 쓴다 — 노드마다 가진 태그가 달라도 각자 맞는 출처가 뽑히고, 둘
/// 다 가지면 앞선 출처가 이긴다. 목록의 어느 태그도 못 내면 **기본 썸네일**(자기
/// 이미지·폴더 대표)로 폴백하므로, 기본은 늘 맨 아래에 있는 셈이라 목록에 두지 않는다.
/// 편집은 즉시 보기 설정에 저장된다.
Future<void> showThumbnailTagDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => const _ThumbnailTagDialog(),
);

class _ThumbnailTagDialog extends ConsumerStatefulWidget {
  const _ThumbnailTagDialog();

  @override
  ConsumerState<_ThumbnailTagDialog> createState() =>
      _ThumbnailTagDialogState();
}

class _ThumbnailTagDialogState extends ConsumerState<_ThumbnailTagDialog> {
  /// 우선순위 목록(앞이 높음). 태그 id만 담는다 — 기본 썸네일은 늘 맨 아래(암묵적).
  late List<int> _order;

  @override
  void initState() {
    super.initState();
    // 저장된 목록에서 기본 항목(옛 예약 값)은 걸러 낸다 — 이제 늘 맨 아래라 목록에 없다.
    _order = [
      for (final s in ref.read(thumbnailSourcesProvider))
        if (s != kDefaultThumbnailSourceId) s,
    ];
  }

  void _save() =>
      ref.read(viewSettingsProvider.notifier).updateThumbnailSources(_order);

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
        if ((d.valueType == TagValueType.link ||
                d.valueType == TagValueType.image) &&
            d.id != null &&
            !_order.contains(d.id))
          d,
    ];

    return escDismissible(
      context,
      AlertDialog(
        title: const Text('썸네일 태그'),
        content: SizedBox(
          width: 400,
          height: 460,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '썸네일 출처의 우선순위입니다. 위에서 아래로 훑어 처음으로 이미지를 내는 '
                '출처를 씁니다. 어느 태그도 못 내면 기본 썸네일(자기 이미지·폴더 대표)을 '
                '씁니다. 링크·이미지 유형 태그는 태그 관리에서 만듭니다.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _order.isEmpty
                    ? Center(
                        child: Text(
                          '지정한 출처가 없습니다. 아래에서 태그를 추가하세요.\n'
                          '(비우면 기본 썸네일만 씁니다.)',
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
                Wrap(
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
      key: ValueKey('thumbnail-$tagId'),
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
