import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/assigned_tag.dart';
import '../../domain/entities/file_node.dart';
import '../../domain/entities/system_tag.dart';
import '../../domain/entities/tag_definition.dart';
import '../../domain/usecases/resolve_link_values.dart';
import '../../domain/usecases/tag_display_order.dart';
import '../tag_visuals.dart';
import 'file_node_provider.dart';
import 'file_view_provider.dart';
import 'tag_provider.dart';

/// 모든 시스템 태그의 표시용 정의(정적). 선택기·정의맵 병합에 쓴다.
final systemTagDefinitionsProvider = Provider<List<TagDefinition>>(
  (ref) => systemTagDefinitions,
);

/// 사용자 정의 태그 + 시스템 태그를 합친, 필터·정렬에서 **고를 수 있는** 태그 목록.
/// 관리 화면의 CRUD 목록([tagDefinitionsProvider])과 달리 시스템 태그를 포함한다.
final pickableTagDefinitionsProvider = Provider<List<TagDefinition>>((ref) {
  final user = ref.watch(tagDefinitionsProvider).valueOrNull ?? const [];
  return [...user, ...systemTagDefinitions];
});

/// 표시할 시스템 태그 id 집합(보기 설정 파생). 목록·프리뷰 칩 렌더 필터에 쓴다.
final visibleSystemTagIdsProvider = Provider<Set<int>>(
  (ref) => ref.watch(viewSettingsProvider).visibleSystemTagIds,
);

/// 태그 부여를 목록·프리뷰에 **칩으로 표시할지** 판정하는 술어(보기 설정 파생).
/// 시스템 태그는 표시로 켠 것만, 사용자 태그는 감춤으로 끄지 않은 것만 통과한다.
/// 그룹 헤더 이름은 이 필터를 거치지 않아 감춘 태그도 나타난다.
final tagChipVisibleProvider = Provider<bool Function(int)>(
  (ref) => ref.watch(viewSettingsProvider).isTagChipVisible,
);

/// 저장된 표시 순서를 지금 존재하는 태그 전체를 덮는 완전한 순서로 보정한 것.
/// 목록·프리뷰의 칩 정렬과 순서 편집 다이얼로그가 모두 이 순서를 단일 출처로 쓴다.
/// 보정으로 시스템 태그의 기본 자리(사용자 태그 뒤)를 지키되, 저장된 순서는 그대로
/// 존중하므로 사용자가 끌어 옮긴 자리는 유지된다([normalizeTagOrder]).
final effectiveTagDisplayOrderProvider = Provider<List<int>>((ref) {
  final stored = ref.watch(tagDisplayOrderProvider);
  final allIds = [
    for (final d in ref.watch(pickableTagDefinitionsProvider))
      if (d.id != null) d.id!,
  ];
  return normalizeTagOrder(allIds, stored);
});

/// 링크 태그값(대상 노드 id 문자열)을 대상 이름으로 해석하는 함수. 대상을 찾지
/// 못하면 null. 표시·필터·정렬·그룹이 링크를 이름 기준으로 다루도록 주입한다.
final linkTargetNameResolverProvider = Provider<String? Function(String)>((
  ref,
) {
  final byId = ref.watch(fileNodesByIdProvider);
  return (raw) => byId[int.tryParse(raw)]?.name;
});

/// 사용자 태그 부여만 담되 **링크 값을 대상 이름으로 해석한** 맵. 대상을 찾지 못한
/// 링크에는 미해결 표식이 붙는다([resolveLinkAssignments]).
///
/// 시스템 태그를 병합하기 **전에** 놓는 이유는 미해결 링크 시스템 태그 때문이다 —
/// 그 값은 해석이 끝나야 알 수 있어, 병합 뒤에 해석하면 계산 순서가 거꾸로 된다.
final _resolvedUserAssignmentsProvider = Provider<Map<int, List<AssignedTag>>>((
  ref,
) {
  final userByFile =
      ref.watch(assignmentsByFileProvider).valueOrNull ?? const {};
  final nameOf = ref.watch(linkTargetNameResolverProvider);
  return resolveLinkAssignments(userByFile, nameOf);
});

