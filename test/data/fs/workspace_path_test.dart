import 'package:filetagger/data/fs/workspace_path.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('workspaceAbsolutePath', () {
    test("상대 경로의 '/'를 플랫폼 구분자로 바꿔 루트에 잇는다", () {
      final root = p.join('base', 'root');
      expect(
        workspaceAbsolutePath(root, 'sub/dir/file.txt'),
        p.join(root, 'sub', 'dir', 'file.txt'),
      );
    });

    test('최상위 항목은 루트 바로 밑이다', () {
      final root = p.join('base', 'root');
      expect(workspaceAbsolutePath(root, 'file.txt'), p.join(root, 'file.txt'));
    });

    test('이름에 공백이 있어도 구분자만 바뀐다', () {
      final root = p.join('base', 'my root');
      expect(
        workspaceAbsolutePath(root, 'my folder/my file.txt'),
        p.join(root, 'my folder', 'my file.txt'),
      );
    });

    test('경로를 정규화한다', () {
      final root = p.join('base', 'root');
      expect(
        workspaceAbsolutePath(root, 'sub/../other/file.txt'),
        p.join(root, 'other', 'file.txt'),
      );
    });
  });
}
