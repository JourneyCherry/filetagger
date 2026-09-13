/// 콘솔 문구의 **원문**(템플릿 언어). 다른 언어는 이것의 번역본이다.
library;

import '../domain/entities/file_filter.dart';
import 'console_strings.dart';

class ConsoleStringsKo extends ConsoleStrings {
  const ConsoleStringsKo();

  @override
  String get languageCode => 'ko';

  @override
  String get tokenPath => '경로';
  @override
  String get tokenTarget => '대상';
  @override
  String get tokenTag => '태그';
  @override
  String get tokenTagName => '이름';
  @override
  String get tokenNewName => '새 이름';
  @override
  String get tokenChanges => '바꿀 것';
  @override
  String get tokenValue => '값';
  @override
  String get tokenValueType => '값 유형';
  @override
  String get tokenCondition => '조건';
  @override
  String get tokenCriterion => '기준';
  @override
  String get tokenCount => '수';
  @override
  String get tokenRange => '시작:끝';
  @override
  String get tokenFile => '파일';
  @override
  String get tokenImageFile => '이미지 파일';
  @override
  String get tokenLanguage => '언어';
  @override
  String get tokenKey => '키';

  @override
  String get runnerDescription => 'File Tagger 관리 폴더의 태그를 명령 한 줄로 다룬다.';

  @override
  String get optWorkspaceHelp =>
      '관리 폴더. 주지 않으면 workspace 설정을, 그것도 없으면 현재 디렉토리를 쓴다.';
  @override
  String get optJsonHelp => '사람이 아니라 기계가 읽는 JSON으로 낸다.';
  @override
  String get optLangHelp => '콘솔이 낼 언어. 주지 않으면 설정을, 설정도 없으면 OS 설정을 따른다.';
  @override
  String get optAutoScanHelp => '인덱스가 대상을 모르면 한 번 훑고 다시 판정한다.';
  @override
  String get optCountHelp => '목록 대신 갯수만 낸다.';
  @override
  String get labelTotal => '합계';

  @override
  String get optFilterHelp => '태그 조건으로 대상을 고른다. 화면의 필터 줄과 같은 문법.';
  @override
  String get optFilterHelpHelp => '조건·정렬·묶기 문법을 낸다.';
  @override
  String get filterHelpHeading => '조건 문법 — 화면의 조건 줄과 같다.';
  @override
  String filterHelpChunks(String quote, String escape) =>
      '조각 하나가 조건 하나이고, 조각은 공백으로 나뉜다.\n'
      '공백이 든 이름·값은 $quote로 감싼다. $quote와 $escape 자신은 앞에 $escape를 붙인다.';
  @override
  String filterHelpConditions(String excludePrefix, String orPrefix) =>
      '  <태그>                그 태그가 붙어 있으면 걸린다\n'
      '  <태그><연산자><값>    값을 견준다\n'
      '  $excludePrefix<태그 조건>          걸리는 것을 숨긴다(제외)\n'
      '  $orPrefix<태그 조건>          앞 조건과 한 묶음으로 잇는다(OR — 조각 맨 앞에 붙인다)\n'
      '\n'
      '  조건은 모두 만족해야 걸리고, 이어붙인 것끼리는 하나만 만족하면 된다.\n'
      '\n'
      '  연산자';
  @override
  String filterHelpAlias(String aliases, String canonical) =>
      '($aliases 도 $canonical 으로 읽는다)';
  @override
  String filterHelpMultiValue(String everyValueOperators) =>
      '값이 여럿인 태그는 하나라도 맞으면 걸린다. $everyValueOperators 만 모든 값이 그래야 한다.';
  @override
  String filterOperatorName(FilterOperator op) => switch (op) {
    FilterOperator.exists => '있음',
    FilterOperator.equals => '같음',
    FilterOperator.notEquals => '다름',
    FilterOperator.lessThan => '미만',
    FilterOperator.lessOrEqual => '이하',
    FilterOperator.greaterThan => '초과',
    FilterOperator.greaterOrEqual => '이상',
    FilterOperator.contains => '포함',
    FilterOperator.notContains => '미포함',
  };
  @override
  String filterHelpSort(String descendingPrefix, String randomPrefix) =>
      '  <태그>                오름차순\n'
      '  $descendingPrefix<태그>               내림차순\n'
      '  $randomPrefix<태그>               무작위';
  @override
  String filterHelpGroup(String folderHierarchyName) =>
      '  <태그>                그 태그값으로 묶는다\n'
      '  $folderHierarchyName                폴더 계층으로 묶는다';
  @override
  String get optSortHelp => '태그값으로 정렬한다(앞선 기준이 이긴다).';
  @override
  String get optGroupHelp => '태그값·폴더 계층으로 묶어 낸다.';

