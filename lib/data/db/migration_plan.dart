/// 테이블 재작성 한 단계의 계획 — 오늘의 컬럼 하나하나를 **디스크에 실제로 있는**
/// 컬럼에 비추어 어떻게 채울지 나눈다.
///
/// drift의 테이블 재작성은 새 테이블을 지금의 테이블 정의로 만든 뒤, 오늘 정의된
/// 컬럼을 옛 테이블에서 **이름으로** 복사한다 — 디스크에 그 이름이 있는지는 보지
/// 않는다. 그래서 나중에 생긴 컬럼은 앞선 단계에서 "없는 컬럼"으로 참조되고, 앞선
/// 단계가 지운 옛 컬럼은 뒤 단계에서 같은 식으로 참조된다. 어느 쪽이든 그 자리에서
/// 마이그레이션이 끊긴다.
///
/// 이 계획은 디스크 모양을 먼저 보고 그 두 경우를 각각 [newColumns]와 [copied]로
/// 돌려, **어느 모양에서 시작하든** 지금 정의로 수렴시킨다(부분 적용·재실행 포함).
class TableRewritePlan {
  const TableRewritePlan({
    required this.transformed,
    required this.copied,
    required this.newColumns,
  });

  /// 변환식으로 채울 컬럼 → 그 식이 읽는 옛 컬럼 이름. 읽을 옛 컬럼이 디스크에
  /// 있을 때만 오른다.
  final Map<String, String> transformed;

  /// 옛 테이블에서 같은 이름으로 그대로 옮길 컬럼.
  final Set<String> copied;

  /// 옛 테이블에 그 이름이 없는 컬럼 — 복사할 수 없으므로 새 컬럼으로 넘긴다.
  /// 변환식이 붙는 컬럼도 옛 테이블에 제 이름이 없으면 여기 함께 든다.
  final Set<String> newColumns;

  /// 옛 테이블에 근거가 하나도 없어 비워 두는 컬럼(변환식도 복사도 못 하는 것).
  /// 널을 허용하지 않는 컬럼이 여기 들면 재작성이 성립하지 않는다.
  Set<String> get leftEmpty => newColumns.difference(transformed.keys.toSet());
}

/// [target](지금 정의의 컬럼 이름)을 [onDisk](디스크의 실제 컬럼 이름)에 비추어
/// 나눈다.
///
/// [transformSources]는 "이 컬럼은 옛 컬럼 X를 읽어 채운다"는 뜻이다. X가 디스크에
/// 없으면 변환식을 붙이지 않고, 같은 이름 컬럼이 있으면 그대로 복사하며, 그마저
/// 없으면 비워 둔다.
TableRewritePlan planTableRewrite({
  required Set<String> onDisk,
  required Iterable<String> target,
  Map<String, String> transformSources = const {},
}) {
  final transformed = <String, String>{};
  final copied = <String>{};
  final newColumns = <String>{};

  for (final column in target) {
    final source = transformSources[column];
    if (source != null && onDisk.contains(source)) {
      transformed[column] = source;
    } else if (onDisk.contains(column)) {
      copied.add(column);
    }
    if (!onDisk.contains(column)) newColumns.add(column);
  }

  return TableRewritePlan(
    transformed: transformed,
    copied: copied,
    newColumns: newColumns,
  );
}
