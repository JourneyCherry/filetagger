import '../entities/query_preset.dart';

/// 워크스페이스별 조건 프리셋 목록을 읽고 쓰는 저장소.
///
/// 구현(저장 형식·위치)은 data 계층에 격리한다. 저장된 것이 없거나 손상되면 빈
/// 목록을 돌려준다. 목록의 순서가 곧 사용자가 배치한 순서다.
abstract class QueryPresetRepository {
  Future<List<QueryPreset>> load();

  Future<void> save(List<QueryPreset> presets);
}
