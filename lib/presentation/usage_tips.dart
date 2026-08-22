/// 앱 활용 팁(사용법 안내)의 단일 출처.
///
/// 태그·필터·그룹을 조합해 쓰는 관용법은 화면만 봐서는 떠올리기 어렵다(예: 목록에서
/// 파일을 감추는 전용 기능이 없고, 사용자가 만든 태그를 필터에서 제외하는 방식으로
/// 해결한다). 그런 "기능이 아니라 쓰는 법"을 여기 모아 도움말의 "사용 팁" 탭에서
/// 보인다. 기능·개념 자체의 설명은 같은 도움말의 "사용법" 탭이 맡는다
/// (`help_topics.dart`).
///
/// 팁이 안내하는 조작에 대응하는 명령이 있으면 [UsageTip.command]로 가리킨다 —
/// 라벨·단축키는 명령 카탈로그가 단일 출처이므로 팁 본문에 옮겨 적지 않는다.
///
/// 글월은 ARB에 있고 여기서는 차례·아이콘·가리키는 명령만 정한다.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'commands/app_commands.dart';

/// 활용 팁 하나.
class UsageTip {
  const UsageTip({
    required this.title,
    required this.body,
    required this.icon,
    this.command,
  });

  /// 한 줄 제목(무엇을 할 수 있는지).
  final String title;

  /// 방법 설명. 여러 문장이 될 수 있다.
  final String body;

  final IconData icon;

  /// 이 팁이 안내하는 조작을 부르는 명령. 있으면 라벨·단축키를 함께 보인다.
  final AppCommandId? command;
}

/// 표시 순서대로의 전체 팁 목록.
List<UsageTip> usageTipsOf(AppLocalizations l10n) => [
  UsageTip(
    title: l10n.tipHideFilesTitle,
    body: l10n.tipHideFilesBody,
    icon: Icons.visibility_off_outlined,
    command: AppCommandId.toggleFilterBar,
  ),
  UsageTip(
    title: l10n.tipHideFolderTitle,
    body: l10n.tipHideFolderBody,
    icon: Icons.folder_off_outlined,
    command: AppCommandId.toggleFilterBar,
  ),
  UsageTip(
    title: l10n.tipFolderGroupTitle,
    body: l10n.tipFolderGroupBody,
    icon: Icons.account_tree_outlined,
    command: AppCommandId.toggleGrouping,
  ),
  UsageTip(
    title: l10n.tipGroupByValueTitle,
    body: l10n.tipGroupByValueBody,
    icon: Icons.workspaces_outlined,
    command: AppCommandId.toggleGrouping,
  ),
  UsageTip(
    title: l10n.tipFilterTextTitle,
    body: l10n.tipFilterTextBody,
    icon: Icons.keyboard_alt_outlined,
    command: AppCommandId.toggleFilterBar,
  ),
  UsageTip(
    title: l10n.tipSortTextTitle,
    body: l10n.tipSortTextBody,
    icon: Icons.swap_horiz,
    command: AppCommandId.toggleSortBar,
  ),
  UsageTip(
    title: l10n.tipPresetSwitchTitle,
    body: l10n.tipPresetSwitchBody,
    icon: Icons.bookmarks_outlined,
    command: AppCommandId.togglePresetBar,
  ),
  UsageTip(
    title: l10n.tipThumbnailSourceTitle,
    body: l10n.tipThumbnailSourceBody,
    icon: Icons.image_outlined,
    command: AppCommandId.manageThumbnailTags,
  ),
  UsageTip(
    title: l10n.tipKeywordEntityTitle,
    body: l10n.tipKeywordEntityBody,
    icon: Icons.sell_outlined,
    command: AppCommandId.createKeyword,
  ),
  UsageTip(
    title: l10n.tipLinkNextTitle,
    body: l10n.tipLinkNextBody,
    icon: Icons.link,
  ),
  UsageTip(
    title: l10n.tipNameTagTitle,
    body: l10n.tipNameTagBody,
    icon: Icons.text_fields,
    command: AppCommandId.manageNameTags,
  ),
  UsageTip(
    title: l10n.tipSubtitleTagTitle,
    body: l10n.tipSubtitleTagBody,
    icon: Icons.short_text,
    command: AppCommandId.manageSubtitleTags,
  ),
  UsageTip(
    title: l10n.tipExportTagsTitle,
    body: l10n.tipExportTagsBody,
    icon: Icons.ios_share,
    command: AppCommandId.exportSelection,
  ),
  UsageTip(
    title: l10n.tipUnresolvedLinksTitle,
    body: l10n.tipUnresolvedLinksBody,
    icon: Icons.link_off,
    command: AppCommandId.toggleFilterBar,
  ),
];
