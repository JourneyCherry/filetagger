import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 태그값 유형은 정렬·입력·검증 분기의 기준이므로, 유형 집합이 의도치 않게
  // 바뀌면 드러나도록 가드한다.
  test('TagValueType은 label/text/number/date를 갖는다', () {
    expect(
      TagValueType.values,
      containsAll(const [
        TagValueType.label,
        TagValueType.text,
        TagValueType.number,
        TagValueType.date,
      ]),
    );
  });
}
