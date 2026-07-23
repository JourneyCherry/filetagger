/// 커스텀 이미지 태그의 **캐시 키 규약과 순수 계산**을 모은 곳. 파일 I/O·이미지
/// 디코딩(데이터 계층)과 분리해, 키 형식·상대 경로·축소 크기·참조 수집을 플랫폼
/// 없이 유닛테스트한다.
library;

import '../../core/constants.dart';
import '../entities/assigned_tag.dart';
import '../entities/tag_value_type.dart';

/// 캐시 키(파일명)를 워크스페이스 루트 기준 상대 경로로. 썸네일 해석
/// ([resolveThumbnailRelPaths]·[FileThumbnail])이 '/'로 잇고 다시 가르는 규약을
/// 따른다(캐시 폴더는 `.filetagger/` 아래에 있어 루트 하위 경로가 된다).
String thumbnailCacheRelPath(String key) =>
    '$filetaggerDirName/$thumbnailCacheDirName/$key';

/// 원본 크기가 [maxDimension]을 넘으면 비율을 유지한 축소 목표 크기를, 넘지 않으면
/// null(축소 불필요)을 돌려준다. 가장 긴 변이 [maxDimension]에 맞도록 줄인다.
(int width, int height)? downscaleTargetSize(
  int width,
  int height,
  int maxDimension,
) {
  if (width <= 0 || height <= 0) return null;
  final longest = width > height ? width : height;
  if (longest <= maxDimension) return null;
  final factor = maxDimension / longest;
  final tw = (width * factor).round();
  final th = (height * factor).round();
  return (tw < 1 ? 1 : tw, th < 1 ? 1 : th);
}

/// 부여 기록 전체에서 **커스텀 이미지 태그가 참조하는 캐시 키** 집합을 모은다.
/// GC(참조되지 않는 캐시 파일 삭제)의 "살려 둘 키" 목록으로 쓴다. 어느 태그가
/// 썸네일 출처로 지정됐는지와 무관하게 **모든** 이미지 태그의 값을 센다(캐시 파일은
/// 지정 여부가 아니라 부여 존재로 살아 있다).
Set<String> referencedImageKeys(Map<int, List<AssignedTag>> assignmentsByFile) {
  final keys = <String>{};
  for (final list in assignmentsByFile.values) {
    for (final a in list) {
      if (a.definition.valueType != TagValueType.image) continue;
      final v = a.value;
      if (v != null && v.isNotEmpty) keys.add(v);
    }
  }
  return keys;
}
