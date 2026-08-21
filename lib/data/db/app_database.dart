import 'package:drift/drift.dart';

import '../../domain/entities/folder_manage_mode.dart';
import '../../domain/entities/nested_tagger_mode.dart';
import '../../domain/entities/node_kind.dart';
import '../../domain/entities/tag_value_type.dart';
import 'database_connection.dart';
import 'migration_plan.dart';
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

  /// 각 단계는 **디스크의 실제 컬럼**을 보고 갈린다 — 지금의 테이블 정의를 그대로
  /// 믿고 옛 테이블을 참조하면, 나중에 생긴 컬럼과 앞선 단계가 지운 옛 컬럼이 서로
  /// 다른 단계에서 "없는 컬럼"이 되어 그 자리에서 끊긴다([TableRewritePlan] 참고).
  /// 스키마 버전은 모든 단계가 성공한 뒤에야 기록되므로(그 사이 중단되면 테이블만
  /// 앞서 나간 채 버전이 뒤에 남는다) 어떤 단계든 **다시 돌아도 안전해야** 한다.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // 태그 정의별 다중 부여 허용 플래그 도입.
        await _addColumnIfMissing(
          m,
          tagDefinitions,
          tagDefinitions.allowMultiple,
        );
      }
      if (from < 3) {
        // 연결 끊김(태그 보존) 상태 도입.
        await _addColumnIfMissing(m, fileNodes, fileNodes.missingSince);
      }
      if (from < 4) {
        // 폴더 관리 방식(불투명/관리) + 폴더 이동 추적용 자식 시그니처 도입.
        await _addColumnIfMissing(m, fileNodes, fileNodes.manageMode);
        await _addColumnIfMissing(m, fileNodes, fileNodes.childSignature);
        // 이미 인덱싱된 폴더는 내부가 이미 인덱싱돼 있으므로 '관리'로 설정해 기존
        // (깊은 스캔) 동작을 보존한다. 새로 발견되는 폴더에만 불투명 기본이 적용된다.
        // 폴더를 가려내는 컬럼은 뒤 단계에서 종류 열거로 갈리므로 디스크에 어느 쪽이
        // 있는지 보고 조건을 고르고, 방식이 이미 정해진 폴더는 건드리지 않는다 —
        // 이 단계를 다시 돌아도 사용자가 고른 방식을 덮지 않는다.
        final onDisk = await _columnsOf(fileNodes.actualTableName);
        final isFolder = onDisk.contains(fileNodes.kind.name)
            ? "kind = '${NodeKind.directory.name}'"
            : 'is_directory = 1';
        await customStatement(
          'UPDATE file_nodes SET manage_mode = ? '
          'WHERE $isFolder AND manage_mode IS NULL',
          [FolderManageMode.managed.name],
        );
      }
      if (from < 5) {
        // 이미지 크기의 원본(당시엔 가로·세로를 한 문자열에 합쳐 담았다). 뒤의
        // 단계가 이 컬럼을 갈라 옮기고 없애므로 **테이블 정의에는 더 이상 없다** —
        // 그래서 컬럼 참조 대신 원시 SQL로 만든다. 지나간 스키마를 그대로 재현하는
        // 것이 마이그레이션 사슬의 몫이고, 여기서 건너뛰면 뒤 단계가 읽을 것이 없다.
        //
        // 단, 이미 갈라 담은 테이블에 이 컬럼을 되살리면 안 된다 — 텅 빈 원본이
        // 생겨 뒤 단계가 그것을 갈라 담으며 멀쩡한 값을 지운다. 원본도, 갈라 담은
        // 자리도 없을 때만 만든다.
        final onDisk = await _columnsOf(fileNodes.actualTableName);
        if (!onDisk.contains(_legacyDimensionsColumn) &&
            !onDisk.contains(fileNodes.imageWidth.name)) {
          await customStatement(
            'ALTER TABLE file_nodes ADD COLUMN $_legacyDimensionsColumn TEXT',
          );
        }
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
        await _rewriteFileNodes(m, {
          // 옛 폴더 여부 컬럼을 그대로 종류로 옮긴다(키워드는 이 시점에 없다).
          // 저장 표현이 갈리지 않도록 이름은 열거에서 읽는다.
          fileNodes.kind: _Transform(
            'is_directory',
            CustomExpression<String>(
              "CASE WHEN is_directory THEN '${NodeKind.directory.name}' "
              "ELSE '${NodeKind.file.name}' END",
            ),
          ),
          ..._dimensionTransforms,
        });
      }
      if (from < 8) {
        // 키워드 노드에서 본문 컬럼을 걷어낸다 — 부연 정보는 본문이 아니라 태그로
        // 붙어야 필터·정렬·그룹에 걸리기 때문이다. 그와 함께 종류 이름도 갈렸으므로,
        // 직전 스키마로 한 번이라도 연 DB의 옛 이름을 새 이름으로 옮긴다(종류는 열거
        // **이름**으로 저장되어, 안 옮기면 그 행을 읽지 못한다). 컬럼 제거라 어차피
        // 테이블을 다시 쓰므로 둘을 한 번에 묶는다.
        await _rewriteFileNodes(m, {
          fileNodes.kind: _Transform(
            fileNodes.kind.name,
            // 옛 이름은 열거에서 사라져 상수로만 남길 수 있다(레거시 값).
            CustomExpression<String>(
              "CASE WHEN kind = 'memo' THEN '${NodeKind.keyword.name}' "
              'ELSE kind END',
            ),
          ),
          ..._dimensionTransforms,
        });
      }
      if (from < 9) {
        // 미해결 링크 표식 도입. 기존 부여는 모두 해결된 값(또는 링크가 아닌 값)이라
        // 컬럼 기본값(거짓)이 그대로 맞다.
        await _addColumnIfMissing(
          m,
          tagAssignments,
          tagAssignments.valueUnresolved,
        );
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
        await _addColumnIfMissing(m, fileNodes, fileNodes.childFileCount);
      }
      if (from < 12) {
        // 이미지 크기를 한 문자열에서 너비·높이 두 정수로 가른다. 옛 컬럼을 없애야
        // 하므로 컬럼 추가로 끝나지 않고 테이블을 다시 쓴다(7·8단계와 같은 이유).
        //
        // **값을 옮겨 담고 비우지 않는다.** 비우면 스캐너가 크기를 모르는 파일로
        // 보아 이미지를 전부 다시 읽는데(재사용 조건이 크기 유무를 본다), 그 비용이
        // 라이브러리 크기에 비례해 커진다. 옛 값은 스캐너가 쓴 것뿐이라 형식이
        // 일정해 그 자리에서 가를 수 있다.
        await _rewriteFileNodes(m, _dimensionTransforms);
      }
    },
    beforeOpen: (details) async {
      // 외래키 무결성(태그 정의/파일 삭제 시 부여 기록 정리)을 위해 필요.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// 디스크의 [tableName] 테이블에 **실제로 있는** 컬럼 이름들.
  ///
  /// 마이그레이션 단계가 지금의 테이블 정의가 아니라 디스크 모양을 보고 갈리게 하는
  /// 근거다. 테이블 이름은 코드가 쥔 값이라 그대로 끼워 넣는다(PRAGMA는 어차피 값
  /// 바인딩을 받지 않는다).
  Future<Set<String>> _columnsOf(String tableName) async {
    final rows = await customSelect('PRAGMA table_info($tableName)').get();
    return {for (final row in rows) row.read<String>('name')};
  }

  /// 컬럼이 아직 없을 때만 더한다 — 같은 단계를 다시 돌아도 실패하지 않게.
  Future<void> _addColumnIfMissing(
    Migrator m,
    TableInfo<Table, dynamic> table,
    GeneratedColumn<Object> column,
  ) async {
    final onDisk = await _columnsOf(table.actualTableName);
    if (onDisk.contains(column.name)) return;
    await m.addColumn(table, column);
  }

  /// 합쳐 담겼던 옛 이미지 크기를 너비·높이 두 자리로 가르는 변환.
  ///
  /// **모든 재작성 단계가 이것을 함께 건다.** 재작성은 새 테이블을 지금의 정의로
  /// 만들므로 옛 컬럼이 그 자리에서 떨어져 나가는데, 앞선 단계에서 떨어뜨려 놓고
  /// 뒤 단계에서 가르려 들면 읽을 것이 이미 없다. 옛 컬럼이 살아 있는 첫 재작성에서
  /// 곧바로 갈라 담아야 값이 남는다(없으면 이 변환은 저절로 빠진다).
  Map<GeneratedColumn<Object>, _Transform> get _dimensionTransforms => {
    fileNodes.imageWidth: _Transform(
      _legacyDimensionsColumn,
      CustomExpression<int>(
        _legacyDimensionSql('1', '$_dimensionSeparatorAt - 1'),
      ),
    ),
    fileNodes.imageHeight: _Transform(
      _legacyDimensionsColumn,
      CustomExpression<int>(
        _legacyDimensionSql('$_dimensionSeparatorAt + 1', null),
      ),
    ),
  };

  /// 파일 노드 테이블을 지금의 정의대로 다시 쓴다.
  ///
  /// [transforms]는 "이 컬럼은 옛 컬럼을 읽어 이 식으로 채운다"는 뜻이며, 읽을 옛
  /// 컬럼이 디스크에 있을 때만 붙는다. 나머지는 같은 이름 컬럼이 있으면 그대로
  /// 옮기고, 없으면 새 컬럼으로 두어 비운다.
  Future<void> _rewriteFileNodes(
    Migrator m,
    Map<GeneratedColumn<Object>, _Transform> transforms,
  ) async {
    final plan = planTableRewrite(
      onDisk: await _columnsOf(fileNodes.actualTableName),
      target: fileNodes.$columns.map((column) => column.name),
      transformSources: {
        for (final entry in transforms.entries)
          entry.key.name: entry.value.source,
      },
    );

    await m.alterTable(
      // 테이블 재작성은 Drift가 experimental로 표시해 두었지만, 컬럼 제거·제약
      // 변경을 SQLite에서 안전하게 하는(외래키·legacy_alter_table 처리를 포함한)
      // 유일한 공식 경로다. 손으로 쓴 SQL은 그 처리를 다시 만들어야 한다.
      // ignore: experimental_member_use
      TableMigration(
        fileNodes,
        columnTransformer: {
          for (final entry in transforms.entries)
            if (plan.transformed.containsKey(entry.key.name))
              entry.key: entry.value.expression,
        },
        newColumns: [
          for (final column in fileNodes.$columns)
            if (plan.newColumns.contains(column.name)) column,
        ],
      ),
    );
  }
}