  @override
  String get labelBadCondition => '조건 오류';

  @override
  String get optTopHelp => '앞에서 이만큼만 낸다.';
  @override
  String get optTailHelp => '뒤에서 이만큼만 낸다.';
  @override
  String get optRangeHelp => '이 자리부터 저 자리까지 낸다(1부터 세고 양끝을 포함한다).';
  @override
  String get windowConflict => '낼 수량을 정하는 옵션은 하나만 쓸 수 있습니다.';
  @override
  String badRange(String raw) => '범위는 "$tokenRange" 꼴의 1 이상 정수여야 합니다: $raw';
  @override
  String badCount(String option, String raw) =>
      '--$option은 1 이상의 정수여야 합니다: $raw';

  @override
  String notWorkspace(String path) => '관리 폴더가 아닙니다: $path';

  @override
  String get markApplied => '적용';
  @override
  String get markHeld => '보류';
  @override
  String get markRejected => '거부';
  @override
  String get markUnreadable => '못 읽음';

  @override
  String get notIndexed => '인덱스가 아직 대상을 모릅니다. scan이 먼저 필요합니다.';

  @override
  String get columnScope => '자리';
  @override
  String get columnKey => '키';
  @override
  String get columnValue => '값';
  @override
  String get columnName => '이름';
  @override
  String get columnValueType => '값 유형';
  @override
  String get columnMultiple => '다중';
  @override
  String get columnColor => '색';
  @override
  String get columnAssignments => '부여 수';
  @override
  String get columnSource => '출처';
  @override
  String get columnFile => '파일';
  @override
  String get columnEditable => '수정';
  @override
  String get columnId => 'id';
  @override
  String get columnTagId => '태그 id';

  @override
  String get tagDescription => '태그 정의를 만들고 고치고 지우고 살펴본다.';
  @override
  String get tagAddDescription => '태그 정의를 만든다. 같은 이름·값 유형이 이미 있으면 그대로 둔다.';
  @override
  String get tagModifyDescription => '태그 정의의 이름·값 유형·다중 허용·색을 고친다.';
  @override
  String get tagDeleteDescription => '태그 정의를 지운다. 그 태그의 부여도 함께 사라진다.';
  @override
  String get tagShowDescription =>
      '사용자가 만든 태그 정의를 낸다(파생되는 시스템 태그는 systemtags가 낸다).';

  @override
  String get optMultipleAddHelp => '한 파일에 여러 번 부여할 수 있게 한다.';
  @override
  String get optMultipleModifyHelp => '한 파일에 여러 번 부여할 수 있는지.';
  @override
  String get optColorHelp => '칩 표시색.';
  @override
  String get optClearColorHelp => '칩 표시색을 지운다.';
  @override
  String get optRenameHelp => '태그 이름을 바꾼다.';
  @override
  String get optTypeHelp => '값 유형을 바꾼다. 이미 붙은 값은 그대로 남으므로 새 유형으로 읽히지 않을 수 있다.';
  @override
  String get valueTypesHeading => '값 유형:';

  @override
  String get verbAdded => '만듦';
  @override
  String get verbKept => '그대로';
  @override
  String get verbUpdated => '고침';
  @override
  String get verbDeleted => '지움';

  @override
  String get labelMultiple => '다중';
  @override
  String get labelNone => '-';
  @override
  String get labelRemovedAssignments => '부여 제거';

