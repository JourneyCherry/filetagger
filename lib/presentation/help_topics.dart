/// 도움말의 "사용법" 탭이 쓰는 내용.
///
/// 두 층으로 나눈다. **개념 설명**([helpTopicsOf])은 부르는 명령이 따로 없는 주제
/// (값 유형·폴더 관리 방식 등)라 손으로 적고, **기능·단축키 표**는 명령 카탈로그에서
/// 생성한다([helpCommandGroupsOf]는 어느 묶음에 넣을지만 정한다) — 라벨·단축키를 여기
/// 옮겨 적으면 카탈로그를 고칠 때 안내가 조용히 어긋나기 때문이다.
///
/// 시스템 태그 설명도 같은 원칙이다: 목록·이름·값 유형은 [SystemTag]에서 읽고
/// 설명만 [systemTagDescription]이 붙인다. 시스템 태그를 추가하면 그 switch가
/// 컴파일되지 않아 설명 누락이 곧바로 드러난다.
///
/// 글월 자체는 ARB에 있고 여기서는 **어느 문장을 어떤 차례로, 어떤 아이콘과 함께
/// 놓을지**만 정한다. 그래서 목록이 상수가 아니라 번역본을 받는 함수다.
library;

import 'package:flutter/material.dart';

import '../domain/entities/system_tag.dart';
import '../l10n/app_localizations.dart';
import 'commands/app_commands.dart';

/// 도움말의 탭. 메뉴가 특정 탭으로 바로 열 수 있도록 순서를 여기서 정한다
/// (열거 순서가 곧 탭 순서다).
enum HelpTab {
  /// 명령이 없는 개념 설명.
  howTo,

  /// 여러 기능을 엮어 쓰는 관용법.
  tips,

  /// 명령 카탈로그에서 만든 기능·단축키 표.
  shortcuts,

  /// 앱이 자동으로 붙이는 태그들의 뜻.
  systemTags;

  /// 탭 막대와 메뉴 항목에 함께 쓰는 이름.
  String label(AppLocalizations l10n) => switch (this) {
    HelpTab.howTo => l10n.helpTabHowTo,
    HelpTab.tips => l10n.helpTabTips,
    HelpTab.shortcuts => l10n.helpTabShortcuts,
    HelpTab.systemTags => l10n.helpTabSystemTags,
  };
}

