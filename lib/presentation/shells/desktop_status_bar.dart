import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/file_tree_node.dart';
import '../commands/app_commands.dart';
import '../commands/command_scope.dart';
import '../common/selection_controller.dart';
import '../providers/database_provider.dart';
import '../providers/file_view_provider.dart';
import '../providers/workspace_provider.dart';

/// 데스크톱 셸 하단의 상태표시줄.
///
/// 목록 위에 겹쳐 뜨던 선택 바를 대신한다: 항목 수·선택 수·스캔 진행·필터/정렬
/// 요약·DB 연결 상태를 한 줄에 모으고, 보기 토글(프리뷰)을 오른쪽 끝에 둔다.
class DesktopStatusBar extends ConsumerWidget {
  const DesktopStatusBar({
    super.key,
    required this.handlers,
    required this.scanning,
    required this.previewVisible,
  });

  final CommandHandlers handlers;

  /// 전면 스캔이 진행 중인지(백그라운드 재스캔은 표시하지 않는다).
  final bool scanning;

  final bool previewVisible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final root = ref.watch(workspaceRootProvider);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      color: scheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: SizedBox(
        height: 28,
        child: DefaultTextStyle.merge(
          style: Theme.of(
            context,
          ).textTheme.bodySmall!.copyWith(color: scheme.onSurfaceVariant),
          child: Row(
            children: root == null
                ? const [Text('열린 폴더 없음')]
                : _workspaceStatus(context, ref, scheme),
          ),
        ),
      ),
    );
  }

  List<Widget> _workspaceStatus(
    BuildContext context,
    WidgetRef ref,
    ColorScheme scheme,
  ) {
    final database = ref.watch(databaseProvider);
    final selection = ref.watch(selectionControllerProvider);
    final tree = ref.watch(fileTreeProvider).valueOrNull;
    final filter = ref.watch(fileFilterProvider);
    final sort = ref.watch(fileSortProvider);

    return [
      if (scanning) ...[
        const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 8),
        const Text('스캔 중…'),
        const _Separator(),
      ],
      Text(tree == null ? '목록 불러오는 중…' : '항목 ${countTreeNodes(tree)}개'),
      if (selection.isNotEmpty) ...[
        const _Separator(),
        Text('${selection.length}개 선택'),
        const SizedBox(width: 4),
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: handlers.clearSelection,
          child: const Text('해제'),
        ),
      ],
      const Spacer(),
      if (!filter.isEmpty) ...[
        Text('필터 ${filter.conditions.length}'),
        const _Separator(),
      ],
      if (!sort.isEmpty) ...[
        Text('정렬 ${sort.keys.length}'),
        const _Separator(),
      ],
      Icon(
        database != null ? Icons.storage : Icons.storage_outlined,
        size: 14,
        color: database != null ? scheme.primary : scheme.error,
      ),
      const SizedBox(width: 4),
      Text(database != null ? 'DB 연결됨' : 'DB 미연결'),
      const SizedBox(width: 4),
      IconButton(
        iconSize: 16,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        visualDensity: VisualDensity.compact,
        tooltip: previewVisible ? '프리뷰 숨기기' : '프리뷰 보기',
        onPressed: handlers.handlerOf(AppCommandId.togglePreview),
        icon: Icon(
          previewVisible ? Icons.view_sidebar : Icons.view_sidebar_outlined,
        ),
      ),
    ];
  }
}

/// 상태 항목 사이의 가운뎃점 구분자.
class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 8),
    child: Text('·'),
  );
}
