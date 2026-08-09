import '../../core/collections.dart';
import 'file_filter.dart';
import 'file_grouping.dart';
import 'file_sort.dart';

/// 이름을 붙여 저장해 둔 한 벌(필터 + 정렬 + 그룹 + 이름·썸네일 출처).
///
/// 조건 세 줄과 표시 출처 둘을 통째로 갈아끼우는 단위다 — 불러오면 지금 걸린 것을
/// **모두 지우고** 이 값으로 대체한다(부분 병합 없음). 그래서 "비어 있는 프리셋"도
/// 뜻이 있다(모두 보기 + 파일 이름·기본 썸네일로 되돌리는 프리셋).
///
/// 이름·썸네일 출처를 함께 담는 이유는 **하는 일에 따라 이름 칸과 썸네일에 보고 싶은
/// 것이 조건과 함께 갈리기** 때문이다(읽을 것을 고를 때와 정리할 때가 다르다). 다만
/// 이 둘은 질의가 아니라 **표시**라, 조건 줄에 나란히 놓지는 않는다 — 같은 줄에 서면
/// 정렬·필터에도 걸리는 것처럼 읽히는데 실제로는 렌더링에서 멈춘다.
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
    this.nameSources = const [],
    this.thumbnailSources = const [],
  });

  /// 사용자가 붙인 이름. 목록 안에서 유일하며(같은 이름으로 저장하면 덮어쓴다)
  /// 캡슐에 그대로 보인다.
  final String name;

  final FileFilter filter;
  final FileSortOrder sort;
  final FileGrouping grouping;

  /// 이름 칸에 보일 값의 출처 우선순위(앞이 높음). 비면 파일 이름을 쓴다.
  final List<int> nameSources;

  /// 노드 썸네일의 출처 우선순위(앞이 높음). 비면 기본 썸네일을 쓴다.
  final List<int> thumbnailSources;

  /// 지금 걸린 것이 이 프리셋과 똑같은지(활성 캡슐 표시 판정).
  bool matchesQuery({
    required FileFilter filter,
    required FileSortOrder sort,
    required FileGrouping grouping,
    required List<int> nameSources,
    required List<int> thumbnailSources,
  }) =>
      this.filter == filter &&
      this.sort == sort &&
      this.grouping == grouping &&
      equalLists(this.nameSources, nameSources) &&
      equalLists(this.thumbnailSources, thumbnailSources);

  QueryPreset copyWith({
    String? name,
    FileFilter? filter,
    FileSortOrder? sort,
    FileGrouping? grouping,
    List<int>? nameSources,
    List<int>? thumbnailSources,
  }) => QueryPreset(
    name: name ?? this.name,
    filter: filter ?? this.filter,
    sort: sort ?? this.sort,
    grouping: grouping ?? this.grouping,
    nameSources: nameSources ?? this.nameSources,
    thumbnailSources: thumbnailSources ?? this.thumbnailSources,
  );

  @override
  bool operator ==(Object other) =>
      other is QueryPreset &&
      other.name == name &&
      other.filter == filter &&
      other.sort == sort &&
      other.grouping == grouping &&
      equalLists(other.nameSources, nameSources) &&
      equalLists(other.thumbnailSources, thumbnailSources);

  @override
  int get hashCode => Object.hash(
    name,
    filter,
    sort,
    grouping,
    hashList(nameSources),
    hashList(thumbnailSources),
  );
}
