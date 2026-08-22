import 'package:flutter/material.dart';

import '../../core/build_info.dart';
import '../../core/constants.dart';
import '../../core/repository_page.dart';
import '../../data/platform/link_opener.dart';
import '../../l10n/app_localizations.dart';
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

/// 정보 다이얼로그·라이선스 화면에 함께 쓰는 버전 한 줄.
///
/// **직접 빌드한 실행도 버전과 배포 형태를 함께 보인다.** 버전은 pubspec에서 읽어
/// 채우고, 배포 형태는 **채널을 그대로 적어도 사실과 어긋나지 않는다** — 주입이 없는
/// 빌드는 정말로 설정을 실행 파일 옆에 두는 포터블이고, 설치판은 패키징이 채널을
/// 명시했을 때만 나온다. 그래서 이 줄은 릴리즈 산출물인지를 묻지 않는다.
///
/// 그 자리에 빌드 종류를 적지도 않는다 — 사용자가 이 줄에서 알아야 하는 것은 자기가
/// 쓰는 버전과 그것이 어떤 형태인지이지, 어떻게 컴파일되었는지가 아니다. 버전을 끝내
/// 읽지 못했을 때만 그 사실을 밝히고, 배포 형태는 그때도 그대로 붙인다(둘은 서로
/// 모르는 값이라, 하나를 몰랐다고 아는 쪽까지 감출 이유가 없다).
String _versionLine(AppLocalizations l10n) {
  final kind = switch (distributionChannel) {
    DistributionChannel.portable => l10n.aboutChannelPortable,
    DistributionChannel.package => l10n.aboutChannelPackage,
  };
  final version = appVersion.isEmpty
      ? l10n.aboutVersionUnknown
      : l10n.aboutVersion(appVersion);
  return l10n.aboutVersionLine(version, kind);
}

/// 소스 코드 저장소를 브라우저로 넘긴다.
///
/// **알 수 있는 실패는 넘기는 데까지**다 — OS가 이 주소를 받아 줄 프로그램을 띄우지
/// 못한 것(기본 브라우저 미등록 등)만 돌아온다. 넘긴 뒤의 일(페이지가 뜨는지, 주소가
/// 살아 있는지)은 브라우저의 몫이라 알 방법이 없으므로, 알림도 거기까지만 말한다.
/// 그래도 알리는 것은, 눌러도 아무 일이 없으면 버튼이 죽은 것인지 알 수 없어서다.
///
/// 메신저를 미리 잡아 두는 것은 기다린 뒤에는 이 다이얼로그가 이미 닫혔을 수 있기
/// 때문이다.
Future<void> _openRepository(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final failed = AppLocalizations.of(context).aboutOpenBrowserFailed;
  if (await const LinkOpener().open(sourceRepositoryUrl())) return;
  messenger.showSnackBar(SnackBar(content: Text(failed)));
}

/// 라이선스 화면을 연다.
///
/// 화면 자체는 프레임워크 것([LicensePage])을 그대로 쓰되, 라우트는 [showLicensePage]
/// 대신 직접 밀어 넣는다 — 그 헬퍼는 라우트를 감쌀 틈을 주지 않아 ESC로 닫는 길
/// ([escDismissiblePage])을 붙일 수 없다. 헬퍼가 하던 테마 넘기기는 함께 옮긴다
/// (다이얼로그가 얹은 테마가 새 라우트까지 따라가야 색이 어긋나지 않는다).
void _openLicensePage(
  BuildContext context,
  ThemeData theme,
  AppLocalizations l10n,
) {
  final themes = InheritedTheme.capture(
    from: context,
    to: Navigator.of(context).context,
  );
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => themes.wrap(
        escDismissiblePage(
          LicensePage(
            applicationName: appDisplayName,
            applicationVersion: _versionLine(l10n),
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
    ),
  );
}

class _AboutDialog extends StatelessWidget {
  const _AboutDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(commandOf(AppCommandId.about).label(l10n)),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appDisplayName, style: theme.textTheme.titleMedium),
                    Text(
                      _versionLine(l10n),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.aboutSummary,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            // 소스 코드로 가는 유일한 입구. 앱 자체를 밝히는 이 자리가 "이건 누가
            // 어떻게 만든 것인가"를 찾는 사람이 여는 곳이라, 라이선스와 나란히 둔다.
            // 메뉴에는 두지 않는다 — 앱 밖으로 한 번 나가고 마는 자리라 조작 경로를
            // 둘로 벌릴 만큼 자주 쓰이지 않는다.
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.code),
                label: Text(l10n.aboutSourceRepository),
                onPressed: () => _openRepository(context),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.description_outlined),
                label: Text(l10n.aboutOpenSourceLicenses),
                // 라이선스 화면은 다이얼로그가 아니라 전체 화면 라우트로 열린다.
                // 목록을 훑는 자리라 좁은 다이얼로그에 가두지 않는 편이 낫고,
                // 이 다이얼로그는 뒤에 남아 돌아오면 그대로 보인다.
                onPressed: () => _openLicensePage(context, theme, l10n),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonClose),
        ),
      ],
    );
  }
}
