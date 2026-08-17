import 'package:drift/drift.dart' show Value;
import 'package:filetagger/data/db/app_database.dart';
import 'package:filetagger/domain/entities/folder_manage_mode.dart';
import 'package:filetagger/domain/entities/node_kind.dart';
import 'package:flutter_test/flutter_test.dart';

/// 생성 파일(`app_database.g.dart`)까지 실제 컴파일되는지 확인하는 가드.
/// DB를 열지 않고(host sqlite3 의존 회피) 생성된 컴패니언 타입만 참조한다.
void main() {
  test('FileNodes 스키마에 연결 끊김(missingSince) 컬럼이 반영된다', () {
    const companion = FileNodesCompanion(missingSince: Value(null));
    expect(companion.missingSince.present, isTrue);
    expect(companion.missingSince.value, isNull);
  });

  test('FileNodes 스키마에 폴더 관리 방식·자식 시그니처 컬럼이 반영된다', () {
    const companion = FileNodesCompanion(
      manageMode: Value(FolderManageMode.opaque),
      childSignature: Value('sig'),
    );
    expect(companion.manageMode.value, FolderManageMode.opaque);
    expect(companion.childSignature.value, 'sig');
  });

  test('FileNodes 스키마에 내부 파일 수량 컬럼이 반영된다', () {
    const companion = FileNodesCompanion(childFileCount: Value(3));
    expect(companion.childFileCount.value, 3);
  });

  test('FileNodes 스키마에 이미지 크기 컬럼이 반영된다', () {
    const companion = FileNodesCompanion(imageDimensions: Value('400x300'));
    expect(companion.imageDimensions.value, '400x300');
  });

  test('FileNodes 스키마에 노드 종류 컬럼이 반영된다', () {
    const companion = FileNodesCompanion(kind: Value(NodeKind.keyword));
    expect(companion.kind.value, NodeKind.keyword);
  });

  test('TagAssignments 스키마에 미해결 링크 컬럼이 반영된다', () {
    const companion = TagAssignmentsCompanion(valueUnresolved: Value(true));
    expect(companion.valueUnresolved.value, isTrue);
  });
}
