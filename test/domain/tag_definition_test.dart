import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('label은 값이 없고 나머지 유형은 값을 갖는다', () {
    const label = TagDefinition(name: 'fav', valueType: TagValueType.label);
    expect(label.hasValue, isFalse);
    for (final t in [
      TagValueType.text,
      TagValueType.number,
      TagValueType.date,
    ]) {
      expect(TagDefinition(name: 'x', valueType: t).hasValue, isTrue);
    }
  });

  test('copyWith는 지정한 필드만 바꾸고 clearColor로 색을 비운다', () {
    const base = TagDefinition(
      id: 1,
      name: 'priority',
      valueType: TagValueType.label,
      color: 0xFF112233,
      allowMultiple: false,
    );

    final renamed = base.copyWith(name: 'urgency', allowMultiple: true);
    expect(renamed.name, 'urgency');
    expect(renamed.allowMultiple, isTrue);
    expect(renamed.color, 0xFF112233); // 그대로 유지
    expect(renamed.id, 1);

    final cleared = base.copyWith(clearColor: true);
    expect(cleared.color, isNull);
  });
}
