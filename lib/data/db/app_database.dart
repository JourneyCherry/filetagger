import 'package:drift/drift.dart';

import '../../domain/entities/folder_manage_mode.dart';
import '../../domain/entities/nested_tagger_mode.dart';
import '../../domain/entities/tag_value_type.dart';
import 'database_connection.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// 한 관리 폴더에 종속된 태그 DB. 폴더를 바꾸면 새 인스턴스를 연다.
@DriftDatabase(
  tables: [TagDefinitions, FileNodes, TagAssignments, NestedWorkspaces],
)
class AppDatabase extends _$AppDatabase {
  /// 임의의 실행기로 연다(주로 인메모리 테스트용).
  AppDatabase(super.executor);

  /// 관리 폴더 루트의 `.filetagger/` 안에 있는 DB로 연다.
  AppDatabase.forWorkspace(String workspaceRoot)
    : super(openWorkspaceDatabase(workspaceRoot));

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // 태그 정의별 다중 부여 허용 플래그 도입.
        await m.addColumn(tagDefinitions, tagDefinitions.allowMultiple);
      }
      if (from < 3) {
        // 연결 끊김(태그 보존) 상태 도입.
        await m.addColumn(fileNodes, fileNodes.missingSince);
      }
      if (from < 4) {
        // 폴더 관리 방식(불투명/관리) + 폴더 이동 추적용 자식 시그니처 도입.
        await m.addColumn(fileNodes, fileNodes.manageMode);
        await m.addColumn(fileNodes, fileNodes.childSignature);
        // 이미 인덱싱된 폴더는 내부가 이미 인덱싱돼 있으므로 '관리'로 설정해 기존
        // (깊은 스캔) 동작을 보존한다. 새로 발견되는 폴더에만 불투명 기본이 적용된다.
        await customStatement(
          'UPDATE file_nodes SET manage_mode = ? WHERE is_directory = 1',
          [FolderManageMode.managed.name],
        );
      }
      if (from < 5) {
        // 시스템 태그 '이미지 크기'의 원본. 다음 스캔이 이미지 파일에 채운다.
        await m.addColumn(fileNodes, fileNodes.imageDimensions);
      }
      if (from < 6) {
        // 중첩 워크스페이스 병합 확정 기록(프롬프트 반복 억제).
        await m.createTable(nestedWorkspaces);
      }
    },
    beforeOpen: (details) async {
      // 외래키 무결성(태그 정의/파일 삭제 시 부여 기록 정리)을 위해 필요.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
