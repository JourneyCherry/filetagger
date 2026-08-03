/// 외부 앱 연동 큐 파일 하나의 JSON 표현. 형식의 단일 출처다.
///
/// 도메인 엔티티([ExternalTagCommand])는 순수하게 두고 직렬화는 data 계층이 맡는
/// 배치다(조건 코덱 [query_json.dart]와 같다). 다만 이 형식은 **외부 앱과의 공개
/// 계약**이라, 설정 파일과 달리 사람이 열어 읽는 것을 전제로 들여쓰기해 쓴다.
///
/// **최상위는 객체 하나 또는 객체의 배열**이다. 배열은 한 파일에 여러 요청을 담는
/// 자리(내보내기 등)이고, 그때 결과 표기는 파일이 아니라 **항목 단위**가 된다 —
/// 성공한 항목만 빠지고 나머지는 제 표식을 단 채 남는다.
///
/// 읽기는 **예외를 던지지 않는다** — 형식 오류도 큐 항목의 실패이므로, 다른 실패와
/// 같은 경로(파일 안의 표식)로 기록돼야 하기 때문이다. 그래서 항목마다 결과를 세
/// 갈래([PendingCommand]·[MarkedCommand]·[UnreadableCommand])로 돌려준다.
library;

import 'dart:convert';

import '../../domain/entities/external_tag_command.dart';
import '../../domain/entities/tag_value_type.dart';
import '../settings/query_json.dart';

/// 큐 파일 하나를 읽어 낸 결과.
class CommandFile {
  const CommandFile({required this.items, required this.isArray});

  /// 파일에 담긴 항목들(배열이 아니면 하나).
  final List<ExternalCommandRecord> items;

  /// 원본 최상위가 배열이었는지. 되쓸 때 같은 모양을 지킨다.
  final bool isArray;
}

/// 큐 파일 안의 항목 하나를 읽어 낸 결과.
///
/// 어느 갈래든 **원본을 보존한 채 실패 표식만 얹어 되쓸 수 있다**([toJson]) —
/// 실패 항목은 이동·개명 없이 제자리에 남아, 외부 앱이 자기가 만든 경로 그대로
/// 다시 읽어 원인을 알 수 있어야 한다.
sealed class ExternalCommandRecord {
  const ExternalCommandRecord();

  /// 이 항목의 JSON 객체. [failure]를 주면 실패 표식을 얹는다. 앱이 모르는 키까지
  /// 원본 그대로 남긴다.
  Map<String, dynamic> toJson({CommandFailure? failure});
}

/// 명령으로 읽어 냈고 실패 표식이 없다 — 이번 패스에서 적용할 항목.
final class PendingCommand extends ExternalCommandRecord {
  const PendingCommand({required this.command, required this.source});

  final ExternalTagCommand command;

  /// 되쓸 때 보존할 원본 객체(앱이 해석하지 않는 키 포함).
  final Map<String, dynamic> source;

  @override
  Map<String, dynamic> toJson({CommandFailure? failure}) =>
      _withFailure(source, failure);
}

/// 이미 실패 표식이 적혀 있다 — 적용을 건너뛰고 보존 정리만 본다. 같은 실패를 앱이
/// 켜질 때마다 되풀이하지 않기 위해, 명령 필드는 읽어 보지도 않는다.
final class MarkedCommand extends ExternalCommandRecord {
  const MarkedCommand({required this.failure, required this.source});

  final CommandFailure failure;
  final Map<String, dynamic> source;

  @override
  Map<String, dynamic> toJson({CommandFailure? failure}) =>
      _withFailure(source, failure ?? this.failure);
}

/// 명령으로 읽어 내지 못했다 — 그 자리에 형식 오류 표식을 쓴다.
final class UnreadableCommand extends ExternalCommandRecord {
  const UnreadableCommand({required this.message, this.source, this.rawValue});

  /// 무엇이 어긋났는지. 표식의 [CommandFailure.message]로 그대로 넘어간다.
  final String message;

