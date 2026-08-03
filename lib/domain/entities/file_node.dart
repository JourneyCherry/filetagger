import 'folder_manage_mode.dart';
import 'node_kind.dart';

/// 인덱스에 실린 노드 하나(스캔된 파일·폴더, 또는 사용자가 만든 키워드).
///
/// 파일·폴더는 관리 폴더 루트 기준의 상대 경로로 식별하며, 저장 계층(Drift row)과
/// 독립된 순수 도메인 표현이다. 경로 구분자는 플랫폼·저장 위치와 무관하게 항상
/// '/'로 정규화해 폴더를 다른 OS로 옮겨도 안정적으로 매칭되게 한다.
///
/// 키워드([NodeKind.keyword])는 디스크에 실체가 없어 경로 계층에 속하지 않는다. 이름을
/// 그대로 [path]에 두므로 목록에서는 루트 직속으로 나타나며, 경로 유일성은 종류
/// 안에서만 요구된다(같은 이름의 파일과 키워드가 공존할 수 있다).
class FileNode {
  const FileNode({
    this.id,
    required this.path,
    required this.kind,
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

  /// 관리 폴더 루트 기준 상대 경로('/' 구분). 키워드는 경로가 아니라 이름이다.
  final String path;

  final NodeKind kind;

  /// 파일 크기(바이트). 디스크 파일이 아니면 null.
  final int? size;

  final DateTime? modifiedAt;

  /// 이동 추적용 내용 부분 해시. 스캐너가 파일 앞부분을 읽어 채운다.
  final String? contentHashPrefix;

  /// 태그를 보존한 채 "연결 끊김" 상태로 남은 시각. null이면 실제 존재하는
  /// 노드다. 사라진 태그된 노드가 자동 재연결되지 못했을 때 설정된다.
  final DateTime? missingSince;

  /// 폴더의 관리 방식(내부 인덱싱 여부). 폴더 노드에만 채워지며 그 외는 null.
  /// 처음 발견되는 폴더는 [FolderManageMode.opaque]가 기본이다.
  final FolderManageMode? manageMode;

  /// 폴더 이동 추적용, 직속 자식 구성의 부분 시그니처. 폴더 노드에만 채워진다.
  /// 내용 해시가 없는 폴더를 이동 후에도 동일 폴더로 알아보기 위해 스캐너가
  /// 직속 자식 이름 구성으로 계산한다. 자식이 없으면(빈 폴더) null이다.
  final String? childSignature;

  /// 이미지 파일의 픽셀 크기("가로x세로"). 스캐너가 이미지 헤더를 파싱해 채운다.
  /// 이미지가 아니거나 크기를 못 읽으면 null이다. 시스템 태그 '이미지 크기'의 원본.
  final String? imageDimensions;

  /// 디스크에 있는 디렉토리인지.
  bool get isDirectory => kind == NodeKind.directory;

  /// **디스크에 있는 일반 파일**인지. "폴더가 아님"과 다르다 — 키워드는 둘 다
  /// 아니므로, 파일 실체를 전제하는 동작(열기·해시·확장자·자기 이미지 썸네일)은
  /// 이 값을 물어야 한다.
  bool get isFile => kind == NodeKind.file;

  /// 디스크에 남지 않고 DB에만 있는 키워드인지.
  bool get isKeyword => kind == NodeKind.keyword;

  /// 파일이 사라져 태그만 보존 중인지(수동 재연결 대상).
  bool get isMissing => missingSince != null;

  /// 목록 표시에 쓰는 마지막 경로 세그먼트.
  String get name => path.split('/').last;
}
