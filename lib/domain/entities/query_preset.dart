import 'file_filter.dart';
import 'file_grouping.dart';
import 'file_sort.dart';

/// 이름을 붙여 저장해 둔 조건 한 벌(필터 + 정렬 + 그룹).
///
/// 세 조건 줄을 통째로 갈아끼우는 단위다 — 불러오면 지금 걸린 조건을 **모두 지우고**
/// 이 값으로 대체한다(부분 병합 없음). 그래서 "조건이 비어 있는 프리셋"도 뜻이 있다
/// (모두 보기로 되돌리는 프리셋).
///
/// 담지 않는 것: 자세히 전용 정렬(그 뷰의 헤더 조작이 단일 출처), 보기 모드·프리뷰
/// 비율·크기 배율·펼침 상태(검색 조건이 아니라 지금 화면 상태다).
///
/// 태그 참조는 다른 보기 설정과 같이 정의 id로 담는다. 정의가 지워져도 프리셋에서
/// 지우지 않고(사용자가 만든 자산이라 조용히 갉히면 되돌릴 수 없다) **불러오는
/// 순간에만** 걸러 낸다([resolvePresetApplication]).
class QueryPreset {
  const QueryPreset({
    required this.name,
    this.filter = const FileFilter(),
    this.sort = const FileSortOrder(),
    this.grouping = const FileGrouping(),
  });

  /// 사용자가 붙인 이름. 목록 안에서 유일하며(같은 이름으로 저장하면 덮어쓴다)
  /// 캡슐에 그대로 보인다.
  final String name;

  final FileFilter filter;
  final FileSortOrder sort;
  final FileGrouping grouping;

  /// 지금 걸린 조건이 이 프리셋과 똑같은지(활성 캡슐 표시 판정).
  bool matchesQuery({
    required FileFilter filter,
    required FileSortOrder sort,
    required FileGrouping grouping,
  }) => this.filter == filter && this.sort == sort && this.grouping == grouping;

  QueryPreset copyWith({
    String? name,
    FileFilter? filter,
    FileSortOrder? sort,
    FileGrouping? grouping,
  }) => QueryPreset(
    name: name ?? this.name,
    filter: filter ?? this.filter,
    sort: sort ?? this.sort,
    grouping: grouping ?? this.grouping,
  );

  @override
  bool operator ==(Object other) =>
      other is QueryPreset &&
      other.name == name &&
      other.filter == filter &&
      other.sort == sort &&
      other.grouping == grouping;

  @override
  int get hashCode => Object.hash(name, filter, sort, grouping);
}
