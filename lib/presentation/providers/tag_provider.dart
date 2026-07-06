import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/drift_tag_repository.dart';
import '../../domain/entities/assigned_tag.dart';
import '../../domain/entities/tag_definition.dart';
import '../../domain/repositories/tag_repository.dart';
import 'database_provider.dart';

/// 현재 워크스페이스 DB에 종속된 태그 저장소. 열린 폴더가 없으면 null.
final tagRepositoryProvider = Provider<TagRepository?>((ref) {
  final db = ref.watch(databaseProvider);
  if (db == null) return null;
  return DriftTagRepository(db);
});

/// 전체 태그 정의 목록(이름순) 스트림.
final tagDefinitionsProvider = StreamProvider<List<TagDefinition>>((ref) {
  final repo = ref.watch(tagRepositoryProvider);
  if (repo == null) return Stream.value(const []);
  return repo.watchDefinitions();
});

/// 파일 노드 id → 그 파일에 부여된 태그 목록. 목록 칩·다이얼로그가 구독한다.
final assignmentsByFileProvider = StreamProvider<Map<int, List<AssignedTag>>>((
  ref,
) {
  final repo = ref.watch(tagRepositoryProvider);
  if (repo == null) return Stream.value(const {});
  return repo.watchAssignments().map((assignments) {
    final grouped = <int, List<AssignedTag>>{};
    for (final assigned in assignments) {
      grouped.putIfAbsent(assigned.fileNodeId, () => []).add(assigned);
    }
    return grouped;
  });
});

/// 태그 정의 id → 그 태그가 부여된 (서로 다른) 파일 노드 수. 태그 삭제 시 영향
/// 범위를 사용자에게 경고하는 데 쓴다. 부여가 없으면 맵에 키가 없다(0).
final nodeCountByTagProvider = StreamProvider<Map<int, int>>((ref) {
  final repo = ref.watch(tagRepositoryProvider);
  if (repo == null) return Stream.value(const {});
  return repo.watchAssignments().map((assignments) {
    final nodesByTag = <int, Set<int>>{};
    for (final assigned in assignments) {
      nodesByTag
          .putIfAbsent(assigned.tagDefinitionId, () => <int>{})
          .add(assigned.fileNodeId);
    }
    return {for (final e in nodesByTag.entries) e.key: e.value.length};
  });
});
