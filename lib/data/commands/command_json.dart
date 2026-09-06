/// 밖에서 들어온 명령 파일 하나의 JSON 표현. 형식의 단일 출처다.
///
/// 도메인 엔티티([ExternalTagCommand])는 순수하게 두고 직렬화는 data 계층이 맡는
/// 배치다(조건 코덱 [query_json.dart]와 같다). 다만 이 형식은 **바깥과의 공개 계약**
/// 이라, 설정 파일과 달리 사람이 열어 읽는 것을 전제로 들여쓰기해 쓴다 — 내보내기가
/// 내는 것이 이 형식이고, 콘솔이 먹는 것도 결과로 내는 것도 이 형식이다.
///
/// **최상위는 객체 하나 또는 객체의 배열**이다. 배열은 한 파일에 여러 명령을 담는
/// 자리(내보내기 등)다.
///
/// 읽기는 **예외를 던지지 않는다** — 형식 오류도 항목 하나의 판정일 뿐이라, 나머지
/// 항목의 처리를 막지 않고 사유를 달아 돌려준다.
library;

import 'dart:convert';

import '../../domain/entities/external_tag_command.dart';
import '../../domain/entities/tag_value_type.dart';
import '../settings/query_json.dart';

/// 명령 파일 안의 항목 하나를 읽어 낸 결과.
sealed class CommandRecord {
  const CommandRecord();
}

/// 명령으로 읽어 냈다.
final class ParsedCommand extends CommandRecord {
  const ParsedCommand(this.command);

  final ExternalTagCommand command;
}

/// 명령으로 읽어 내지 못했다. [error]가 무엇이 어긋났는지 말한다.
final class UnreadableCommand extends CommandRecord {
  const UnreadableCommand(this.error, [this.subject]);

  /// 어긋난 갈래. **문장이 아니라 갈래로 두는 것**은 해석기의 실패와 같은 이유다 —
  /// 이 파일은 Flutter 없이도 도는 자리라 번역본을 얻을 길이 없고, 읽어 내는 쪽이
  /// 고른 언어로 낼 몫이다.
  final CommandReadError error;

  /// 갈래가 가리키는 원문(모르는 이름 등). 갈래만으로 짚이면 null이다.
  final String? subject;
}

/// 명령 파일의 항목 하나를 읽어 내지 못한 갈래.
enum CommandReadError {
  /// 파일이 JSON이 아니다.
  notJson,

  /// 최상위 배열에 명령이 하나도 없다.
  emptyArray,

  /// 항목이 JSON 객체가 아니다.
  notObject,

  /// 대상 상대 경로 필드가 없다.
  pathMissing,

  /// 태그 이름 필드가 없다.
  tagMissing,

  /// 조작 이름을 모른다.
  unknownOperation,

  /// 없는 태그의 처리 방침 이름을 모른다.
  unknownMissingTagPolicy,

  /// 값 유형 이름을 모른다.
  unknownValueType,

  /// 대상 종류 이름을 모른다.
  unknownNodeKind,

  /// 값이 가리키는 대상의 종류 이름을 모른다.
  unknownValueNodeKind,

  /// 없는 키워드의 처리 방침 이름을 모른다.
  unknownMissingKeywordPolicy,

  /// 못 찾은 링크의 처리 방침 이름을 모른다.
  unknownMissingLinkPolicy,

  /// 값이 문자열·숫자·불리언이 아니다.
  badValue,

  /// 다중 허용이 참/거짓이 아니다.
  badAllowMultiple,

  /// 색이 정수(ARGB)가 아니다.
  badColor,
}

/// 명령 파일 내용을 읽는다. 어떤 입력에도 예외를 던지지 않는다.
List<CommandRecord> decodeCommandFile(String text) {
  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } catch (_) {
    return const [UnreadableCommand(CommandReadError.notJson)];
  }
  if (decoded is List) {
    // 빈 배열은 할 일이 없다. 조용히 성공으로 치면 부르는 쪽이 "왜 아무것도 안 됐지"를
    // 알 길이 없으므로 형식 오류로 본다.
    if (decoded.isEmpty) {
      return const [UnreadableCommand(CommandReadError.emptyArray)];
    }
    return [for (final element in decoded) _decodeItem(element)];
  }
  return [_decodeItem(decoded)];
}

