import 'dart:io';

import 'package:filetagger/data/fs/node_renamer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('siblingPath', () {
    test('최상위 항목은 이름 자체가 경로', () {
      expect(siblingPath('photo.png', 'new.png'), 'new.png');
    });
    test('중첩 항목은 부모를 유지하고 이름만 바꾼다', () {
      expect(siblingPath('a/b/photo.png', 'x.png'), 'a/b/x.png');
    });
  });

  group('rewriteRenamedPath', () {
    test('자기 자신은 새 경로로', () {
      expect(rewriteRenamedPath('a/b', 'a/b', 'a/z'), 'a/z');
    });
    test('하위 경로는 접두를 치환', () {
      expect(rewriteRenamedPath('a/b/c/d', 'a/b', 'a/z'), 'a/z/c/d');
    });
    test('접두가 겹쳐 보여도 경계(/)가 다르면 무관 → null', () {
      expect(rewriteRenamedPath('a/bc', 'a/b', 'a/z'), isNull);
      expect(rewriteRenamedPath('x', 'a/b', 'a/z'), isNull);
    });
  });

  group('NodeRenamer(디스크)', () {
    late Directory root;
    setUp(() async {
      root = await Directory.systemTemp.createTemp('filetagger_rename_');
    });
    tearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    test('파일 이름을 바꾼다', () async {
      final f = File(p.join(root.path, 'a.txt'));
      await f.writeAsString('hi');
      await const NodeRenamer().rename(
        workspaceRoot: root.path,
        oldRelPath: 'a.txt',
        newRelPath: 'b.txt',
        isDirectory: false,
      );
      expect(await f.exists(), isFalse);
      expect(await File(p.join(root.path, 'b.txt')).readAsString(), 'hi');
    });

    test('폴더 이름을 바꾸면 내용도 함께 옮겨진다', () async {
      final dir = Directory(p.join(root.path, 'sub'));
      await dir.create();
      await File(p.join(dir.path, 'inner.txt')).writeAsString('x');
      await const NodeRenamer().rename(
        workspaceRoot: root.path,
        oldRelPath: 'sub',
        newRelPath: 'renamed',
        isDirectory: true,
      );
      expect(await dir.exists(), isFalse);
      expect(
        await File(p.join(root.path, 'renamed', 'inner.txt')).readAsString(),
        'x',
      );
    });

    test('대상 이름이 이미 있으면 예외를 던진다(덮어쓰지 않음)', () async {
      await File(p.join(root.path, 'a.txt')).writeAsString('a');
      await File(p.join(root.path, 'b.txt')).writeAsString('b');
      expect(
        () => const NodeRenamer().rename(
          workspaceRoot: root.path,
          oldRelPath: 'a.txt',
          newRelPath: 'b.txt',
          isDirectory: false,
        ),
        throwsA(isA<FileSystemException>()),
      );
      // 기존 파일이 보존된다.
      expect(await File(p.join(root.path, 'b.txt')).readAsString(), 'b');
    });
  });
}
