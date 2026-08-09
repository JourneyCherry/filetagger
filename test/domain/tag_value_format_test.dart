import 'package:filetagger/domain/entities/tag_value_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('저장값을 표시 형식으로 되돌린다', () {
    final stored = dateToStoredValue(DateTime(2024, 3, 7));
    expect(storedDateToDisplay(stored), '2024-03-07');
  });

  test('시각이 붙어 있어도 날짜만 보인다', () {
    expect(storedDateToDisplay('2024-12-31T23:45:00.000'), '2024-12-31');
  });

  test('저장값은 시간대에 매이지 않는다(왕복해도 같은 날짜)', () {
    // 같은 DB를 다른 시간대에서 열어도 날짜가 밀리면 안 되므로, 저장값에는 시각도
    // 오프셋도 담지 않는다 — 되읽어도 적은 그대로여야 한다.
    for (final date in [
      DateTime(2024, 1, 1),
      DateTime(2024, 6, 30),
      DateTime(2024, 12, 31),
    ]) {
      final stored = dateToStoredValue(date);
      expect(stored, isNot(contains('Z')));
      expect(storedDateToDisplay(stored), storedDateToDisplay(stored));
      expect(DateTime.parse(stored).day, date.day);
    }
  });

  test('읽을 수 없는 값이면 null(부르는 쪽이 원문을 그대로 쓴다)', () {
    expect(storedDateToDisplay('언젠가'), isNull);
    expect(storedDateToDisplay(''), isNull);
  });
}
