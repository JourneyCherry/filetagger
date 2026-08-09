import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/constants.dart';
import '../../domain/entities/file_grouping.dart';
import '../../domain/entities/folder_manage_mode.dart';
import '../../domain/entities/view_mode.dart';
import '../../domain/entities/workspace_view_settings.dart';
import '../../domain/repositories/view_settings_repository.dart';
import 'query_json.dart';

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
// 이 파일만의 항목(보기 상태·표시 설정)은 여기서, 조건(필터·정렬·그룹)은 프리셋
// 저장소와 공유하는 [query_json.dart]에서 다룬다. 도메인 엔티티는 순수하게 유지한다.
// 태그 식별자는 워크스페이스 DB의 정의 id다 — 정의가 지워졌다면 로드 후 UI가
// "(삭제된 태그)"로 표시하고 사용자가 조건을 지울 수 있다.

Map<String, dynamic> _settingsToJson(WorkspaceViewSettings s) => {
  'filter': filterToJson(s.filter),
  'sort': sortToJson(s.sort),
  'previewRatio': s.previewRatio,
  'rootManageMode': s.rootManageMode.name,
  'systemTags': s.visibleSystemTagIds.toList(),
  'hiddenTags': s.hiddenTagIds.toList(),
  'tagOrder': s.tagDisplayOrder,
  'expanded': s.expandedFolders.toList(),
  'grouping': groupingToJson(s.grouping),
  'viewMode': s.viewMode.name,
  'viewScales': {for (final e in s.viewScales.entries) e.key.name: e.value},
  'detailSort': sortToJson(s.detailSort),
  'detailColumnWidths': {
    for (final e in s.detailColumnWidths.entries) '${e.key}': e.value,
  },
  if (s.thumbnailSources.isNotEmpty) 'thumbnailSources': s.thumbnailSources,
  if (s.nameSources.isNotEmpty) 'nameSources': s.nameSources,
};

WorkspaceViewSettings _settingsFromJson(Map<String, dynamic> json) =>
    WorkspaceViewSettings(
      filter: filterFromJson(json['filter']),
      sort: sortFromJson(json['sort']),
      previewRatio: _ratioFromJson(json['previewRatio']),
      rootManageMode: _rootModeFromJson(json['rootManageMode']),
      visibleSystemTagIds: _systemTagsFromJson(json['systemTags']),
      hiddenTagIds: _intSetFromJson(json['hiddenTags']),
      tagDisplayOrder: _tagOrderFromJson(json['tagOrder']),
      expandedFolders: _expandedFromJson(json['expanded']),
      grouping: _groupingFromJson(json['grouping'], json['grouped']),
      viewMode: enumByName(ViewMode.values, json['viewMode']) ?? ViewMode.list,
      viewScales: _viewScalesFromJson(json['viewScales']),
      detailSort: sortFromJson(json['detailSort']),
      detailColumnWidths: _detailWidthsFromJson(json['detailColumnWidths']),
      thumbnailSources: _thumbnailSourcesFromJson(json),
      nameSources: intListFromJson(json['nameSources']),
    );

/// 썸네일 출처 우선순위를 읽는다. 기본 썸네일은 늘 맨 아래(암묵적)라 목록에 두지
/// 않으므로 저장된 예약 항목([kDefaultThumbnailSourceId])은 걸러 낸다. 구버전의 단일
/// `thumbnailTag`는 `[태그]`로 옮긴다(그 뒤 기본으로 폴백하던 동작 그대로).
List<int> _thumbnailSourcesFromJson(Map<String, dynamic> json) {
  final raw = json['thumbnailSources'];
  if (raw is List) {
    return [
      for (final v in raw)
        if (v is int && v != kDefaultThumbnailSourceId) v,
    ];
  }
  final legacy = json['thumbnailTag'];
  if (legacy is int) return [legacy];
  return const [];
}

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
    final mode = enumByName(ViewMode.values, entry.key);
    final value = entry.value;
    if (mode != null && value is num) {
      result[mode] = value.toDouble().clamp(kViewScaleMin, kViewScaleMax);
    }
  }
  return result;
}

/// 저장된 그룹. `grouping` 키가 있으면 그걸 읽고, 없으면 구버전 `grouped`(bool)를
/// 마이그레이션한다(참=폴더 계층, 거짓=평면). 둘 다 없으면 기본(폴더 계층).
FileGrouping _groupingFromJson(Object? json, Object? legacyGrouped) {
  final parsed = groupingFromJson(json);
  if (parsed != null) return parsed;
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
  final mode = enumByName(FolderManageMode.values, json);
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
