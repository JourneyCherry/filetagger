import 'package:filetagger/domain/entities/tag_value_ordering.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('number는 숫자 크기로 비교(사전순 아님)', () {
    expect(compareTagValues(TagValueType.number, '9', '10'), lessThan(0));
    expect(compareTagValues(TagValueType.number, '10', '9'), greaterThan(0));
    expect(compareTagValues(TagValueType.number, '3', '3'), 0);
  });

  test('date는 시간순으로 비교', () {
    expect(
      compareTagValues(TagValueType.date, '2024-01-01', '2024-12-31'),
      lessThan(0),
    );
  });

  test('text는 대소문자 무시 사전순', () {
    expect(compareTagValues(TagValueType.text, 'apple', 'Banana'), lessThan(0));
  });

  test('숫자로 파싱 안 되는 값은 파싱되는 값보다 뒤로', () {
    expect(compareTagValues(TagValueType.number, 'abc', '5'), greaterThan(0));
    expect(compareTagValues(TagValueType.number, '5', 'abc'), lessThan(0));
  });
}
