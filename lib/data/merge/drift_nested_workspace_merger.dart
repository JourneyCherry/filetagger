import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../domain/entities/tag_value_type.dart';
import '../../domain/repositories/nested_workspace_merger.dart';
import '../db/app_database.dart';
import '../db/database_connection.dart';
import '../thumbnails/thumbnail_store.dart';

/// [NestedWorkspaceMerger]의 Drift 구현. 하위 워크스페이스의 태거 DB 행을 현재
/// 워크스페이스 DB로 옮긴다.
class DriftNestedWorkspaceMerger implements NestedWorkspaceMerger {
  DriftNestedWorkspaceMerger(this._parentDb);

  final AppDatabase _parentDb;

  @override
  Future<void> absorb({
    required String parentRoot,
    required String childRelPath,
    required bool removeSource,
  }) async {
    final childAbs = p.joinAll([parentRoot, ...childRelPath.split('/')]);

    // 1) 하위 DB를 열어 전부 메모리로 읽고 곧바로 닫는다. 뒤이어 원본을 제거할 수
    //    있도록(파일 잠금 해제) 이 단계에서 반드시 닫는다. 하위 스키마가 구버전이면
    //    여는 순간 현재 버전으로 마이그레이션되어 그대로 읽을 수 있다(신버전 하위는
    //    호출부의 버전 게이트가 흡수를 막는다).
    final child = AppDatabase.forWorkspace(childAbs);
    final List<TagDefinitionRow> defs;
    final List<FileNodeRow> nodes;
    final List<TagAssignmentRow> assigns;
    try {
      defs = await child.select(child.tagDefinitions).get();
      nodes = await child.select(child.fileNodes).get();
      assigns = await child.select(child.tagAssignments).get();
    } finally {
      await child.close();
    }

    // 2) 부모 DB로 이관. 이름 충돌 태그는 식별 가능한 이름으로 바꿔 개별 태그로
    //    만든다(자동 매핑 없이 사후 '태그 병합'으로 합치도록 위임).
    final childBase = childRelPath.split('/').last;
    final seenAt = DateTime.now();
    await _parentDb.transaction(() async {
      final takenNames = {
        for (final d in await _parentDb.select(_parentDb.tagDefinitions).get())
          d.name,
      };

      final defIdMap = <int, int>{};
      for (final d in defs) {
        final name = _uniqueName(d.name, childBase, takenNames);
        takenNames.add(name);
        final created = await _parentDb
            .into(_parentDb.tagDefinitions)
            .insertReturning(
              TagDefinitionsCompanion.insert(
                name: name,
                valueType: d.valueType,
                color: Value(d.color),
                allowMultiple: Value(d.allowMultiple),
              ),
            );
        defIdMap[d.id] = created.id;
      }

      // 하위 노드 경로를 루트 기준으로 재기준화해 upsert한다. 관리 방식 override는
      // 비워(null) 흡수 후 재귀 관리 아래에서 모두 인덱싱되게 한다(폴더 노드 자체의
      // 관리 방식은 use case가 재귀로 설정). 이미 있던 경로면 id를 보존해 그 위에
      // 부여를 매단다.
      final nodeIdByChildId = <int, int>{};
      for (final n in nodes) {
        final rebased = '$childRelPath/${n.path}';
        final row = await _parentDb
            .into(_parentDb.fileNodes)
            .insertReturning(
              FileNodesCompanion.insert(
                path: rebased,
                isDirectory: n.isDirectory,
                size: Value(n.size),
                modifiedAt: Value(n.modifiedAt),
                contentHashPrefix: Value(n.contentHashPrefix),
                lastSeenAt: seenAt,
                manageMode: const Value(null),
                childSignature: Value(n.childSignature),
                imageDimensions: Value(n.imageDimensions),
              ),
              onConflict: DoUpdate(
                (_) => FileNodesCompanion(lastSeenAt: Value(seenAt)),
                target: [_parentDb.fileNodes.path],
              ),
            );
        nodeIdByChildId[n.id] = row.id;
      }

      // 링크 태그의 값은 대상 노드 id다 — 흡수하며 노드 id가 재매핑되므로 링크 값도
      // 새 부모 id로 옮긴다. 대상이 흡수 목록 밖이면 값을 비워(null) 링크를 무효로 둔다.
      final linkChildDefIds = {
        for (final d in defs)
          if (d.valueType == TagValueType.link) d.id,
      };
      for (final a in assigns) {
        final fileId = nodeIdByChildId[a.fileNodeId];
        final defId = defIdMap[a.tagDefinitionId];
        if (fileId == null || defId == null) continue;
        var value = a.value;
        if (linkChildDefIds.contains(a.tagDefinitionId) && value != null) {
          final targetChildId = int.tryParse(value);
          final mapped = targetChildId == null
              ? null
              : nodeIdByChildId[targetChildId];
          value = mapped?.toString();
        }
        await _parentDb
            .into(_parentDb.tagAssignments)
            .insert(
              TagAssignmentsCompanion.insert(
                fileNodeId: fileId,
                tagDefinitionId: defId,
                value: Value(value),
              ),
            );
      }
    });

    // 2.5) 커스텀 이미지 태그의 캐시 파일을 부모 캐시로 복사한다. 이미지 값은 재매핑
    //      없는 내용 해시 키라, 원본 캐시 파일만 옮기면(원본 제거 전에) 흡수 후에도
    //      노드 썸네일이 이어진다. 키가 같으면 부모에 이미 있어 자동으로 중복 제거된다.
    final imageChildDefIds = {
      for (final d in defs)
        if (d.valueType == TagValueType.image) d.id,
    };
    final imageKeys = <String>{
      for (final a in assigns)
        if (imageChildDefIds.contains(a.tagDefinitionId) &&
            a.value != null &&
            a.value!.isNotEmpty)
          a.value!,
    };
    await copyThumbnailCache(
      fromRoot: childAbs,
      toRoot: parentRoot,
      keys: imageKeys,
    );

    // 3) 원본 태거 폴더 제거(옵션).
    if (removeSource) {
      final dir = Directory(filetaggerDirPath(childAbs));
      if (await dir.exists()) {
        try {
          await dir.delete(recursive: true);
        } on FileSystemException {
          // 잠금 등으로 지우지 못하면 조용히 둔다(다음 스캔이 다시 발견하면
          // 사용자가 재처리한다).
        }
      }
    }
  }

  /// [base]가 이미 쓰인 이름이면 하위 폴더 이름을 붙여 식별 가능한 고유 이름을
  /// 만든다. 그래도 겹치면 일련번호를 덧붙인다.
  String _uniqueName(String base, String childBase, Set<String> taken) {
    if (!taken.contains(base)) return base;
    final labeled = '$base ($childBase)';
    if (!taken.contains(labeled)) return labeled;
    var i = 2;
    while (taken.contains('$labeled ($i)')) {
      i++;
    }
    return '$labeled ($i)';
  }
}