/// 최상위 요소 하나(객체 하나 또는 배열의 원소)를 항목으로 읽는다.
CommandRecord _decodeItem(Object? element) {
  if (element is! Map) {
    return const UnreadableCommand(CommandReadError.notObject);
  }
  final source = <String, dynamic>{
    for (final entry in element.entries) '${entry.key}': entry.value,
  };

  final path = source[_kPath];
  if (path is! String || path.isEmpty) {
    return const UnreadableCommand(CommandReadError.pathMissing);
  }
  final tag = source[_kTag];
  if (tag is! String || tag.isEmpty) {
    return const UnreadableCommand(CommandReadError.tagMissing);
  }

  final rawOp = source[_kOp];
  final operation = rawOp == null
      ? ExternalCommandOperation.add
      : enumByName(ExternalCommandOperation.values, rawOp);
  if (operation == null) {
    return UnreadableCommand(CommandReadError.unknownOperation, rawOp);
  }

  final rawMissing = source[_kMissing];
  final missingTag = rawMissing == null
      ? MissingTagPolicy.fail
      : enumByName(MissingTagPolicy.values, rawMissing);
  if (missingTag == null) {
    return UnreadableCommand(
      CommandReadError.unknownMissingTagPolicy,
      rawMissing,
    );
  }

  // 값 유형은 없어도 형식 오류가 아니다 — 생성 타입에서만 필요하고, 그 판정(없으면
  // 실패)은 적용 시점의 몫이다. 다만 **모르는 이름**은 오타이므로 여기서 걸러 낸다.
  final rawValueType = source[_kValueType];
  final createValueType = rawValueType == null
      ? null
      : enumByName(TagValueType.values, rawValueType);
  if (rawValueType != null && createValueType == null) {
    return UnreadableCommand(CommandReadError.unknownValueType, rawValueType);
  }

  final rawNodeType = source[_kNodeType];
  final targetKind = rawNodeType == null
      ? ExternalNodeKind.file
      : enumByName(ExternalNodeKind.values, rawNodeType);
  if (targetKind == null) {
    return UnreadableCommand(CommandReadError.unknownNodeKind, rawNodeType);
  }

  final rawValueNodeType = source[_kValueNodeType];
  final valueKind = rawValueNodeType == null
      ? ExternalNodeKind.file
      : enumByName(ExternalNodeKind.values, rawValueNodeType);
  if (valueKind == null) {
    return UnreadableCommand(
      CommandReadError.unknownValueNodeKind,
      rawValueNodeType,
    );
  }

  final rawMissingKeyword = source[_kMissingKeyword];
  final missingKeyword = rawMissingKeyword == null
      ? MissingKeywordPolicy.fail
      : enumByName(MissingKeywordPolicy.values, rawMissingKeyword);
  if (missingKeyword == null) {
    return UnreadableCommand(
      CommandReadError.unknownMissingKeywordPolicy,
      rawMissingKeyword,
    );
  }

  final rawMissingLink = source[_kMissingLink];
  final missingLink = rawMissingLink == null
      ? MissingLinkPolicy.fail
      : enumByName(MissingLinkPolicy.values, rawMissingLink);
  if (missingLink == null) {
    return UnreadableCommand(
      CommandReadError.unknownMissingLinkPolicy,
      rawMissingLink,
    );
  }

  // 다중 부여 허용은 **적으면 그대로 존중**한다. 오타가 유령 태그를 만드는 것을
  // 막는 가드는 "필드를 안 받는 것"이 아니라 "기본값을 두지 않는 것"이며, 그건
  // 값 유형이 이미 쓰는 방식이다. 받지 않으면 다중값 태그를 내보내 되받을 때 값이
  // 마지막 하나로 조용히 접힌다.
  final rawAllowMultiple = source[_kAllowMultiple];
  if (rawAllowMultiple != null && rawAllowMultiple is! bool) {
    return const UnreadableCommand(CommandReadError.badAllowMultiple);
  }
  final rawColor = source[_kColor];
  if (rawColor != null && rawColor is! int) {
    return const UnreadableCommand(CommandReadError.badColor);
  }

  // 외부 도구가 숫자·불리언을 그대로 쓰는 것은 흔한 일이라 받아 적는다(저장은 문자열).
  final rawValue = source[_kValue];
  final String? value;
  if (rawValue == null) {
    value = null;
  } else if (rawValue is String) {
    value = rawValue;
  } else if (rawValue is num || rawValue is bool) {
    value = '$rawValue';
  } else {
    return const UnreadableCommand(CommandReadError.badValue);
  }

  return ParsedCommand(
    ExternalTagCommand(
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
  );
}

/// 명령 하나를 파일 내용으로 쓴다(읽기와 대칭 — 테스트가 쓴다).
///
/// 기본값이 있는 필드도 적어 파일만 보고 뜻을 알 수 있게 한다.
String encodeCommandFile(ExternalTagCommand command) =>
    encodeCommandObjects([commandToJson(command)], asArray: false);

/// 여러 항목을 한 파일로 쓴다. [asArray]가 false이고 항목이 하나면 객체 하나로,
/// 아니면 배열로 쓴다.
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
