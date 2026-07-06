import 'folder_manage_mode.dart';

/// 스캔으로 인덱싱된 파일 또는 폴더 하나.
///
/// 관리 폴더 루트 기준의 상대 경로로 식별하며, 저장 계층(Drift row)과 독립된
/// 순수 도메인 표현이다. 경로 구분자는 플랫폼·저장 위치와 무관하게 항상 '/'로
/// 정규화해 폴더를 다른 OS로 옮겨도 안정적으로 매칭되게 한다.
class FileNode {
  const FileNode({
    this.id,
    required this.path,
    required this.isDirectory,
    this.size,
    this.modifiedAt,
    this.contentHashPrefix,
    this.missingSince,
    this.manageMode,
    this.childSignature,
    this.imageDimensions,
  });

  /// 저장소가 부여한 식별자. 아직 저장 전이면 null.
  final int? id;

  /// 관리 폴더 루트 기준 상대 경로('/' 구분).
  final String path;

  final bool isDirectory;

  /// 파일 크기(바이트). 폴더면 null.
  final int? size;

  final DateTime? modifiedAt;

  /// 이동 추적용 내용 부분 해시. 스캐너가 파일 앞부분을 읽어 채운다.
  final String? contentHashPrefix;

  /// 태그를 보존한 채 "연결 끊김" 상태로 남은 시각. null이면 실제 존재하는
  /// 노드다. 사라진 태그된 노드가 자동 재연결되지 못했을 때 설정된다.
  final DateTime? missingSince;

  /// 폴더의 관리 방식(내부 인덱싱 여부). 폴더 노드에만 채워지며 파일이면 null.
  /// 처음 발견되는 폴더는 [FolderManageMode.opaque]가 기본이다.
  final FolderManageMode? manageMode;

  /// 폴더 이동 추적용, 직속 자식 구성의 부분 시그니처. 폴더 노드에만 채워진다.
  /// 내용 해시가 없는 폴더를 이동 후에도 동일 폴더로 알아보기 위해 스캐너가
  /// 직속 자식 이름 구성으로 계산한다. 자식이 없으면(빈 폴더) null이다.
  final String? childSignature;

  /// 이미지 파일의 픽셀 크기("가로x세로"). 스캐너가 이미지 헤더를 파싱해 채운다.
  /// 이미지가 아니거나 크기를 못 읽으면 null이다. 시스템 태그 '이미지 크기'의 원본.
  final String? imageDimensions;

  /// 파일이 사라져 태그만 보존 중인지(수동 재연결 대상).
  bool get isMissing => missingSince != null;

  /// 목록 표시에 쓰는 마지막 경로 세그먼트.
  String get name => path.split('/').last;
}
