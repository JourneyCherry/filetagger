import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/constants.dart';
import '../../domain/entities/file_grouping.dart';
import '../../domain/entities/query_preset.dart';
import '../../domain/repositories/query_preset_repository.dart';
import 'query_json.dart';

/// 조건 프리셋 목록을 워크스페이스의 `.filetagger/` 안 JSON 파일로 읽고 쓴다.
///
/// 조건(필터·정렬·그룹) 표현은 보기 설정 저장소와 [query_json.dart]를 공유한다.
/// 파일이 없거나 형식이 깨지면 빈 목록을 돌려줘 앱이 계속 뜨게 한다.
class JsonQueryPresetStore implements QueryPresetRepository {
  JsonQueryPresetStore(this.workspaceRoot);

  final String workspaceRoot;

  File _file() =>
      File(p.join(workspaceRoot, filetaggerDirName, queryPresetsFileName));

  @override
  Future<List<QueryPreset>> load() async {
    final file = _file();
    if (!await file.exists()) return const [];
    try {
      final decoded = jsonDecode(await file.readAsString());
      return _presetsFromJson(decoded);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> save(List<QueryPreset> presets) async {
    final file = _file();
    await file.create(recursive: true);
    await file.writeAsString(jsonEncode(_presetsToJson(presets)));
  }
}

// ── 직렬화 ──
//
// 목록 순서가 곧 사용자가 배치한 순서다. 이름이 없는 항목은 가리킬 수단이 없어
// 건너뛴다(그 밖의 어긋난 조각은 조건 코덱이 각자 걸러 낸다).

Map<String, dynamic> _presetsToJson(List<QueryPreset> presets) => {
  'presets': [
    for (final preset in presets)
      {
        'name': preset.name,
        'filter': filterToJson(preset.filter),
        'sort': sortToJson(preset.sort),
        'grouping': groupingToJson(preset.grouping),
      },
  ],
};

List<QueryPreset> _presetsFromJson(Object? json) {
  if (json is! Map) return const [];
  final raw = json['presets'];
  if (raw is! List) return const [];
  final presets = <QueryPreset>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final name = item['name'];
    if (name is! String || name.isEmpty) continue;
    presets.add(
      QueryPreset(
        name: name,
        filter: filterFromJson(item['filter']),
        sort: sortFromJson(item['sort']),
        // 그룹은 "저장된 값 없음"과 "빈 그룹(평면 목록)"이 다른 뜻이지만, 프리셋은
        // 저장 시점의 조건을 그대로 담으므로 읽을 수 없으면 빈 그룹으로 둔다.
        grouping: groupingFromJson(item['grouping']) ?? const FileGrouping(),
      ),
    );
  }
  return presets;
}
