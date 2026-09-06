/// 콘솔이 내는 **사람용 문구**의 언어별 단일 출처.
///
/// **ARB가 아니라 여기 있는 이유**는 [system_tag_names.dart]와 같다 — ARB에서 생성된
/// `AppLocalizations`는 `package:flutter/widgets.dart`를 import하므로 Flutter를 링크하지
/// 않는 콘솔 진입점이 닿을 수 없다. 그래서 콘솔이 읽을 수 있는 **순수 Dart 표**를 따로
/// 둔다.
///
/// **기계가 보는 것은 여기 들지 않는다.** JSON의 키, `reason`·`detail` 같은 갈래 이름,
/// 값 유형 이름은 받는 도구가 분기하는 값이라 언어를 타면 안 된다. 여기 담기는 것은
/// 사람이 터미널에서 눈으로 읽는 것뿐이다.
///
/// **추상 getter로 두어 빠뜨림을 컴파일러가 잡는다.** 언어를 더하면 구현 클래스가
/// 하나 늘 뿐이고, 문구를 더하면 모든 언어가 그것을 채워야 컴파일된다 — 표를 맵으로
/// 두었을 때처럼 키가 조용히 비는 자리가 없다.
library;

import 'console_strings_en.dart';
import 'console_strings_ko.dart';

/// 템플릿 언어(`l10n.yaml`이 지목한 것과 같아야 한다). 모르는 언어를 만나면 이
/// 언어의 문구로 되돌아간다.
const String consoleTemplateLanguageCode = 'ko';

const Map<String, ConsoleStrings> _byLanguage = {
  'ko': ConsoleStringsKo(),
  'en': ConsoleStringsEn(),
};

/// 문구를 가진 언어 코드들. 지원 언어 목록과 어긋나지 않는지 테스트가 대조한다.
Set<String> get consoleStringLanguages => _byLanguage.keys.toSet();

/// [localeName]이 가리키는 언어의 문구.
///
/// `언어_지역` 형태도 받아 **언어 부분만** 본다. 모르는 언어면 템플릿 언어를 준다.
ConsoleStrings consoleStringsFor(String localeName) =>
    _byLanguage[consoleLanguageOf(localeName)] ??
    _byLanguage[consoleTemplateLanguageCode]!;

/// 로케일 이름에서 언어 부분만 뽑는다.
String consoleLanguageOf(String localeName) =>
    localeName.split(RegExp('[_-]')).first;

/// 콘솔이 내는 사람용 문구 한 벌.
///
/// 이름 규칙은 셋이다 — `token…`은 사용법에 `<…>`로 감싸 넣는 자리 이름,
/// `label…`은 출력 열에 붙는 짧은 표식, 나머지는 설명·오류 문장이다.
abstract class ConsoleStrings {
  const ConsoleStrings();

  /// 이 문구가 속한 언어 코드.
  String get languageCode;

  // ── 사용법에 넣는 자리 이름 ──

  String get tokenPath;
  String get tokenTarget;
  String get tokenTag;
  String get tokenTagName;
  String get tokenNewName;
  String get tokenChanges;
  String get tokenValue;
  String get tokenValueType;
  String get tokenCondition;
  String get tokenCriterion;
  String get tokenCount;
  String get tokenRange;
  String get tokenFile;
  String get tokenImageFile;
  String get tokenLanguage;
  String get tokenKey;

  // ── 표면 전체 ──

  String get runnerDescription;

  // ── 잎 명령이 함께 갖는 옵션 ──

  String get optWorkspaceHelp;
  String get optJsonHelp;
  String get optLangHelp;
  String get optAutoScanHelp;

  // ── 조건 계층 ──

  String get optFilterHelp;
  String get optSortHelp;
  String get optGroupHelp;

  /// 조건 조각을 읽지 못했음을 알리는 줄 앞머리.
  String get labelBadCondition;

  // ── 낼 수량 ──

  String get optTopHelp;
  String get optTailHelp;
  String get optRangeHelp;
  String get windowConflict;
  String badRange(String raw);
  String badCount(String option, String raw);

  // ── 관리 폴더 ──

  String notWorkspace(String path);

  // ── 판정의 사람용 표현 ──

  String get markApplied;
  String get markHeld;
  String get markRejected;
  String get markUnreadable;

  /// 보류가 무엇을 기다리는지. 사유 이름만으로는 다음에 무엇을 할지가 서지 않는다.
  String get notIndexed;

