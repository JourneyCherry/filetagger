import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/assigned_tag.dart';
import '../../domain/entities/system_tag.dart';
import '../../domain/entities/tag_definition.dart';
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

/// 파일 노드 id → 그 노드의 **사용자 + 시스템** 태그 부여 목록. 시스템 태그 값은
/// 노드에서 계산해 병합한다. 표시/필터/정렬이 쓰는 단일 출처.
///
/// 사용자 태그가 앞, 시스템 태그가 뒤에 온다. 시스템 태그 값은 표시 여부와 무관하게
/// 항상 병합되어(필터·정렬 정확성) 있고, 칩 표시 필터는 소비 측이
/// [visibleSystemTagIdsProvider]로 건다.
final effectiveAssignmentsByFileProvider =
    Provider<Map<int, List<AssignedTag>>>((ref) {
      final nodes = ref.watch(fileNodesProvider).valueOrNull ?? const [];
      final userByFile =
          ref.watch(assignmentsByFileProvider).valueOrNull ?? const {};

      final result = <int, List<AssignedTag>>{};
      for (final node in nodes) {
        final id = node.id;
        if (id == null) continue;
        final system = systemAssignmentsFor(node);
        final user = userByFile[id] ?? const <AssignedTag>[];
        if (system.isEmpty && user.isEmpty) continue;
        result[id] = [...user, ...system];
      }
      return result;
    });
