/// 콘솔이 밖으로 내는 것 — 종료 코드와 판정의 두 가지 표현.
///
/// **사람용과 기계용을 가른다.** `--json`을 준 쪽은 다른 도구·AI가 결과를 받아 다음
/// 동작을 하려는 자리이므로 형태가 흔들리면 안 되고, 주지 않은 쪽은 터미널에서 눈으로
/// 읽는 자리다. 두 표현을 한곳에 두어 한쪽만 고쳐지는 일을 막는다.
///
/// **사유와 세부는 어느 쪽에서도 번역하지 않는다.** 기계가 분기하는 값인 데다, 사람이
/// 읽는 자리에서도 어느 갈래인지는 문장보다 이름이 분명하다 — 그 갈래를 낸 계층이
/// 순수 Dart라 문장을 지을 수 없는 것과 같은 자리다.
///
/// 순수 변환이라 파일도 DB도 모른다 — 테스트가 판정만 지어 넣고 문장을 확인한다.
library;

import '../data/commands/command_json.dart';
import '../domain/usecases/apply_external_commands.dart';
import '../l10n/console_strings.dart';

// ── 종료 코드 ──
//
// 셸 관례(`sysexits`)를 따른다. 스크립트가 분기하는 자리라, "왜 안 됐는가"를 표준
// 출력이 아니라 **코드로** 답할 수 있어야 한다.

/// 다 됐다.
const int exitOk = 0;

/// 명령을 잘못 썼다(인자 수·모르는 옵션).
const int exitUsage = 64;

/// 거부됐다. 기다려도 달라지지 않는다.
const int exitRejected = 65;

/// 관리 폴더가 아니다.
const int exitNoWorkspace = 66;

/// 지금은 할 수 없다 — 다른 프로세스가 이미 전체 스캔을 돌리고 있다.
const int exitBusy = 69;

/// 파일을 읽고 쓰지 못했다.
const int exitIoError = 74;

/// 인덱스가 대상을 아직 모른다. 거부가 아니라 **스캔이 있어야 판정이 선다**는 뜻이다.
const int exitHeld = 75;

/// 판정 묶음 하나의 종료 코드.
///
/// **거부가 보류를 이긴다.** 보류는 스캔 뒤 다시 넣으면 되는 것이라 스크립트가
/// 재시도로 받아야 하지만, 한 항목이라도 거부됐다면 그 묶음은 다시 넣어도 같은 자리에서
/// 걸린다 — 재시도로 감추면 안 된다.
int exitCodeFor(List<ExternalCommandResult> results) {
  var held = false;
  for (final result in results) {
    switch (result) {
      case CommandRejected():
        return exitRejected;
      case CommandHeld():
        held = true;
      case CommandApplied():
        break;
    }
  }
  return held ? exitHeld : exitOk;
}

// ── 명령이 서기도 전에 끝난 실패 ──

/// 콘솔이 낸 실패의 갈래.
///
/// **문장이 아니라 이름**이라 받는 도구가 분기할 수 있다 — 적용 판정의
/// [CommandFailureReason]과 같은 원칙이고, 그쪽이 덮지 못하는 실패(명령을 세우기도
/// 전에 끝나는 것)를 여기 든다. 종료 코드만으로는 "잘못 썼다" 안의 무엇이 잘못됐는지가
/// 갈리지 않으므로, `--json`을 준 실행은 이 이름을 받는다.
enum ConsoleFailure {
  /// 가리킨 자리가 관리 폴더가 아니다.
  notWorkspace,

  /// 관리 폴더를 읽지 못했다.
  workspaceUnreadable,

  /// 다른 프로세스가 이미 전체 스캔을 돌리고 있다.
  scanBusy,

  /// 파일을 읽지 못했다.
  fileUnreadable,

  /// 이미지로 읽히지 않는다.
  notAnImage,

  /// 명령을 잘못 썼다(인자 수·모르는 옵션). [subject]가 파서의 말을 싣는다.
  usage,

  /// 낼 수량을 정하는 옵션을 잘못 썼다.
  badWindow,

  /// 조건 조각을 읽지 못했다.
  badCondition,

  /// 조건에 아무것도 걸리지 않았다.
  noMatch,

  /// 인덱스에 그 대상이 없다.
  noSuchTarget,

  /// 시스템 태그는 콘솔이 다루지 않는다.
  systemTag,

  /// 그 이름의 태그가 없다.
  tagMissing,

  /// 옮겨 갈 이름을 이미 다른 태그가 쓰고 있다.
  nameTaken,

  /// 같은 이름의 태그가 다른 값 유형으로 이미 있다.
  valueTypeMismatch,