/// 파일 노드 id → 그 노드의 시스템 태그 부여. 노드에서 파생되는 것과, 부여 목록을
/// 봐야 아는 것(미해결 링크)을 함께 계산한다. 링크 해석 여부와 무관하게 같은 값이라
/// 아래 두 맵이 이것을 나눠 쓴다.
final _systemAssignmentsByFileProvider = Provider<Map<int, List<AssignedTag>>>((
  ref,
) {
  final nodes = ref.watch(fileNodesProvider).valueOrNull ?? const [];
  final resolvedUser = ref.watch(_resolvedUserAssignmentsProvider);
  final result = <int, List<AssignedTag>>{};
  for (final node in nodes) {
    final id = node.id;
    if (id == null) continue;
    final system = systemAssignmentsFor(
      node,
      assignments: resolvedUser[id] ?? const [],
    );
    if (system.isNotEmpty) result[id] = system;
  }
  return result;
});

/// 파일 노드 id → 그 노드의 **사용자 + 시스템** 태그 부여 목록. 시스템 태그 값은
/// 노드에서 계산해 병합한다. 표시·이동이 쓰는 단일 출처라 링크 값은 **저장값(id)
/// 그대로**다(필터·정렬·그룹은 [resolvedAssignmentsByFileProvider]를 쓴다).
///
/// 사용자 태그가 앞, 시스템 태그가 뒤에 온다. 시스템 태그 값은 표시 여부와 무관하게
/// 항상 병합되어(필터·정렬 정확성) 있고, 칩 표시 필터는 소비 측이
/// [visibleSystemTagIdsProvider]로 건다.
final effectiveAssignmentsByFileProvider =
    Provider<Map<int, List<AssignedTag>>>((ref) {
      return _merge(
        ref.watch(fileNodesProvider).valueOrNull ?? const [],
        ref.watch(assignmentsByFileProvider).valueOrNull ?? const {},
        ref.watch(_systemAssignmentsByFileProvider),
      );
    });

/// [effectiveAssignmentsByFileProvider]에서 링크 태그값만 대상 이름으로 바꾼 맵.
/// 도메인 질의 계층(필터·정렬·그룹)이 링크를 이름 기준으로 다루도록 이 맵을 쓴다
/// (표시·이동은 id가 필요해 원본 맵을 쓴다).
final resolvedAssignmentsByFileProvider = Provider<Map<int, List<AssignedTag>>>(
  (ref) {
    return _merge(
      ref.watch(fileNodesProvider).valueOrNull ?? const [],
      ref.watch(_resolvedUserAssignmentsProvider),
      ref.watch(_systemAssignmentsByFileProvider),
    );
  },
);

/// 노드 id → 이름 칸에 보일 문자열(이름 태그가 정한 것). 태그가 글자를 내지 못한
/// 노드는 키가 없어, 소비 측이 노드 이름으로 폴백한다.
///
/// 링크 값이 대상 이름으로 풀린 맵을 쓴다 — 저장값(노드 id)을 이름 자리에 그대로
/// 보이면 뜻이 없다.
final displayNameByIdProvider = Provider<Map<int, String>>((ref) {
  final sources = ref.watch(nameSourcesProvider);
  if (sources.isEmpty) return const {};
  return buildDisplayNameIndex(
    assignmentsByFile: ref.watch(resolvedAssignmentsByFileProvider),
    nameSources: sources,
  );
});

/// 노드마다 사용자 부여 뒤에 시스템 부여를 잇는다. 인덱스에 있는 노드만 담고,
/// 둘 다 빈 노드는 자리를 만들지 않는다.
Map<int, List<AssignedTag>> _merge(
  List<FileNode> nodes,
  Map<int, List<AssignedTag>> user,
  Map<int, List<AssignedTag>> system,
) {
  final result = <int, List<AssignedTag>>{};
  for (final node in nodes) {
    final id = node.id;
    if (id == null) continue;
    final u = user[id] ?? const <AssignedTag>[];
    final s = system[id] ?? const <AssignedTag>[];
    if (u.isEmpty && s.isEmpty) continue;
    result[id] = [...u, ...s];
  }
  return result;
}
