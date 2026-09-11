import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/drift_tag_repository.dart';
import '../../domain/entities/assigned_tag.dart';
import '../../domain/entities/tag_definition.dart';
import '../../domain/repositories/tag_repository.dart';
import 'database_provider.dart';

/// 현재 워크스페이스 DB에 종속된 태그 저장소. 열린 폴더가 없으면 null.
///
/// **폴더를 열 때 가리키는 곳이 없는 부여를 한 번 걷어낸다.** 정의 없는 부여는 이름도
/// 유형도 없어 어느 화면에도 뜨지 않으므로 사용자가 지울 수단이 없고, 남아 있으면 부여
/// 수만 부풀린다. 평소에는 지울 것이 없다(외래키가 이미 딸려 지운다) — 외래키가 서지
/// 않은 채 쓰인 적이 있는 DB를 위한 자리다. 콘솔은 `prune`이 같은 일을 한다.
final tagRepositoryProvider = Provider<TagRepository?>((ref) {
  final db = ref.watch(databaseProvider);
  if (db == null) return null;
  final repo = DriftTagRepository(db);
  // 결과를 기다리지 않는다 — 지울 것이 있었다면 부여 스트림이 곧 그 뒤 모습을 낸다.
  unawaited(repo.deleteDanglingAssignments());
  return repo;
});

/// 전체 태그 정의 목록(이름순) 스트림.
final tagDefinitionsProvider = StreamProvider<List<TagDefinition>>((ref) {
  final repo = ref.watch(tagRepositoryProvider);
  if (repo == null) return Stream.value(const []);
  return repo.watchDefinitions();
});

/// 워크스페이스의 모든 태그 부여(정의를 조인한 것) 스트림.
///
/// 아래 두 파생 맵이 이 하나를 나눠 본다 — 각자 구독하면 같은 조인 질의가 두 번 돌고
/// 부여 객체도 두 벌 만들어진다.
final assignmentsProvider = StreamProvider<List<AssignedTag>>((ref) {
  final repo = ref.watch(tagRepositoryProvider);
  if (repo == null) return Stream.value(const []);
  return repo.watchAssignments();
});

/// 파일 노드 id → 그 파일에 부여된 태그 목록. 목록 칩·다이얼로그가 구독한다.
final assignmentsByFileProvider =
    Provider<AsyncValue<Map<int, List<AssignedTag>>>>((ref) {
      return ref.watch(assignmentsProvider).whenData((assignments) {
        final grouped = <int, List<AssignedTag>>{};
        for (final assigned in assignments) {
          grouped.putIfAbsent(assigned.fileNodeId, () => []).add(assigned);
        }
        return grouped;
      });
    });

/// 태그 정의 id → 그 태그가 부여된 (서로 다른) 파일 노드 수. 태그 삭제 시 영향
/// 범위를 사용자에게 경고하는 데 쓴다. 부여가 없으면 맵에 키가 없다(0).
final nodeCountByTagProvider = Provider<AsyncValue<Map<int, int>>>((ref) {
  return ref.watch(assignmentsProvider).whenData((assignments) {
    final nodesByTag = <int, Set<int>>{};
    for (final assigned in assignments) {
      nodesByTag
          .putIfAbsent(assigned.tagDefinitionId, () => <int>{})
          .add(assigned.fileNodeId);
    }
    return {for (final e in nodesByTag.entries) e.key: e.value.length};
  });
});