/// 명령 없이 개념만 설명하는 항목.
class HelpTopic {
  const HelpTopic({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;
}

/// 개념 설명(표시 순서대로).
List<HelpTopic> helpTopicsOf(AppLocalizations l10n) => [
  HelpTopic(
    title: l10n.helpTopicTagsTitle,
    body: l10n.helpTopicTagsBody,
    icon: Icons.sell_outlined,
  ),
  HelpTopic(
    title: l10n.helpTopicStorageTitle,
    body: l10n.helpTopicStorageBody,
    icon: Icons.save_outlined,
  ),
  HelpTopic(
    title: l10n.helpTopicManageModeTitle,
    body: l10n.helpTopicManageModeBody,
    icon: Icons.folder_special_outlined,
  ),
  HelpTopic(
    title: l10n.helpTopicQueryRowsTitle,
    body: l10n.helpTopicQueryRowsBody,
    icon: Icons.filter_alt_outlined,
  ),
  HelpTopic(
    title: l10n.helpTopicPresetsTitle,
    body: l10n.helpTopicPresetsBody,
    icon: Icons.bookmarks_outlined,
  ),
  HelpTopic(
    title: l10n.helpTopicPresetSourcesTitle,
    body: l10n.helpTopicPresetSourcesBody,
    icon: Icons.text_fields,
  ),
  HelpTopic(
    title: l10n.helpTopicNestedTitle,
    body: l10n.helpTopicNestedBody,
    icon: Icons.merge_outlined,
  ),
  HelpTopic(
    title: l10n.helpTopicKeywordTitle,
    body: l10n.helpTopicKeywordBody,
    icon: Icons.sell_outlined,
  ),
  HelpTopic(
    title: l10n.helpTopicTypeAheadTitle,
    body: l10n.helpTopicTypeAheadBody,
    icon: Icons.keyboard_alt_outlined,
  ),
  HelpTopic(
    title: l10n.helpTopicDisconnectedTitle,
    body: l10n.helpTopicDisconnectedBody,
    icon: Icons.link_off,
  ),
];

/// 기능·단축키 표의 한 묶음. 명령을 어느 묶음에 넣을지만 정하고, 라벨·단축키는
/// 명령 카탈로그에서 읽는다.
class HelpCommandGroup {
  const HelpCommandGroup(this.title, this.commands, {this.note});

  final String title;
  final List<AppCommandId> commands;

  /// 그 묶음 전체에 붙는 한 줄 단서(조건이 있는 명령들의 전제 등).
  final String? note;
}

/// 기능·단축키 표(표시 순서대로). 모든 명령이 정확히 한 번씩 실려야 한다 —
/// 대응 테스트가 누락·중복을 잡는다.
List<HelpCommandGroup> helpCommandGroupsOf(AppLocalizations l10n) => [
  HelpCommandGroup(l10n.helpGroupFolder, const [
    AppCommandId.openFolder,
    AppCommandId.closeFolder,
    AppCommandId.rescan,
    AppCommandId.revealInFileManager,
    AppCommandId.exportSelection,
    AppCommandId.exitApp,
  ]),
  HelpCommandGroup(l10n.helpGroupSelectionTags, const [
    AppCommandId.selectAll,
    AppCommandId.clearSelection,
    AppCommandId.openNode,
    AppCommandId.toggleExpand,
    AppCommandId.assignTags,
    AppCommandId.reconnect,
    AppCommandId.manageTags,
    AppCommandId.manageNameTags,
    AppCommandId.manageSubtitleTags,
    AppCommandId.manageThumbnailTags,
    AppCommandId.tagDisplayOrder,
  ]),
  HelpCommandGroup(l10n.helpGroupKeyword, const [
    AppCommandId.createKeyword,
    AppCommandId.editKeyword,
    AppCommandId.deleteKeyword,
  ], note: l10n.helpGroupKeywordNote),
  HelpCommandGroup(l10n.helpGroupView, const [
    AppCommandId.viewModeList,
    AppCommandId.viewModeIcon,
    AppCommandId.viewModeDetail,
    AppCommandId.togglePreview,
    AppCommandId.togglePresetBar,
    AppCommandId.toggleFilterBar,
    AppCommandId.toggleSortBar,
    AppCommandId.toggleGrouping,
    AppCommandId.toggleListEdit,
  ]),
  HelpCommandGroup(l10n.helpGroupKeyboardNav, const [
    AppCommandId.moveCursorUp,
    AppCommandId.moveCursorDown,
    AppCommandId.extendSelectionUp,
    AppCommandId.extendSelectionDown,
    AppCommandId.moveCursorUpNoSelect,
    AppCommandId.moveCursorDownNoSelect,
    AppCommandId.cursorLeft,
    AppCommandId.cursorRight,
    AppCommandId.toggleTagFocus,
    AppCommandId.confirmCursor,
    AppCommandId.toggleCursorSelection,
    AppCommandId.editFocusedTag,
    AppCommandId.deleteFocusedTag,
  ], note: l10n.helpGroupKeyboardNavNote),
  HelpCommandGroup(l10n.helpGroupHelp, const [
    AppCommandId.help,
    AppCommandId.checkForUpdates,
    AppCommandId.about,
  ]),
];

/// 시스템 태그 하나의 설명. 값이 없을 수 있는 조건이나 값을 고쳤을 때 무슨 일이
/// 벌어지는지처럼, 태그 이름만 봐서는 알 수 없는 것을 적는다.
String systemTagDescription(AppLocalizations l10n, SystemTag tag) =>
    switch (tag) {
      SystemTag.fileSize => l10n.helpSystemTagFileSize,
      SystemTag.modifiedTime => l10n.helpSystemTagModifiedTime,
      SystemTag.extension => l10n.helpSystemTagExtension,
      SystemTag.imageWidth => l10n.helpSystemTagImageWidth,
      SystemTag.imageHeight => l10n.helpSystemTagImageHeight,
      SystemTag.fileName => l10n.helpSystemTagFileName,
      SystemTag.childFileCount => l10n.helpSystemTagChildFileCount,
      SystemTag.keyword => l10n.helpSystemTagKeyword,
      SystemTag.unresolvedLink => l10n.helpSystemTagUnresolvedLink,
    };