  /// JSON 객체로는 읽혔으나 명령이 되지 못한 경우의 원본(그때는 이쪽을 보존한다).
  final Map<String, dynamic>? source;

  /// 객체조차 아니었던 원본(파일 원문 또는 배열 원소). 외부 앱이 자기가 쓴 것을
  /// 볼 수 있도록 되쓸 때 함께 남긴다.
  final Object? rawValue;

  /// 이 어긋남을 실패 표식으로 옮긴다(사유는 언제나 형식 오류).
  CommandFailure toFailure(DateTime at) => CommandFailure(
    reason: CommandFailureReason.malformed,
    at: at,
    message: message,
  );

  @override
  Map<String, dynamic> toJson({CommandFailure? failure}) => {
    if (source != null) ...source!,
    if (failure != null) _kFailure: _failureToJson(failure),
    if (source == null) _kRaw: rawValue,
  };
}

/// 큐 파일 내용을 읽는다. 어떤 입력에도 예외를 던지지 않는다.
CommandFile decodeCommandFile(String text) {
  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } catch (_) {
    return CommandFile(
      items: [UnreadableCommand(message: _msgNotJson, rawValue: text)],
      isArray: false,
    );
  }
  if (decoded is List) {
    // 빈 배열은 할 일이 없는데 지울 근거도 없어 큐에 영영 남는다 — 형식 오류로
    // 보아 표식을 달면 보존 정리가 제때 치운다.
    if (decoded.isEmpty) {
      return CommandFile(
        items: [UnreadableCommand(message: _msgEmptyArray, rawValue: text)],
        isArray: false,
      );
    }
    return CommandFile(
      items: [for (final element in decoded) _decodeItem(element)],
      isArray: true,
    );
  }
  return CommandFile(items: [_decodeItem(decoded)], isArray: false);
}

