import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../commands/app_commands.dart';
import 'dialog_utils.dart';

/// 앱 정보 다이얼로그(도움말 메뉴 첫 층).
///
/// 도움말 다이얼로그와 성격이 다르다 — 조작을 안내하는 자리가 아니라 앱 자체를 밝히는
/// 자리라, 탭으로 합치지 않고 따로 연다. 라이선스 원문은 프레임워크 내장 화면
/// ([showLicensePage])을 그대로 쓰고, 이 다이얼로그는 그리로 가는 입구만 둔다 —
/// 앱과 의존 패키지의 라이선스를 목록으로 모아 주는 일을 다시 만들 이유가 없다.
///
/// 워크스페이스 상태를 읽지 않는다(폴더를 열기 전에도 볼 수 있어야 한다).
Future<void> showAppAboutDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _AboutDialog());

class _AboutDialog extends StatelessWidget {
  const _AboutDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return escDismissible(
      context,
      AlertDialog(
        title: Text(commandOf(AppCommandId.about).label),
        content: dialogContentBox(
          context,
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    commandOf(AppCommandId.about).icon,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(appDisplayName, style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '태그로 파일을 정리하고 찾는 앱입니다. 태그는 관리 폴더 안에 함께 저장되어 '
                '폴더를 옮기면 따라갑니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('오픈소스 라이선스'),
                  // 라이선스 화면은 다이얼로그가 아니라 전체 화면 라우트로 열린다.
                  // 목록을 훑는 자리라 좁은 다이얼로그에 가두지 않는 편이 낫고,
                  // 이 다이얼로그는 뒤에 남아 돌아오면 그대로 보인다.
                  onPressed: () => showLicensePage(
                    context: context,
                    applicationName: appDisplayName,
                    applicationIcon: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        commandOf(AppCommandId.about).icon,
                        color: theme.colorScheme.primary,
                      ),
                    ),
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