  @override
  String get needTagName => '태그 이름이 필요합니다.';
  @override
  String get needNameAndType => '태그 이름과 값 유형이 필요합니다.';
  @override
  String get tooManyNames => '태그 이름은 하나만 받습니다.';
  @override
  String systemTagNotEditable(String name) => '시스템 태그는 콘솔에서 다룰 수 없습니다: $name';
  @override
  String noSuchTag(String name) => '그 이름의 태그가 없습니다: $name';
  @override
  String nameTaken(String name) => '그 이름의 태그가 이미 있습니다: $name';
  @override
  String typeMismatch(String type) => '같은 이름의 태그가 다른 값 유형으로 이미 있습니다: $type';
  @override
  String unknownValueType(String raw) => '알 수 없는 값 유형입니다: $raw';
  @override
  String badColor(String raw) => '색을 16진 표기로 읽지 못했습니다: $raw';
  @override
  String get colorConflict => '색을 정하면서 동시에 지울 수는 없습니다.';

  @override
  String get listDescription => '파일·키워드에 붙은 태그를 부여하고 고치고 떼고 살펴본다.';
  @override
  String get listAddDescription => '태그를 부여한다. 다중 부여를 허용하는 태그면 값이 하나 더 붙는다.';
  @override
  String get listModifyDescription => '그 태그의 기존 부여를 걷어내고 준 값 하나로 둔다.';
  @override
  String get listDeleteDescription =>
      '부여를 뗀다. 값을 주면 값이 같은 부여만, 주지 않으면 그 태그 전부.';
  @override
  String get listShowDescription => '대상에 붙은 태그를, 또는 조건에 걸린 대상들을 낸다.';

  @override
  String get optKeywordHelp => '대상을 경로가 아니라 키워드 이름으로 읽는다.';
  @override
  String get optValueKeywordHelp => '링크 값을 경로가 아니라 키워드 이름으로 읽는다.';
  @override
  String get optCreateKeywordHelp => '지목한 키워드가 없으면 만들어 진행한다.';
  @override
  String get optKeepLinkHelp => '링크 대상을 찾지 못해도 적은 원문을 미해결 링크로 남긴다.';
  @override
  String get optSystemHelp =>
      '파생되는 시스템 태그를 조회에 함께 낸다. 내보내기에는 어느 쪽이든 담기지 않는다(받는 쪽이 거부한다).';
  @override
  String get optExportHelp =>
      '다른 관리 폴더에 먹일 수 있는 명령 파일(JSON)로 낸다. import가 이 형식을 읽는다.';
  @override
  String get optExportToHelp => '명령 파일을 이 자리에 쓰고, 딸린 이미지를 그 옆에 함께 놓는다.';
  @override
  String get labelImages => '이미지';
  @override
  String imagesNotBundled(int count) =>
      '이미지 $count개는 함께 나가지 못했습니다 — 자리를 지목해 내보내면 파일 옆에 함께 놓입니다.';
  @override
  String fileWriteFailed(String path) => '파일을 쓰지 못했습니다: $path';

  @override
  String get labelUser => '사용자';
  @override
  String get labelSystem => '시스템';
  @override
  String get labelUnclassified => '(미분류)';

  @override
  String get oneTargetOnly => '대상은 하나만 받습니다.';
  @override
  String get needTargetAndTag => '대상과 태그 이름이 필요합니다.';
  @override
  String get targetOrFilter => '대상을 직접 주면서 조건을 함께 줄 수는 없습니다.';
  @override
  String get keywordWithFilter => '조건으로 고를 때는 키워드 대상을 쓸 수 없습니다.';
  @override
  String keywordWithSameName(String raw, String keywordOption) =>
      '같은 이름의 키워드가 있습니다. 키워드를 지목하려면 $keywordOption을 함께 주십시오: $raw';
  @override
  String noSuchTarget(String raw) => '대상을 찾을 수 없습니다: $raw';
  @override
  String get noMatch => '조건에 걸린 대상이 없습니다.';

