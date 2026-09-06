/// 조건 계층이 딛고 설 재료를 인덱스에서 한 번에 읽어 온다.
///
/// **시스템 태그는 여기서 계산해 붙인다.** 저장된 부여가 아니라 노드에서 파생되는
/// 값이라 DB에 없으므로, 조건이 그것을 짚으려면 읽어 오는 자리에서 한 벌 만들어
/// 얹어야 한다. 크기·확장자·수정 시각으로 거르는 것이 콘솔에서 가장 흔한 조건이라,
/// 이것이 빠지면 필터가 반만 도는 셈이 된다.
library;

import '../data/db/app_database.dart';
import '../data/repositories/drift_file_node_repository.dart';
import '../data/repositories/drift_tag_repository.dart';
import '../domain/entities/assigned_tag.dart';
import '../domain/entities/file_node.dart';
import '../domain/entities/system_tag.dart';
import '../domain/entities/tag_definition.dart';
import '../domain/usecases/resolve_link_values.dart';
import '../l10n/system_tag_names.dart';

/// 인덱스에 든 것 전부와, 조건이 이름을 풀 때 쓸 태그 카탈로그.
class WorkspaceQueryData {
  const WorkspaceQueryData({
    required this.nodes,
    required this.assignmentsByFile,
    required this.storedAssignmentsByFile,
    required this.definitions,
    required this.definitionsById,
  });

  /// 인덱스에 든 노드 전부(키워드 포함).
  final List<FileNode> nodes;

  /// 노드 id → 그 노드의 부여. **시스템 태그가 계산되어 함께 들어 있고, 링크 값은
  /// 대상의 이름으로 풀려 있다.** 조건 계층이 딛는 것이 이것이다.
  final Map<int, List<AssignedTag>> assignmentsByFile;

  /// 노드 id → **저장된** 부여만. 내보내기처럼 실제로 적혀 있는 것만 다뤄야 하는
  /// 자리가 쓴다.
  final Map<int, List<AssignedTag>> storedAssignmentsByFile;

  /// 이름으로 태그를 찾을 때 쓰는 카탈로그(사용자 정의 + 시스템).
  final List<TagDefinition> definitions;

  /// id로 태그를 찾을 때 쓰는 표(사용자 정의 + 시스템).
  final Map<int, TagDefinition> definitionsById;
}

/// 조건 계층의 재료를 읽어 온다.
///
/// [localeName]은 시스템 태그의 **표시** 이름을 정한다. 이름으로 찾는 쪽은 어느
/// 언어로 적혔는지 알 수 없으므로 모든 언어를 함께 받는다
/// ([systemTagLookupDefinitions]).
Future<WorkspaceQueryData> loadQueryData(
  AppDatabase db, {
  required String localeName,
}) async {
  final nodes = await DriftFileNodeRepository(db).watchAll().first;
  final tags = DriftTagRepository(db);
  final userDefinitions = await tags.watchDefinitions().first;
  final assignments = await tags.watchAssignments().first;

  final stored = <int, List<AssignedTag>>{};
  for (final a in assignments) {
    stored.putIfAbsent(a.fileNodeId, () => []).add(a);
  }

  // 링크는 저장은 대상 id로, 비교·표시는 대상 **이름**으로 한다. 화면과 같은 순서로
  // 이름을 먼저 풀어야 미해결 링크 시스템 태그가 제 값을 갖는다 — 그 값은 해석이
  // 끝나야 알 수 있다.
  final byId = {
    for (final node in nodes)
      if (node.id != null) node.id!: node,
  };
  final resolved = resolveLinkAssignments(
    stored,
    (raw) => byId[int.tryParse(raw)]?.name,
  );

  final systemDefinitions = systemTagDefinitionsFor(localeName);
  final combined = <int, List<AssignedTag>>{};
  for (final node in nodes) {
    final id = node.id;
    if (id == null) continue;
    final own = resolved[id] ?? const <AssignedTag>[];
    combined[id] = [
      ...own,
      ...systemAssignmentsFor(
        node,
        definitions: systemDefinitions,
        assignments: own,
      ),
    ];
  }

  // 화면과 같은 순서로 쌓는다 — 이름이 겹치면 시스템 태그가 이긴다.
  final catalog = <TagDefinition>[
    ...userDefinitions,
    ...systemTagLookupDefinitions(localeName),
  ];
  return WorkspaceQueryData(
    nodes: nodes,
    assignmentsByFile: combined,
    storedAssignmentsByFile: stored,
    definitions: catalog,
    definitionsById: {
      for (final d in catalog)
        if (d.id != null) d.id!: d,
    },
  );
}
