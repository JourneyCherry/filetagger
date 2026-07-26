/// 도움말의 "사용법" 탭이 쓰는 내용.
///
/// 두 층으로 나눈다. **개념 설명**([helpTopics])은 부르는 명령이 따로 없는 주제
/// (값 유형·폴더 관리 방식 등)라 손으로 적고, **기능·단축키 표**는 명령 카탈로그에서
/// 생성한다([helpCommandGroups]는 어느 묶음에 넣을지만 정한다) — 라벨·단축키를 여기
/// 옮겨 적으면 카탈로그를 고칠 때 안내가 조용히 어긋나기 때문이다.
///
/// 시스템 태그 설명도 같은 원칙이다: 목록·이름·값 유형은 [SystemTag]에서 읽고
/// 설명만 [systemTagDescription]이 붙인다. 시스템 태그를 추가하면 그 switch가
/// 컴파일되지 않아 설명 누락이 곧바로 드러난다.
library;

import 'package:flutter/material.dart';

import '../domain/entities/system_tag.dart';
import 'commands/app_commands.dart';

/// 도움말의 탭. 메뉴가 특정 탭으로 바로 열 수 있도록 순서를 여기서 정한다
/// (열거 순서가 곧 탭 순서다).
enum HelpTab {
  /// 명령이 없는 개념 설명.
  howTo('사용법'),

  /// 여러 기능을 엮어 쓰는 관용법.
  tips('사용 팁'),

  /// 명령 카탈로그에서 만든 기능·단축키 표.
  shortcuts('기능과 단축키'),

  /// 앱이 자동으로 붙이는 태그들의 뜻.
  systemTags('시스템 태그');

  const HelpTab(this.label);

