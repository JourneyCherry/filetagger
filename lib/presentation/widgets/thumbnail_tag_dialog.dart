import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/tag_value_type.dart';
import '../providers/file_view_provider.dart';
import '../providers/tag_provider.dart';
import 'dialog_utils.dart';
import 'tag_chip.dart';

/// 노드 썸네일의 출처로 쓸 **링크 태그**를 고르는 다이얼로그.
///
/// 링크 유형 사용자 태그만 후보로 낸다(그 태그가 가리키는 대상 이미지를 썸네일로
/// 쓴다). '없음'을 고르면 커스텀 썸네일을 끄고 기본 동작(이미지=자기 자신,
/// 폴더=하위 대표)만 쓴다. 고르는 즉시 보기 설정에 저장된다.
Future<void> showThumbnailTagDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => const _ThumbnailTagDialog(),
);

class _ThumbnailTagDialog extends ConsumerWidget {
  const _ThumbnailTagDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkTags = [
      for (final d in ref.watch(tagDefinitionsProvider).valueOrNull ?? const [])
        if (d.valueType == TagValueType.link && d.id != null) d,
    ];
    final selected = ref.watch(thumbnailTagIdProvider);
    final notifier = ref.read(viewSettingsProvider.notifier);

    return escDismissible(
      context,
      AlertDialog(
        title: const Text('썸네일 태그'),
        content: SizedBox(
          width: 360,
          height: 420,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '링크 유형 태그를 하나 골라 그 대상 이미지를 노드의 썸네일로 씁니다. '
                '태그는 태그 관리에서 만들고, 파일에 부여할 때 대상 이미지를 고릅니다.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              if (linkTags.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      '링크 유형 태그가 없습니다.\n태그 관리에서 값 유형이 “링크”인 태그를 먼저 만들어주세요.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: RadioGroup<int?>(
                    groupValue: selected,
                    onChanged: notifier.updateThumbnailTagId,
                    child: ListView(
                      children: [
                        const RadioListTile<int?>(
                          value: null,
                          title: Text('없음 (기본 썸네일)'),
                        ),
                        for (final d in linkTags)
                          RadioListTile<int?>(
                            value: d.id,
                            title: Align(
                              alignment: Alignment.centerLeft,
                              child: TagChip(definition: d),
                            ),
                          ),
                      ],
                    ),
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
