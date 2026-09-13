import 'package:collection/collection.dart';

import 'assigned_tag.dart';
import 'tag_value_ordering.dart';
import 'tag_value_type.dart';

/// 필터 조건이 태그값을 어떻게 견주는지.
///
/// [exists]는 값과 무관하게 태그가 붙어 있으면 만족(label 태그의 유일한 연산).
/// 나머지는 부여된 값을 하나씩 견주는데, **값이 여럿일 때 몇 개가 통과해야 하는지가
/// 연산의 성격을 탄다**([requiresEveryValue]) — 긍정 연산은 하나라도, 부정 연산은
/// 모두다. 비교는 태그 유형에 맞춰 해석된다([compareTagValues]).
///
/// 부정 연산([notEquals]·[notContains])은 조건의 [FilterCondition.exclude]와 다르다.
/// 부정 연산은 **태그가 붙어 있어야** 만족할 수 있는 표시 조건이고, 제외는 만족하는
/// 노드를 숨기는 조건이다. 태그가 없는 노드의 취급이 갈린다.
enum FilterOperator {
  exists,
  equals,
  notEquals,
  lessThan,
  lessOrEqual,
  greaterThan,
  greaterOrEqual,
  contains,
  notContains,
}

/// 값이 여럿인 태그에서 **모든 값**이 통과해야 만족하는 연산인지.
///
/// 부정 연산이 그렇다. "그 값이 아니다·그 글자가 없다"는 부여 하나가 아니라 **그 태그
/// 전체**에 대한 물음이라, 하나라도로 두면 값이 섞인 노드가 `~`와 `!~`에 **동시에**
/// 걸려 둘이 서로의 여집합이 아니게 된다(세어 보면 합이 전체를 넘는다).
///
/// 긍정 연산은 하나라도가 맞다 — 다중값 태그에 "이 값을 가졌나"를 묻는 자연스러운 뜻이고,
/// 모두로 두면 값이 둘 이상인 노드는 어떤 값으로도 골라낼 수 없다.
///
/// **값이 하나인 태그에서는 둘이 같은 답을 낸다** — 가르는 것은 다중값 태그뿐이다.
bool requiresEveryValue(FilterOperator op) =>
    op == FilterOperator.notEquals || op == FilterOperator.notContains;

/// 태그 유형별로 고를 수 있는 필터 연산자. label은 값이 없어 존재 여부만,
/// text는 부분 일치(contains)를 포함하고, number·date는 대소 비교까지 연다.
List<FilterOperator> operatorsForType(TagValueType type) {
  switch (type) {
    case TagValueType.label:
    // image는 값이 불투명한 캐시 키라 label처럼 존재 여부만 건다.
    case TagValueType.image:
      return const [FilterOperator.exists];
    case TagValueType.text:
    // link은 대상 이름 기준 텍스트 비교라 text와 같은 연산자 집합을 쓴다.
    case TagValueType.link:
      return const [
        FilterOperator.exists,
        FilterOperator.equals,
        FilterOperator.notEquals,
        FilterOperator.contains,
        FilterOperator.notContains,
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
    this.orWithPrevious = false,
  });

  final int tagDefinitionId;
  final FilterOperator operator;

  /// 값 비교 연산의 피연산자. [FilterOperator.exists]면 무의미(null).
  final String? operand;

  /// true면 제외 조건(만족 시 숨김), false면 표시 조건(만족해야 표시).
  final bool exclude;

  /// **앞 조건과 한 묶음**인지. 참이면 앞 조건과 OR로 이어지고, 거짓이면 새 묶음을
  /// 시작한다([FileFilter.matches]).
  ///
  /// **묶음 번호가 아니라 이어붙임으로 둔다.** 번호를 두면 조건을 지우거나 옮길 때
  /// 번호가 흩어져 "어느 묶음이 비었는지"를 따로 건사해야 하지만, 이어붙임은 목록의
  /// 차례만 보면 되어 지금의 추가·재배치가 그대로 산다. 텍스트 문법도 조각 하나가
  /// 조건 하나라는 규칙을 지킨 채 접두사 하나로 표현된다.
  ///
  /// 목록의 **첫 조건**에 붙으면 이을 앞이 없으므로 무시된다(제 묶음을 시작한다).
  final bool orWithPrevious;

  /// 이 조건이 한 노드(그 부여 기록들)를 만족시키는지.
  ///
  /// 노드마다 불리므로 해당 태그의 부여만 골라 담지 않고 한 번 훑으며 판정한다.
  /// 피연산자 해석([TagValueKey])도 값마다가 아니라 노드마다 한 번만 한다.
  ///
  /// 값이 여럿이면 [requiresEveryValue]가 몇 개를 봐야 하는지 정한다. 어느 쪽이든
  /// **견줄 값이 하나는 있어야** 한다 — 값 없이 붙은 부여만 있으면 부정 연산도 만족하지
  /// 않는다(태그가 아예 없는 노드와 같은 자리다).
  bool matches(Iterable<AssignedTag> tags) {
    if (operator == FilterOperator.exists) {
      for (final t in tags) {
        if (t.tagDefinitionId == tagDefinitionId) return true;
      }
      return false;
    }
    final every = requiresEveryValue(operator);
    TagValueKey? operandKey;
    var judged = false;
    for (final t in tags) {
      if (t.tagDefinitionId != tagDefinitionId) continue;
      // 유형은 이 태그의 첫 부여에서 읽는다(같은 태그의 부여는 유형이 같다).
      operandKey ??= TagValueKey(t.definition.valueType, operand ?? '');
      final value = t.value;
      if (value == null || value.isEmpty) continue;
      judged = true;
      // 답이 정해지는 자리에서 끊는다(값 해석을 아끼는 자리이기도 하다).
      if (_valueMatches(operandKey, value) != every) return !every;
    }
    return every && judged;
  }

  bool _valueMatches(TagValueKey operandKey, String value) {
    // 대소 비교 연산에서만 값을 유형에 맞게 해석한다(포함 연산은 글자만 본다).
    late final int cmp = TagValueKey(
      operandKey.type,
      value,
    ).compareTo(operandKey);
    switch (operator) {
      case FilterOperator.exists:
        return true;
      case FilterOperator.contains:
        return value.toLowerCase().contains(operandKey.lowerValue);
      case FilterOperator.notContains:
        return !value.toLowerCase().contains(operandKey.lowerValue);
      case FilterOperator.equals:
        return cmp == 0;
      case FilterOperator.notEquals:
        return cmp != 0;
      case FilterOperator.lessThan:
        return cmp < 0;
      case FilterOperator.lessOrEqual:
        return cmp <= 0;
      case FilterOperator.greaterThan:
        return cmp > 0;
      case FilterOperator.greaterOrEqual:
        return cmp >= 0;
    }
  }

  FilterCondition copyWith({
    int? tagDefinitionId,
    FilterOperator? operator,
    String? operand,
    bool clearOperand = false,
    bool? exclude,
    bool? orWithPrevious,
  }) {
    return FilterCondition(
      tagDefinitionId: tagDefinitionId ?? this.tagDefinitionId,
      operator: operator ?? this.operator,
      operand: clearOperand ? null : (operand ?? this.operand),
      exclude: exclude ?? this.exclude,
      orWithPrevious: orWithPrevious ?? this.orWithPrevious,
    );
  }

  /// 값 동등성. 저장된 조건 프리셋이 **지금 걸린 조건과 같은지** 견주는 데 쓴다
  /// (같으면 그 프리셋을 활성으로 표시한다).
  @override
  bool operator ==(Object other) =>
      other is FilterCondition &&
      other.tagDefinitionId == tagDefinitionId &&
      other.operator == operator &&
      other.operand == operand &&
      other.exclude == exclude &&
      other.orWithPrevious == orWithPrevious;

  @override
  int get hashCode =>
      Object.hash(tagDefinitionId, operator, operand, exclude, orWithPrevious);
}