/// 최상위 요소 하나(객체 하나 또는 배열의 원소)를 항목으로 읽는다.
ExternalCommandRecord _decodeItem(Object? element) {
  if (element is! Map) {
    return UnreadableCommand(message: _msgNotObject, rawValue: element);
  }
  final source = <String, dynamic>{
    for (final entry in element.entries) '${entry.key}': entry.value,
  };

  // 표식 판정을 **파싱 직후 가장 먼저** 한다. 표식을 파일 앞머리에 두고 파싱 전에
  // 가려내는 방법은, 항목 하나가 작아 얻는 것이 없는 대신 키 순서·공백에 형식이
  // 취약해진다.
  final rawFailure = source[_kFailure];
  if (rawFailure != null) {
    final failure = _failureFromJson(rawFailure);
    // 표식이 있는데 읽을 수 없으면 제대로 된 표식으로 한 번 갈아 쓴다(그래야
    // 보존 정리가 나이를 셀 수 있다). 그 뒤로는 읽히므로 되풀이되지 않는다.
    if (failure == null) {
      return UnreadableCommand(message: _msgBadFailure, source: source);
    }
    return MarkedCommand(failure: failure, source: source);
  }

  UnreadableCommand unreadable(String message) =>
      UnreadableCommand(message: message, source: source);

  final path = source[_kPath];
  if (path is! String || path.isEmpty) return unreadable(_msgNoPath);
  final tag = source[_kTag];
  if (tag is! String || tag.isEmpty) return unreadable(_msgNoTag);

  final rawOp = source[_kOp];
  final operation = rawOp == null
      ? ExternalCommandOperation.add
      : enumByName(ExternalCommandOperation.values, rawOp);
  if (operation == null) return unreadable('$_msgUnknownOp$rawOp');

  final rawMissing = source[_kMissing];
  final missingTag = rawMissing == null
      ? MissingTagPolicy.fail
      : enumByName(MissingTagPolicy.values, rawMissing);
  if (missingTag == null) return unreadable('$_msgUnknownMissing$rawMissing');

  // 값 유형은 없어도 형식 오류가 아니다 — 생성 타입에서만 필요하고, 그 판정(없으면
  // 실패)은 적용 시점의 몫이다. 다만 **모르는 이름**은 오타이므로 여기서 걸러 낸다.
  final rawValueType = source[_kValueType];
  final createValueType = rawValueType == null
      ? null
      : enumByName(TagValueType.values, rawValueType);
  if (rawValueType != null && createValueType == null) {
    return unreadable('$_msgUnknownValueType$rawValueType');
  }

  final rawNodeType = source[_kNodeType];
  final targetKind = rawNodeType == null
      ? ExternalNodeKind.file
      : enumByName(ExternalNodeKind.values, rawNodeType);
  if (targetKind == null) return unreadable('$_msgUnknownNodeType$rawNodeType');

  final rawValueNodeType = source[_kValueNodeType];
  final valueKind = rawValueNodeType == null
      ? ExternalNodeKind.file
      : enumByName(ExternalNodeKind.values, rawValueNodeType);
  if (valueKind == null) {
    return unreadable('$_msgUnknownValueNodeType$rawValueNodeType');
  }

  final rawMissingKeyword = source[_kMissingKeyword];
  final missingKeyword = rawMissingKeyword == null
      ? MissingKeywordPolicy.fail
      : enumByName(MissingKeywordPolicy.values, rawMissingKeyword);
  if (missingKeyword == null) {
    return unreadable('$_msgUnknownMissingKeyword$rawMissingKeyword');
  }

  final rawMissingLink = source[_kMissingLink];
  final missingLink = rawMissingLink == null
      ? MissingLinkPolicy.fail
      : enumByName(MissingLinkPolicy.values, rawMissingLink);
  if (missingLink == null) {
    return unreadable('$_msgUnknownMissingLink$rawMissingLink');
  }

  // 다중 부여 허용은 **적으면 그대로 존중**한다. 오타가 유령 태그를 만드는 것을
  // 막는 가드는 "필드를 안 받는 것"이 아니라 "기본값을 두지 않는 것"이며, 그건
  // 값 유형이 이미 쓰는 방식이다. 받지 않으면 다중값 태그를 내보내 되받을 때 값이
  // 마지막 하나로 조용히 접힌다.
  final rawAllowMultiple = source[_kAllowMultiple];
  if (rawAllowMultiple != null && rawAllowMultiple is! bool) {
    return unreadable(_msgBadAllowMultiple);
  }
  final rawColor = source[_kColor];
  if (rawColor != null && rawColor is! int) return unreadable(_msgBadColor);

  // 외부 앱이 숫자·불리언을 그대로 쓰는 것은 흔한 일이라 받아 적는다(저장은 문자열).
  final rawValue = source[_kValue];
  final String? value;
  if (rawValue == null) {
    value = null;
  } else if (rawValue is String) {
    value = rawValue;
  } else if (rawValue is num || rawValue is bool) {
    value = '$rawValue';
  } else {
    return unreadable(_msgBadValue);
  }

  return PendingCommand(
    command: ExternalTagCommand(
      targetPath: path,
      tagName: tag,
      operation: operation,
      value: value,
      missingTag: missingTag,
      createValueType: createValueType,
      targetKind: targetKind,
      valueKind: valueKind,
      missingKeyword: missingKeyword,
      missingLink: missingLink,
      createAllowMultiple: rawAllowMultiple as bool?,
      createColor: rawColor as int?,
    ),
    source: source,
  );
}

/// 명령 하나를 큐 파일 내용으로 쓴다(읽기와 대칭 — 테스트와 큐 이관이 쓴다).
///
/// 기본값이 있는 필드도 적어 파일만 보고 뜻을 알 수 있게 한다.
String encodeCommandFile(ExternalTagCommand command) =>
    encodeCommandObjects([commandToJson(command)], asArray: false);

/// 여러 항목을 한 파일로 쓴다. [asArray]가 false이고 항목이 하나면 객체 하나로,
/// 아니면 배열로 쓴다 — 되쓸 때 원본의 모양을 지키기 위함이다.
String encodeCommandObjects(
  List<Map<String, dynamic>> objects, {
  required bool asArray,
}) {
  final json = (!asArray && objects.length == 1) ? objects.first : objects;
  return const JsonEncoder.withIndent('  ').convert(json);
}

