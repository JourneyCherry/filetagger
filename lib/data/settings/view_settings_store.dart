import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/constants.dart';
import '../../domain/entities/file_filter.dart';
import '../../domain/entities/file_grouping.dart';
import '../../domain/entities/file_sort.dart';
import '../../domain/entities/folder_manage_mode.dart';
import '../../domain/entities/view_mode.dart';
import '../../domain/entities/workspace_view_settings.dart';
import '../../domain/repositories/view_settings_repository.dart';
import '../../domain/usecases/group_query_text.dart';

/// 보기 설정(필터·정렬)을 워크스페이스의 `.filetagger/` 안 JSON 파일로 읽고 쓴다.
///
/// 열거형은 이름으로 저장해 값 순서 변경에 영향받지 않는다(태그 유형 저장과 동일
/// 원칙). 파일이 없거나 형식이 깨지면 기본값을 돌려줘 앱이 계속 뜨게 한다.
class JsonViewSettingsStore implements ViewSettingsRepository {
  JsonViewSettingsStore(this.workspaceRoot);

  final String workspaceRoot;

  File _file() =>
      File(p.join(workspaceRoot, filetaggerDirName, viewSettingsFileName));

  @override
  Future<WorkspaceViewSettings> load() async {
    final file = _file();
    if (!await file.exists()) return const WorkspaceViewSettings();
    try {
      final decoded = jsonDecode(await file.readAsString());
      return _settingsFromJson(decoded as Map<String, dynamic>);
    } catch (_) {
      return const WorkspaceViewSettings();
    }
  }

  @override
  Future<void> save(WorkspaceViewSettings settings) async {
    final file = _file();
    await file.create(recursive: true);
    await file.writeAsString(jsonEncode(_settingsToJson(settings)));
  }
}

// ── 직렬화 ──
//
// 저장 형식은 이 파일에만 둔다(도메인 엔티티는 순수하게 유지). 태그 식별자는
// 워크스페이스 DB의 정의 id다 — 정의가 지워졌다면 로드 후 UI가 "(삭제된 태그)"로
// 표시하고 사용자가 조건을 지울 수 있다.

Map<String, dynamic> _settingsToJson(WorkspaceViewSettings s) => {
  'filter': _filterToJson(s.filter),
  'sort': _sortToJson(s.sort),
  'previewRatio': s.previewRatio,
  'rootManageMode': s.rootManageMode.name,
  'systemTags': s.visibleSystemTagIds.toList(),
  'hiddenTags': s.hiddenTagIds.toList(),
  'tagOrder': s.tagDisplayOrder,
  'expanded': s.expandedFolders.toList(),
  'grouping': _groupingToJson(s.grouping),
  'viewMode': s.viewMode.name,
  'viewScales': {
    for (final e in s.viewScales.entries) e.key.name: e.value,
  },
  'detailSort': _sortToJson(s.detailSort),
  'detailColumnWidths': {
    for (final e in s.detailColumnWidths.entries) '${e.key}': e.value,
  },
};

WorkspaceViewSettings _settingsFromJson(Map<String, dynamic> json) =>
    WorkspaceViewSettings(
      filter: _filterFromJson(json['filter']),
      sort: _sortFromJson(json['sort']),
      previewRatio: _ratioFromJson(json['previewRatio']),
      rootManageMode: _rootModeFromJson(json['rootManageMode']),
      visibleSystemTagIds: _systemTagsFromJson(json['systemTags']),
      hiddenTagIds: _intSetFromJson(json['hiddenTags']),
      tagDisplayOrder: _tagOrderFromJson(json['tagOrder']),
      expandedFolders: _expandedFromJson(json['expanded']),
      grouping: _groupingFromJson(json['grouping'], json['grouped']),
      viewMode: _enumByName(ViewMode.values, json['viewMode']) ?? ViewMode.list,
      viewScales: _viewScalesFromJson(json['viewScales']),
      detailSort: _sortFromJson(json['detailSort']),
      detailColumnWidths: _detailWidthsFromJson(json['detailColumnWidths']),
    );

/// 자세히 컬럼 폭. 키(태그 id 문자열)가 정수가 아니거나 값이 비숫자면 건너뛰고,
/// 값은 허용 범위로 가둔다. 없거나 형식이 어긋나면 빈 맵(전부 기본 폭).
Map<int, double> _detailWidthsFromJson(Object? json) {
  if (json is! Map) return const <int, double>{};
  final result = <int, double>{};
  for (final entry in json.entries) {
    final id = int.tryParse('${entry.key}');
    final value = entry.value;
    if (id != null && value is num) {
      result[id] = value.toDouble().clamp(
        kDetailColumnWidthMin,
        kDetailColumnWidthMax,
      );
    }
  }
  return result;
}

/// 보기 모드별 크기 배율. 알 수 없는 모드명·비숫자 값은 건너뛰고, 값은 허용 범위로
/// 가둔다. 없거나 형식이 어긋나면 빈 맵(전부 기본 배율).
Map<ViewMode, double> _viewScalesFromJson(Object? json) {
  if (json is! Map) return const <ViewMode, double>{};
  final result = <ViewMode, double>{};
  for (final entry in json.entries) {
    final mode = _enumByName(ViewMode.values, entry.key);
    final value = entry.value;
    if (mode != null && value is num) {
      result[mode] = value.toDouble().clamp(kViewScaleMin, kViewScaleMax);
    }
  }
  return result;
}

