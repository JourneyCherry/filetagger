import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/build_info.dart';
import '../../core/store_page.dart';
import '../../data/platform/link_opener.dart';
import '../../domain/entities/update_check_outcome.dart';
import '../commands/app_commands.dart';
import '../providers/update_provider.dart';
import 'dialog_utils.dart';

/// 사용자가 직접 실행한 업데이트 확인의 결과 다이얼로그.
///
/// **자동 확인과 대칭을 이룬다** — 앱을 켤 때 도는 확인은 상태표시줄에만 조용히
/// 남기지만, 사용자가 누른 확인은 결과가 무엇이든(최신이어도) 답을 준다. 물어봤는데
/// 아무 반응이 없으면 확인이 된 것인지 알 수 없기 때문이다.
///
/// 여는 즉시 새로 확인을 걸고, 조회가 끝나기 전까지는 확인 중임을 보인다.
Future<void> showUpdateCheckDialog(BuildContext context, WidgetRef ref) {
  final checking = ref.read(updateCheckProvider.notifier).recheck();
  return showDialog<void>(
    context: context,
    builder: (_) => _UpdateCheckDialog(checking: checking),
  );
}

class _UpdateCheckDialog extends StatelessWidget {
  const _UpdateCheckDialog({required this.checking});

  /// 이 다이얼로그가 걸어 둔 확인. provider 상태가 아니라 이 Future를 보는 것은,
  /// **이번에 누른 확인의 결과**를 보이기 위함이다.
  final Future<UpdateCheckOutcome> checking;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UpdateCheckOutcome>(
      future: checking,
      builder: (context, snapshot) {
        // 판정 유즈케이스가 실패를 결과로 눕히므로 예외는 거의 오지 않지만,
        // 온다면 사용자에게는 확인 실패와 같은 일이다.
        final outcome = snapshot.hasError
            ? const UpdateCheckFailed()
            : snapshot.data;
        return AlertDialog(
          title: Text(commandOf(AppCommandId.checkForUpdates).label),
          content: dialogContentBox(
            context,
            width: 360,
            child: outcome == null
                ? const _Checking()
                : _Result(outcome: outcome),
          ),
          actions: [
            if (outcome != null) ..._actions(context, outcome),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  /// 결과별로 사용자를 보낼 곳. 보낼 곳이 없으면 닫기만 남는다.
  ///
  /// 넘기지 못했을 때 할 말도 함께 고른다 — 릴리즈 페이지는 브라우저가, 스토어 스킴은
  /// 스토어 앱이 받으므로 못 열린 것이 서로 다르다.
  List<Widget> _actions(BuildContext context, UpdateCheckOutcome outcome) {
    final destination = switch (outcome) {
      UpdateAvailable(:final release) => (
        label: '릴리즈 페이지 열기',
        url: release.pageUrl,
        failure: '웹 브라우저를 열지 못했습니다.',
      ),
      UpdateCheckSkipped(reason: UpdateCheckSkipReason.managedByStore) =>
        switch (storePageUrl()) {
          final Uri url => (
            label: '스토어에서 열기',
            url: url,
            failure: '스토어 앱을 열지 못했습니다.',
          ),
          null => null,
        },
      _ => null,
    };
    if (destination == null) return const [];
    return [
      FilledButton(
        onPressed: () =>
            _openDestination(context, destination.url, destination.failure),
        child: Text(destination.label),
      ),
    ];
  }
}

/// 목적지를 앱 밖으로 넘기고 이 다이얼로그를 닫는다.
///
/// **알 수 있는 실패는 넘기는 데까지**다 — OS가 그 주소를 받아 줄 프로그램을 띄우지
/// 못한 것만 돌아오고, 넘긴 뒤의 일(페이지가 뜨는지)은 알 방법이 없어 알림도 거기까지만
/// 말한다. 그래도 알리는 것은, 눌러도 아무 일이 없으면 버튼이 죽은 것인지 알 수 없어서다.
///
/// 닫기를 기다리지 않고 먼저 하는 것은 종전 그대로다(누른 순간 닫힌다). 그래서 메신저를
/// 미리 잡아 둔다 — 알릴 때쯤이면 이 다이얼로그는 이미 없다.
Future<void> _openDestination(
  BuildContext context,
  Uri url,
  String failure,
) async {
  final messenger = ScaffoldMessenger.of(context);
  Navigator.of(context).pop();
  if (await const LinkOpener().open(url)) return;
  messenger.showSnackBar(SnackBar(content: Text(failure)));
}

class _Checking extends StatelessWidget {
  const _Checking();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      SizedBox(width: 12),
      Text('확인하는 중…'),
    ],
  );
}

class _Result extends StatelessWidget {
  const _Result({required this.outcome});

  final UpdateCheckOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, headline, detail) = _content;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(headline, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                detail,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  (IconData, String, String) get _content => switch (outcome) {
    UpdateAvailable(:final release) => (
      Icons.system_update_alt,
      '새 업데이트가 있습니다.',
      '현재 $appVersion · 최신 ${release.version}',
    ),
    UpToDate() => (Icons.check_circle_outline, '최신 버전입니다.', '현재 $appVersion'),
    UpdateCheckSkipped(reason: UpdateCheckSkipReason.unknownVersion) => (
      Icons.help_outline,
      '버전을 알 수 없습니다.',
      '이 실행의 버전을 확인할 수 없어 배포본과 견줄 수 없습니다.',
    ),
    UpdateCheckSkipped(reason: UpdateCheckSkipReason.managedByStore) => (
      Icons.storefront_outlined,
      '스토어가 업데이트를 관리합니다.',
      '이 배포본은 스토어를 통해 갱신되므로 앱이 직접 받아 설치하지 않습니다.',
    ),
    UpdateCheckFailed() => (
      Icons.cloud_off_outlined,
      '업데이트를 확인하지 못했습니다.',
      '네트워크 연결을 확인한 뒤 다시 시도해 주세요.',
    ),
  };
}