/// 재작성 때 컬럼 하나를 채우는 변환 — 읽을 옛 컬럼의 이름과, 값을 옮기는 식.
///
/// 이름을 따로 들고 있어야 그 옛 컬럼이 디스크에 있는지 먼저 보고 식을 붙일지
/// 정할 수 있다(식 자체에서는 무엇을 읽는지 알아낼 수 없다).
class _Transform {
  const _Transform(this.source, this.expression);

  final String source;
  final Expression<Object> expression;
}

/// 가로·세로가 한 문자열로 합쳐 담겼던 옛 컬럼의 이름. 지금의 테이블 정의에는 없어
/// 이름으로만 참조할 수 있으므로 단일 출처로 둔다.
const String _legacyDimensionsColumn = 'image_dimensions';

/// 합쳐 담긴 값에서 가로·세로를 가르는 구분자의 자리를 찾는 SQL(없으면 0).
const String _dimensionSeparatorAt = "instr($_legacyDimensionsColumn, 'x')";

/// 합쳐 담겼던 옛 이미지 크기 문자열에서 한 조각을 잘라 정수로 옮기는 SQL.
///
/// [from]부터 [length]만큼(널이면 끝까지) 자른다. 구분자가 없는 값은 통째로 버려
/// 미지정으로 남긴다 — 그렇게 두면 다음 스캔이 그 파일만 다시 읽어 채우지만,
/// 억지로 잘랐다간 엉뚱한 수가 태그값으로 굳어 남는다.
String _legacyDimensionSql(String from, String? length) {
  final slice = length == null
      ? 'substr($_legacyDimensionsColumn, $from)'
      : 'substr($_legacyDimensionsColumn, $from, $length)';
  return 'CASE WHEN $_dimensionSeparatorAt > 0 '
      'THEN CAST($slice AS INTEGER) END';
}
