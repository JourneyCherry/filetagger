import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/assigned_tag.dart';
import '../../domain/entities/file_node.dart';
import '../../domain/entities/system_tag.dart';
import '../../domain/usecases/tag_display_order.dart';
import '../providers/system_tag_provider.dart';
import 'file_thumbnail.dart';
import 'tag_capsule.dart';
import 'tag_chip.dart';

/// 선택 대상의 미리보기 이미지와 부여된 모든 태그를 보여주는 프리뷰 창.
///
/// 단일 선택이면 그 노드를 미리보고, 선택이 없거나 여럿이면 안내만 표시한다.
/// 값 태그 칩은 눌러 바로 값을 수정할 수 있다(목록과 동일).
class PreviewPane extends ConsumerWidget {
  const PreviewPane({
    super.key,
    required this.node,
    required this.selectedCount,
    required this.onEditAssignment,
    required this.onRemoveAssignment,
    required this.onAddTag,
  });

  /// 미리볼 단일 노드. 선택이 없거나 둘 이상이면 null.
  final FileNode? node;

  /// 현재 선택된 노드 수. 여럿일 때 안내 문구에 쓴다.
  final int selectedCount;

  /// 값 태그 칩을 눌렀을 때 그 부여 기록의 값을 바로 수정하는 콜백.
  final ValueChanged<AssignedTag> onEditAssignment;

  /// 태그 칩의 x 버튼으로 그 부여 기록을 해제하는 콜백.
  final ValueChanged<AssignedTag> onRemoveAssignment;

  /// '+' 버튼으로 이 노드에 태그를 새로 부여하는 콜백.
  final VoidCallback onAddTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final target = node;
    return Container(
      color: scheme.surface,
      padding: const EdgeInsets.all(16),
      child: target == null
          ? _placeholder(context)
          : _preview(context, ref, target),
    );
  }

  Widget _placeholder(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = selectedCount > 1
        ? '$selectedCount개 선택됨'
        : '항목을 선택하면 미리보기가 표시됩니다';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined, size: 48, color: scheme.outline),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _preview(BuildContext context, WidgetRef ref, FileNode target) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final assignmentsByFile = ref.watch(effectiveAssignmentsByFileProvider);
    final isTagVisible = ref.watch(tagChipVisibleProvider);
    final all = target.id == null
        ? const <AssignedTag>[]
        : (assignmentsByFile[target.id] ?? const <AssignedTag>[]);
    // 표시 술어를 통과한 태그만 보인다(사용자 태그는 감추지 않은 것, 시스템 태그는
    // 표시로 켠 것). 목록 행과 같은 표시 순서를 쓴다.
    final tags = orderAssignedTags([
      for (final a in all)
        if (isTagVisible(a.tagDefinitionId)) a,
    ], ref.watch(effectiveTagDisplayOrderProvider));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: FileThumbnail(
              node: target,
              expand: true,
              fit: BoxFit.contain,
              // 프리뷰는 그 노드 자체를 보는 자리 — 이미지 파일 등 자기 이미지가 있는
              // 노드는 커스텀 썸네일 대신 자기 자신을 띄운다.
              preferSelfImage: true,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          target.name,
          style: theme.textTheme.titleMedium?.copyWith(
            color: target.isMissing ? scheme.error : null,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          target.path,
          style: theme.textTheme.bodySmall?.copyWith(color: scheme.outline),
        ),
        const SizedBox(height: 4),
        _meta(context, target),
        if (target.isMissing) ...[
          const SizedBox(height: 6),
          Text(
            '연결 끊김 — 원본 파일을 찾아 태그를 재연결하세요',
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
        const Divider(height: 24),
        Text('태그', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final a in tags)
                  AssignedTagChip(
                    tag: a,
                    onPressed: isEditableAssignment(a)
                        ? () => onEditAssignment(a)
                        : null,
                    // 시스템 태그는 제거할 수 없어 x 버튼을 달지 않는다.
                    onDeleted: isSystemTagId(a.tagDefinitionId)
                        ? null
                        : () => onRemoveAssignment(a),
                  ),
                CapsuleAddButton(tooltip: '태그 추가', onPressed: onAddTag),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _meta(BuildContext context, FileNode target) {
    final style = Theme.of(context).textTheme.bodySmall;
    final parts = <String>[
      if (!target.isDirectory && target.size != null) _formatSize(target.size!),
      if (target.modifiedAt != null) _formatDate(target.modifiedAt!),
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(parts.join('  ·  '), style: style);
  }
}

/// 바이트 크기를 사람이 읽기 좋은 단위로 표기한다.
String _formatSize(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final text = unit == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  return '$text ${units[unit]}';
}

/// 수정시각을 로컬 시각의 'yyyy-MM-dd HH:mm'으로 표기한다.
String _formatDate(DateTime dt) {
  final d = dt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
}
