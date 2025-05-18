import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum ErrorCode {
  success,
  notImplemented,
  pathNotExist, //없는 경로
  pathExist, //존재하는 경로
  tagNotExist, //없는 태그
  tagExist, //존재하는 태그
  tagDuplicated, //중복된 태그
  valueNotExist, //없는 값
  valueExist, //존재하는 값
  dbNoConnection,
}

sealed class Result<T> {
  const Result();
  const factory Result.ok(T value) = Ok<T>;
  const factory Result.error(ErrorCode code) = Error<T>;
}

final class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

final class Error<T> extends Result<T> {
  final ErrorCode code;
  const Error(this.code);
}

String errorMessage(BuildContext context, ErrorCode code) {
  final loc = AppLocalizations.of(context);
  if (loc == null) {
    return "Fail to read Localization Information.";
  }
  switch (code) {
    case ErrorCode.dbNoConnection:
      return loc.err_db_no_connection;
    case ErrorCode.notImplemented:
      return "Not Implemented."; // 구현되지 않은 기능 에러는 개발자용으로 로컬라이제이션 하지 않음
    default:
      return "";
  }
}
