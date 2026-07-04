import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/file_filter.dart';
import '../../domain/entities/file_node.dart';
import '../../domain/entities/file_sort.dart';
import '../../domain/entities/tag_definition.dart';
import '../../domain/usecases/query_files.dart';
import 'file_node_provider.dart';
import 'tag_provider.dart';

/// 현재 적용 중인 태그 조합 필터(순서 있는 조건 목록).
final fileFilterProvider = StateProvider<FileFilter>((ref) => const FileFilter());

/// 현재 정렬 순서(순서 있는 정렬 단계 목록). 비면 이름순.
final fileSortProvider =
    StateProvider<FileSortOrder>((ref) => const FileSortOrder());

/// 태그 정의를 id로 빠르게 찾기 위한 조회 맵.
final definitionsByIdProvider = Provider<Map<int, TagDefinition>>((ref) {
  final defs = ref.watch(tagDefinitionsProvider).valueOrNull ?? const [];
  return {for (final d in defs) if (d.id != null) d.id!: d};
});

/// 필터·정렬을 적용한 표시용 파일 목록. 로딩/에러 상태는 그대로 전달한다.
final visibleFileNodesProvider = Provider<AsyncValue<List<FileNode>>>((ref) {
  final nodes = ref.watch(fileNodesProvider);
  final assignments =
      ref.watch(assignmentsByFileProvider).valueOrNull ?? const {};
  final definitionsById = ref.watch(definitionsByIdProvider);
  final filter = ref.watch(fileFilterProvider);
  final sort = ref.watch(fileSortProvider);

  return nodes.whenData(
    (files) => const QueryFiles()(
      files: files,
      assignmentsByFile: assignments,
      filter: filter,
      sort: sort,
      definitionsById: definitionsById,
    ),
  );
});
