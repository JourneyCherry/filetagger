import 'assigned_tag.dart';
import 'tag_value_ordering.dart';
import 'tag_value_type.dart';

/// 필터 조건이 태그값을 어떻게 견주는지.
///
/// [exists]는 값과 무관하게 태그가 붙어 있으면 만족(label 태그의 유일한 연산).
/// 나머지는 부여된 값 중 하나라도 피연산자와의 비교를 통과하면 만족한다.
/// 비교는 태그 유형에 맞춰 해석된다([compareTagValues]).
enum FilterOperator {
  exists,
  equals,
  notEquals,
  lessThan,
  lessOrEqual,
  greaterThan,
  greaterOrEqual,
  contains,
}

/// 태그 유형별로 고를 수 있는 필터 연산자. label은 값이 없어 존재 여부만,
/// text는 부분 일치(contains)를 포함하고, number·date는 대소 비교까지 연다.
List<FilterOperator> operatorsForType(TagValueType type) {
  switch (type) {
    case TagValueType.label:
      return const [FilterOperator.exists];
    case TagValueType.text:
      return const [
        FilterOperator.exists,
        FilterOperator.equals,
        FilterOperator.notEquals,
        FilterOperator.contains,
      ];
    case TagValueType.number:
    case TagValueType.date:
      return const [
        FilterOperator.exists,
        FilterOperator.equals,
        FilterOperator.notEquals,
        FilterOperator.lessThan,
        FilterOperator.lessOrEqual,
        FilterOperator.greaterThan,
        FilterOperator.greaterOrEqual,
      ];
  }
}

/// 파일 목록에 거는 조건 하나. 태그·연산자·(값 연산이면)피연산자와, 표시
/// 조건인지 제외 조건인지를 갖는다.
///
/// 태그처럼 하나씩 추가하는 단위이며, [exclude]가 true면 이 조건을 만족하는
/// 노드를 무조건 숨긴다(다른 표시 조건 만족 여부와 무관).
class FilterCondition {
  const FilterCondition({
    required this.tagDefinitionId,
    this.operator = FilterOperator.exists,
    this.operand,
    this.exclude = false,
  });

  final int tagDefinitionId;
  final FilterOperator operator;

  /// 값 비교 연산의 피연산자. [FilterOperator.exists]면 무의미(null).
  final String? operand;

  /// true면 제외 조건(만족 시 숨김), false면 표시 조건(만족해야 표시).
  final bool exclude;

  /// 이 조건이 한 노드(그 부여 기록들)를 만족시키는지.
  bool matches(Iterable<AssignedTag> tags) {
    final relevant = <AssignedTag>[
      for (final t in tags)
        if (t.tagDefinitionId == tagDefinitionId) t,
    ];
    if (operator == FilterOperator.exists) return relevant.isNotEmpty;
    if (relevant.isEmpty) return false;
    final type = relevant.first.definition.valueType;
    final operandValue = operand ?? '';
    for (final t in relevant) {
      final value = t.value;
      if (value == null || value.isEmpty) continue;
      if (_valueMatches(type, value, operandValue)) return true;
    }
    return false;
  }

  bool _valueMatches(TagValueType type, String value, String operandValue) {
    switch (operator) {
      case FilterOperator.exists:
        return true;
      case FilterOperator.contains:
        return value.toLowerCase().contains(operandValue.toLowerCase());
      case FilterOperator.equals:
        return compareTagValues(type, value, operandValue) == 0;
      case FilterOperator.notEquals:
        return compareTagValues(type, value, operandValue) != 0;
      case FilterOperator.lessThan:
        return compareTagValues(type, value, operandValue) < 0;
      case FilterOperator.lessOrEqual:
        return compareTagValues(type, value, operandValue) <= 0;
      case FilterOperator.greaterThan:
        return compareTagValues(type, value, operandValue) > 0;
      case FilterOperator.greaterOrEqual:
        return compareTagValues(type, value, operandValue) >= 0;
    }
  }

  FilterCondition copyWith({
    int? tagDefinitionId,
    FilterOperator? operator,
    String? operand,
    bool clearOperand = false,
    bool? exclude,
  }) {
    return FilterCondition(
      tagDefinitionId: tagDefinitionId ?? this.tagDefinitionId,
      operator: operator ?? this.operator,
      operand: clearOperand ? null : (operand ?? this.operand),
      exclude: exclude ?? this.exclude,
    );
  }
}

/// 순서 있는 조건 목록으로 파일을 걸러내는 필터.
///
/// 표시 조건은 모두 만족해야 하고(AND), 제외 조건은 하나라도 만족하면 숨긴다.
/// 조건 순서는 결과에 영향을 주지 않지만 태그처럼 추가·재배치하는 UI를 위해
/// 목록으로 보존한다.
class FileFilter {
  const FileFilter({this.conditions = const <FilterCondition>[]});

  final List<FilterCondition> conditions;

  bool get isEmpty => conditions.isEmpty;

  bool matches(Iterable<AssignedTag> tags) {
    final list = tags is List<AssignedTag> ? tags : tags.toList();
    for (final c in conditions) {
      final satisfied = c.matches(list);
      if (c.exclude) {
        if (satisfied) return false;
      } else if (!satisfied) {
        return false;
      }
    }
    return true;
  }

  FileFilter add(FilterCondition condition) =>
      FileFilter(conditions: [...conditions, condition]);

  FileFilter removeAt(int index) => FileFilter(
        conditions: [
          for (var i = 0; i < conditions.length; i++)
            if (i != index) conditions[i],
        ],
      );

  FileFilter replaceAt(int index, FilterCondition condition) => FileFilter(
        conditions: [
          for (var i = 0; i < conditions.length; i++)
            if (i == index) condition else conditions[i],
        ],
      );

  FileFilter reorder(int oldIndex, int newIndex) {
    final next = [...conditions];
    final item = next.removeAt(oldIndex);
    next.insert(newIndex, item);
    return FileFilter(conditions: next);
  }
}
