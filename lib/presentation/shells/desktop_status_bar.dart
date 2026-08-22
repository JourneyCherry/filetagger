import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/platform/link_opener.dart';
import '../../domain/entities/update_check_outcome.dart';
import '../../l10n/app_localizations.dart';
import '../commands/app_commands.dart';
import '../commands/command_scope.dart';
import '../../domain/entities/scan_progress.dart';
import '../common/scan_progress_label.dart';
import '../common/selection_controller.dart';
import '../providers/command_queue_provider.dart';
import '../providers/database_provider.dart';
import '../providers/file_view_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/update_provider.dart';
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
    required this.backgroundScanning,
    required this.scanProgress,
    required this.previewVisible,
  });

  final CommandHandlers handlers;

  /// 전면 스캔(폴더 열기·수동 재스캔)이 진행 중인지.
  final bool scanning;

  /// watcher가 트리거한 조용한 재스캔이 진행 중인지. 본문에는 스피너가 뜨지 않으므로
  /// 목록이 저절로 바뀌는 이유를 여기서 알려야 한다.
  final bool backgroundScanning;

  /// 진행 중인 스캔이 마지막으로 알려 온 진행 상태. 없으면 수치 없이 알린다.
  final ScanProgress? scanProgress;

  final bool previewVisible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final root = ref.watch(workspaceRootProvider);
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

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
                // 폴더를 열지 않았어도 설정 저장 실패는 알려야 한다(테마 변경이
                // 그 상태에서도 저장된다).
                ? [
                    Text(l10n.statusNoFolder),
                    const Spacer(),
                    ..._settingsSaveStatus(l10n, ref, scheme),
                    // 오른쪽 끝이라 뒤에 올 것이 없다(구분자를 달지 않는다).
                    ..._updateStatus(
                      l10n,
                      ref,
                      scheme,
                      trailingSeparator: false,
                    ),
                  ]
                : _workspaceStatus(context, ref, scheme, l10n),
          ),
        ),
      ),
    );
  }

  List<Widget> _workspaceStatus(
    BuildContext context,
    WidgetRef ref,
    ColorScheme scheme,
    AppLocalizations l10n,
  ) {
    final database = ref.watch(databaseProvider);
    final selection = ref.watch(selectionControllerProvider);
    final visibleCount = ref.watch(visibleNodeCountProvider);
    final filter = ref.watch(fileFilterProvider);
    final sort = ref.watch(fileSortProvider);

    return [
      if (scanning || backgroundScanning) ...[
        const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 8),
        Text(scanProgressLabel(l10n, scanProgress)),
        const _Separator(),
      ],
      Text(
        visibleCount == null
            ? l10n.statusLoading
            : l10n.statusItemCount(visibleCount),
      ),
      if (selection.isNotEmpty) ...[
        const _Separator(),
        Text(l10n.statusSelectedCount(selection.length)),
        const SizedBox(width: 4),
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: handlers.clearSelection,
          child: Text(l10n.statusClearSelection),
        ),
      ],
      const Spacer(),
      ..._updateStatus(l10n, ref, scheme),
      ..._settingsSaveStatus(l10n, ref, scheme),
      ..._externalCommandStatus(l10n, ref, scheme),
      if (!filter.isEmpty) ...[
        Text(l10n.statusFilterCount(filter.conditions.length)),
        const _Separator(),
      ],
      if (!sort.isEmpty) ...[
        Text(l10n.statusSortCount(sort.keys.length)),
        const _Separator(),
      ],
      Icon(
        database != null ? Icons.storage : Icons.storage_outlined,
        size: 14,
        color: database != null ? scheme.primary : scheme.error,
      ),
      const SizedBox(width: 4),
      Text(
        database != null ? l10n.statusDbConnected : l10n.statusDbDisconnected,
      ),
      const SizedBox(width: 4),
      IconButton(
        iconSize: 16,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        visualDensity: VisualDensity.compact,
        tooltip: previewVisible
            ? l10n.statusHidePreview
            : l10n.statusShowPreview,
        onPressed: handlers.handlerOf(AppCommandId.togglePreview),
        icon: Icon(
          previewVisible ? Icons.view_sidebar : Icons.view_sidebar_outlined,
        ),
      ),
    ];
  }
}

/// 배포처에 새 버전이 올라와 있음을 알리는 한 줄.
///
/// 앱을 켤 때 도는 **자동 확인의 유일한 표시 경로**다. 다이얼로그로 가로막지 않고
/// 상태표시줄에만 얹어, 눈에 띄되 하던 일이 끊기지 않게 한다(사용자가 직접 누른
/// 확인은 반대로 다이얼로그로 답한다). 새 버전이 없거나 확인하지 못했으면 자리를
/// 차지하지 않는다.
List<Widget> _updateStatus(
  AppLocalizations l10n,
  WidgetRef ref,
  ColorScheme scheme, {
  bool trailingSeparator = true,
}) {
  final outcome = ref.watch(updateCheckProvider).valueOrNull;
  if (outcome is! UpdateAvailable) return const [];
  return [
    Tooltip(
      message: l10n.statusUpdateHint,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.normal),
        ),
        onPressed: () => const LinkOpener().open(outcome.release.pageUrl),
        icon: const Icon(Icons.system_update_alt, size: 14),
        label: Text(l10n.statusNewVersion(outcome.release.version)),
      ),
    ),
    if (trailingSeparator) const _Separator(),
  ];
}

/// 전역 설정(테마·최근 폴더)이 디스크에 남지 않는 중임을 알린다.
///
/// 읽기 전용 매체에서 포터블판을 돌리거나 설정 폴더에 쓸 권한이 없는 경우다. 조용히
/// 삼키면 최근 폴더가 안 남는 이유를 사용자가 알 수 없다. 정상일 때는 자리를
/// 차지하지 않는다.
List<Widget> _settingsSaveStatus(
  AppLocalizations l10n,
  WidgetRef ref,
  ColorScheme scheme,
) {
  if (!ref.watch(settingsSaveFailedProvider)) return const [];
  return [
    Tooltip(
      message: l10n.statusSettingsUnsavedHint,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sync_problem, size: 14, color: scheme.error),
          const SizedBox(width: 4),
          Text(
            l10n.statusSettingsUnsaved,
            style: TextStyle(color: scheme.error),
          ),
        ],
      ),
    ),
    const _Separator(),
  ];
}

/// 외부 앱 연동(드롭인 큐)이 마지막으로 바꾼 건수. 성공을 다이얼로그로 알리지
/// 않는 대칭을 지키되, **사용자가 하지 않은 태그 변경**과 **조용한 실패**는 보이게
/// 하는 최소한이다. 아무 일도 없었으면 자리를 차지하지 않는다.
List<Widget> _externalCommandStatus(
  AppLocalizations l10n,
  WidgetRef ref,
  ColorScheme scheme,
) {
  final outcome = ref.watch(lastCommandOutcomeProvider);
  if (outcome == null) return const [];
  return [
    Tooltip(
      message: outcome.failed > 0
          ? l10n.statusExternalHintWithFailures
          : l10n.statusExternalHint,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (outcome.applied > 0)
            Text(l10n.statusExternalApplied(outcome.applied)),
          if (outcome.applied > 0 && outcome.failed > 0)
            const SizedBox(width: 6),
          if (outcome.failed > 0)
            Text(
              l10n.statusExternalFailed(outcome.failed),
              style: TextStyle(color: scheme.error),
            ),
        ],
      ),
    ),
    const _Separator(),
  ];
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
