/// 파일 유형·프리뷰 배치와 관련된 순수 헬퍼들. 플랫폼·UI 프레임워크에 의존하지
/// 않아 그대로 유닛테스트한다.
library;

import '../domain/entities/assigned_tag.dart';
import '../domain/entities/file_node.dart';

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
/// **사용자가 지정한 커스텀 썸네일([custom])이 있으면 그것을 최우선**으로 쓴다(링크
/// 태그가 가리키는 대상 이미지). 없으면 기본 동작 — 이미지 파일은 자기 자신 한 장,
/// 폴더는 하위 대표 이미지들(겹쳐 쌓기용)이다.
///
/// [preferSelfImage]는 **프리뷰**용이다: 자기 자신을 이미지로 표현할 수 있는 노드
/// (이미지 파일)는 커스텀 썸네일보다 **자기 자신을** 보인다 — 프리뷰는 그 노드 자체를
/// 크게 보는 자리이므로, 목록의 대체 썸네일이 아니라 원본을 띄운다. 자기 이미지가 없는
/// 노드(폴더·텍스트 등)만 커스텀을 프리뷰에 쓴다. 목록(기본값 false)은 늘 커스텀 우선.
List<String> resolveThumbnailRelPaths(
  FileNode node,
  Map<String, List<String>> folderThumbnails, {
  List<String> custom = const [],
  bool preferSelfImage = false,
}) {
  if (node.isMissing) return const [];
  // 프리뷰: 자기 이미지가 있으면 커스텀보다 자기 자신을 우선한다.
  if (preferSelfImage && !node.isDirectory && isImagePath(node.path)) {
    return [node.path];
  }
  if (custom.isNotEmpty) return custom;
  if (!node.isDirectory) {
    return isImagePath(node.path) ? [node.path] : const [];
  }
  return folderThumbnails[node.path] ?? const [];
}

/// 노드 id → 그 노드의 커스텀 썸네일(루트 기준 이미지 상대 경로들) 인덱스.
///
/// 지정된 링크 태그([thumbnailTagId])가 가리키는 **대상이 이미지면** 그 경로를 그
/// 노드의 썸네일로 쓴다(다중 부여면 여러 장을 겹쳐 쌓는다). 태그가 지정되지
/// 않았거나, 대상을 찾지 못하거나, 대상이 이미지가 아니면 그 노드는 결과에서
/// 빠져([resolveThumbnailRelPaths]가 기본 동작으로 폴백). 링크 값은 대상 노드 id
/// 문자열이다.
Map<int, List<String>> buildCustomThumbnailIndex({
  required int? thumbnailTagId,
  required Map<int, List<AssignedTag>> assignmentsByFile,
  required Map<int, FileNode> nodesById,
}) {
  if (thumbnailTagId == null) return const {};
  final result = <int, List<String>>{};
  for (final entry in assignmentsByFile.entries) {
    final images = <String>[];
    for (final a in entry.value) {
      if (a.tagDefinitionId != thumbnailTagId) continue;
      final raw = a.value;
      if (raw == null || raw.isEmpty) continue;
      final target = nodesById[int.tryParse(raw)];
      if (target == null || target.isMissing) continue;
      if (isImagePath(target.path)) images.add(target.path);
    }
    if (images.isNotEmpty) result[entry.key] = images;
  }
  return result;
}