  // ── 표의 머리글 ──
  //
  // 열 이름은 기계용 JSON의 키와 같은 것을 가리키되, 사람이 읽는 말로 적는다.

  String get columnScope;
  String get columnKey;
  String get columnValue;
  String get columnName;
  String get columnValueType;
  String get columnMultiple;
  String get columnColor;
  String get columnAssignments;
  String get columnSource;
  String get columnFile;
  String get columnEditable;
  String get columnId;

  // ── `tag` ──

  String get tagDescription;
  String get tagAddDescription;
  String get tagModifyDescription;
  String get tagDeleteDescription;
  String get tagShowDescription;

  String get optMultipleAddHelp;
  String get optMultipleModifyHelp;
  String get optColorHelp;
  String get optClearColorHelp;
  String get optRenameHelp;
  String get optTypeHelp;

  String get verbAdded;
  String get verbKept;
  String get verbUpdated;
  String get verbDeleted;

  String get labelMultiple;

  /// 값이 없는 열에 두는 표식. 자리를 비우면 열이 밀려 `cut`·`awk`가 집지 못한다.
  String get labelNone;
  String get labelRemovedAssignments;

  String get needTagName;
  String get needNameAndType;
  String get tooManyNames;
  String systemTagNotEditable(String name);
  String noSuchTag(String name);
  String nameTaken(String name);
  String typeMismatch(String type);
  String unknownValueType(String raw);
  String badColor(String raw);
  String get colorConflict;

  // ── `list` ──

  String get listDescription;
  String get listAddDescription;
  String get listModifyDescription;
  String get listDeleteDescription;
  String get listShowDescription;

  String get optKeywordHelp;
  String get optValueKeywordHelp;
  String get optCreateKeywordHelp;
  String get optKeepLinkHelp;
  String get optSystemHelp;

  String get labelUser;
  String get labelSystem;
  String get labelUnclassified;

  String get oneTargetOnly;
  String get needTargetAndTag;
  String get targetOrFilter;
  String get keywordWithFilter;
  String noSuchTarget(String raw);
  String get noMatch;

  // ── `scan` ──

  String get scanDescription;
  String get labelNodes;
  String get labelUnreadableDirs;
  String get labelNestedWorkspaces;
  String get labelScanning;
  String get labelIndexed;
  String get scanBusy;
  String workspaceUnreadable(String root);

  // ── `import` ──

  String get importDescription;
  String get needCommandFile;
  String fileUnreadable(String path);

  // ── `image` ──

  String get imageDescription;
  String get needImageFile;
  String notAnImage(String path);

  // ── `status` ──

  String get statusDescription;
  String get labelKeywords;
  String get labelTagDefinitions;
  String get labelAssignments;

  // ── `systemtags` ──

  String get systemTagsDescription;
  String get labelEditable;
  String get labelReadOnly;

  // ── `config` ──

  String get configDescription;
  String get configShowDescription;
  String get configSetDescription;
  String get configUnsetDescription;

  /// 도움말 꼬리에 붙는 설정 키 목록의 머리.
  String get configKeysHeading;

  /// 설정 키 하나가 무엇을 정하는지. 키를 더하면 여기도 는다.
  String get configKeyLangHelp;
  String get configKeyWorkspaceHelp;

  String get optGlobalScopeHelp;
  String get optUserScopeHelp;

  String get labelGlobalScope;
  String get labelUserScope;

  /// 두 범위를 밟아 실제로 서게 된 값의 줄.
  String get labelInForce;

  /// 계정별 값을 가리키는 이름.
  String get labelAccount;

  /// 설정에 적힌 것이 없어 OS 로케일을 따르는 상태.
  String get labelFromSystem;

  /// 설정에 적힌 것이 없어 명령을 부른 자리를 따르는 상태.
  String get labelFromCurrentDir;

  /// 지금 계정이 무엇인지 환경이 알려 주지 않은 경우.
  String get labelNoAccount;

  String get needConfigKey;
  String get needKeyAndValue;
  String unknownConfigKey(String key);
  String unknownLanguage(String raw, Iterable<String> known);
  String configWriteFailed(String path);

  /// 계정을 알 수 없어 계정별 자리에 적지 못한 경우.
  String get noAccountToWrite;

  // ── 명령이 낸 사유에 붙이는 앞머리 ──

  /// 인자를 받지 않는 명령에 인자를 준 경우.
  String takesNoArguments(String command);
}
