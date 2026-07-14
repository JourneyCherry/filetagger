import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/system_tag.dart';
import '../../domain/entities/tag_definition.dart';
import '../providers/file_view_provider.dart';
import '../providers/system_tag_provider.dart';
import '../providers/tag_provider.dart';
import '../tag_visuals.dart';
import '../widgets/tag_chip.dart';
import '../widgets/tag_editors.dart';

/// 태그 종류(TagDefinition)를 생성·편집·삭제하는 전용 관리 화면.
///
/// 모바일 셸의 진입점이다. 데스크톱은 화면 전환 없이 관리 다이얼로그를 띄운다
/// (`tag_manage_dialog.dart`).
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
              onPressed: () => openTagEditor(context),
              icon: const Icon(Icons.add),
              label: const Text('새 태그'),
            ),
      body: repo == null
          ? const Center(child: Text('폴더를 먼저 열어주세요.'))
          : definitions.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('태그를 불러오지 못했습니다: $e')),
              data: (items) => ListView(
                children: [
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('아직 만든 태그가 없습니다.')),
                    )
                  else
                    for (final d in items) ...[
                      _DefinitionTile(d),
                      const Divider(height: 1),
                    ],
                  const _SystemTagSection(),
                ],
              ),
            ),
    );
  }
}

class _DefinitionTile extends StatelessWidget {
  const _DefinitionTile(this.definition);

  final TagDefinition definition;

  @override
  Widget build(BuildContext context) {
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
      trailing: TagDefinitionActions(definition: definition),
    );
  }
}

/// OS/파일에서 파생되는 시스템 태그의 표시 여부를 토글하는 섹션. 시스템 태그는
/// 생성·삭제·색 변경을 할 수 없고 표시 여부만 켜고 끌 수 있다(값은 표시와 무관하게
/// 늘 계산되어 필터·정렬에 참여). 표시 설정은 워크스페이스 보기 설정에 저장된다.
class _SystemTagSection extends ConsumerWidget {
  const _SystemTagSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(visibleSystemTagIdsProvider);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
          child: Text('시스템 태그', style: theme.textTheme.titleSmall),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            '파일에서 자동으로 파생되는 태그입니다. 표시 여부만 켜고 끌 수 있습니다.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final tag in SystemTag.values)
          ListTile(
            title: Align(
              alignment: Alignment.centerLeft,
              child: TagChip(definition: tag.definition),
            ),
            subtitle: Text(
              tag.editable
                  ? '수정 가능 · ${tagValueTypeLabel(tag.valueType)}'
                  : tagValueTypeLabel(tag.valueType),
            ),
            trailing: TagVisibilityToggle(
              visible: visible.contains(tag.id),
              onChanged: (on) => ref
                  .read(viewSettingsProvider.notifier)
                  .updateSystemTagVisibility(tag.id, on),
            ),
          ),
      ],
    );
  }
}
