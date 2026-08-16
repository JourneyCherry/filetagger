import 'dart:math';

import 'package:collection/collection.dart';

/// 정렬 방법. [random]은 값의 크기 대신 씨앗에서 나온 무작위 자리로 견주되,
/// **값이 같은 노드는 여전히 동률**이라 다음 단계로 넘어간다(다단계 정렬이
/// 그대로 산다).
enum SortDirection { ascending, descending, random }

/// 무작위 정렬을 다시 섞을 새 씨앗.
///
/// 씨앗은 "무엇을 견주는가"가 아니라 "어떻게 섞는가"를 정한다 — 씨앗이 그대로면
/// 목록을 다시 세워도(재스캔·태그 수정·앱 재시작) 같은 순서가 나오므로, 화면이
/// 제풀에 흐트러지지 않는다.
int newSortSeed() => Random().nextInt(1 << 32);

/// 한 태그를 기준으로 한 정렬 단계(태그 + 방법).
///
/// 태그처럼 하나씩 추가하는 단위다. 여러 개를 순서대로 두면 앞 단계부터 비교해
/// 동률일 때만 다음 단계로 넘어가는 다단계 정렬이 된다.
class SortKey {
  const SortKey({
    required this.tagDefinitionId,
    this.direction = SortDirection.ascending,
    this.seed = 0,
  });

  /// 새로 섞은 무작위 단계. 무작위를 고르는 것이 곧 "다시 섞기"가 되도록,
  /// 이 단계가 만들어질 때마다 씨앗을 새로 뽑는다.
  SortKey.shuffled({required this.tagDefinitionId})
    : direction = SortDirection.random,
      seed = newSortSeed();

  final int tagDefinitionId;
  final SortDirection direction;

  /// 무작위 정렬에서 섞는 방법을 정하는 씨앗(다른 방법에서는 쓰이지 않는다).
  final int seed;

  /// 다음 정렬 방법(오름 → 내림 → 무작위). 정렬 줄의 캡슐을 탭할 때마다 도는
  /// 차례이며, 무작위로 들어설 때마다 새로 섞인다.
  SortKey cycled() => switch (direction) {
    SortDirection.ascending => SortKey(
      tagDefinitionId: tagDefinitionId,
      direction: SortDirection.descending,
    ),
    SortDirection.descending => SortKey.shuffled(
      tagDefinitionId: tagDefinitionId,
    ),
    SortDirection.random => SortKey(tagDefinitionId: tagDefinitionId),
  };

  /// 오름↔내림만 뒤집는다. 열 머리글을 눌러 정렬하는 자세히 보기가 쓴다 — 표의
  /// 머리글은 "그 열로 정렬"이 뜻이라 무작위가 끼어들 자리가 아니다.
  SortKey toggled() => SortKey(
    tagDefinitionId: tagDefinitionId,
    direction: direction == SortDirection.ascending
        ? SortDirection.descending
        : SortDirection.ascending,
  );

  /// 값 동등성. 저장된 조건 프리셋이 지금 걸린 정렬과 같은지 견주는 데 쓴다.
  /// 씨앗도 값이다 — 빼면 다시 섞은 것이 "안 바뀐 것"으로 읽혀 화면에 닿지 않는다.
  @override
  bool operator ==(Object other) =>
      other is SortKey &&
      other.tagDefinitionId == tagDefinitionId &&
      other.direction == direction &&
      other.seed == seed;

  @override
  int get hashCode => Object.hash(tagDefinitionId, direction, seed);
}

const _keys = ListEquality<SortKey>();

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

  FileSortOrder cycleAt(int index) => FileSortOrder(
    keys: [
      for (var i = 0; i < keys.length; i++)
        if (i == index) keys[i].cycled() else keys[i],
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
      other is FileSortOrder && _keys.equals(other.keys, keys);

  @override
  int get hashCode => _keys.hash(keys);
}
