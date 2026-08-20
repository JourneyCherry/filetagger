import 'package:drift/drift.dart';

import '../../domain/entities/folder_manage_mode.dart';
import '../../domain/entities/nested_tagger_mode.dart';
import '../../domain/entities/node_kind.dart';
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
  int get schemaVersion => 12;

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
        // 이미지 크기의 원본(당시엔 가로·세로를 한 문자열에 합쳐 담았다). 뒤의
        // 단계가 이 컬럼을 갈라 옮기고 없애므로 **테이블 정의에는 더 이상 없다** —
        // 그래서 컬럼 참조 대신 원시 SQL로 만든다. 지나간 스키마를 그대로 재현하는
        // 것이 마이그레이션 사슬의 몫이고, 여기서 건너뛰면 뒤 단계가 읽을 것이 없다.
        await customStatement(
          'ALTER TABLE file_nodes ADD COLUMN image_dimensions TEXT',
        );
      }
      if (from < 6) {
        // 중첩 워크스페이스 병합 확정 기록(프롬프트 반복 억제).
        await m.createTable(nestedWorkspaces);
      }
      if (from < 7) {
        // 노드 종류(파일/디렉토리/키워드) 도입. 폴더 여부 불리언을 열거로 갈고,
        // 경로 유일성을 종류 안으로 좁힌다(키워드는 이름을 경로 자리에 담으므로
        // 같은 이름의 파일과 공존해야 한다). 컬럼 제거와 제약 변경이라 컬럼
        // 추가로 끝나지 않고 테이블을 다시 쓴다.
        await m.alterTable(
          // 테이블 재작성은 Drift가 experimental로 표시해 두었지만, 컬럼 제거·제약
          // 변경을 SQLite에서 안전하게 하는(외래키·legacy_alter_table 처리를 포함한)
          // 유일한 공식 경로다. 손으로 쓴 SQL은 그 처리를 다시 만들어야 한다.
          // ignore: experimental_member_use
          TableMigration(
            fileNodes,
            columnTransformer: {
              // 옛 폴더 여부 컬럼을 그대로 종류로 옮긴다(키워드는 이 시점에 없다).
              // 저장 표현이 갈리지 않도록 이름은 열거에서 읽는다.
              fileNodes.kind: CustomExpression<String>(
                "CASE WHEN is_directory THEN '${NodeKind.directory.name}' "
                "ELSE '${NodeKind.file.name}' END",
              ),
            },
            newColumns: [fileNodes.kind],
          ),
        );
      }
      if (from < 8) {
        // 키워드 노드에서 본문 컬럼을 걷어낸다 — 부연 정보는 본문이 아니라 태그로
        // 붙어야 필터·정렬·그룹에 걸리기 때문이다. 그와 함께 종류 이름도 갈렸으므로,
        // 직전 스키마로 한 번이라도 연 DB의 옛 이름을 새 이름으로 옮긴다(종류는 열거
        // **이름**으로 저장되어, 안 옮기면 그 행을 읽지 못한다). 컬럼 제거라 어차피
        // 테이블을 다시 쓰므로 둘을 한 번에 묶는다.
        await m.alterTable(
          // ignore: experimental_member_use
          TableMigration(
            fileNodes,
            columnTransformer: {
              // 옛 이름은 열거에서 사라져 상수로만 남길 수 있다(레거시 값).
              fileNodes.kind: CustomExpression<String>(
                "CASE WHEN kind = 'memo' THEN '${NodeKind.keyword.name}' "
                'ELSE kind END',
              ),
            },
          ),
        );
      }
      if (from < 9) {
        // 미해결 링크 표식 도입. 기존 부여는 모두 해결된 값(또는 링크가 아닌 값)이라
        // 컬럼 기본값(거짓)이 그대로 맞다.
        await m.addColumn(tagAssignments, tagAssignments.valueUnresolved);
      }
      if (from < 10) {
        // 내용 해시를 손으로 짠 것에서 표준 구현으로 갈았다. 스캐너는 크기·수정시각이
        // 그대로인 파일의 **저장된 해시를 그대로 재사용**하므로, 비워 두지 않으면 옛
        // 형식의 값이 영영 남아 새로 계산한 값과 결코 맞지 않는다 — 그 파일들은 이동
        // 추적이 조용히 끊긴다. 비우면 다음 스캔이 한 번 다시 읽어 채운다.
        await customStatement(
          'UPDATE file_nodes SET content_hash_prefix = NULL',
        );
      }
      if (from < 11) {
        // 시스템 태그 '내부 파일 수량'의 원본. 다음 스캔이 폴더에 채운다 — 그때까지
        // 값을 모르는 폴더는 시스템 태그가 수량 대신 폴더 표식 노릇만 한다
        // ([SystemTag.childFileCount] 참고).
        await m.addColumn(fileNodes, fileNodes.childFileCount);
      }
      if (from < 12) {
        // 이미지 크기를 한 문자열에서 너비·높이 두 정수로 가른다. 옛 컬럼을 없애야
        // 하므로 컬럼 추가로 끝나지 않고 테이블을 다시 쓴다(7·8단계와 같은 이유).
        //
        // **값을 옮겨 담고 비우지 않는다.** 비우면 스캐너가 크기를 모르는 파일로
        // 보아 이미지를 전부 다시 읽는데(재사용 조건이 크기 유무를 본다), 그 비용이
        // 라이브러리 크기에 비례해 커진다. 옛 값은 스캐너가 쓴 것뿐이라 형식이
        // 일정해 그 자리에서 가를 수 있다.
        await m.alterTable(
          // ignore: experimental_member_use
          TableMigration(
            fileNodes,
            columnTransformer: {
              fileNodes.imageWidth: CustomExpression<int>(
                _legacyDimensionSql('1', "instr(image_dimensions, 'x') - 1"),
              ),
              fileNodes.imageHeight: CustomExpression<int>(
                _legacyDimensionSql("instr(image_dimensions, 'x') + 1", null),
              ),
            },
            newColumns: [fileNodes.imageWidth, fileNodes.imageHeight],
          ),
        );
      }
    },
    beforeOpen: (details) async {
      // 외래키 무결성(태그 정의/파일 삭제 시 부여 기록 정리)을 위해 필요.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

/// 합쳐 담겼던 옛 이미지 크기 문자열에서 한 조각을 잘라 정수로 옮기는 SQL.
///
/// [from]부터 [length]만큼(널이면 끝까지) 자른다. 구분자가 없는 값은 통째로 버려
/// 미지정으로 남긴다 — 그렇게 두면 다음 스캔이 그 파일만 다시 읽어 채우지만,
/// 억지로 잘랐다간 엉뚱한 수가 태그값으로 굳어 남는다.
String _legacyDimensionSql(String from, String? length) {
  final slice = length == null
      ? 'substr(image_dimensions, $from)'
      : 'substr(image_dimensions, $from, $length)';
  return "CASE WHEN instr(image_dimensions, 'x') > 0 "
      'THEN CAST($slice AS INTEGER) END';
}
