/// 파일 유형·프리뷰 배치와 관련된 순수 헬퍼들. 플랫폼·UI 프레임워크에 의존하지
/// 않아 그대로 유닛테스트한다.
library;

import '../domain/entities/assigned_tag.dart';
import '../domain/entities/file_node.dart';
import '../domain/entities/tag_value_type.dart';
import '../domain/entities/workspace_view_settings.dart';
import '../domain/usecases/thumbnail_cache.dart';

/// Flutter 이미지 디코더가 표시할 수 있는 확장자 집합(소문자, 점 제외).
const Set<String> imageFileExtensions = {
  'jpg',
  'jpeg',
  'png',
  'gif',
  'webp',
  'bmp',
};

/// 경로가 이미지 파일 확장자를 가지는지(대소문자 무시).
bool isImagePath(String path) {
  final dot = path.lastIndexOf('.');
  if (dot < 0 || dot == path.length - 1) return false;
  return imageFileExtensions.contains(path.substring(dot + 1).toLowerCase());
}

/// 프리뷰 창을 가로 배치(목록 왼쪽)로 둘지 여부. 창이 세로로 길면 위쪽(세로
/// 배치)이 낫다는 판단만 담는다. 배치 자체는 호출 측이 그린다.
bool preferHorizontalPreview(double width, double height) => width >= height;

/// 폴더 썸네일을 겹쳐 쌓아 그릴 때 최대 몇 장까지 쓸지.
const int kFolderThumbnailStackCount = 3;

/// 각 폴더(루트 기준 상대 경로)에 대해 그 하위(재귀)의 대표 이미지들(이름순 앞에서
/// 최대 [kFolderThumbnailStackCount]장)을 구한다. 겹쳐 쌓은 폴더 썸네일에 쓴다.
/// 폴더 노드와 연결 끊김 노드는 후보에서 제외하며, 디스크를 다시 읽지 않고
/// 인메모리 인덱스만으로 계산한다.
Map<String, List<String>> buildFolderThumbnailIndex(Iterable<FileNode> nodes) {
  final images = <String>[];
  for (final node in nodes) {
    if (node.isDirectory || node.isMissing) continue;
    if (isImagePath(node.path)) images.add(node.path);
  }
  images.sort();

  final result = <String, List<String>>{};
  for (final path in images) {
    // 이 이미지의 모든 상위 폴더에 상한까지 채워 넣는다. 이름순으로 정렬돼 있어
    // 각 폴더가 하위 이미지들을 이름순 앞에서부터 모은다.
    var slash = path.indexOf('/');
    while (slash != -1) {
      final list = result.putIfAbsent(path.substring(0, slash), () => []);
      if (list.length < kFolderThumbnailStackCount) list.add(path);
      slash = path.indexOf('/', slash + 1);
    }
  }
  return result;
}

/// 노드가 목록·프리뷰에서 보여줄 이미지들의 루트 기준 상대 경로. 비면 기본 아이콘.
///
/// **출처 우선순위([sources])** 순으로 훑어 처음으로 이미지를 낸 출처를 쓴다. 각
/// 항목은 커스텀 태그 id(그 노드의 이미지들은 [customByTag]에서 찾는다) 또는
/// [kDefaultThumbnailSourceId](기본 동작: 이미지=자기 자신, 폴더=하위 대표)다. 어느
/// 출처도 이미지를 못 내면 마지막에 기본 동작으로 폴백한다 — 커스텀 없는 노드도 늘
/// 제 썸네일을 보이게 한다.
///
/// [preferSelfImage]는 **프리뷰**용이다: 자기 자신을 이미지로 표현할 수 있는 노드
/// (이미지 파일)는 우선순위와 무관하게 **자기 자신을** 보인다 — 프리뷰는 그 노드
/// 자체를 크게 보는 자리이므로, 목록의 대체 썸네일이 아니라 원본을 띄운다. 자기
/// 이미지가 없는 노드(폴더·텍스트 등)만 커스텀을 프리뷰에 쓴다.
List<String> resolveThumbnailRelPaths(
  FileNode node,
  Map<String, List<String>> folderThumbnails, {
  List<int> sources = const [],
  Map<int, List<String>> customByTag = const {},
  bool preferSelfImage = false,
}) {
  if (node.isMissing) return const [];
  // 프리뷰: 자기 이미지가 있으면 우선순위와 무관하게 자기 자신을 우선한다.
  if (preferSelfImage && !node.isDirectory && isImagePath(node.path)) {
    return [node.path];
  }
  for (final source in sources) {
    if (source == kDefaultThumbnailSourceId) {
      final builtIn = _builtInThumbnails(node, folderThumbnails);
      if (builtIn.isNotEmpty) return builtIn;
      continue;
    }
    final images = customByTag[source];
    if (images != null && images.isNotEmpty) return images;
  }
  // 어느 출처도 못 냈으면(기본이 목록에 없었거나 아무 것도 안 나온 경우) 기본으로 폴백.
  return _builtInThumbnails(node, folderThumbnails);
}

/// 기본 썸네일: 이미지 파일은 자기 자신 한 장, 폴더는 하위 대표들(겹쳐 쌓기), 그 밖은
/// 없음.
List<String> _builtInThumbnails(
  FileNode node,
  Map<String, List<String>> folderThumbnails,
) {
  if (!node.isDirectory) {
    return isImagePath(node.path) ? [node.path] : const [];
  }
  return folderThumbnails[node.path] ?? const [];
}

/// 노드 id → (썸네일 출처 태그 id → 그 노드의 커스텀 이미지 상대 경로들) 인덱스.
///
/// [sourceTagIds]에 든 링크/이미지 태그만 본다. **링크**면 가리키는 대상이 이미지일
/// 때 그 경로를, **이미지(커스텀 등록)**면 `.filetagger/` 캐시의 상대 경로를 담는다
/// (다중 부여면 여러 장을 겹쳐 쌓는다). [resolveThumbnailRelPaths]가 우선순위에 따라
/// 이 중 하나를 고른다. 링크 값은 대상 노드 id, 이미지 값은 캐시 키다.
Map<int, Map<int, List<String>>> buildCustomThumbnailIndex({
  required Set<int> sourceTagIds,
  required Map<int, List<AssignedTag>> assignmentsByFile,
  required Map<int, FileNode> nodesById,
}) {
  if (sourceTagIds.isEmpty) return const {};
  final result = <int, Map<int, List<String>>>{};
  for (final entry in assignmentsByFile.entries) {
    Map<int, List<String>>? byTag;
    for (final a in entry.value) {
      if (!sourceTagIds.contains(a.tagDefinitionId)) continue;
      final raw = a.value;
      if (raw == null || raw.isEmpty) continue;
      String? path;
      if (a.definition.valueType == TagValueType.image) {
        // 캐시 파일 존재 여부는 여기서 확인하지 않는다 — 없으면 FileThumbnail이
        // 기본 아이콘으로 폴백한다.
        path = thumbnailCacheRelPath(raw);
      } else {
        // 링크: 저장값(대상 노드 id)이 가리키는 노드가 이미지면 그 경로를 쓴다.
        final target = nodesById[int.tryParse(raw)];
        if (target == null || target.isMissing || !isImagePath(target.path)) {
          continue;
        }
        path = target.path;
      }
      byTag ??= <int, List<String>>{};
      (byTag[a.tagDefinitionId] ??= <String>[]).add(path);
    }
    if (byTag != null) result[entry.key] = byTag;
  }
  return result;
}
