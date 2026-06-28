import 'package:drift/drift.dart';

import '../../domain/entities/tag_value_type.dart';
import 'database_connection.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// 한 관리 폴더에 종속된 태그 DB. 폴더를 바꾸면 새 인스턴스를 연다.
@DriftDatabase(tables: [TagDefinitions, FileNodes, TagAssignments])
class AppDatabase extends _$AppDatabase {
  /// 임의의 실행기로 연다(주로 인메모리 테스트용).
  AppDatabase(super.executor);

  /// 관리 폴더 루트의 `.filetagger/` 안에 있는 DB로 연다.
  AppDatabase.forWorkspace(String workspaceRoot)
      : super(openWorkspaceDatabase(workspaceRoot));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          // 외래키 무결성(태그 정의/파일 삭제 시 부여 기록 정리)을 위해 필요.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
