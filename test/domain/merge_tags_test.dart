import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/domain/usecases/merge_tags.dart';
import 'package:flutter_test/flutter_test.dart';

/// 합칠 수 있는 대상 판정(값 유형·다중 허용 일치, 시스템/자기 자신 제외)에 대한
/// 가드레일. 실제 이관·중복 정리는 저장소가 수행하므로 여기선 후보 규칙만 검증한다.
void main() {
  const priority = TagDefinition(
    id: 1,
    name: 'priority',
    valueType: TagValueType.label,
  );

  test('값 유형·다중 허용이 같은 다른 사용자 태그만 합칠 수 있다', () {
    const sameKind = TagDefinition(
      id: 2,
      name: 'flag',
      valueType: TagValueType.label,
    );
    expect(canMergeTags(priority, sameKind), isTrue);
  });

  test('값 유형이 다르면 합칠 수 없다', () {
    const other = TagDefinition(
      id: 2,
      name: 'score',
      valueType: TagValueType.number,
    );
    expect(canMergeTags(priority, other), isFalse);
  });

  test('다중 부여 허용이 다르면 합칠 수 없다', () {
    const multi = TagDefinition(
      id: 2,
      name: 'flag',
      valueType: TagValueType.label,
      allowMultiple: true,
    );
    expect(canMergeTags(priority, multi), isFalse);
  });

  test('자기 자신·시스템 태그·저장 전(id 없음) 태그는 대상이 아니다', () {
    expect(canMergeTags(priority, priority), isFalse);
    expect(
      canMergeTags(
        priority,
        const TagDefinition(
          id: 2,
          name: 'sys',
          valueType: TagValueType.label,
          isSystem: true,
        ),
      ),
      isFalse,
    );
    expect(
      canMergeTags(
        priority,
        const TagDefinition(name: 'unsaved', valueType: TagValueType.label),
      ),
      isFalse,
    );
  });

  test('mergeTargetsFor는 자기 자신과 부적합 후보를 걸러 이름순을 유지한다', () {
    const defs = [
      priority,
      TagDefinition(id: 2, name: 'flag', valueType: TagValueType.label),
      TagDefinition(id: 3, name: 'score', valueType: TagValueType.number),
      TagDefinition(id: 4, name: 'zzz', valueType: TagValueType.label),
    ];
    final targets = mergeTargetsFor(priority, defs);
    expect(targets.map((t) => t.id), [2, 4]);
  });
}