  /// 값 유형 이름을 모른다.
  unknownValueType,

  /// 색을 읽지 못했다.
  badColor,

  /// 낼 문구를 가진 언어가 아니다.
  unknownLanguage,

  /// 설정 키 이름을 모른다.
  unknownConfigKey,

  /// 계정을 알 수 없어 계정별 자리에 적지 못했다.
  noAccount,

  /// 설정 파일을 쓰지 못했다.
  configWriteFailed,
}

/// 실패 하나의 기계용 표현. 판정의 실패([resultToJson]의 `failure`)와 **같은 키를
/// 쓴다** — 받는 쪽이 어디서 온 실패든 같은 자리를 보면 된다.
Map<String, dynamic> consoleFailureToJson(
  ConsoleFailure reason, {
  String? subject,
}) => {
  kFailure: {kReason: reason.name, if (subject != null) kSubject: subject},
};

// ── 판정의 두 표현 ──

/// 판정 하나의 기계용 표현. **명령 파일과 같은 모양에 결과만 얹는다** — 거부된 항목은
/// 사유를 보고 고쳐 그대로 다시 먹일 수 있다.
Map<String, dynamic> resultToJson(ExternalCommandResult result) => {
  ...commandToJson(result.command),
  kResult: switch (result) {
    CommandApplied() => resultApplied,
    CommandHeld() => resultHeld,
    CommandRejected() => resultRejected,
  },
  if (result case CommandRejected(:final reason, :final detail, :final subject))
    kFailure: {
      kReason: reason.name,
      if (detail != null) kDetail: detail.name,
      if (subject != null) kSubject: subject,
    },
};

/// 명령으로 읽어 내지 못한 항목의 기계용 표현.
Map<String, dynamic> unreadableToJson(UnreadableCommand record) => {
  kResult: resultUnreadable,
  kFailure: {
    kReason: record.error.name,
    if (record.subject != null) kSubject: record.subject,
  },
};

/// 판정 하나의 사람용 한 줄. 앞머리에 결과, 그다음 대상과 태그, 사유가 있으면 뒤에.
String resultLine(ExternalCommandResult result, ConsoleStrings strings) {
  final command = result.command;
  final value = command.value;
  final target =
      '${command.targetPath}\t${command.tagName}'
      '${value == null ? '' : '=$value'}';
  return switch (result) {
    CommandApplied() => '${strings.markApplied}\t$target',
    CommandHeld() => '${strings.markHeld}\t$target\t${strings.notIndexed}',
    CommandRejected(:final reason, :final detail, :final subject) =>
      '${strings.markRejected}\t$target\t${reason.name}'
          '${detail == null ? '' : ' — ${branchLabel(detail.name, subject)}'}',
  };
}

/// 명령으로 읽어 내지도 못한 항목의 사람용 한 줄.
String unreadableLine(UnreadableCommand record, ConsoleStrings strings) =>
    '${strings.markUnreadable}\t'
    '${branchLabel(record.error.name, record.subject)}';

/// 갈래 하나의 사람용 표기. 이름 뒤에 짚어 줄 원문이 있으면 붙인다.
String branchLabel(String branch, String? subject) =>
    subject == null ? branch : '$branch: $subject';

/// 판정 묶음의 갯수 줄. 사람용 출력의 맨 윗줄이다.
String summaryLine(
  List<ExternalCommandResult> results,
  ConsoleStrings strings, {
  int unreadable = 0,
}) {
  var applied = 0;
  var held = 0;
  var rejected = 0;
  for (final result in results) {
    switch (result) {
      case CommandApplied():
        applied++;
      case CommandHeld():
        held++;
      case CommandRejected():
        rejected++;
    }
  }
  return '${strings.markApplied} $applied · ${strings.markHeld} $held'
      ' · ${strings.markRejected} $rejected'
      '${unreadable == 0 ? '' : ' · ${strings.markUnreadable} $unreadable'}';
}

// ── 기계용 출력의 키 ──
//
// 명령 필드와 섞이지 않는 이름을 쓴다.

const String kResult = 'result';

/// 목록 대신 갯수만 낼 때의 유일한 키. 조회가 늘 배열을 내는 것과 가르려고 객체에
/// 담는다 — 받는 쪽이 모양만 보고 어느 쪽인지 안다.
const String kCount = 'count';
const String kFailure = 'failure';
const String kReason = 'reason';
const String kDetail = 'detail';
const String kSubject = 'subject';

const String resultApplied = 'applied';
const String resultHeld = 'held';
const String resultRejected = 'rejected';

/// 판정이 아니라 **명령으로 읽어 내지 못한** 항목. 명령 파일에서만 난다.
const String resultUnreadable = 'unreadable';
