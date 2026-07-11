import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/system_tag.dart';
import '../../domain/entities/tag_definition.dart';
import '../../domain/usecases/tag_display_order.dart';
import '../providers/file_view_provider.dart';
import '../providers/system_tag_provider.dart';
import '../tag_visuals.dart';
import 'dialog_utils.dart';
import 'tag_chip.dart';
import 'tag_editors.dart';

/// 태그의 생성·편집·삭제·합치기·표시 순서를 한 다이얼로그에서 처리한다.
///
/// 데스크톱에서 '태그 관리'가 여는 창이다(화면 전환 없이 제자리에서). 사용자 태그와
/// 시스템 태그를 표시 순서 그대로 한 목록에 놓아, 순서와 편집을 같은 자리에서 다룬다.
Future<void> showTagManageDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => const _TagManageDialog(),
);

class _TagManageDialog extends ConsumerWidget {
  const _TagManageDialog();

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
        title: const Text('태그 관리'),
        content: SizedBox(
          width: 520,
          height: 460,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '위에 있는 태그일수록 목록 행의 앞에 표시됩니다. 시스템 태그는 파일에서 자동으로 '
                '파생되어 표시 여부만 켜고 끌 수 있고, 기본적으로 사용자 태그 뒤에 놓이지만 '
                '원하는 자리로 끌어 옮길 수 있습니다.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ReorderableListView.builder(
                  // 행 끝이 편집 버튼·스위치라 기본 손잡이 대신 왼쪽 손잡이를 쓴다.
                  buildDefaultDragHandles: false,
                  itemCount: definitions.length,
                  onReorderItem: (oldIndex, newIndex) {
                    final ids = [for (final d in definitions) d.id!];
                    ids.insert(newIndex, ids.removeAt(oldIndex));
                    ref
                        .read(viewSettingsProvider.notifier)
                        .updateTagDisplayOrder(ids);
                  },
                  itemBuilder: (context, index) => _TagRow(
                    key: ValueKey(definitions[index].id),
                    index: index,
                    definition: definitions[index],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => openTagEditor(context),
            icon: const Icon(Icons.add),
            label: const Text('새 태그'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}

/// 태그 한 종류의 행: 칩 · 값 유형, 그리고 사용자 태그면 편집 버튼, 시스템 태그면
/// 표시 여부 스위치. 순서 변경 손잡이와 삭제 버튼은 캡슐 안에 담아(필터·정렬 칩과
/// 같은 모양) 행 끝의 별도 버튼을 없앴다.
class _TagRow extends ConsumerWidget {
  const _TagRow({super.key, required this.index, required this.definition});

  final int index;
  final TagDefinition definition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = definition.id!;
    final systemTag = definition.isSystem ? systemTagById(id) : null;
    final subtitle = [
      tagValueTypeLabel(definition.valueType),
      if (definition.allowMultiple) '다중 부여',
      if (systemTag?.editable ?? false) '수정 가능',
    ].join(' · ');

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 8, right: 4),
      title: Align(
        alignment: Alignment.centerLeft,
        child: TagChip(
          definition: definition,
          dragIndex: index,
          // 시스템 태그는 삭제할 수 없어 x 아이콘을 감춘다(자리는 그대로).
          onDeleted: definition.isSystem
              ? null
              : () => confirmTagDelete(context, ref, definition),
        ),
      ),
      subtitle: Text(subtitle),
      trailing: definition.isSystem
          ? Switch(
              value: ref.watch(visibleSystemTagIdsProvider).contains(id),
              onChanged: (on) => ref
                  .read(viewSettingsProvider.notifier)
                  .updateSystemTagVisibility(id, on),
            )
          : TagDefinitionActions(definition: definition, showDelete: false),
    );
  }
}
