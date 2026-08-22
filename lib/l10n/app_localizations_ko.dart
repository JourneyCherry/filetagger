// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get menuLanguage => '언어';

  @override
  String get languageSystem => '시스템 설정';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get cmdOpenFolder => '폴더 열기';

  @override
  String get cmdCloseFolder => '폴더 닫기';

  @override
  String get cmdRescan => '다시 스캔';

  @override
  String get cmdSelectAll => '전체 선택';

  @override
  String get cmdClearSelection => '선택 해제';

  @override
  String get cmdOpenNode => '열기';

  @override
  String get cmdToggleExpand => '펼치기 / 접기';

  @override
  String get cmdAssignTags => '태그 부여';

  @override
  String get cmdReconnect => '원본 파일 찾기';

  @override
  String get cmdRevealInFileManager => '탐색기에서 열기';

  @override
  String get cmdExportSelection => '태그 내보내기…';

  @override
  String get cmdManageTags => '태그 관리';

  @override
  String get cmdManageThumbnailTags => '썸네일 태그…';

  @override
  String get cmdManageNameTags => '이름 태그…';

  @override
  String get cmdManageSubtitleTags => '부제 태그…';

  @override
  String get cmdCreateKeyword => '키워드 만들기…';

  @override
  String get cmdEditKeyword => '키워드 편집…';

  @override
  String get cmdDeleteKeyword => '키워드 삭제';

  @override
  String get cmdHelp => '도움말 보기';

  @override
  String get cmdCheckForUpdates => '업데이트 확인';

  @override
  String get cmdAbout => '정보';

  @override
  String get cmdExitApp => '프로그램 종료';

  @override
  String get cmdTagDisplayOrder => '태그 표시 순서';

  @override
  String get cmdToggleFilterBar => '필터 조건 보기';

  @override
  String get cmdToggleSortBar => '정렬 조건 보기';

  @override
  String get cmdToggleListEdit => '목록에서 수정 활성화';

  @override
  String get cmdToggleGrouping => '그룹 기준 보기';

  @override
  String get cmdTogglePresetBar => '프리셋 보기';

  @override
  String get cmdTogglePreview => '프리뷰 보기';

  @override
  String get cmdMoveCursorUp => '커서 위로';

  @override
  String get cmdMoveCursorDown => '커서 아래로';

  @override
  String get cmdExtendSelectionUp => '범위 위로';

  @override
  String get cmdExtendSelectionDown => '범위 아래로';

  @override
  String get cmdMoveCursorUpNoSelect => '커서만 위로';

  @override
  String get cmdMoveCursorDownNoSelect => '커서만 아래로';

  @override
  String get cmdCursorLeft => '접기 · 상위로 / 태그 왼쪽';

  @override
  String get cmdCursorRight => '펼치기 / 태그 오른쪽';

  @override
  String get cmdToggleTagFocus => '태그 칸 드나들기';

  @override
  String get cmdConfirmCursor => '확정 / 열기';

  @override
  String get cmdToggleCursorSelection => '커서 선택 토글';

  @override
  String get cmdDeleteFocusedTag => '태그 제거';

  @override
  String get cmdEditFocusedTag => '태그값 수정';

  @override
  String get cmdViewModeList => '보기 모드: 목록';

  @override
  String get cmdViewModeIcon => '보기 모드: 아이콘';

  @override
  String get cmdViewModeDetail => '보기 모드: 자세히';

  @override
  String get mobileFilterSort => '필터 · 정렬';

  @override
  String mobileSelectedCount(int count) {
    return '$count개 선택';
  }

  @override
  String get mobileMore => '더 보기';

  @override
  String get commonCancel => '취소';

  @override
  String get commonClose => '닫기';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonSave => '저장';

  @override
  String get commonName => '이름';

  @override
  String get commonNone => '없음';

  @override
  String get commonTag => '태그';

  @override
  String get commonAddTag => '태그 추가';

  @override
  String get commonTagToAdd => '추가할 태그';

  @override
  String get commonNewTag => '새 태그';

  @override
  String get commonRemoveFromList => '목록에서 빼기';

  @override
  String get aboutChannelPortable => '포터블';

  @override
  String get aboutChannelPackage => '설치판';

  @override
  String get aboutVersionUnknown => '버전을 알 수 없음';

  @override
  String aboutVersion(String version) {
    return '버전 $version';
  }

  @override
  String aboutVersionLine(String version, String channel) {
    return '$version · $channel';
  }

  @override
  String get aboutOpenBrowserFailed => '웹 브라우저를 열지 못했습니다.';

  @override
  String get aboutSummary =>
      '태그로 파일을 정리하고 찾는 앱입니다. 태그는 관리 폴더 안에 함께 저장되어 폴더를 옮기면 따라갑니다.';

  @override
  String get aboutSourceRepository => '소스 코드 저장소';

  @override
  String get aboutOpenSourceLicenses => '오픈소스 라이선스';

  @override
  String get updateOpenReleasePage => '릴리즈 페이지 열기';

  @override
  String get updateOpenStore => '스토어에서 열기';

  @override
  String get updateOpenStoreFailed => '스토어 앱을 열지 못했습니다.';

  @override
  String get updateChecking => '확인하는 중…';

  @override
  String get updateAvailableHeadline => '새 업데이트가 있습니다.';

  @override
  String updateAvailableDetail(String current, String latest) {
    return '현재 $current · 최신 $latest';
  }

  @override
  String get updateUpToDateHeadline => '최신 버전입니다.';

  @override
  String updateUpToDateDetail(String current) {
    return '현재 $current';
  }

  @override
  String get updateUnknownVersionHeadline => '버전을 알 수 없습니다.';

  @override
  String get updateUnknownVersionDetail => '이 실행의 버전을 확인할 수 없어 배포본과 견줄 수 없습니다.';

  @override
  String get updateManagedByStoreHeadline => '스토어가 업데이트를 관리합니다.';

  @override
  String get updateManagedByStoreDetail =>
      '이 배포본은 스토어를 통해 갱신되므로 앱이 직접 받아 설치하지 않습니다.';

  @override
  String get updateFailedHeadline => '업데이트를 확인하지 못했습니다.';

  @override
  String get updateFailedDetail => '네트워크 연결을 확인한 뒤 다시 시도해 주세요.';

  @override
  String get helpTabHowTo => '사용법';

  @override
  String get helpTabTips => '사용 팁';

  @override
  String get helpTabShortcuts => '기능과 단축키';

  @override
  String get helpTabSystemTags => '시스템 태그';

  @override
  String get helpTopicTagsTitle => '태그와 태그값';

  @override
  String get helpTopicTagsBody =>
      '태그는 종류를 만들어 두고 파일·폴더에 부여합니다. 값 유형이 \"라벨\"이면 값 없이 붙었는지만 따지고, 텍스트·숫자·날짜는 값을 함께 적습니다. \"링크\"는 워크스페이스 안의 다른 항목을, \"이미지\"는 바깥에서 가져온 이미지 파일을 값으로 갖습니다. 값 유형에 따라 정렬 기준(사전순·숫자순·시간순)이 달라집니다.';

  @override
  String get helpTopicStorageTitle => '태그가 저장되는 곳';

  @override
  String get helpTopicStorageBody =>
      '태그는 관리 폴더 안의 숨김 폴더에 함께 저장됩니다. 폴더를 통째로 옮기거나 복사하면 태그도 따라갑니다. 앱 전역 설정(최근 연 폴더 등)만 OS의 앱 데이터 폴더에 남습니다.';

  @override
  String get helpTopicManageModeTitle => '폴더마다 정하는 관리 방식';

  @override
  String get helpTopicManageModeBody =>
      '폴더는 \"폴더만 관리\"(하나의 항목으로만 다루고 내부를 감춤), \"내부 관리\"(직속 내용만), \"재귀적으로 관리\"(하위까지 이어서) 중 하나로 다룹니다. 따로 정하지 않은 폴더는 상위의 방식을 물려받습니다. 큰 폴더의 내부를 인덱싱하지 않으려면 관리 방식을 바꾸세요.';

  @override
  String get helpTopicQueryRowsTitle => '필터 · 정렬 · 그룹 세 줄';

  @override
  String get helpTopicQueryRowsBody =>
      '도구모음의 세 줄은 문법이 같고 뜻만 다릅니다. 필터는 조건, 정렬은 단계, 그룹은 묶는 기준입니다. 어느 줄이든 조건 칩을 끌어 순서를 바꾸거나, 빈 곳을 눌러 텍스트로 직접 칠 수 있습니다. 태그 이름이 아니라 태그 자체를 기억하므로 나중에 태그 이름을 바꿔도 조건이 끊기지 않습니다. 정렬 캡슐을 누르면 오름차순·내림차순·무작위를 차례로 오갑니다 — 무작위는 그 태그값의 순서만 흩고 값이 같은 항목끼리는 건드리지 않아, 뒤 단계의 정렬이 그대로 살아 있습니다. 무작위를 다시 고를 때마다 새로 섞입니다.';

  @override
  String get helpTopicPresetsTitle => '조건 프리셋';

  @override
  String get helpTopicPresetsBody =>
      '자주 쓰는 필터·정렬·그룹에 이름 태그·썸네일 태그까지 한 벌로 묶어 이름을 붙여 둡니다. 프리셋을 누르면 지금 걸린 것을 모두 지우고 그 한 벌로 갈아끼웁니다 — 일부만 더해지는 것이 아닙니다. 하는 일에 따라 찾는 조건뿐 아니라 이름 칸과 썸네일에 보고 싶은 것도 함께 갈리기 때문에 다섯을 한 벌로 다룹니다. 무엇이 담겼는지는 캡슐에 마우스를 올리면 보입니다. 지금 걸린 것과 똑같은 프리셋은 강조되어, 무엇을 보고 있는지 알 수 있습니다. 이름 변경·덮어쓰기는 프리셋을 우클릭(모바일은 길게 누르기)하고, 순서는 끌어서 바꿉니다. 프리셋도 태그처럼 관리 폴더 안에 저장되어 폴더를 옮기면 따라갑니다. 자세히 보기의 열 머리글 정렬과 보기 모드·크기 배율은 검색 조건이 아니라 프리셋에 담기지 않습니다.';

  @override
  String get helpTopicPresetSourcesTitle => '이름 · 부제 · 썸네일 태그가 프리셋에 담긴다';

  @override
  String get helpTopicPresetSourcesBody =>
      '이름·부제·썸네일 태그는 한 번 정해 두는 설정처럼 보이지만 프리셋에 함께 담깁니다. 그래서 프리셋을 부르면 필터·정렬·그룹만이 아니라 이름 칸과 그 아래 줄, 썸네일이 보이는 방식도 그 프리셋의 것으로 바뀝니다. 이 셋을 지정하지 않은 채로 저장한 프리셋을 부르면 파일 이름과 경로, 기본 썸네일로 되돌아갑니다 — 이 기능이 생기기 전에 만들어 둔 프리셋도 그렇습니다. 원하는 상태로 맞춘 뒤 그 프리셋에 덮어쓰면 다음부터는 함께 되살아납니다.';

  @override
  String get helpTopicNestedTitle => '폴더 안에 다른 관리 폴더가 있을 때';

  @override
  String get helpTopicNestedBody =>
      '이미 태그를 쓰던 폴더를 다른 관리 폴더 안에서 발견하면 어떻게 할지 묻습니다. 흡수하면 하위의 태그가 상위로 합쳐지고, 독립으로 두면 건드리지 않으며, 무시하면 이번에만 넘어갑니다. 흡수는 하위가 더 새로운 형식으로 저장돼 있으면 막힙니다.';

  @override
  String get helpTopicKeywordTitle => '키워드 — 파일로 남지 않는 항목';

  @override
  String get helpTopicKeywordBody =>
      '키워드는 디스크에 파일이나 폴더로 남지 않고 태그 저장소 안에만 있는 항목입니다. 이름 하나가 전부이고, 작가의 국적이나 계정 같은 부연 정보는 그 키워드에 태그로 붙입니다 — 그래야 다른 항목과 똑같이 필터·정렬·그룹에 걸립니다. 파일에서는 링크 태그로 키워드를 가리켜 둘을 잇습니다. 스캔의 대상이 아니라 폴더 관리 방식이나 파일 이동에 영향받지 않고, 목록에서는 맨 위 층에 놓입니다.';

  @override
  String get helpTopicTypeAheadTitle => '글자를 쳐서 항목 찾기';

  @override
  String get helpTopicTypeAheadBody =>
      '목록에 포커스가 있을 때 글자를 치면 그 글자로 시작하는 항목으로 커서가 건너뜁니다(이름 칸에 보이는 이름 기준이라, 이름 태그로 갈아 낀 이름이 있으면 그 이름으로 찾습니다). 이어서 치면 검색어가 좁혀지고, 같은 글자를 거듭 치면 그 글자로 시작하는 항목들을 차례로 돕니다. 잠시 멈추면 검색어가 지워져 다음 글자가 새 검색이 됩니다. 목록을 줄이는 것이 아니라 커서만 옮기는 것이라, 필터를 걸어 둔 채로도 그대로 쓸 수 있습니다. 접어 둔 그룹이나 폴더 안에 있어 지금 보이지 않는 항목도 찾아냅니다 — 필터에 걸러지지 않았다면 대상이며, 찾으면 그 항목에 이르는 그룹·폴더만 펼쳐 드러냅니다. 세 보기 모드에서 모두 되고, 아이콘 보기는 지금 파고든 계층 안에서만 찾습니다.';

  @override
  String get helpTopicDisconnectedTitle => '연결이 끊긴 항목';

  @override
  String get helpTopicDisconnectedBody =>
      '앱 밖에서 파일을 옮기거나 지우면 그 항목은 연결 끊김으로 남고 태그는 보존됩니다. 같은 내용의 파일을 다시 찾으면 자동으로 이어 붙고, 못 찾으면 원본 파일 찾기로 직접 지목해 태그를 되살릴 수 있습니다.';

  @override
  String get helpGroupFolder => '폴더';

  @override
  String get helpGroupSelectionTags => '선택 · 태그';

  @override
  String get helpGroupKeyword => '키워드';

  @override
  String get helpGroupKeywordNote => '편집·삭제는 키워드를 하나만 고른 상태에서 듣습니다.';

  @override
  String get helpGroupView => '보기';

  @override
  String get helpGroupKeyboardNav => '키보드 탐색';

  @override
  String get helpGroupKeyboardNavNote =>
      '목록 보기에서, 목록에 포커스가 있을 때 듣습니다. 아이콘·자세히 보기는 각자의 방향키 이동을 따로 씁니다.';

  @override
  String get helpGroupHelp => '도움말';

  @override
  String get helpShortcutsIntro =>
      '메뉴·버튼으로 부를 수 있는 조작과, 있다면 그 단축키입니다. 지금 할 수 없는 조작(고른 항목이 없을 때의 태그 부여 등)도 함께 싣습니다.';

  @override
  String helpTipRelatedCommand(String command) {
    return '관련 조작: $command';
  }

  @override
  String get helpSystemTagOverview =>
      '아래 태그들은 파일 자체에서 값을 끌어내 자동으로 붙습니다. 직접 만들거나 지울 수 없고 저장되지도 않지만, 직접 만든 태그와 똑같이 필터·정렬·그룹에 쓸 수 있습니다. 태그 관리에서 각각을 목록에 보일지만 정합니다. 어떤 항목에 값이 없으면(폴더의 크기 등) 그 항목에는 태그가 붙지 않은 것으로 다룹니다.';

  @override
  String get helpSystemTagFileSize =>
      '파일의 바이트 크기입니다. 폴더에는 붙지 않아, 이 태그를 \"있음\"으로 거르면 파일만 남습니다.';

  @override
  String get helpSystemTagModifiedTime =>
      '파일시스템이 기록한 마지막 수정 시각입니다. 시간순으로 정렬·비교됩니다.';

  @override
  String get helpSystemTagExtension =>
      '점을 뺀 확장자를 소문자로 담습니다. 폴더와 확장자 없는 파일에는 붙지 않고, 이름이 점으로 시작하기만 하는 파일도 확장자로 보지 않습니다. 값으로 묶으면 종류별 파일 수를 볼 수 있습니다.';

  @override
  String get helpSystemTagImageWidth =>
      '이미지의 가로 픽셀 수입니다. 크기를 읽을 수 있는 이미지에만 붙으므로, 이 태그를 \"있음\"으로 걸러 이미지만 모을 수 있습니다. 숫자라서 큰 것부터 정렬하거나 \"얼마 이상\"으로 거를 수 있습니다.';

  @override
  String get helpSystemTagImageHeight =>
      '이미지의 세로 픽셀 수입니다. 가로와 따로 붙어(둘은 늘 함께 붙거나 함께 없습니다), 가로·세로를 각각 정렬 기준이나 조건으로 쓸 수 있습니다.';

  @override
  String get helpSystemTagFileName =>
      '항목의 이름입니다. 시스템 태그 중 유일하게 값을 고칠 수 있고, 고치면 디스크의 실제 이름이 바뀝니다(키워드는 디스크에 실체가 없어 키워드의 이름만 바뀝니다).';

  @override
  String get helpSystemTagChildFileCount =>
      '폴더가 바로 아래에 담고 있는 파일의 수입니다. 하위 폴더와 그 안의 파일은 세지 않습니다. 폴더에만 붙으므로 폴더 표식을 겸해, 필터에서 \"있음\"으로 폴더만, 제외로 파일만 남길 수 있습니다(빈 폴더도 0이 붙습니다). 내부를 감춘 폴더에도 붙어, 열어 보지 않고 안에 무엇이 얼마나 있는지 가늠하거나 수량으로 정렬할 수 있습니다.';

  @override
  String get helpSystemTagKeyword =>
      '키워드에만 붙는 표식으로 값은 없습니다. 키워드를 목록에서 보고 싶지 않으면 필터에서 이 태그를 제외하면 됩니다.';

  @override
  String get helpSystemTagUnresolvedLink =>
      '가리키는 대상을 찾지 못한 링크 태그를 하나라도 가진 항목에 붙는 표식으로 값은 없습니다. 대상이 지워졌거나, 다른 태거에서 가져온 링크의 대상이 아직 이 폴더에 없을 때 생깁니다. 필터에서 \"있음\"으로 걸러 모아 두고, 각 링크 칩을 더블클릭해 다시 연결하거나 x로 지우면 됩니다.';

  @override
  String get tipHideFilesTitle => '목록에서 파일 감추기';

  @override
  String get tipHideFilesBody =>
      '감추기 전용 기능은 없습니다. 대신 \"숨김\" 같은 이름의 태그를 직접 만들어 감추고 싶은 항목에 부여하고, 필터 줄에서 그 태그를 상시 제외하세요. 태그는 그대로 남아 있어 제외를 풀면 다시 보입니다.';

  @override
  String get tipHideFolderTitle => '폴더째 목록에서 빼기';

  @override
  String get tipHideFolderBody =>
      '별도의 \"무시\" 관리 방식을 두지 않은 것도 같은 이유입니다. 폴더에 \"숨김\" 태그를 붙이고 필터에서 제외하면 그 폴더와 아래 내용이 목록에서 통째로 빠집니다.';

  @override
  String get tipFolderGroupTitle => '폴더에 붙인 태그를 하위에 전파하지 않기';

  @override
  String get tipFolderGroupBody =>
      '폴더 태그를 하위 파일마다 복제할 필요가 없습니다. 그룹 줄에 \"폴더 계층\"을 넣으면(기본값) 하위 파일이 그 폴더 헤더 아래 모여, 태그를 전파한 것과 같은 효과를 냅니다. 폴더 단위로 태그를 관리하고 싶을 때 쓰세요.';

  @override
  String get tipGroupByValueTitle => '태그값으로 묶어 보기';

  @override
  String get tipGroupByValueBody =>
      '그룹 줄에 태그 이름을 넣으면 그 태그의 값별로 묶이고(SQL의 GROUP BY처럼) 헤더에 값별 파일 수가 뜹니다. 여러 단계를 넣으면 바깥에서 안쪽으로 중첩되고, \"폴더 계층\"과 섞으면 폴더 안을 다시 값으로 나눌 수 있습니다.';

  @override
  String get tipFilterTextTitle => '필터를 텍스트로 치기';

  @override
  String get tipFilterTextBody =>
      '필터 줄의 빈 곳을 누르면 조건을 글자로 칩니다. 태그 이름과 연산자는 자동완성에서 고르고, 스페이스를 누르면 조건이 캡슐로 접힙니다. 접힌 캡슐은 글자 하나처럼 다뤄져 지우고 옮기는 것이 보통 텍스트와 같습니다.';

  @override
  String get tipSortTextTitle => '정렬 우선순위를 잘라 붙여 바꾸기';

  @override
  String get tipSortTextBody =>
      '정렬 줄도 빈 곳을 누르면 같은 방식으로 칩니다. 왼쪽에서 오른쪽 순서가 그대로 정렬 우선순위라, 캡슐을 잘라 붙이면 드래그보다 빠르게 순서를 바꿉니다. 이름 앞에 접두사를 붙이면 내림차순·무작위가 됩니다.';

  @override
  String get tipPresetSwitchTitle => '하는 일에 따라 조건과 표시를 통째로 갈아타기';

  @override
  String get tipPresetSwitchBody =>
      '읽을 것을 고를 때와 정리할 때는 보고 싶은 것이 다릅니다. 필터·정렬·그룹에 이름 태그·썸네일 태그까지 짜 두고 프리셋으로 저장하면, 다음부터는 캡슐 하나로 그 조합 전체를 되돌립니다. 예를 들어 읽을 때는 \"안 읽음\"만 남기고 제목 태그를 이름 자리에 세워 표지를 썸네일로 보는 프리셋을, 정리할 때는 태그가 없는 항목을 찾아 실제 파일 이름을 그대로 보는 프리셋을 나란히 두는 식입니다.';

  @override
  String get tipThumbnailSourceTitle => '원하는 이미지를 썸네일로 쓰기';

  @override
  String get tipThumbnailSourceBody =>
      '값 유형이 \"링크\"인 태그를 만들어 파일에 부여하면(부여할 때 워크스페이스 안의 대상을 고릅니다) 그 대상의 이미지가 썸네일이 됩니다. 워크스페이스 밖의 이미지를 쓰려면 \"이미지\" 유형 태그를 만들어 파일을 고르세요. 어느 태그를 썸네일 출처로 쓸지와 그 우선순위는 썸네일 태그에서 정합니다.';

  @override
  String get tipKeywordEntityTitle => '태그값에 담기 어려운 정보를 키워드로 세우기';

  @override
  String get tipKeywordEntityBody =>
      '작가처럼 그 자체가 여러 정보(국적·계정 등)를 갖는 대상은 태그값 문자열로 적으면 더 붙일 자리가 없습니다. 키워드를 하나 만들어 그 정보들을 키워드의 태그로 붙이고, 그림 파일에는 링크 태그로 그 키워드를 가리키세요. 키워드 캡슐을 더블클릭하면 곧장 그 대상으로 이동하고, 키워드에 붙인 태그로 되레 그림을 찾아낼 수도 있습니다.';

  @override
  String get tipLinkNextTitle => '링크 태그로 다음 항목 넘기기';

  @override
  String get tipLinkNextBody =>
      '링크 태그는 썸네일 외에도 쓸 수 있습니다. 링크 캡슐을 더블클릭(모바일은 더블탭)하면 가리키는 항목으로 곧장 이동하므로, 만화의 다음 권처럼 이어 보는 순서를 태그로 이어 둘 수 있습니다.';

  @override
  String get tipNameTagTitle => '파일 이름 대신 태그값을 이름으로 보기';

  @override
  String get tipNameTagBody =>
      '내려받은 파일 이름이 알아볼 수 없는 문자열이어도 파일을 바꿀 필요는 없습니다. 제목 같은 텍스트 태그를 이름 태그로 지정하면 목록의 이름 자리에 그 값이 대신 보입니다. 여러 개를 순서대로 두면 앞에 있는 것부터 찾아 쓰고, 그 태그가 없는 항목은 원래 파일 이름을 그대로 보입니다.';

  @override
  String get tipSubtitleTagTitle => '이름 아래 줄에 경로 대신 다른 값 보기';

  @override
  String get tipSubtitleTagBody =>
      '이름 아래 줄에는 기본으로 경로가 보입니다. 태그로 묶어 보는 동안에는 경로보다 작가·연도처럼 다른 축이 더 궁금할 수 있는데, 그때 부제 태그를 지정하면 그 값이 대신 보입니다. 이름 태그와 같은 방식이라 여러 개를 순서대로 둘 수 있고, 그 태그가 없는 항목은 경로를 그대로 보입니다.';

  @override
  String get tipExportTagsTitle => '태그를 다른 폴더로 옮기기';

  @override
  String get tipExportTagsBody =>
      '가져오기 기능은 따로 없습니다. 항목을 골라 내보내면 요청함 형식의 파일이 나오고, 그 파일을 받는 폴더의 .filetagger/queue/에 넣기만 하면 그대로 적용됩니다. 태그가 없으면 값 유형·색까지 그대로 만들어집니다.';

  @override
  String get tipUnresolvedLinksTitle => '끊어진 링크 모아서 손보기';

  @override
  String get tipUnresolvedLinksBody =>
      '가리키던 항목이 지워졌거나, 다른 폴더에서 가져온 링크의 대상이 아직 없으면 링크 캡슐에 표식이 붙습니다. 필터에서 \"미해결 링크\" 태그를 \"있음\"으로 걸면 그런 항목만 모이고, 캡슐을 더블클릭해 다시 연결하거나 x로 지우면 됩니다.';

  @override
  String homeScanFailed(String error) {
    return '스캔에 실패했습니다: $error';
  }

  @override
  String homeNoAppForFile(String name) {
    return '이 파일을 열 앱이 없습니다: $name';
  }

  @override
  String homeRevealFailed(String error) {
    return '탐색기에서 열지 못했습니다: $error';
  }

  @override
  String get homeRecentFolders => '최근 폴더';

  @override
  String homeSettingsLoadFailed(String error) {
    return '설정을 불러오지 못했습니다: $error';
  }

  @override
  String get homeNoRecentFolders => '아직 연 폴더가 없습니다.';

  @override
  String get menuKeyword => '키워드';

  @override
  String get menuFolderManageOptions => '폴더 관리 옵션';

  @override
  String get tooltipFolderManageMode => '폴더 관리 방식';

  @override
  String get keywordCreateTitle => '키워드 만들기';

  @override
  String get keywordCreateConfirm => '만들기';

  @override
  String get keywordEditTitle => '키워드 편집';

  @override
  String get exportNothingToExport => '내보낼 태그 부여가 없습니다.';

  @override
  String get exportFileTypeLabel => '요청함 파일';

  @override
  String exportDone(int count) {
    return '태그 $count건을 내보냈습니다.';
  }

  @override
  String exportDoneWithImages(int count, int images) {
    return '태그 $count건을 내보냈습니다 (이미지 $images개 동봉).';
  }

  @override
  String exportFailed(String error) {
    return '내보내지 못했습니다: $error';
  }

  @override
  String get assignTitleSingleFile => '파일 1개';

  @override
  String assignTitleFiles(int count) {
    return '$count개 파일';
  }

  @override
  String get renameTitle => '이름 변경';

  @override
  String get renameNewName => '새 이름';

  @override
  String get renameConfirm => '변경';

  @override
  String get renamePathSeparator => '이름에 경로 구분자(/ \\)는 쓸 수 없습니다.';

  @override
  String renameFailed(String error) {
    return '이름을 바꾸지 못했습니다: $error';
  }

  @override
  String get scopeRootFolder => '루트 폴더';

  @override
  String get scopeReductionTitle => '관리 범위 축소';

  @override
  String scopeReductionTarget(String target) {
    return '‘$target’의 관리 범위를 줄입니다.';
  }

  @override
  String scopeReductionWarning(int count) {
    return '범위 밖이 되는 $count개 하위 항목의 태그가 함께 제거되며, 되돌릴 수 없습니다.';
  }

  @override
  String get scopeReductionConfirm => '범위 축소';

  @override
  String get nestedTitle => '중첩된 태그 폴더 발견';

  @override
  String get nestedPrompt => '하위 폴더가 자체 태그 데이터를 가지고 있습니다. 어떻게 처리할지 선택하세요.';

  @override
  String get nestedAbsorb => '흡수';

  @override
  String get nestedAbsorbDetail => '태그와 목록을 현재 워크스페이스로 가져와 관리합니다.';

  @override
  String get nestedAbsorbBlocked => '하위 태거가 더 높은 버전이라 흡수할 수 없습니다.';

  @override
  String get nestedIndependent => '독립';

  @override
  String get nestedIndependentDetail =>
      '내부를 열지 않는 단일 노드로 두고, 하위 태거는 건드리지 않습니다.';

  @override
  String get nestedIgnore => '무시';

  @override
  String get nestedIgnoreDetail => '하위 태거를 무시하고 내부 파일을 현재 규칙으로 인덱싱합니다.';

  @override
  String get nestedRemoveSource => '흡수 후 하위 태그 폴더 제거';

  @override
  String get nestedRemoveSourceOn => '하위 .filetagger 폴더를 삭제합니다(되돌릴 수 없음).';

  @override
  String get nestedRemoveSourceOff => '하위 태거를 남기고 이후 ‘무시’로 처리합니다.';

  @override
  String get nestedLater => '나중에';

  @override
  String get nestedApply => '적용';

  @override
  String get commonOk => '확인';

  @override
  String get menuFile => '파일';

  @override
  String get menuRecentFolders => '최근 연 폴더';

  @override
  String get menuEdit => '편집';

  @override
  String get menuRootManageMode => '루트 폴더 관리 방식';

  @override
  String get menuView => '보기';

  @override
  String get menuViewMode => '보기 모드';

  @override
  String get menuTheme => '테마';

  @override
  String get menuTag => '태그';

  @override
  String get menuHelp => '도움말';

  @override
  String get menuHelpTopics => '항목별 보기';

  @override
  String get themeSystem => '시스템 설정';

  @override
  String get themeLight => '밝게';

  @override
  String get themeDark => '어둡게';

  @override
  String get rootManageDirectOnly => '직속 항목만 관리';

  @override
  String get rootManageRecursive => '전체 재귀 관리';

  @override
  String get viewModeList => '목록';

  @override
  String get viewModeIcon => '아이콘';

  @override
  String get viewModeDetail => '자세히';

  @override
  String get folderManageOpaque => '폴더만 관리 (내부 감춤)';

  @override
  String get folderManageManaged => '내부 관리';

  @override
  String get folderManageRecursive => '재귀적으로 관리';

  @override
  String get chipCustomImage => '커스텀 이미지';

  @override
  String get chipLinkNoTarget => '(없음)';

  @override
  String get chipUnresolvedHint => '가리키는 대상을 찾지 못했습니다. 더블클릭해 다시 연결하거나 x로 지웁니다.';

  @override
  String get chipDeletedTag => '(삭제된 태그)';

  @override
  String get colorPickerTitle => '색 고르기';

  @override
  String get tagPickerLabel => '태그';

  @override
  String get tagPickerSearchHint => '태그 이름 검색';

  @override
  String get pickerImageTypeLabel => '이미지';

  @override
  String get thumbnailRegisterFailed => '이미지를 등록하지 못했습니다.';

  @override
  String get groupFolderHierarchyDesc => '경로 계층';

  @override
  String get queryEmpty => '없음';

  @override
  String get valueTypeLabel => '라벨';

  @override
  String get valueTypeText => '텍스트';

  @override
  String get valueTypeNumber => '숫자';

  @override
  String get valueTypeDate => '날짜';

  @override
  String get valueTypeLink => '링크';

  @override
  String get valueTypeImage => '이미지';

  @override
  String get filterOpExists => '있음';

  @override
  String get filterOpContains => '포함';

  @override
  String get filterOpNotContains => '미포함';

  @override
  String get filterOpMenuExists => '있음 (존재)';

  @override
  String get filterOpMenuEquals => '= 같음';

  @override
  String get filterOpMenuNotEquals => '≠ 다름';

  @override
  String get filterOpMenuLessThan => '< 미만';

  @override
  String get filterOpMenuLessOrEqual => '≤ 이하';

  @override
  String get filterOpMenuGreaterThan => '> 초과';

  @override
  String get filterOpMenuGreaterOrEqual => '≥ 이상';

  @override
  String get filterOpMenuContains => '포함';

  @override
  String get filterOpMenuNotContains => '미포함';

  @override
  String get commonEdit => '편집';

  @override
  String get tagVisibilityHide => '목록에서 감추기';

  @override
  String get tagVisibilityShow => '목록에 표시하기';

  @override
  String get tagMergeIntoThis => '다른 태그를 여기에 합치기';

  @override
  String get tagMergeNoCandidates => '합칠 수 있는 태그가 없습니다';

  @override
  String get tagDeleteTitle => '태그 삭제';

  @override
  String tagDeleteTarget(String name) {
    return '‘$name’ 태그를 삭제합니다.';
  }

  @override
  String tagDeleteWarning(int count) {
    return '$count개 파일에 부여된 이 태그의 값이 모두 함께 제거되며, 되돌릴 수 없습니다.';
  }

  @override
  String tagMergeTitle(String name) {
    return '‘$name’에 합치기';
  }

  @override
  String tagMergeDescription(String name) {
    return '아래에서 고른 태그의 부여 기록을 ‘$name’ 태그로 옮기고, 고른 태그들은 제거합니다. ‘$name’의 이름과 색이 유지됩니다.';
  }

  @override
  String tagMergeSingleValueNote(String name) {
    return '같은 파일에 두 태그가 모두 있으면 ‘$name’의 값을 유지하고 합쳐지는 태그 쪽 값은 버립니다.';
  }

  @override
  String get tagMergeConfirm => '합치기';

  @override
  String tagMergeFailed(String error) {
    return '합치지 못했습니다: $error';
  }

  @override
  String get tagNameRequired => '이름을 입력해주세요.';

  @override
  String get tagSaveFailed => '저장하지 못했습니다(이름이 중복일 수 있습니다).';

  @override
  String get tagEditTitle => '태그 편집';

  @override
  String get tagValueTypeField => '값 유형';

  @override
  String get tagColorField => '색상';

  @override
  String get tagAllowMultiple => '다중 부여 허용';

  @override
  String get tagAllowMultipleDetail => '한 파일에 이 태그를 여러 번 붙일 수 있게 합니다.';

  @override
  String get tagColorCustom => '직접 고르기';

  @override
  String get tagManageTitle => '태그 관리';

  @override
  String get tagManageOrderNote =>
      '위에 있는 태그일수록 목록 행의 앞에 표시됩니다. 시스템 태그는 파일에서 자동으로 파생되어 표시 여부만 켜고 끌 수 있고, 기본적으로 사용자 태그 뒤에 놓이지만 원하는 자리로 끌어 옮길 수 있습니다.';

  @override
  String get tagBadgeMultiple => '다중 부여';

  @override
  String get tagBadgeEditable => '수정 가능';

  @override
  String tagBadgeEditableWithType(String type) {
    return '수정 가능 · $type';
  }

  @override
  String get tagOrderTitle => '태그 표시 순서';

  @override
  String get tagOrderNote =>
      '위에 있는 태그일수록 목록 행의 앞에 표시됩니다. 시스템 태그는 기본적으로 사용자 태그 뒤에 놓이지만, 원하는 자리로 끌어 옮길 수 있습니다.';

  @override
  String get thumbnailTagTitle => '썸네일 태그';

  @override
  String get tagManageOpenFolderFirst => '폴더를 먼저 열어주세요.';

  @override
  String tagManageLoadFailed(String error) {
    return '태그를 불러오지 못했습니다: $error';
  }

  @override
  String get tagManageEmpty => '아직 만든 태그가 없습니다.';

  @override
  String get systemTagSection => '시스템 태그';

  @override
  String get systemTagSectionNote =>
      '파일에서 자동으로 파생되는 태그입니다. 표시 여부만 켜고 끌 수 있습니다.';

  @override
  String get rowPresets => '프리셋';

  @override
  String get rowFilter => '필터';

  @override
  String get rowSort => '정렬';

  @override
  String get rowGroup => '그룹';

  @override
  String get presetSaveTooltip => '현재 조건을 프리셋으로 저장';

  @override
  String get filterAddTooltip => '필터 조건 추가';

  @override
  String get filterClearTooltip => '필터 조건 모두 지우기';

  @override
  String get sortAddTooltip => '정렬 기준 추가';

  @override
  String get sortClearTooltip => '정렬 기준 모두 지우기';

  @override
  String get groupAddTooltip => '그룹 기준 추가';

  @override
  String get groupClearTooltip => '그룹 기준 모두 지우기';

  @override
  String get filterDateRequired => '날짜를 선택하세요.';

  @override
  String get filterNumberRequired => '숫자를 입력하세요.';

  @override
  String get filterConditionAddTitle => '필터 조건 추가';

  @override
  String get filterConditionEditTitle => '필터 조건 편집';

  @override
  String get filterIncludeSegment => '표시';

  @override
  String get filterExcludeSegment => '제외';

  @override
  String get filterOperatorField => '연산';

  @override
  String get filterPickDate => '날짜 선택';

  @override
  String get filterPickDateButton => '선택';

  @override
  String get filterValueField => '값';

  @override
  String get sortKeyAddTitle => '정렬 기준 추가';

  @override
  String get sortLabelNote => '라벨 태그는 정렬 방법과 무관하게 부여된 항목을 위로 정렬합니다.';

  @override
  String get sortAscending => '오름차순';

  @override
  String get sortDescending => '내림차순';

  @override
  String get sortRandom => '무작위';

  @override
  String get sortRandomNote =>
      '값의 순서 대신 무작위로 섞습니다. 값이 같은 항목끼리는 흐트러지지 않아 뒤 단계의 정렬이 그대로 적용됩니다.';

  @override
  String get groupKeyAddTitle => '그룹 기준 추가';

  @override
  String get commonAdd => '추가';

  @override
  String presetAppliedWithDropped(int count) {
    return '없는 태그를 가리키는 항목 $count개는 빼고 불러왔습니다.';
  }

  @override
  String get presetRenameTitle => '프리셋 이름 변경';

  @override
  String get presetDeleteTitle => '프리셋 삭제';

  @override
  String presetDeleteBody(String name) {
    return '‘$name’ 프리셋을 지웁니다. 지금 걸린 조건은 그대로 남습니다.';
  }

  @override
  String get presetMenuRename => '이름 변경…';

  @override
  String get presetMenuOverwrite => '현재 조건·표시로 덮어쓰기';

  @override
  String presetSummaryFilter(String value) {
    return '필터: $value';
  }

  @override
  String presetSummarySort(String value) {
    return '정렬: $value';
  }

  @override
  String presetSummaryGroup(String value) {
    return '그룹: $value';
  }

  @override
  String presetSummaryName(String value) {
    return '이름: $value';
  }

  @override
  String presetSummarySubtitle(String value) {
    return '부제: $value';
  }

  @override
  String presetSummaryThumbnail(String value) {
    return '썸네일: $value';
  }

  @override
  String get sortDefaultByName => '기본(이름순)';

  @override
  String get groupNotGrouped => '묶지 않음';

  @override
  String get sourceDefaultName => '파일 이름';

  @override
  String get sourceDefaultSubtitle => '경로';

  @override
  String get sourceDefaultThumbnail => '기본';

  @override
  String get presetSaveTitle => '현재 조건·표시를 프리셋으로 저장';

  @override
  String get presetOverwriteHelper => '같은 이름의 프리셋을 덮어씁니다.';

  @override
  String get presetSaveOverwrite => '덮어쓰기';

  @override
  String get rowSubtitle => '부제';

  @override
  String get rowThumbnail => '썸네일';

  @override
  String sourceMissingTag(int tagId) {
    return '(없는 태그 $tagId)';
  }

  @override
  String get nameTagTitle => '이름 태그';

  @override
  String get nameTagNote =>
      '목록의 이름 자리에 보일 값의 우선순위입니다. 위에서 아래로 훑어 처음으로 글자를 내는 태그의 값을 씁니다. 어느 태그도 못 내면 파일 이름을 씁니다. 이 설정은 조건 프리셋에 함께 담겨, 프리셋을 부르면 같이 바뀝니다.';

  @override
  String get nameTagEmpty =>
      '지정한 태그가 없습니다. 아래에서 태그를 추가하세요.\n(비우면 파일 이름을 그대로 씁니다.)';

  @override
  String get subtitleTagTitle => '부제 태그';

  @override
  String get subtitleTagNote =>
      '목록의 이름 아래 줄에 보일 값의 우선순위입니다. 위에서 아래로 훑어 처음으로 글자를 내는 태그의 값을 씁니다. 어느 태그도 못 내면 경로를 씁니다. 이 설정은 조건 프리셋에 함께 담겨, 프리셋을 부르면 같이 바뀝니다.';

  @override
  String get subtitleTagEmpty =>
      '지정한 태그가 없습니다. 아래에서 태그를 추가하세요.\n(비우면 경로를 그대로 씁니다.)';

  @override
  String get thumbnailTagNote =>
      '썸네일 출처의 우선순위입니다. 위에서 아래로 훑어 처음으로 이미지를 내는 출처를 씁니다. 어느 태그도 못 내면 기본 썸네일(자기 이미지·폴더 대표)을 씁니다. 링크·이미지 유형 태그는 태그 관리에서 만듭니다. 이 설정은 조건 프리셋에 함께 담겨, 프리셋을 부르면 같이 바뀝니다.';

  @override
  String get thumbnailTagEmpty =>
      '지정한 출처가 없습니다. 아래에서 태그를 추가하세요.\n(비우면 기본 썸네일만 씁니다.)';

  @override
  String get keywordDeleteTitle => '키워드 삭제';

  @override
  String keywordDeleteBody(String name) {
    return '‘$name’ 키워드와 그 태그를 지웁니다. 되돌릴 수 없습니다.';
  }

  @override
  String get linkTargetPickerTitle => '링크 대상 선택';

  @override
  String get linkTargetSearchHint => '파일 이름으로 검색';

  @override
  String get linkTargetNoMatch => '일치하는 파일이 없습니다.';

  @override
  String get tagValueNumberRequired => '숫자를 입력해주세요.';

  @override
  String tagValuePromptTitle(String name) {
    return '‘$name’ 값';
  }

  @override
  String get tagValueField => '값';

  @override
  String get tagValueNumberHelper => '비워두면 기본값이 채워집니다.';

  @override
  String get tagValueTextHelper => '빈 값도 저장할 수 있습니다.';

  @override
  String get assignedTags => '부여된 태그';

  @override
  String get assignedTagsEmpty => '아직 부여된 태그가 없습니다.';

  @override
  String get assignNoDefinitions => '먼저 태그 관리에서 태그를 만들어주세요.';

  @override
  String assignFileCount(int count, int total) {
    return '$count/$total 파일';
  }

  @override
  String get assignMixedValue => '값 혼합';

  @override
  String get assignSetValueForAll => '값을 모두 이 값으로 설정';

  @override
  String get assignUnassignAll => '모두 해제';

  @override
  String get assignConfirm => '부여';

  @override
  String get assignLinkNoTarget => '대상 미선택';

  @override
  String get assignLinkPick => '대상 선택';

  @override
  String get assignNoImage => '이미지 없음';

  @override
  String get assignImagePick => '이미지 선택';

  @override
  String get assignImageChange => '이미지 변경';

  @override
  String get assignDateToday => '오늘 (미선택)';

  @override
  String get assignLinkRequired => '링크 대상을 선택하세요.';

  @override
  String get assignImageRequired => '이미지를 선택하세요.';

  @override
  String get scanning => '스캔 중…';

  @override
  String scanningSeen(int seen) {
    return '스캔 중… 항목 $seen개 확인';
  }

  @override
  String scanningSeenIndexed(int seen, int indexed) {
    return '스캔 중… 항목 $seen개 확인 · 파일 $indexed개 읽음';
  }

  @override
  String get statusNoFolder => '열린 폴더 없음';

  @override
  String get statusLoading => '목록 불러오는 중…';

  @override
  String statusItemCount(int count) {
    return '항목 $count개';
  }

  @override
  String statusSelectedCount(int count) {
    return '$count개 선택';
  }

  @override
  String get statusClearSelection => '해제';

  @override
  String statusFilterCount(int count) {
    return '필터 $count';
  }

  @override
  String statusSortCount(int count) {
    return '정렬 $count';
  }

  @override
  String get statusDbConnected => 'DB 연결됨';

  @override
  String get statusDbDisconnected => 'DB 미연결';

  @override
  String get statusHidePreview => '프리뷰 숨기기';

  @override
  String get statusShowPreview => '프리뷰 보기';

  @override
  String get statusUpdateHint => '눌러 릴리즈 페이지를 엽니다.';

  @override
  String statusNewVersion(String version) {
    return '새 버전 $version';
  }

  @override
  String get statusSettingsUnsavedHint =>
      '설정 파일을 쓸 수 없어 테마와 최근 폴더 목록이 이번 실행 동안만 유지됩니다.';

  @override
  String get statusSettingsUnsaved => '설정이 저장되지 않는 중';

  @override
  String get statusExternalHintWithFailures =>
      '외부 앱이 요청한 태그 변경입니다. 실패한 항목은 큐 파일에 사유가 남아 있습니다.';

  @override
  String get statusExternalHint => '외부 앱이 요청한 태그 변경입니다.';

  @override
  String statusExternalApplied(int count) {
    return '외부 적용 $count';
  }

  @override
  String statusExternalFailed(int count) {
    return '실패 $count';
  }

  @override
  String listLoadFailed(String error) {
    return '목록을 불러오지 못했습니다: $error';
  }

  @override
  String get listEmptyFiltered => '필터 조건에 맞는 파일이 없습니다.';

  @override
  String get listEmptyFolder => '이 폴더에는 표시할 파일이 없습니다.';

  @override
  String get listEmptyGroup => '이 그룹에는 표시할 항목이 없습니다.';

  @override
  String get treeCollapse => '접기';

  @override
  String get treeExpand => '펼치기';

  @override
  String get markMissing => '연결 끊김 — 원본 파일을 찾아 태그를 재연결하세요';

  @override
  String get markOpaqueFolder => '내부 감춤 — 메뉴에서 ‘내부 관리’로 펼치기';

  @override
  String get subtitleKeyword => '키워드';

  @override
  String groupUnclassified(String name) {
    return '$name · (미분류)';
  }

  @override
  String get detailColumnAdd => '추가…';

  @override
  String get detailColumnRemove => '제거';

  @override
  String get iconViewAll => '전체';

  @override
  String get iconViewUp => '상위로';

  @override
  String previewSelectedCount(int count) {
    return '$count개 선택됨';
  }

  @override
  String get previewEmpty => '항목을 선택하면 미리보기가 표시됩니다';

  @override
  String get sheetFolderManageTitle => '폴더 관리 방식';

  @override
  String get sheetFolderOpaque => '폴더만 관리';

  @override
  String get sheetFolderOpaqueDetail => '폴더 하나로만 다루고 내부는 감춥니다.';

  @override
  String get sheetFolderManagedDetail => '직속 내용만 인덱싱합니다.';

  @override
  String get sheetFolderRecursiveDetail => '하위 폴더까지 이어서 인덱싱합니다.';

  @override
  String get reconnectTitle => '원본 파일 찾기';

  @override
  String reconnectPrompt(String name) {
    return '‘$name’의 태그를 옮길 원본 파일을 고르세요. 이름이 비슷한 후보가 위에 옵니다. 원본이 없으면 \"보존 취소\"로 태그를 제거할 수 있습니다.';
  }

  @override
  String get reconnectSearchHint => '경로로 검색';

  @override
  String get reconnectNoCandidates => '연결할 수 있는(태그 없는) 후보 노드가 없습니다.';

  @override
  String get reconnectNoMatch => '검색 결과가 없습니다.';

  @override
  String get reconnectRemove => '보존 취소(제거)';

  @override
  String get exportTitle => '태그 내보내기';

  @override
  String exportPrompt(int count) {
    return '$count개 항목의 태그를 요청함 파일 하나로 내보냅니다. 받는 쪽은 그 파일을 자기 폴더의 요청함에 넣기만 하면 됩니다.';
  }

  @override
  String get exportTagsToSend => '내보낼 태그';

  @override
  String get exportSelectAll => '모두';

  @override
  String get exportSelectNone => '해제';

  @override
  String get exportNoCandidates => '고른 항목에 붙은 태그가 없습니다.';

  @override
  String get exportIncludeValues => '태그값 포함';

  @override
  String get exportIncludeValuesDetail => '끄면 태그만 붙고 값은 비어 갑니다.';

  @override
  String get exportIncludeImages => '이미지 파일 포함';

  @override
  String get exportIncludeImagesDetail => '커스텀 썸네일 이미지를 요청 파일 옆에 함께 씁니다.';

  @override
  String get exportConfirm => '내보내기…';

  @override
  String get systemTagFileSize => '크기';

  @override
  String get systemTagModifiedTime => '수정 시각';

  @override
  String get systemTagExtension => '확장자';

  @override
  String get systemTagImageWidth => '이미지 너비';

  @override
  String get systemTagImageHeight => '이미지 높이';

  @override
  String get systemTagFileName => '파일 이름';

  @override
  String get systemTagChildFileCount => '내부 파일 수량';

  @override
  String get systemTagKeyword => '키워드';

  @override
  String get systemTagUnresolvedLink => '미해결 링크';

  @override
  String get groupFolderHierarchy => '폴더 계층';

  @override
  String get keywordNameEmpty => '키워드 이름을 입력하세요.';

  @override
  String get keywordNameSeparator => '이름에 경로 구분자(/ \\)는 쓸 수 없습니다.';

  @override
  String get keywordNameDuplicate => '같은 이름의 키워드가 이미 있습니다.';

  @override
  String get renameTargetExists => '같은 이름의 항목이 이미 있습니다.';

  @override
  String get revealUnsupported => '이 플랫폼에서는 파일 관리자를 열 수 없습니다.';
}