/// 명령 하나의 JSON 객체 표현.
Map<String, dynamic> commandToJson(ExternalTagCommand command) => {
  _kPath: command.targetPath,
  _kNodeType: command.targetKind.name,
  _kOp: command.operation.name,
  _kTag: command.tagName,
  if (command.value != null) _kValue: command.value,
  // 링크 대상 판별은 값이 있을 때만 뜻이 있다(없는 값에 대한 판별은 잡음이다).
  if (command.value != null) _kValueNodeType: command.valueKind.name,
  _kMissing: command.missingTag.name,
  _kMissingKeyword: command.missingKeyword.name,
  _kMissingLink: command.missingLink.name,
  if (command.createValueType != null)
    _kValueType: command.createValueType!.name,
  if (command.createAllowMultiple != null)
    _kAllowMultiple: command.createAllowMultiple,
  if (command.createColor != null) _kColor: command.createColor,
};

// ── 직렬화 세부 ──

const String _kPath = 'path';
const String _kOp = 'op';
const String _kTag = 'tag';
const String _kValue = 'value';
const String _kMissing = 'missing';
const String _kValueType = 'valueType';
const String _kAllowMultiple = 'allowMultiple';
const String _kColor = 'color';
const String _kNodeType = 'nodeType';
const String _kValueNodeType = 'valueNodeType';
const String _kMissingKeyword = 'missingKeyword';
const String _kMissingLink = 'missingLink';
const String _kFailure = 'failure';
const String _kRaw = 'raw';

const String _msgNotJson = 'JSON으로 읽을 수 없습니다.';
const String _msgNotObject = '항목이 JSON 객체가 아닙니다.';
const String _msgEmptyArray = '요청이 하나도 없는 빈 배열입니다.';
const String _msgBadFailure = '실패 표식을 읽을 수 없습니다.';
const String _msgNoPath = "'$_kPath'(대상 상대 경로)가 없습니다.";
const String _msgNoTag = "'$_kTag'(태그 이름)가 없습니다.";
const String _msgUnknownOp = "알 수 없는 '$_kOp': ";
const String _msgUnknownMissing = "알 수 없는 '$_kMissing': ";
const String _msgUnknownValueType = "알 수 없는 '$_kValueType': ";
const String _msgUnknownNodeType = "알 수 없는 '$_kNodeType': ";
const String _msgUnknownValueNodeType = "알 수 없는 '$_kValueNodeType': ";
const String _msgUnknownMissingKeyword = "알 수 없는 '$_kMissingKeyword': ";
const String _msgUnknownMissingLink = "알 수 없는 '$_kMissingLink': ";
const String _msgBadValue = "'$_kValue'는 문자열·숫자·불리언이어야 합니다.";
const String _msgBadAllowMultiple = "'$_kAllowMultiple'는 참/거짓이어야 합니다.";
const String _msgBadColor = "'$_kColor'는 정수(ARGB)여야 합니다.";

Map<String, dynamic> _withFailure(
  Map<String, dynamic> source,
  CommandFailure? failure,
) => {...source, if (failure != null) _kFailure: _failureToJson(failure)};

Map<String, dynamic> _failureToJson(CommandFailure failure) => {
  'reason': failure.reason.name,
  'at': failure.at.toIso8601String(),
  if (failure.message != null) 'message': failure.message,
};

/// 사유와 시각을 모두 읽어야 표식으로 인정한다 — 시각이 없으면 보존 정리가 나이를
/// 셀 수 없어 그 항목이 영영 남는다.
CommandFailure? _failureFromJson(Object? json) {
  if (json is! Map) return null;
  final reason = enumByName(CommandFailureReason.values, json['reason']);
  final rawAt = json['at'];
  if (reason == null || rawAt is! String) return null;
  final at = DateTime.tryParse(rawAt);
  if (at == null) return null;
  final message = json['message'];
  return CommandFailure(
    reason: reason,
    at: at,
    message: message is String ? message : null,
  );
}
