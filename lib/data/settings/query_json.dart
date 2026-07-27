/// 조건(필터·정렬·그룹)의 JSON 표현. 저장 형식의 단일 출처다.
///
/// 워크스페이스 보기 설정([JsonViewSettingsStore])과 조건 프리셋
/// ([JsonQueryPresetStore])이 같은 조건을 담으므로, 형식이 갈라지지 않도록 변환을
/// 여기 한 곳에 둔다. 도메인 엔티티는 순수하게 유지한다(직렬화는 data 계층의 몫).
///
/// 태그 식별자는 워크스페이스 DB의 정의 id다 — 정의가 지워졌다면 읽어 들인 뒤
/// 소비하는 쪽이 걸러 낸다.
library;

import '../../domain/entities/file_filter.dart';
import '../../domain/entities/file_grouping.dart';
import '../../domain/entities/file_sort.dart';
import '../../domain/usecases/group_query_text.dart';

Map<String, dynamic> filterToJson(FileFilter filter) => {
  'conditions': [
    for (final c in filter.conditions)
      {
        'tag': c.tagDefinitionId,
        'op': c.operator.name,
        if (c.operand != null) 'operand': c.operand,
        'exclude': c.exclude,
      },
  ],
};

/// 저장된 필터. 형식이 어긋나거나 알 수 없는 연산자면 그 조건만 건너뛴다.
FileFilter filterFromJson(Object? json) {
  if (json is! Map) return const FileFilter();
  final raw = json['conditions'];
  if (raw is! List) return const FileFilter();
  final conditions = <FilterCondition>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final tag = item['tag'];
    final op = enumByName(FilterOperator.values, item['op']);
    if (tag is! int || op == null) continue;
    conditions.add(
      FilterCondition(
        tagDefinitionId: tag,
        operator: op,
        operand: item['operand'] as String?,
        exclude: item['exclude'] == true,
      ),
    );
  }
  return FileFilter(conditions: conditions);
}

Map<String, dynamic> sortToJson(FileSortOrder sort) => {
  'keys': [
    for (final k in sort.keys)
      {'tag': k.tagDefinitionId, 'direction': k.direction.name},
  ],
};

/// 저장된 정렬. 형식이 어긋나거나 알 수 없는 방향이면 그 단계만 건너뛴다.
FileSortOrder sortFromJson(Object? json) {
  if (json is! Map) return const FileSortOrder();
  final raw = json['keys'];
  if (raw is! List) return const FileSortOrder();
  final keys = <SortKey>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final tag = item['tag'];
    final direction = enumByName(SortDirection.values, item['direction']);
    if (tag is! int || direction == null) continue;
    keys.add(SortKey(tagDefinitionId: tag, direction: direction));
  }
  return FileSortOrder(keys: keys);
}

/// 그룹 단계를 정의 id 나열로 저장한다(폴더 계층 키는 예약 id로). 텍스트·칩
/// 계층이 그룹 키를 정의 id로 다루는 것과 같은 방식이라 재해석이 단순하다.
List<int> groupingToJson(FileGrouping grouping) => [
  for (final k in grouping.keys) groupKeyId(k),
];

/// 저장된 그룹. 저장된 값이 없거나 형식이 어긋나면 null을 돌려줘, 호출부가 각자의
/// 기본값(또는 구버전 마이그레이션)을 고르게 한다.
FileGrouping? groupingFromJson(Object? json) {
  if (json is! List) return null;
  return groupFromKeys([
    for (final item in json)
      if (item is int) groupKeyFromId(item),
  ]);
}

/// 이름으로 열거형 값을 찾되, 알 수 없는 이름이면 null(해당 항목은 건너뜀).
///
/// 열거형은 이름으로 저장해 값 순서 변경에 영향받지 않는다(태그 유형 저장과 동일
/// 원칙). 설정 계열 저장소가 함께 쓴다.
T? enumByName<T extends Enum>(List<T> values, Object? name) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}
