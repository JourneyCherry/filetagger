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
        '필터 줄의 키보드 아이콘을 누르면 조건을 글자로 칩니다. 태그 이름과 연산자는 '
        '자동완성에서 고르고, 스페이스를 누르면 조건이 캡슐로 접힙니다. 접힌 캡슐은 '
        '글자 하나처럼 다뤄져 지우고 옮기는 것이 보통 텍스트와 같습니다.',
    icon: Icons.keyboard_alt_outlined,
    command: AppCommandId.toggleFilterBar,
  ),
  UsageTip(
    title: '정렬 우선순위를 잘라 붙여 바꾸기',
    body:
        '정렬 줄에도 같은 키보드 아이콘이 있습니다. 왼쪽에서 오른쪽 순서가 그대로 정렬 '
        '우선순위라, 캡슐을 잘라 붙이면 드래그보다 빠르게 순서를 바꿉니다. 이름 앞에 '
        '방향 접두사를 붙이면 내림차순이 됩니다.',
    icon: Icons.swap_horiz,
    command: AppCommandId.toggleSortBar,
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
    title: '링크 태그로 다음 항목 넘기기',
    body:
        '링크 태그는 썸네일 외에도 쓸 수 있습니다. 링크 캡슐을 더블클릭(모바일은 '
        '더블탭)하면 가리키는 항목으로 곧장 이동하므로, 만화의 다음 권처럼 이어 보는 '
        '순서를 태그로 이어 둘 수 있습니다.',
    icon: Icons.link,
  ),
];
