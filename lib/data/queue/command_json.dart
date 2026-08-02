/// 외부 앱 연동 큐 파일 하나의 JSON 표현. 형식의 단일 출처다.
///
/// 도메인 엔티티([ExternalTagCommand])는 순수하게 두고 직렬화는 data 계층이 맡는
/// 배치다(조건 코덱 [query_json.dart]와 같다). 다만 이 형식은 **외부 앱과의 공개
/// 계약**이라, 설정 파일과 달리 사람이 열어 읽는 것을 전제로 들여쓰기해 쓴다.
///
/// 읽기는 **예외를 던지지 않는다** — 형식 오류도 큐 항목의 실패이므로, 다른 실패와
/// 같은 경로(파일 안의 표식)로 기록돼야 하기 때문이다. 그래서 결과를 세 갈래
/// ([PendingCommand]·[MarkedCommand]·[UnreadableCommand])로 돌려준다.
library;

import 'dart:convert';

import '../../domain/entities/external_tag_command.dart';
import '../../domain/entities/tag_value_type.dart';
import '../settings/query_json.dart';

/// 큐 파일 하나를 읽어 낸 결과.
///
/// 어느 갈래든 **원본을 보존한 채 실패 표식만 얹어 되쓸 수 있다**([withFailure]) —
/// 실패 항목은 이동·개명 없이 제자리에 남아, 외부 앱이 자기가 만든 경로 그대로
/// 다시 읽어 원인을 알 수 있어야 한다.
sealed class ExternalCommandRecord {
  const ExternalCommandRecord();

  /// 이 항목에 실패 표식을 얹은 파일 내용(파일 전체 재작성용 — JSON 앞머리에
  /// 끼워 넣을 수는 없다). 앱이 모르는 키까지 원본 그대로 남긴다.
  String withFailure(CommandFailure failure);
}

/// 명령으로 읽어 냈고 실패 표식이 없다 — 이번 패스에서 적용할 항목.
final class PendingCommand extends ExternalCommandRecord {
  const PendingCommand({required this.command, required this.source});

  final ExternalTagCommand command;

  /// 되쓸 때 보존할 원본 객체(앱이 해석하지 않는 키 포함).
  final Map<String, dynamic> source;

  @override
  String withFailure(CommandFailure failure) =>
      _encode({...source, _kFailure: _failureToJson(failure)});
}

/// 이미 실패 표식이 적혀 있다 — 적용을 건너뛰고 보존 정리만 본다. 같은 실패를 앱이
/// 켜질 때마다 되풀이하지 않기 위해, 명령 필드는 읽어 보지도 않는다.
final class MarkedCommand extends ExternalCommandRecord {
  const MarkedCommand({required this.failure, required this.source});

  final CommandFailure failure;
  final Map<String, dynamic> source;

  @override
  String withFailure(CommandFailure failure) =>
      _encode({...source, _kFailure: _failureToJson(failure)});
}

/// 명령으로 읽어 내지 못했다 — 그 자리에 형식 오류 표식을 쓴다.
final class UnreadableCommand extends ExternalCommandRecord {
  const UnreadableCommand({
    required this.message,
    required this.rawText,
    this.source,
  });

  /// 무엇이 어긋났는지. 표식의 [CommandFailure.message]로 그대로 넘어간다.
  final String message;

  /// 파일 원문. JSON으로조차 읽히지 않은 경우에도 외부 앱이 자기가 쓴 것을 볼 수
  /// 있도록 되쓸 때 함께 남긴다.
  final String rawText;

  /// JSON 객체로는 읽혔으나 명령이 되지 못한 경우의 원본(그때는 이쪽을 보존한다).
  final Map<String, dynamic>? source;

  /// 이 어긋남을 실패 표식으로 옮긴다(사유는 언제나 형식 오류).
  CommandFailure toFailure(DateTime at) => CommandFailure(
    reason: CommandFailureReason.malformed,
    at: at,
    message: message,
  );

  @override
  String withFailure(CommandFailure failure) => _encode({
    if (source != null) ...source!,
    _kFailure: _failureToJson(failure),
    if (source == null) _kRaw: rawText,
  });
}

/// 큐 파일 내용을 읽는다. 어떤 입력에도 예외를 던지지 않는다.
ExternalCommandRecord decodeCommandFile(String text) {
  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } catch (_) {
    return UnreadableCommand(message: _msgNotJson, rawText: text);
  }
  if (decoded is! Map) {
    return UnreadableCommand(message: _msgNotObject, rawText: text);
  }
  final source = <String, dynamic>{
    for (final entry in decoded.entries) '${entry.key}': entry.value,
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
      return UnreadableCommand(
        message: _msgBadFailure,
        rawText: text,
        source: source,
      );
    }
    return MarkedCommand(failure: failure, source: source);
  }

  UnreadableCommand unreadable(String message) =>
      UnreadableCommand(message: message, rawText: text, source: source);

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
    ),
    source: source,
  );
}

/// 명령을 큐 파일 내용으로 쓴다(읽기와 대칭 — 테스트와 큐 이관이 쓴다).
///
/// 기본값이 있는 필드도 적어 파일만 보고 뜻을 알 수 있게 한다.
String encodeCommandFile(ExternalTagCommand command) => _encode({
  _kPath: command.targetPath,
  _kOp: command.operation.name,
  _kTag: command.tagName,
  if (command.value != null) _kValue: command.value,
  _kMissing: command.missingTag.name,
  if (command.createValueType != null)
    _kValueType: command.createValueType!.name,
});

// ── 직렬화 세부 ──

const String _kPath = 'path';
const String _kOp = 'op';
const String _kTag = 'tag';
const String _kValue = 'value';
const String _kMissing = 'missing';
const String _kValueType = 'valueType';
const String _kFailure = 'failure';
const String _kRaw = 'raw';

const String _msgNotJson = 'JSON으로 읽을 수 없습니다.';
const String _msgNotObject = '최상위가 JSON 객체가 아닙니다.';
const String _msgBadFailure = '실패 표식을 읽을 수 없습니다.';
const String _msgNoPath = "'$_kPath'(대상 상대 경로)가 없습니다.";
const String _msgNoTag = "'$_kTag'(태그 이름)가 없습니다.";
const String _msgUnknownOp = "알 수 없는 '$_kOp': ";
const String _msgUnknownMissing = "알 수 없는 '$_kMissing': ";
const String _msgUnknownValueType = "알 수 없는 '$_kValueType': ";
const String _msgBadValue = "'$_kValue'는 문자열·숫자·불리언이어야 합니다.";

/// 사람이 열어 읽는 파일이라 들여쓰기해 쓴다.
String _encode(Map<String, dynamic> json) =>
    const JsonEncoder.withIndent('  ').convert(json);

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
