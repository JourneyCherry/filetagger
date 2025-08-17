import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum ErrorCode {
  success,
  notImplemented,
  pathIDInvalid, //허용되지 않은 경로 ID
  pathNotExist, //없는 경로
  pathExist, //존재하는 경로
  pathDuplicated, //중복된 경로
  tagIDInvalid, //허용되지 않은 태그 ID
  tagTypeInvalid, //허용되지 않은 태그 타입
  tagNotExist, //없는 태그
  tagExist, //존재하는 태그
  tagDuplicated, //중복된 태그
  valueIDInvalid, //허용되지 않은 값 ID
  valueValueInvalid, //허용되지 않은 값
  valueNotExist, //없는 값
  valueExist, //존재하는 값
  valueDuplicated, //중복된 값
  dbNoConnection,
  directoryOtherStillOpened, //다른 디렉토리가 열려있는데 열려고 시도
  unknownDataType, //알 수 없는 데이터 타입(Path, Tag, Value 중 하나가 아님)
  dbUpsertFailed, //DB 데이터 삽입/수정 실패
}

sealed class Result<T> {
  const Result();
  bool get isOk => this is Ok<T>;
  bool get isError => this is Error<T>;
  T? get valueOrNull => isOk ? (this as Ok<T>).value : null;
  ErrorCode? get errorOrNull => isError ? (this as Error<T>).code : null;

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
