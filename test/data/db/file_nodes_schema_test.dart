import 'package:drift/drift.dart' show Value;
import 'package:filetagger/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// 생성 파일(`app_database.g.dart`)까지 실제 컴파일되는지 확인하는 가드.
/// DB를 열지 않고(host sqlite3 의존 회피) 생성된 컴패니언 타입만 참조한다.
void main() {
  test('FileNodes 스키마에 연결 끊김(missingSince) 컬럼이 반영된다', () {
    const companion = FileNodesCompanion(missingSince: Value(null));
    expect(companion.missingSince.present, isTrue);
    expect(companion.missingSince.value, isNull);
  });
}
