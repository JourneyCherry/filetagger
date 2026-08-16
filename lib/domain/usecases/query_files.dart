import '../entities/assigned_tag.dart';
import '../entities/file_filter.dart';
import '../entities/file_node.dart';
import '../entities/file_sort.dart';
import '../entities/tag_definition.dart';
import '../entities/tag_value_ordering.dart';
import '../entities/tag_value_type.dart';

/// 인메모리 파일 목록에 필터와 다단계 정렬을 적용하는 순수 유즈케이스.
///
/// 저장소를 거치지 않고 이미 스트림된 목록·부여 기록을 변환한다. 정렬·필터
/// 기준은 태그값과 유형이라 도메인 로직으로 두고 presentation에서 재사용한다.
class QueryFiles {
  const QueryFiles();

  List<FileNode> call({
    required List<FileNode> files,
    required Map<int, List<AssignedTag>> assignmentsByFile,
    required FileFilter filter,
    required FileSortOrder sort,
    required Map<int, TagDefinition> definitionsById,
  }) {
    final filtered = <FileNode>[
      for (final file in files)
        if (filter.matches(_tagsOf(file, assignmentsByFile))) file,
    ];
    filtered.sort(
      comparator(
        assignmentsByFile: assignmentsByFile,
        sort: sort,
        definitionsById: definitionsById,
      ),
    );
    return filtered;
  }

  /// 다단계 태그 정렬 + 이름 안정화 비교기. 평면 목록 정렬과 트리의 형제 정렬이
  /// 같은 규칙을 쓰도록 공개한다.
  ///
  /// 비교기는 노드마다 뽑은 **정렬 재료**(단계별 대표값·소문자 이름)를 기억해 두고
  /// 쓴다 — 정렬은 한 노드를 여러 번 비교하므로, 대표값 고르기와 숫자·날짜 파싱을
  /// 비교마다 되풀이하면 값이 없는 노드까지 매번 목록을 훑게 된다. 그래서 한 번 만든
  /// 비교기는 그것을 만들 때 넘긴 부여·정의 맵에서만 쓴다(트리 빌더가 형제 목록마다
  /// 같은 비교기를 다시 쓰는 방식 그대로다).
  Comparator<FileNode> comparator({
    required Map<int, List<AssignedTag>> assignmentsByFile,
    required FileSortOrder sort,
    required Map<int, TagDefinition> definitionsById,
  }) {
    final keys = sort.keys;
    final types = [
      for (final key in keys) definitionsById[key.tagDefinitionId]?.valueType,
    ];
    // 노드는 같은 객체로 여러 번 비교되므로 신원(identity)으로 재료를 기억한다.
    final materials = <FileNode, _SortMaterial>{};
    _SortMaterial materialOf(FileNode node) => materials.putIfAbsent(
      node,
      () => _SortMaterial(node, keys, types, assignmentsByFile),
    );

    return (a, b) {
      final ma = materialOf(a);
      final mb = materialOf(b);
      for (var i = 0; i < keys.length; i++) {
        final av = ma.values[i];
        final bv = mb.values[i];
        // 이 태그값이 없는 노드는 정렬 방법과 무관하게 이 단계에서 뒤로 민다.
        if (av == null && bv == null) continue;
        if (av == null) return 1;
        if (bv == null) return -1;
        // 값이 같으면 어떤 방법이든 동률이라 다음 단계로 넘어간다(무작위도 값
        // 자체를 섞을 뿐, 같은 값끼리의 순서는 뒤 단계가 정한다).
        final cmp = av.compareTo(bv);
        if (cmp == 0) continue;
        final ordered = switch (keys[i].direction) {
          SortDirection.ascending => cmp,
          SortDirection.descending => -cmp,
          SortDirection.random => ma.randomRanks[i].compareTo(
            mb.randomRanks[i],
          ),
        };
        // 무작위 자리가 겹친 두 값은 견줄 수 없어 동률로 두고 다음 단계로 넘긴다.
        if (ordered != 0) return ordered;
      }
      // 정렬 단계가 없거나 모든 단계가 동률이면 이름으로 안정화한다.
      return _compareName(ma, mb);
    };
  }

  List<AssignedTag> _tagsOf(
    FileNode file,
    Map<int, List<AssignedTag>> assignmentsByFile,
  ) {
    final id = file.id;
    if (id == null) return const [];
    return assignmentsByFile[id] ?? const [];
  }

  int _compareName(_SortMaterial a, _SortMaterial b) {
    // 탐색기 관례대로 폴더를 파일보다 먼저 두고, 그 안에서 이름순.
    if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
    final byName = a.lowerName.compareTo(b.lowerName);
    return byName != 0 ? byName : a.path.compareTo(b.path);
  }
}

