/// 파일 유형·프리뷰 배치와 관련된 순수 헬퍼들. 플랫폼·UI 프레임워크에 의존하지
/// 않아 그대로 유닛테스트한다.
library;

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
/// 이미지 파일은 자기 자신 한 장, 폴더는 하위 대표 이미지들(겹쳐 쌓기용)이다.
/// (사용자 커스텀 지정은 이후 작업으로 미룬다.)
List<String> resolveThumbnailRelPaths(
  FileNode node,
  Map<String, List<String>> folderThumbnails,
) {
  if (node.isMissing) return const [];
  if (!node.isDirectory) {
    return isImagePath(node.path) ? [node.path] : const [];
  }
  return folderThumbnails[node.path] ?? const [];
}
