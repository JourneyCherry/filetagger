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
library;

import 'package:flutter/material.dart';

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
const List<UsageTip> usageTips = [
  UsageTip(
    title: '목록에서 파일 감추기',
    body:
        '감추기 전용 기능은 없습니다. 대신 "숨김" 같은 이름의 태그를 직접 만들어 감추고 '
        '싶은 항목에 부여하고, 필터 줄에서 그 태그를 상시 제외하세요. 태그는 그대로 '
        '남아 있어 제외를 풀면 다시 보입니다.',
    icon: Icons.visibility_off_outlined,
    command: AppCommandId.toggleFilterBar,
  ),
  UsageTip(
    title: '폴더째 목록에서 빼기',
    body:
        '별도의 "무시" 관리 방식을 두지 않은 것도 같은 이유입니다. 폴더에 "숨김" 태그를 '
        '붙이고 필터에서 제외하면 그 폴더와 아래 내용이 목록에서 통째로 빠집니다.',
    icon: Icons.folder_off_outlined,
    command: AppCommandId.toggleFilterBar,
  ),
  UsageTip(
    title: '폴더에 붙인 태그를 하위에 전파하지 않기',
    body:
        '폴더 태그를 하위 파일마다 복제할 필요가 없습니다. 그룹 줄에 "폴더 계층"을 '
        '넣으면(기본값) 하위 파일이 그 폴더 헤더 아래 모여, 태그를 전파한 것과 같은 '
        '효과를 냅니다. 폴더 단위로 태그를 관리하고 싶을 때 쓰세요.',
    icon: Icons.account_tree_outlined,
    command: AppCommandId.toggleGrouping,
  ),
  UsageTip(
    title: '태그값으로 묶어 보기',
    body:
        '그룹 줄에 태그 이름을 넣으면 그 태그의 값별로 묶이고(SQL의 GROUP BY처럼) '
        '헤더에 값별 파일 수가 뜹니다. 여러 단계를 넣으면 바깥에서 안쪽으로 중첩되고, '
        '"폴더 계층"과 섞으면 폴더 안을 다시 값으로 나눌 수 있습니다.',
    icon: Icons.workspaces_outlined,
    command: AppCommandId.toggleGrouping,
  ),
  UsageTip(
    title: '필터를 텍스트로 치기',
    body:
        '필터 줄의 빈 곳을 누르면 조건을 글자로 칩니다. 태그 이름과 연산자는 '
        '자동완성에서 고르고, 스페이스를 누르면 조건이 캡슐로 접힙니다. 접힌 캡슐은 '
        '글자 하나처럼 다뤄져 지우고 옮기는 것이 보통 텍스트와 같습니다.',
    icon: Icons.keyboard_alt_outlined,
    command: AppCommandId.toggleFilterBar,
  ),
  UsageTip(
    title: '정렬 우선순위를 잘라 붙여 바꾸기',
    body:
        '정렬 줄도 빈 곳을 누르면 같은 방식으로 칩니다. 왼쪽에서 오른쪽 순서가 그대로 정렬 '
        '우선순위라, 캡슐을 잘라 붙이면 드래그보다 빠르게 순서를 바꿉니다. 이름 앞에 '
        '접두사를 붙이면 내림차순·무작위가 됩니다.',
    icon: Icons.swap_horiz,
    command: AppCommandId.toggleSortBar,
  ),
  UsageTip(
    title: '하는 일에 따라 조건과 표시를 통째로 갈아타기',
    body:
        '읽을 것을 고를 때와 정리할 때는 보고 싶은 것이 다릅니다. 필터·정렬·그룹에 이름 '
        '태그·썸네일 태그까지 짜 두고 프리셋으로 저장하면, 다음부터는 캡슐 하나로 그 '
        '조합 전체를 되돌립니다. 예를 들어 읽을 때는 "안 읽음"만 남기고 제목 태그를 이름 '
        '자리에 세워 표지를 썸네일로 보는 프리셋을, 정리할 때는 태그가 없는 항목을 찾아 '
        '실제 파일 이름을 그대로 보는 프리셋을 나란히 두는 식입니다.',
    icon: Icons.bookmarks_outlined,
    command: AppCommandId.togglePresetBar,
  ),
  UsageTip(
    title: '원하는 이미지를 썸네일로 쓰기',
    body:
        '값 유형이 "링크"인 태그를 만들어 파일에 부여하면(부여할 때 워크스페이스 안의 '
        '대상을 고릅니다) 그 대상의 이미지가 썸네일이 됩니다. 워크스페이스 밖의 이미지를 '
        '쓰려면 "이미지" 유형 태그를 만들어 파일을 고르세요. 어느 태그를 썸네일 출처로 '
        '쓸지와 그 우선순위는 썸네일 태그에서 정합니다.',
    icon: Icons.image_outlined,
    command: AppCommandId.manageThumbnailTags,
  ),
  UsageTip(
    title: '태그값에 담기 어려운 정보를 키워드로 세우기',
    body:
        '작가처럼 그 자체가 여러 정보(국적·계정 등)를 갖는 대상은 태그값 문자열로 적으면 '
        '더 붙일 자리가 없습니다. 키워드를 하나 만들어 그 정보들을 키워드의 태그로 붙이고, '
        '그림 파일에는 링크 태그로 그 키워드를 가리키세요. 키워드 캡슐을 더블클릭하면 곧장 '
        '그 대상으로 이동하고, 키워드에 붙인 태그로 되레 그림을 찾아낼 수도 있습니다.',
    icon: Icons.sell_outlined,
    command: AppCommandId.createKeyword,
  ),
  UsageTip(
    title: '링크 태그로 다음 항목 넘기기',
    body:
        '링크 태그는 썸네일 외에도 쓸 수 있습니다. 링크 캡슐을 더블클릭(모바일은 '
        '더블탭)하면 가리키는 항목으로 곧장 이동하므로, 만화의 다음 권처럼 이어 보는 '
        '순서를 태그로 이어 둘 수 있습니다.',
    icon: Icons.link,
  ),
  UsageTip(
    title: '파일 이름 대신 태그값을 이름으로 보기',
    body:
        '내려받은 파일 이름이 알아볼 수 없는 문자열이어도 파일을 바꿀 필요는 없습니다. '
        '제목 같은 텍스트 태그를 이름 태그로 지정하면 목록의 이름 자리에 그 값이 대신 '
        '보입니다. 여러 개를 순서대로 두면 앞에 있는 것부터 찾아 쓰고, 그 태그가 없는 '
        '항목은 원래 파일 이름을 그대로 보입니다.',
    icon: Icons.text_fields,
    command: AppCommandId.manageNameTags,
  ),
  UsageTip(
    title: '이름 아래 줄에 경로 대신 다른 값 보기',
    body:
        '이름 아래 줄에는 기본으로 경로가 보입니다. 태그로 묶어 보는 동안에는 경로보다 '
        '작가·연도처럼 다른 축이 더 궁금할 수 있는데, 그때 부제 태그를 지정하면 그 값이 '
        '대신 보입니다. 이름 태그와 같은 방식이라 여러 개를 순서대로 둘 수 있고, 그 태그가 '
        '없는 항목은 경로를 그대로 보입니다.',
    icon: Icons.short_text,
    command: AppCommandId.manageSubtitleTags,
  ),
  UsageTip(
    title: '태그를 다른 폴더로 옮기기',
    body:
        '가져오기 기능은 따로 없습니다. 항목을 골라 내보내면 요청함 형식의 파일이 나오고, '
        '그 파일을 받는 폴더의 .filetagger/queue/에 넣기만 하면 그대로 적용됩니다. 태그가 '
        '없으면 값 유형·색까지 그대로 만들어집니다.',
    icon: Icons.ios_share,
    command: AppCommandId.exportSelection,
  ),
  UsageTip(
    title: '끊어진 링크 모아서 손보기',
    body:
        '가리키던 항목이 지워졌거나, 다른 폴더에서 가져온 링크의 대상이 아직 없으면 링크 '
        '캡슐에 표식이 붙습니다. 필터에서 "미해결 링크" 태그를 "있음"으로 걸면 그런 항목만 '
        '모이고, 캡슐을 더블클릭해 다시 연결하거나 x로 지우면 됩니다.',
    icon: Icons.link_off,
    command: AppCommandId.toggleFilterBar,
  ),
];
