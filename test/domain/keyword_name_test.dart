import 'package:filetagger/domain/usecases/keyword_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('앞뒤 공백은 다듬어 받는다', () {
    final r = normalizeKeywordName('  작가 A  ');
    expect(r.name, '작가 A');
    expect(r.error, isNull);
  });

  test('빈 이름과 공백뿐인 이름은 거절한다', () {
    expect(normalizeKeywordName('').error, KeywordNameError.empty);
    expect(normalizeKeywordName('   ').error, KeywordNameError.empty);
    expect(normalizeKeywordName('   ').name, isNull);
  });

  test('경로 구분자가 든 이름은 거절한다', () {
    // 키워드는 경로 계층에 속하지 않는다 — 구분자를 받으면 목록·그룹이 있지도 않은
    // 조상 폴더를 세우려 든다.
    expect(normalizeKeywordName('a/b').error, KeywordNameError.separator);
    expect(normalizeKeywordName(r'a\b').error, KeywordNameError.separator);
  });

  test('사유는 서로 구별된다', () {
    // 문구 자체는 화면(번역본)의 몫이라 여기서 보지 않는다. 사유가 겹치면 화면이
    // 무엇을 알려야 할지 가릴 수 없으므로 그것만 지킨다.
    expect(
      KeywordNameError.values.map((e) => e.name).toSet().length,
      KeywordNameError.values.length,
    );
  });
}