/// 값을 견줄 수는 없고 "붙어 있다"만 뜻하는 대표값(label·image·유형 미상). 서로
/// 견주면 늘 동률이라 한 벌만 만들어 나눠 쓴다.
final TagValueKey _presenceKey = TagValueKey(TagValueType.label, '');

/// 한 노드를 정렬하는 데 필요한 재료를 미리 뽑아 둔 것(비교마다 다시 뽑지 않는다).
class _SortMaterial {
  _SortMaterial(
    FileNode node,
    List<SortKey> keys,
    List<TagValueType?> types,
    Map<int, List<AssignedTag>> assignmentsByFile,
  ) : this._(
        node,
        keys,
        _representativeValues(node, keys, types, assignmentsByFile),
      );

  _SortMaterial._(FileNode node, List<SortKey> keys, this.values)
    : isDirectory = node.isDirectory,
      lowerName = node.name.toLowerCase(),
      path = node.path,
      randomRanks = _randomRanks(keys, values);

  /// 정렬 단계별 대표값(값이 없는 단계는 null → 그 단계에서 늘 뒤로).
  final List<TagValueKey?> values;

  /// 무작위 단계에서 이 노드가 갖는 자리. 다른 방법의 단계 자리는 읽히지 않는다.
  final List<int> randomRanks;

  final bool isDirectory;
  final String lowerName;
  final String path;

  /// 파일이 가진 각 정렬 단계 태그의 값 중 정렬 방법에 맞는 대표값(오름=최소,
  /// 내림=최대, 무작위=오름과 같음 — 값끼리 견주지 않으니 고를 기준이 없다).
  /// 값이 하나도 없으면 null. 여러 값(다중 부여)을 하나로 접어 안정적으로
  /// 비교한다. label·image는 값이 없거나(label) 불투명해(image) 부여 여부만 보아,
  /// 붙어 있으면 비교상 동률인 대표값(빈 값)을, 없으면 null을 돌려 정렬 방법과
  /// 무관하게 "부여된 요소가 위, 없는 요소는 뒤"가 되게 한다.
  static List<TagValueKey?> _representativeValues(
    FileNode node,
    List<SortKey> keys,
    List<TagValueType?> types,
    Map<int, List<AssignedTag>> assignmentsByFile,
  ) {
    if (keys.isEmpty) return const [];
    final id = node.id;
    final tags = id == null
        ? const <AssignedTag>[]
        : (assignmentsByFile[id] ?? const <AssignedTag>[]);
    return [
      for (var i = 0; i < keys.length; i++)
        _representativeValue(
          tags,
          keys[i].tagDefinitionId,
          types[i],
          keys[i].direction == SortDirection.descending,
        ),
    ];
  }

  /// 무작위 단계의 자리를 대표값에서 미리 뽑아 둔다. 무작위 단계가 하나도 없으면
  /// 읽힐 일이 없어 만들지 않는다.
  static List<int> _randomRanks(List<SortKey> keys, List<TagValueKey?> values) {
    if (!keys.any((k) => k.direction == SortDirection.random)) return const [];
    return [
      for (var i = 0; i < keys.length; i++)
        if (keys[i].direction == SortDirection.random && values[i] != null)
          randomOrderRank(keys[i].seed, values[i]!)
        else
          0,
    ];
  }

  static TagValueKey? _representativeValue(
    List<AssignedTag> tags,
    int tagDefinitionId,
    TagValueType? type,
    bool descending,
  ) {
    if (type == TagValueType.label || type == TagValueType.image) {
      for (final t in tags) {
        if (t.tagDefinitionId == tagDefinitionId) return _presenceKey;
      }
      return null;
    }
    // 유형을 모르면(정의가 사라진 태그) 값을 견줄 규칙이 없다 — 값이 있는지만 보아
    // 없는 쪽을 뒤로 밀고, 있는 것끼리는 동률로 둔다.
    if (type == null) {
      for (final t in tags) {
        if (t.tagDefinitionId != tagDefinitionId) continue;
        final v = t.value;
        if (v != null && v.isNotEmpty) return _presenceKey;
      }
      return null;
    }

    TagValueKey? best;
    for (final t in tags) {
      if (t.tagDefinitionId != tagDefinitionId) continue;
      final v = t.value;
      if (v == null || v.isEmpty) continue;
      final key = TagValueKey(type, v);
      // 오름차순이면 더 작은 값, 내림차순이면 더 큰 값을 대표로.
      if (best == null) {
        best = key;
      } else {
        final cmp = key.compareTo(best);
        if (descending ? cmp > 0 : cmp < 0) best = key;
      }
    }
    return best;
  }
}