/// 그룹 단계를 정의 id 나열로 저장한다(폴더 계층 키는 예약 id로). 텍스트·칩
/// 계층이 그룹 키를 정의 id로 다루는 것과 같은 방식이라 재해석이 단순하다.
List<int> _groupingToJson(FileGrouping grouping) => [
  for (final k in grouping.keys) groupKeyId(k),
];

/// 저장된 그룹. `grouping` 키가 있으면 그걸 읽고, 없으면 구버전 `grouped`(bool)를
/// 마이그레이션한다(참=폴더 계층, 거짓=평면). 둘 다 없으면 기본(폴더 계층).
FileGrouping _groupingFromJson(Object? json, Object? legacyGrouped) {
  if (json is List) {
    return groupFromKeys([
      for (final item in json)
        if (item is int) groupKeyFromId(item),
    ]);
  }
  if (legacyGrouped is bool) {
    return legacyGrouped ? kDefaultGrouping : const FileGrouping();
  }
  return kDefaultGrouping;
}

/// 펼쳐 둔 폴더 경로 집합. 없거나 형식이 어긋나면 빈 집합(전부 접힘).
Set<String> _expandedFromJson(Object? json) {
  if (json is! List) return const <String>{};
  return {
    for (final item in json)
      if (item is String) item,
  };
}

/// 표시할 시스템 태그 id 집합. 없거나 형식이 어긋나면 빈 집합(전부 숨김).
Set<int> _systemTagsFromJson(Object? json) => _intSetFromJson(json);

/// 정수 id 집합(감출 사용자 태그 등). 없거나 형식이 어긋나면 빈 집합.
Set<int> _intSetFromJson(Object? json) {
  if (json is! List) return const <int>{};
  return {
    for (final item in json)
      if (item is int) item,
  };
}

/// 태그 표시 순서. 없거나 형식이 어긋나면 빈 목록(기존 표시 순서 유지).
/// 중복 id는 처음 것만 남겨 순위가 갈라지지 않게 한다.
List<int> _tagOrderFromJson(Object? json) {
  if (json is! List) return const <int>[];
  final seen = <int>{};
  return [
    for (final item in json)
      if (item is int && seen.add(item)) item,
  ];
}

/// 저장된 루트 관리 방식. 알 수 없거나 없으면 기본값. 루트는 불투명이 될 수
/// 없으므로 opaque가 저장돼 있어도 기본값(managed)으로 되돌린다.
FolderManageMode _rootModeFromJson(Object? json) {
  final mode = _enumByName(FolderManageMode.values, json);
  if (mode == null || mode == FolderManageMode.opaque) {
    return kDefaultRootManageMode;
  }
  return mode;
}

/// 저장된 프리뷰 비율을 허용 범위로 가둔다. 없거나 숫자가 아니면 기본값.
double _ratioFromJson(Object? json) {
  if (json is num) {
    return json.toDouble().clamp(kPreviewRatioMin, kPreviewRatioMax);
  }
  return kDefaultPreviewRatio;
}

Map<String, dynamic> _filterToJson(FileFilter filter) => {
  'conditions': [
    for (final c in filter.conditions)
      {
        'tag': c.tagDefinitionId,
        'op': c.operator.name,
        if (c.operand != null) 'operand': c.operand,
        'exclude': c.exclude,
      },
  ],
};

FileFilter _filterFromJson(Object? json) {
  if (json is! Map) return const FileFilter();
  final raw = json['conditions'];
  if (raw is! List) return const FileFilter();
  final conditions = <FilterCondition>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final tag = item['tag'];
    final op = _enumByName(FilterOperator.values, item['op']);
    if (tag is! int || op == null) continue;
    conditions.add(
      FilterCondition(
        tagDefinitionId: tag,
        operator: op,
        operand: item['operand'] as String?,
        exclude: item['exclude'] == true,
      ),
    );
  }
  return FileFilter(conditions: conditions);
}

Map<String, dynamic> _sortToJson(FileSortOrder sort) => {
  'keys': [
    for (final k in sort.keys)
      {'tag': k.tagDefinitionId, 'direction': k.direction.name},
  ],
};

FileSortOrder _sortFromJson(Object? json) {
  if (json is! Map) return const FileSortOrder();
  final raw = json['keys'];
  if (raw is! List) return const FileSortOrder();
  final keys = <SortKey>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final tag = item['tag'];
    final direction = _enumByName(SortDirection.values, item['direction']);
    if (tag is! int || direction == null) continue;
    keys.add(SortKey(tagDefinitionId: tag, direction: direction));
  }
  return FileSortOrder(keys: keys);
}

/// 이름으로 열거형 값을 찾되, 알 수 없는 이름이면 null(해당 항목은 건너뜀).
T? _enumByName<T extends Enum>(List<T> values, Object? name) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}
