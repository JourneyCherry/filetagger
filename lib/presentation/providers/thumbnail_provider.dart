import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/file_types.dart';
import 'file_node_provider.dart';

/// 폴더(루트 기준 상대 경로) → 그 하위 대표 이미지들(상대 경로, 최대 몇 장) 인덱스.
///
/// 스캔 목록에서 파생하며, 목록·프리뷰의 폴더 썸네일이 여기서 쌓을 이미지를 찾는다.
/// 목록 전체를 매 타일마다 훑지 않도록 한 번만 계산해 공유한다.
final folderThumbnailIndexProvider = Provider<Map<String, List<String>>>((ref) {
  final nodes = ref.watch(fileNodesProvider).valueOrNull ?? const [];
  return buildFolderThumbnailIndex(nodes);
});