const _conditions = ListEquality<FilterCondition>();

/// 순서 있는 조건 목록으로 파일을 걸러내는 필터.
///
/// 조건은 **묶음** 단위로 판정된다 — [FilterCondition.orWithPrevious]가 참인 조건은
/// 앞 조건의 묶음에 붙고, 거짓이면 새 묶음을 연다. 묶음 하나는 **하나라도 만족하면
/// 만족**(OR)이고, 묶음끼리는 **모두 만족해야** 한다(AND). 이어붙임이 하나도 없으면
/// 묶음마다 조건이 하나씩이라 예전의 전부-AND와 같다.
///
/// 표시 묶음은 만족해야 통과하고, 제외 묶음은 만족하면 숨긴다. 묶음의 성격은
/// **첫 조건의 [FilterCondition.exclude]**가 정한다 — 제외는 원래 "하나라도 걸리면
/// 숨김"이라 묶어도 뜻이 같지만, 성격을 조건마다 다시 보면 한 묶음 안에서 판정이
/// 갈려 읽는 사람이 결과를 셀 수 없다.
///
/// 조건 순서는 이제 **묶음의 경계를 정하므로 결과에 영향을 준다**.
class FileFilter {
  const FileFilter({this.conditions = const <FilterCondition>[]});

  final List<FilterCondition> conditions;

  bool get isEmpty => conditions.isEmpty;

  bool matches(Iterable<AssignedTag> tags) {
    final list = tags is List<AssignedTag> ? tags : tags.toList();
    var exclude = false;
    var satisfied = false;
    var open = false;

    // 묶음 하나를 닫는다. 표시 묶음은 만족해야 하고, 제외 묶음은 만족하면 숨긴다.
    bool closes() => open && (exclude ? satisfied : !satisfied);

    for (final c in conditions) {
      // 첫 조건은 이을 앞이 없어 제 묶음을 연다.
      if (!c.orWithPrevious || !open) {
        if (closes()) return false;
        exclude = c.exclude;
        satisfied = false;
        open = true;
      }
      // 이미 만족한 묶음은 더 볼 것이 없다(값 해석을 아끼는 자리이기도 하다).
      satisfied = satisfied || c.matches(list);
    }
    return !closes();
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

  /// 값 동등성(조건의 순서까지 같아야 같다). 조건 프리셋의 활성 여부 판정에 쓴다.
  @override
  bool operator ==(Object other) =>
      other is FileFilter && _conditions.equals(other.conditions, conditions);

  @override
  int get hashCode => _conditions.hash(conditions);
}
