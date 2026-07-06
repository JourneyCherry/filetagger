import '../entities/workspace_view_settings.dart';

/// 워크스페이스별 보기 설정(필터·정렬)을 읽고 쓰는 저장소.
///
/// 구현(JSON 파일 등 저장 형식·위치)은 data 계층에 격리한다. 저장된 설정이
/// 없거나 손상되면 기본값([WorkspaceViewSettings])을 돌려준다.
abstract class ViewSettingsRepository {
  Future<WorkspaceViewSettings> load();

  Future<void> save(WorkspaceViewSettings settings);
}
