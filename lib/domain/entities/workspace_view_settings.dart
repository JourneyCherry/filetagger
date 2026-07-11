import 'file_filter.dart';
import 'file_sort.dart';
import 'folder_manage_mode.dart';

/// 프리뷰 창이 분할에서 차지하는 비율의 기본값과 허용 범위. 창 폭/높이에 대한
/// 프리뷰 쪽 몫이다. 어느 한쪽이 사라지지 않도록 최소·최대로 가둔다. 값의 단일
/// 출처로 두어 저장소(파싱)와 UI(드래그 클램프)가 함께 참조한다.
const double kDefaultPreviewRatio = 0.34;
const double kPreviewRatioMin = 0.15;
const double kPreviewRatioMax = 0.7;

/// 루트 폴더의 기본 관리 방식. 루트는 항상 최소한 직속 내용을 보이므로
/// [FolderManageMode.managed](비재귀) 또는 [FolderManageMode.managedRecursive]만
/// 갖는다(불투명은 없음). 기본은 직속 내용만 인덱싱하는 [FolderManageMode.managed].
const FolderManageMode kDefaultRootManageMode = FolderManageMode.managed;

/// 한 워크스페이스의 보기 설정(필터 + 정렬 + 프리뷰 비율 + 루트 관리 방식 +
/// 태그 표시 설정 + 트리 펼침 상태 + 폴더 묶기 여부)을 하나로 묶은 값.
///
/// 태그처럼 워크스페이스에 종속되므로 `.filetagger/` 안에 저장해 폴더를 옮겨도
/// 함께 따라온다. 직렬화(저장 형식)는 data 계층의 저장소가 담당한다.
class WorkspaceViewSettings {
  const WorkspaceViewSettings({
    this.filter = const FileFilter(),
    this.sort = const FileSortOrder(),
    this.previewRatio = kDefaultPreviewRatio,
    this.rootManageMode = kDefaultRootManageMode,
    this.visibleSystemTagIds = const <int>{},
    this.tagDisplayOrder = const <int>[],
    this.expandedFolders = const <String>{},
    this.groupByFolder = true,
  });

  final FileFilter filter;
  final FileSortOrder sort;

  /// 프리뷰 창이 분할에서 차지하는 비율([kPreviewRatioMin]~[kPreviewRatioMax]).
  final double previewRatio;

  /// 루트 폴더의 관리 방식(관리/재귀 관리). 루트부터 상속이 시작된다.
  final FolderManageMode rootManageMode;

  /// 목록·프리뷰에 **칩으로 표시할** 시스템 태그 id 집합. 기본은 빈 집합(전부 숨김)
  /// 이라 기존 목록에 칩이 갑자기 늘지 않는다(opt-in). 시스템 태그 값은 표시 여부와
  /// 무관하게 항상 계산되어 필터·정렬에 참여하고, 이 집합은 칩 렌더링에만 관여한다.
  final Set<int> visibleSystemTagIds;

  /// 태그 칩을 렌더할 순서(태그 정의 id 나열, 시스템 태그의 음수 id 포함).
  ///
  /// 부분 목록이어도 되며, 여기 없는 태그는 뒤에 붙는다(적용 로직은
  /// `tag_display_order` 유즈케이스). 기본은 빈 목록 = 기존 표시 순서 유지.
  final List<int> tagDisplayOrder;

  /// 그룹(계층) 목록에서 펼쳐 놓은 폴더 경로들. 여기 없는 폴더는 접힌 상태다.
  /// 세션을 넘겨 유지되도록 워크스페이스 설정에 함께 담는다.
  final Set<String> expandedFolders;

  /// 목록을 폴더 계층으로 묶어 보일지. 켜면 폴더 아래로 자식을 들여써 묶고(폴더가
  /// 매치되는 자손을 함께 드러내는 전파 효과가 생긴다), 끄면 모든 항목을 한 단계로
  /// 평평하게 펼쳐(폴더 묶음에 따른 전파 없이) 각 항목을 독립적으로 다룬다.
  final bool groupByFolder;

  bool get isEmpty => filter.isEmpty && sort.isEmpty;

  WorkspaceViewSettings copyWith({
    FileFilter? filter,
    FileSortOrder? sort,
    double? previewRatio,
    FolderManageMode? rootManageMode,
    Set<int>? visibleSystemTagIds,
    List<int>? tagDisplayOrder,
    Set<String>? expandedFolders,
    bool? groupByFolder,
  }) => WorkspaceViewSettings(
    filter: filter ?? this.filter,
    sort: sort ?? this.sort,
    previewRatio: previewRatio ?? this.previewRatio,
    rootManageMode: rootManageMode ?? this.rootManageMode,
    visibleSystemTagIds: visibleSystemTagIds ?? this.visibleSystemTagIds,
    tagDisplayOrder: tagDisplayOrder ?? this.tagDisplayOrder,
    expandedFolders: expandedFolders ?? this.expandedFolders,
    groupByFolder: groupByFolder ?? this.groupByFolder,
  );
}
