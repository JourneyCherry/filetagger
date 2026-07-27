import '../../core/collections.dart';

/// 정렬 방향.
enum SortDirection { ascending, descending }

/// 한 태그를 기준으로 한 정렬 단계(태그 + 방향).
///
/// 태그처럼 하나씩 추가하는 단위다. 여러 개를 순서대로 두면 앞 단계부터 비교해
/// 동률일 때만 다음 단계로 넘어가는 다단계 정렬이 된다.
class SortKey {
  const SortKey({
    required this.tagDefinitionId,
    this.direction = SortDirection.ascending,
  });

  final int tagDefinitionId;
  final SortDirection direction;

  SortKey toggled() => SortKey(
    tagDefinitionId: tagDefinitionId,
    direction: direction == SortDirection.ascending
        ? SortDirection.descending
        : SortDirection.ascending,
  );

  /// 값 동등성. 저장된 조건 프리셋이 지금 걸린 정렬과 같은지 견주는 데 쓴다.
  @override
  bool operator ==(Object other) =>
      other is SortKey &&
      other.tagDefinitionId == tagDefinitionId &&
      other.direction == direction;

  @override
  int get hashCode => Object.hash(tagDefinitionId, direction);
}

/// 순서 있는 정렬 단계 목록.
///
/// 비어 있으면 파일 이름순이 기본이다(정렬 로직은 QueryFiles 참조). 각 단계의
/// 순서가 우선순위이므로 재배치가 결과를 바꾼다.
class FileSortOrder {
  const FileSortOrder({this.keys = const <SortKey>[]});

  final List<SortKey> keys;

  bool get isEmpty => keys.isEmpty;

  bool contains(int tagDefinitionId) =>
      keys.any((k) => k.tagDefinitionId == tagDefinitionId);

  FileSortOrder add(SortKey key) => FileSortOrder(keys: [...keys, key]);

  FileSortOrder removeAt(int index) => FileSortOrder(
    keys: [
      for (var i = 0; i < keys.length; i++)
        if (i != index) keys[i],
    ],
  );

  FileSortOrder toggleAt(int index) => FileSortOrder(
    keys: [
      for (var i = 0; i < keys.length; i++)
        if (i == index) keys[i].toggled() else keys[i],
    ],
  );

  FileSortOrder reorder(int oldIndex, int newIndex) {
    final next = [...keys];
    final item = next.removeAt(oldIndex);
    next.insert(newIndex, item);
    return FileSortOrder(keys: next);
  }

  /// 값 동등성(단계 순서=우선순위까지 같아야 같다). 조건 프리셋의 활성 여부 판정에 쓴다.
  @override
  bool operator ==(Object other) =>
      other is FileSortOrder && equalLists(other.keys, keys);

  @override
  int get hashCode => hashList(keys);
}
