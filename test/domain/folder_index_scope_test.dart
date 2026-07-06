import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/folder_manage_mode.dart';
import 'package:filetagger/domain/usecases/folder_index_scope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FileNode dir(String path, {FolderManageMode? mode}) =>
      FileNode(path: path, isDirectory: true, manageMode: mode);
  FileNode file(String path) => FileNode(path: path, isDirectory: false);

  group('resolveManageModes (상속)', () {
    test('override 없는 하위는 루트가 재귀면 재귀를 상속한다', () {
      final nodes = [dir('a'), dir('a/b')];
      final resolved = resolveManageModes(
        nodes,
        FolderManageMode.managedRecursive,
      );
      expect(resolved['a'], FolderManageMode.managedRecursive);
      expect(resolved['a/b'], FolderManageMode.managedRecursive);
    });

    test('루트가 비재귀(managed)면 override 없는 최상위 하위는 불투명이 된다', () {
      final resolved = resolveManageModes([dir('a')], FolderManageMode.managed);
      expect(resolved['a'], FolderManageMode.opaque);
    });

    test('중간에서 managed override로 지정하면 그 하위는 불투명으로 상속된다', () {
      // 루트 재귀지만 a=managed(비재귀) → a/b(override 없음)는 불투명.
      final nodes = [dir('a', mode: FolderManageMode.managed), dir('a/b')];
      final resolved = resolveManageModes(
        nodes,
        FolderManageMode.managedRecursive,
      );
      expect(resolved['a'], FolderManageMode.managed);
      expect(resolved['a/b'], FolderManageMode.opaque);
    });

    test('명시 override는 부모와 무관하게 그대로 쓴다', () {
      final nodes = [dir('a'), dir('a/b', mode: FolderManageMode.opaque)];
      final resolved = resolveManageModes(
        nodes,
        FolderManageMode.managedRecursive,
      );
      expect(resolved['a/b'], FolderManageMode.opaque);
    });
  });

  group('droppedNodePaths (범위 축소 시 사라질 노드)', () {
    // a(재귀 상속) 아래 파일/폴더가 인덱싱된 상태.
    List<FileNode> tree() => [
      dir('a'),
      file('a/f.txt'),
      dir('a/b'),
      file('a/b/g.txt'),
    ];

    Map<String, FolderManageMode?> overridesOf(List<FileNode> nodes) => {
      for (final n in nodes)
        if (n.isDirectory) n.path: n.manageMode,
    };

    test('폴더를 불투명으로 바꾸면 그 하위 전부가 사라진다', () {
      final nodes = tree();
      final ov = overridesOf(nodes)..['a'] = FolderManageMode.opaque;
      final dropped = droppedNodePaths(
        nodes,
        FolderManageMode.managedRecursive,
        ov,
      );
      // a 자신은 남고(루트가 직속으로 인덱싱), 그 아래는 모두 사라진다.
      expect(dropped, {'a/f.txt', 'a/b', 'a/b/g.txt'});
    });

    test('재귀를 비재귀(managed)로 내리면 직속만 남고 더 깊은 하위가 사라진다', () {
      final nodes = tree();
      final ov = overridesOf(nodes)..['a'] = FolderManageMode.managed;
      final dropped = droppedNodePaths(
        nodes,
        FolderManageMode.managedRecursive,
        ov,
      );
      // a의 직속(a/f.txt, a/b)은 남고, a/b의 내부(a/b/g.txt)는 사라진다.
      expect(dropped, {'a/b/g.txt'});
    });

    test('루트를 재귀→비재귀로 내리면 최상위 직속만 남는다', () {
      final nodes = tree();
      final dropped = droppedNodePaths(
        nodes,
        FolderManageMode.managed,
        overridesOf(nodes),
      );
      // 루트 직속(a)만 남고, a 내부는 상속이 불투명이 되어 모두 사라진다.
      expect(dropped, {'a/f.txt', 'a/b', 'a/b/g.txt'});
    });

    test('범위를 줄이지 않으면 사라지는 노드가 없다', () {
      final nodes = tree();
      final dropped = droppedNodePaths(
        nodes,
        FolderManageMode.managedRecursive,
        overridesOf(nodes),
      );
      expect(dropped, isEmpty);
    });
  });

  group('indexingFolderPaths (인덱싱 범위)', () {
    test('루트 비재귀에선 루트만 직속을 인덱싱하고 하위(불투명)는 제외', () {
      // a는 override 없어 상속→불투명 → 직속 인덱싱 안 함.
      final indexing = indexingFolderPaths([
        dir('a'),
      ], FolderManageMode.managed);
      expect(indexing, {''});
    });

    test('루트 재귀면 override 없는 하위 폴더도 모두 인덱싱 범위', () {
      final indexing = indexingFolderPaths([
        dir('a'),
        dir('a/b'),
      ], FolderManageMode.managedRecursive);
      expect(indexing, {'', 'a', 'a/b'});
    });

    test('재귀 하위의 managed override 아래(불투명 상속)는 범위 밖', () {
      final indexing = indexingFolderPaths([
        dir('a', mode: FolderManageMode.managed),
        dir('a/b'),
      ], FolderManageMode.managedRecursive);
      // a는 직속 인덱싱, a/b는 상속으로 불투명 → 제외.
      expect(indexing, {'', 'a'});
    });
  });
}
