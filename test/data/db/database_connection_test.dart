import 'package:filetagger/core/constants.dart';
import 'package:filetagger/data/db/database_connection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('워크스페이스 DB 경로 계산', () {
    const root = '/some/workspace';

    test('.filetagger 폴더를 관리 폴더 루트 아래에 둔다', () {
      expect(
        filetaggerDirPath(root),
        p.join(root, filetaggerDirName),
      );
    });

    test('DB 파일을 .filetagger 폴더 안에 둔다', () {
      expect(
        databaseFilePath(root),
        p.join(root, filetaggerDirName, databaseFileName),
      );
    });
  });
}