  /// 탭 막대와 메뉴 항목에 함께 쓰는 이름.
  final String label;
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
const List<HelpTopic> helpTopics = [
  HelpTopic(
    title: '태그와 태그값',
    body:
        '태그는 종류를 만들어 두고 파일·폴더에 부여합니다. 값 유형이 "라벨"이면 값 '
        '없이 붙었는지만 따지고, 텍스트·숫자·날짜는 값을 함께 적습니다. "링크"는 '
        '워크스페이스 안의 다른 항목을, "이미지"는 바깥에서 가져온 이미지 파일을 '
        '값으로 갖습니다. 값 유형에 따라 정렬 기준(사전순·숫자순·시간순)이 달라집니다.',
    icon: Icons.sell_outlined,
  ),
  HelpTopic(
    title: '태그가 저장되는 곳',
    body:
        '태그는 관리 폴더 안의 숨김 폴더에 함께 저장됩니다. 폴더를 통째로 옮기거나 '
        '복사하면 태그도 따라갑니다. 앱 전역 설정(최근 연 폴더 등)만 OS의 앱 데이터 '
        '폴더에 남습니다.',
    icon: Icons.save_outlined,
  ),
  HelpTopic(
    title: '폴더마다 정하는 관리 방식',
    body:
        '폴더는 "폴더만 관리"(하나의 항목으로만 다루고 내부를 감춤), "내부 관리"'
        '(직속 내용만), "재귀적으로 관리"(하위까지 이어서) 중 하나로 다룹니다. 따로 '
        '정하지 않은 폴더는 상위의 방식을 물려받습니다. 큰 폴더의 내부를 인덱싱하지 '
        '않으려면 관리 방식을 바꾸세요.',
    icon: Icons.folder_special_outlined,
  ),
  HelpTopic(
    title: '필터 · 정렬 · 그룹 세 줄',
    body:
        '도구모음의 세 줄은 문법이 같고 뜻만 다릅니다. 필터는 조건, 정렬은 단계, '
        '그룹은 묶는 기준입니다. 어느 줄이든 조건 칩을 끌어 순서를 바꾸거나, 빈 곳을 '
        '눌러 텍스트로 직접 칠 수 있습니다. 태그 이름이 아니라 태그 자체를 기억하므로 '
        '나중에 태그 이름을 바꿔도 조건이 끊기지 않습니다.',
    icon: Icons.filter_alt_outlined,
  ),
  HelpTopic(
    title: '폴더 안에 다른 관리 폴더가 있을 때',
    body:
        '이미 태그를 쓰던 폴더를 다른 관리 폴더 안에서 발견하면 어떻게 할지 묻습니다. '
        '흡수하면 하위의 태그가 상위로 합쳐지고, 독립으로 두면 건드리지 않으며, '
        '무시하면 이번에만 넘어갑니다. 흡수는 하위가 더 새로운 형식으로 저장돼 있으면 '
        '막힙니다.',
    icon: Icons.merge_outlined,
  ),
  HelpTopic(
    title: '연결이 끊긴 항목',
    body:
        '앱 밖에서 파일을 옮기거나 지우면 그 항목은 연결 끊김으로 남고 태그는 보존됩니다. '
        '같은 내용의 파일을 다시 찾으면 자동으로 이어 붙고, 못 찾으면 원본 파일 찾기로 '
        '직접 지목해 태그를 되살릴 수 있습니다.',
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
const List<HelpCommandGroup> helpCommandGroups = [
  HelpCommandGroup('폴더', [
    AppCommandId.openFolder,
    AppCommandId.closeFolder,
    AppCommandId.rescan,
    AppCommandId.revealInFileManager,
    AppCommandId.exitApp,
  ]),
  HelpCommandGroup('선택 · 태그', [
    AppCommandId.selectAll,
    AppCommandId.clearSelection,
    AppCommandId.activateNode,
    AppCommandId.assignTags,
    AppCommandId.reconnect,
    AppCommandId.manageTags,
    AppCommandId.manageThumbnailTags,
    AppCommandId.tagDisplayOrder,
  ]),
  HelpCommandGroup('보기', [
    AppCommandId.viewModeList,
    AppCommandId.viewModeIcon,
    AppCommandId.viewModeDetail,
    AppCommandId.togglePreview,
    AppCommandId.toggleFilterBar,
    AppCommandId.toggleSortBar,
    AppCommandId.toggleGrouping,
    AppCommandId.toggleListEdit,
  ]),
  HelpCommandGroup(
    '키보드 탐색',
    [
      AppCommandId.moveCursorUp,
      AppCommandId.moveCursorDown,
      AppCommandId.extendSelectionUp,
      AppCommandId.extendSelectionDown,
      AppCommandId.moveCursorUpNoSelect,
      AppCommandId.moveCursorDownNoSelect,
      AppCommandId.moveTagLeft,
      AppCommandId.moveTagRight,
      AppCommandId.confirmCursor,
      AppCommandId.toggleCursorSelection,
      AppCommandId.editFocusedTag,
      AppCommandId.deleteFocusedTag,
    ],
    note: '목록 보기에서, 목록에 포커스가 있을 때 듣습니다. 아이콘·자세히 보기는 '
        '각자의 방향키 이동을 따로 씁니다.',
  ),
  HelpCommandGroup('도움말', [AppCommandId.help]),
];

/// 시스템 태그 하나의 설명. 값이 없을 수 있는 조건이나 값을 고쳤을 때 무슨 일이
/// 벌어지는지처럼, 태그 이름만 봐서는 알 수 없는 것을 적는다.
String systemTagDescription(SystemTag tag) => switch (tag) {
  SystemTag.fileSize => '파일의 바이트 크기입니다. 폴더에는 붙지 않아, 이 태그를 '
      '"있음"으로 거르면 파일만 남습니다.',
  SystemTag.modifiedTime => '파일시스템이 기록한 마지막 수정 시각입니다. 시간순으로 '
      '정렬·비교됩니다.',
  SystemTag.extension => '점을 뺀 확장자를 소문자로 담습니다. 폴더와 확장자 없는 '
      '파일에는 붙지 않고, 이름이 점으로 시작하기만 하는 파일도 확장자로 보지 '
      '않습니다. 값으로 묶으면 종류별 파일 수를 볼 수 있습니다.',
  SystemTag.imageDimensions => '이미지의 가로·세로 픽셀 크기입니다. 크기를 읽을 수 '
      '있는 이미지에만 붙으므로, 이 태그를 "있음"으로 걸러 이미지만 모을 수 있습니다.',
  SystemTag.fileName => '파일·폴더의 이름입니다. 시스템 태그 중 유일하게 값을 고칠 '
      '수 있고, 고치면 디스크의 실제 이름이 바뀝니다.',
  SystemTag.folder => '폴더에만 붙는 표식으로 값은 없습니다. 필터에서 "있음"으로 '
      '폴더만, 제외로 파일만 남길 수 있습니다.',
};

/// 시스템 태그 전체를 설명하는 안내 문단(탭 머리에 둔다).
const String systemTagOverview =
    '아래 태그들은 파일 자체에서 값을 끌어내 자동으로 붙습니다. 직접 만들거나 지울 수 '
    '없고 저장되지도 않지만, 직접 만든 태그와 똑같이 필터·정렬·그룹에 쓸 수 있습니다. '
    '태그 관리에서 각각을 목록에 보일지만 정합니다. 어떤 항목에 값이 없으면(폴더의 '
    '크기 등) 그 항목에는 태그가 붙지 않은 것으로 다룹니다.';
