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
  Comparator<FileNode> comparator({
    required Map<int, List<AssignedTag>> assignmentsByFile,
    required FileSortOrder sort,
    required Map<int, TagDefinition> definitionsById,
  }) {
    return (a, b) {
      for (final key in sort.keys) {
        final cmp = _compareByKey(
          a,
          b,
          key,
          assignmentsByFile,
          definitionsById,
        );
        if (cmp != 0) return cmp;
      }
      // 정렬 단계가 없거나 모든 단계가 동률이면 이름으로 안정화한다.
      return _compareName(a, b);
    };
  }

  int _compareByKey(
    FileNode a,
    FileNode b,
    SortKey key,
    Map<int, List<AssignedTag>> assignmentsByFile,
    Map<int, TagDefinition> definitionsById,
  ) {
    final type = definitionsById[key.tagDefinitionId]?.valueType;
    final descending = key.direction == SortDirection.descending;
    final av = _representativeValue(
      _tagsOf(a, assignmentsByFile),
      key.tagDefinitionId,
      type,
      descending,
    );
    final bv = _representativeValue(
      _tagsOf(b, assignmentsByFile),
      key.tagDefinitionId,
      type,
      descending,
    );
    // 이 태그값이 없는 노드는 방향과 무관하게 이 단계에서 뒤로 민다.
    if (av == null && bv == null) return 0;
    if (av == null) return 1;
    if (bv == null) return -1;
    if (type == null) return 0;
    final cmp = compareTagValues(type, av, bv);
    return descending ? -cmp : cmp;
  }

  /// 파일이 가진 이 태그의 값 중 정렬 방향에 맞는 대표값(오름=최소, 내림=최대).
  /// 값이 하나도 없으면 null(→ 정렬에서 항상 뒤로). 여러 값(다중 부여)을 하나로
  /// 접어 안정적으로 비교한다. label은 값이 없으므로 부여 여부만 보아, 존재하면
  /// 비교상 동률인 대표값(빈 문자열)을, 없으면 null을 돌려 방향과 무관하게
  /// "부여된 요소가 위, 없는 요소는 뒤"가 되게 한다.
  String? _representativeValue(
    List<AssignedTag> tags,
    int tagDefinitionId,
    TagValueType? type,
    bool descending,
  ) {
    // label과 image는 값이 없거나(label) 불투명해(image) 부여 여부만 정렬한다.
    if (type == TagValueType.label || type == TagValueType.image) {
      final present = tags.any((t) => t.tagDefinitionId == tagDefinitionId);
      return present ? '' : null;
    }

    String? best;
    for (final t in tags) {
      if (t.tagDefinitionId != tagDefinitionId) continue;
      final v = t.value;
      if (v == null || v.isEmpty) continue;
      if (best == null) {
        best = v;
        continue;
      }
      if (type == null) continue;
      final cmp = compareTagValues(type, v, best);
      // 오름차순이면 더 작은 값, 내림차순이면 더 큰 값을 대표로.
      if (descending ? cmp > 0 : cmp < 0) best = v;
    }
    return best;
  }

  List<AssignedTag> _tagsOf(
    FileNode file,
    Map<int, List<AssignedTag>> assignmentsByFile,
  ) {
    final id = file.id;
    if (id == null) return const [];
    return assignmentsByFile[id] ?? const [];
  }

  int _compareName(FileNode a, FileNode b) {
    // 탐색기 관례대로 폴더를 파일보다 먼저 두고, 그 안에서 이름순.
    if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
    final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    return byName != 0 ? byName : a.path.compareTo(b.path);
  }
}
