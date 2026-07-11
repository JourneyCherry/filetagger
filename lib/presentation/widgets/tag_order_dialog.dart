import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/tag_display_order.dart';
import '../providers/file_view_provider.dart';
import '../providers/system_tag_provider.dart';
import '../tag_visuals.dart';
import 'dialog_utils.dart';
import 'tag_chip.dart';

/// 목록·프리뷰의 태그 칩을 어떤 순서로 보일지 드래그로 정하는 다이얼로그.
/// 바꾸는 즉시 보기 설정에 저장되어 목록에 반영된다.
Future<void> showTagOrderDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _TagOrderDialog());

class _TagOrderDialog extends ConsumerWidget {
  const _TagOrderDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 시스템 태그도 칩으로 표시될 수 있으므로 순서 편집 대상에 함께 넣는다. 완전한
    // 표시 순서를 써서, 화면에 보이는 자리와 드래그로 저장되는 순서가 어긋나지 않게 한다.
    final definitions = orderTagDefinitions([
      for (final d in ref.watch(pickableTagDefinitionsProvider))
        if (d.id != null) d,
    ], ref.watch(effectiveTagDisplayOrderProvider));

    return escDismissible(
      context,
      AlertDialog(
        title: const Text('태그 표시 순서'),
        content: SizedBox(
          width: 360,
          height: 420,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '위에 있는 태그일수록 목록 행의 앞에 표시됩니다. 시스템 태그는 기본적으로 사용자 태그 '
                '뒤에 놓이지만, 원하는 자리로 끌어 옮길 수 있습니다.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ReorderableListView.builder(
                  itemCount: definitions.length,
                  onReorderItem: (oldIndex, newIndex) {
                    final ids = [for (final d in definitions) d.id!];
                    ids.insert(newIndex, ids.removeAt(oldIndex));
                    ref
                        .read(viewSettingsProvider.notifier)
                        .updateTagDisplayOrder(ids);
                  },
                  itemBuilder: (context, index) {
                    final definition = definitions[index];
                    return ListTile(
                      key: ValueKey(definition.id),
                      dense: true,
                      title: Align(
                        alignment: Alignment.centerLeft,
                        child: TagChip(definition: definition),
                      ),
                      subtitle: Text(tagValueTypeLabel(definition.valueType)),
                    );
                  },
                ),
              ),
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
}
