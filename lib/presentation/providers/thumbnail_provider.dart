import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/file_types.dart';
import 'file_node_provider.dart';
import 'file_view_provider.dart';
import 'tag_provider.dart';

/// 폴더(루트 기준 상대 경로) → 그 하위 대표 이미지들(상대 경로, 최대 몇 장) 인덱스.
///
/// 스캔 목록에서 파생하며, 목록·프리뷰의 폴더 썸네일이 여기서 쌓을 이미지를 찾는다.
/// 목록 전체를 매 타일마다 훑지 않도록 한 번만 계산해 공유한다.
final folderThumbnailIndexProvider = Provider<Map<String, List<String>>>((ref) {
  final nodes = ref.watch(fileNodesProvider).valueOrNull ?? const [];
  return buildFolderThumbnailIndex(nodes);
});

/// 노드 id → 커스텀 썸네일(루트 기준 이미지 상대 경로들) 인덱스. 사용자가 지정한
/// 링크 태그가 가리키는 대상 이미지를 그 노드의 썸네일로 쓴다(없으면 기본 동작).
/// 목록·프리뷰의 [resolveThumbnailRelPaths]에 최우선으로 주입된다.
final customThumbnailIndexProvider = Provider<Map<int, List<String>>>((ref) {
  final tagId = ref.watch(thumbnailTagIdProvider);
  if (tagId == null) return const {};
  final assignments =
      ref.watch(assignmentsByFileProvider).valueOrNull ?? const {};
  final nodesById = ref.watch(fileNodesByIdProvider);
  return buildCustomThumbnailIndex(
    thumbnailTagId: tagId,
    assignmentsByFile: assignments,
    nodesById: nodesById,
  );
});