  @override
  String get scanDescription => '관리 폴더를 훑어 인덱스를 맞춘다.';
  @override
  String get labelNodes => '노드';
  @override
  String get labelUnreadableDirs => '못 읽은 폴더';
  @override
  String get labelNestedWorkspaces => '중첩 관리 폴더';
  @override
  String get labelScanning => '훑는 중';
  @override
  String get labelIndexed => '인덱싱';
  @override
  String workspaceUnreadable(String root) => '관리 폴더를 나열하지 못했습니다: $root';

  @override
  String get importDescription => '내보낸 명령 파일을 읽어 그대로 적용한다.';
  @override
  String get needCommandFile => '읽을 명령 파일 하나가 필요합니다.';
  @override
  String fileUnreadable(String path) => '파일을 읽지 못했습니다: $path';

  @override
  String get imageDescription => '바깥 이미지를 캐시에 등록하고 캐시 키와 관리 폴더 기준 경로를 낸다.';
  @override
  String get needImageFile => '등록할 이미지 파일 하나가 필요합니다.';
  @override
  String notAnImage(String path) => '이미지로 읽지 못했습니다: $path';

  @override
  String get pruneDescription => '없앤 시스템 태그를 가리키는 옛 참조를 보기 설정·프리셋에서 걷어낸다.';
  @override
  String get labelViewSettings => '보기 설정';
  @override
  String get labelPresets => '프리셋';

  @override
  String get statusDescription => '인덱스에 들어 있는 노드·키워드·태그의 수를 낸다.';
  @override
  String get labelKeywords => '키워드';
  @override
  String get labelTagDefinitions => '태그 정의';
  @override
  String get labelAssignments => '부여';

  @override
  String get systemTagsDescription => '조건에 쓸 수 있는 시스템 태그와 그 성질을 낸다.';
  @override
  String get labelEditable => '수정 가능';
  @override
  String get labelReadOnly => '읽기 전용';

  @override
  String get configDescription => '콘솔 자신의 설정을 살펴보고 고친다.';
  @override
  String get configShowDescription => '지금 서 있는 설정과 두 설정 파일의 자리를 낸다.';
  @override
  String get configSetDescription => '설정 하나를 적는다. 범위를 주지 않으면 계정별에 적는다.';
  @override
  String get configUnsetDescription => '설정 하나를 지운다. 범위를 주지 않으면 계정별에서 지운다.';

  @override
  String get configKeysHeading => '설정 키:';
  @override
  String get configKeyLangHelp => '콘솔이 낼 언어. --lang을 주지 않은 실행이 이 값을 쓴다.';
  @override
  String get configKeyWorkspaceHelp => '기본 관리 폴더. -C를 주지 않은 명령이 이 폴더를 연다.';

  @override
  String get optGlobalScopeHelp => '실행 파일 옆의 전역 설정에 적는다.';
  @override
  String get optUserScopeHelp => 'OS 계정별 설정에 적는다(기본).';

  @override
  String get labelGlobalScope => '전역';
  @override
  String get labelUserScope => '계정별';
  @override
  String get labelInForce => '지금';
  @override
  String get labelAccount => '계정';
  @override
  String get labelFromSystem => 'OS 설정';
  @override
  String get labelFromCurrentDir => '현재 디렉토리';
  @override
  String get labelNoAccount => '(계정 모름)';

  @override
  String get needConfigKey => '설정 키가 필요합니다.';
  @override
  String get needKeyAndValue => '설정 키와 값이 필요합니다.';
  @override
  String unknownConfigKey(String key) => '알 수 없는 설정 키입니다: $key';
  @override
  String unknownLanguage(String raw, Iterable<String> known) =>
      '문구를 갖지 않은 언어입니다: $raw (${known.join(' ')})';
  @override
  String configWriteFailed(String path) => '설정을 적지 못했습니다: $path';
  @override
  String get noAccountToWrite => '지금 계정의 이름을 알 수 없어 계정별로 적지 못합니다.';

  @override
  String takesNoArguments(String command) => '$command은(는) 인자를 받지 않습니다.';
}
