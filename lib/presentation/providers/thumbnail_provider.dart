import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/constants.dart';
import '../../core/file_types.dart';
import '../../data/thumbnails/thumbnail_store.dart';
import '../../domain/entities/workspace_view_settings.dart';
import '../../domain/usecases/thumbnail_cache.dart';
import 'file_node_provider.dart';
import 'file_view_provider.dart';
import 'tag_provider.dart';
import 'workspace_provider.dart';

/// 폴더(루트 기준 상대 경로) → 그 하위 대표 이미지들(상대 경로, 최대 몇 장) 인덱스.
///
/// 스캔 목록에서 파생하며, 목록·프리뷰의 폴더 썸네일이 여기서 쌓을 이미지를 찾는다.
/// 목록 전체를 매 타일마다 훑지 않도록 한 번만 계산해 공유한다.
final folderThumbnailIndexProvider = Provider<Map<String, List<String>>>((ref) {
  final nodes = ref.watch(fileNodesProvider).valueOrNull ?? const [];
  return buildFolderThumbnailIndex(nodes);
});

/// 노드 id → (썸네일 출처 태그 id → 그 노드의 커스텀 이미지 상대 경로들) 인덱스.
/// 우선순위에 든 링크/이미지 태그(대상 노드의 이미지 또는 등록한 외부 이미지)만
/// 담는다. 목록·프리뷰의 [resolveThumbnailRelPaths]가 우선순위에 따라 하나를 고른다.
final customThumbnailIndexProvider =
    Provider<Map<int, Map<int, List<String>>>>((ref) {
      final sources = ref.watch(thumbnailSourcesProvider);
      final sourceTagIds = {
        for (final s in sources)
          if (s != kDefaultThumbnailSourceId) s,
      };
      if (sourceTagIds.isEmpty) return const {};
      final assignments =
          ref.watch(assignmentsByFileProvider).valueOrNull ?? const {};
      final nodesById = ref.watch(fileNodesByIdProvider);
      final index = buildCustomThumbnailIndex(
        sourceTagIds: sourceTagIds,
        assignmentsByFile: assignments,
        nodesById: nodesById,
      );
      final root = ref.watch(workspaceRootProvider);
      if (root == null) return index;
      return _dropMissingCacheFiles(index, root);
    });

/// 캐시 파일이 실제로 없는 커스텀 이미지 경로를 뺀다. 없으면 그 출처는 이미지를 못
/// 낸 것으로 쳐 **다음 우선순위 출처(또는 기본)로 폴백**한다 — 상위 출처의 캐시가
/// 사라졌다고 하위의 멀쩡한 썸네일까지 막혀 빈 아이콘이 뜨는 것을 방지한다. 캐시
/// 경로(`.filetagger/` 하위)만 확인하고, 링크 대상 경로(스캔된 노드)는 그대로 둔다.
/// 서로 다른 노드가 같은 캐시를 가리키므로 경로별로 한 번만 확인한다.
Map<int, Map<int, List<String>>> _dropMissingCacheFiles(
  Map<int, Map<int, List<String>>> index,
  String root,
) {
  final existsByPath = <String, bool>{};
  bool cacheExists(String rel) => existsByPath.putIfAbsent(
    rel,
    () => File(p.joinAll([root, ...rel.split('/')])).existsSync(),
  );

  final result = <int, Map<int, List<String>>>{};
  for (final entry in index.entries) {
    Map<int, List<String>>? byTag;
    for (final tag in entry.value.entries) {
      final kept = [
        for (final path in tag.value)
          if (!path.startsWith('$filetaggerDirName/') || cacheExists(path)) path,
      ];
      if (kept.isEmpty) continue;
      byTag ??= <int, List<String>>{};
      byTag[tag.key] = kept;
    }
    if (byTag != null) result[entry.key] = byTag;
  }
  return result;
}

/// 커스텀 이미지 태그의 캐시 청소기. 부여가 사라진 이미지 캐시 파일을 지운다.
///
/// **저장소가 실제로 있고 부여가 그 저장소에서 다 실린 뒤에만** 돈다. 워크스페이스가
/// 없거나 전환 중이면 [assignmentsByFileProvider]가 빈 자리표시자(`{}`)를 내는데, 이를
/// "참조 없음"으로 오인해 GC를 돌리면 멀쩡한 캐시를 몽땅 지운다(특히 껐다 켤 때 모든
/// 캐시가 유예보다 오래돼 전부 삭제됨). 그래서 저장소 존재 + 로딩 아님을 함께 확인한다.
/// 지정된 썸네일 태그와 무관하게 **모든** 이미지 태그가 참조하는 키를 살려 두고, 방금
/// 등록한 파일은 [gcThumbnails]의 유예로 보호된다. 홈 화면이 이 프로바이더를 watch한다.
final thumbnailGcProvider = Provider<void>((ref) {
  final root = ref.watch(workspaceRootProvider);
  final repo = ref.watch(tagRepositoryProvider);
  final async = ref.watch(assignmentsByFileProvider);
  if (root == null || repo == null || async.isLoading) return;
  final assignments = async.valueOrNull;
  if (assignments == null) return;
  final referenced = referencedImageKeys(assignments);
  unawaited(gcThumbnails(root, referenced));
});
