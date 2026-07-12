import 'tag_definition.dart';
import 'tag_value_type.dart';

/// 그룹 키의 예약 식별자. 실제 태그(양수)·시스템 태그(작은 음수)와 겹치지 않는,
/// 폴더 계층 전용 합성 정의의 id다. 값은 여기 상수 하나가 단일 출처다.
///
/// 폴더 계층은 태그값 버킷과 다른 축(경로 계층)이라 진짜 태그가 아니지만, 텍스트·칩
/// 계층은 그룹 키를 태그 정의 id로 흘려보내므로 이 예약 id로 실어 나른다. 시스템
/// 태그 카탈로그([SystemTag])에는 들지 않으니, id가 음수라 해도 시스템 태그로
/// 취급해선 안 된다(그 구분이 필요한 곳은 [FolderHierarchyGroupKey] 타입으로 가른다).
const int kFolderHierarchyGroupId = -100;

/// 그룹 후보·텍스트 해석에만 노출되는, 폴더 계층 그룹 키의 합성 태그 정의.
///
/// 필터·정렬 피커엔 나오지 않고 그룹 피커에서만 후보가 된다. 값이 없는 구조적
/// 키라 label로 두고, 시스템 소유로 표시해 사용자 CRUD 대상에서 뺀다.
const TagDefinition folderHierarchyDefinition = TagDefinition(
  id: kFolderHierarchyGroupId,
  name: '폴더 계층',
  valueType: TagValueType.label,
  isSystem: true,
);

/// 그룹 한 단계. 태그값으로 묶거나([TagGroupKey]), 폴더 계층으로 묶는다
/// ([FolderHierarchyGroupKey]). 폴더 계층은 값 버킷과 다른 축이라 전용 키로 둔다.
sealed class GroupKey {
  const GroupKey();
}

/// 한 태그의 값으로 묶는 그룹 단계. 값이 없는 노드는 "(미분류)" 버킷으로 모인다.
final class TagGroupKey extends GroupKey {
  const TagGroupKey(this.tagDefinitionId);

  final int tagDefinitionId;

  @override
  bool operator ==(Object other) =>
      other is TagGroupKey && other.tagDefinitionId == tagDefinitionId;

  @override
  int get hashCode => tagDefinitionId.hashCode;
}

/// 폴더 경로 계층으로 묶는 그룹 단계. 기존 "폴더 그룹화"를 대체한다. 한 그룹
/// 순서에 최대 한 번만 올 수 있다.
final class FolderHierarchyGroupKey extends GroupKey {
  const FolderHierarchyGroupKey();

  @override
  bool operator ==(Object other) => other is FolderHierarchyGroupKey;

  @override
  int get hashCode => kFolderHierarchyGroupId;
}

/// 그룹 키를 저장·해석에 쓰는 정의 id로. 폴더 계층 키는 예약 id로 흘려보낸다
/// (텍스트·칩 계층이 그룹 키를 정의 id로 다루는 것과 같은 방식).
int groupKeyId(GroupKey key) => switch (key) {
  FolderHierarchyGroupKey() => kFolderHierarchyGroupId,
  TagGroupKey(:final tagDefinitionId) => tagDefinitionId,
};

/// 정의 id를 그룹 키로. 예약 id는 폴더 계층 키, 나머지는 태그 키다.
GroupKey groupKeyFromId(int id) => id == kFolderHierarchyGroupId
    ? const FolderHierarchyGroupKey()
    : TagGroupKey(id);

/// 순서 있는 그룹 단계 목록. 바깥→안쪽으로 중첩해 묶는다.
///
/// 비어 있으면 그룹 없이 평면 목록이다. 각 단계의 순서가 중첩 순서이므로 재배치가
/// 결과를 바꾼다. 폴더 계층 키는 임의 위치에 최대 한 번 올 수 있고(그 뒤의 값 키는
/// 각 폴더의 직속 파일을 다시 그룹화한다), 태그 키는 태그당 한 단계다.
class FileGrouping {
  const FileGrouping({this.keys = const <GroupKey>[]});

  final List<GroupKey> keys;

  bool get isEmpty => keys.isEmpty;

  /// 폴더 계층 키가 이미 들어 있는지(폴더 키는 최대 1회).
  bool get hasFolderHierarchy => keys.any((k) => k is FolderHierarchyGroupKey);

  bool containsTag(int tagDefinitionId) =>
      keys.any((k) => k is TagGroupKey && k.tagDefinitionId == tagDefinitionId);

  FileGrouping add(GroupKey key) => FileGrouping(keys: [...keys, key]);

  FileGrouping removeAt(int index) => FileGrouping(
    keys: [
      for (var i = 0; i < keys.length; i++)
        if (i != index) keys[i],
    ],
  );

  FileGrouping reorder(int oldIndex, int newIndex) {
    final next = [...keys];
    final item = next.removeAt(oldIndex);
    next.insert(newIndex, item);
    return FileGrouping(keys: next);
  }
}
