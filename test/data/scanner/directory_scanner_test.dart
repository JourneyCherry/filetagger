import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:filetagger/core/constants.dart';
import 'package:filetagger/data/scanner/directory_scanner.dart';
import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/folder_manage_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// 테스트에서 Windows 항목에 숨김 속성을 건다(FFI SetFileAttributesW). kernel32는
/// top-level final의 지연 초기화라 Windows 테스트에서 처음 호출될 때만 로드된다.
const int _fileAttributeHidden = 0x2;
final int Function(Pointer<Utf16>, int) _setFileAttributesW =
    DynamicLibrary.open('kernel32.dll').lookupFunction<
      Int32 Function(Pointer<Utf16>, Uint32),
      int Function(Pointer<Utf16>, int)
    >('SetFileAttributesW');

void _markHidden(String path) {
  final ptr = path.toNativeUtf16();
  try {
    _setFileAttributesW(ptr, _fileAttributeHidden);
  } finally {
    malloc.free(ptr);
  }
}

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('filetagger_scan_test');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  Future<void> touchFile(String relative) async {
    final file = File(p.join(root.path, p.joinAll(relative.split('/'))));
    await file.create(recursive: true);
  }

  // 400x300을 담은 최소 PNG 헤더(스캐너의 이미지 크기 파싱용).
  const pngHeader = <int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
    0x00, 0x00, 0x01, 0x90, 0x00, 0x00, 0x01, 0x2C,
  ];

  Future<void> writePng(String relative) async {
    final file = File(p.join(root.path, p.joinAll(relative.split('/'))));
    await file.create(recursive: true);
    await file.writeAsBytes(pngHeader);
  }

  group('이미지 크기 인덱싱', () {
    test('이미지 파일은 헤더에서 크기를 채우고, 비이미지는 null', () async {
      await writePng('pic.png');
      await touchFile('note.txt');

      final result = await const DirectoryScanner().scan(root.path);
      final pic = result.nodes.firstWhere((n) => n.path == 'pic.png');
      final note = result.nodes.firstWhere((n) => n.path == 'note.txt');
      expect(pic.imageDimensions, '400x300');
      expect(note.imageDimensions, isNull);
    });

    test('크기·수정시각이 그대로면 저장된 이미지 크기를 재사용한다(재파싱 안 함)', () async {
      await writePng('pic.png');
      final first = (await const DirectoryScanner().scan(
        root.path,
      )).nodes.firstWhere((n) => n.path == 'pic.png');

      // 같은 파일이지만 저장값이 다른 척(1x1). 재사용되면 이 값이 그대로 나온다.
      final prior = <String, FileNode>{
        'pic.png': FileNode(
          path: 'pic.png',
          isDirectory: false,
          size: first.size,
          modifiedAt: first.modifiedAt,
          contentHashPrefix: first.contentHashPrefix,
          imageDimensions: '1x1',
        ),
      };
      final again = (await const DirectoryScanner().scan(
        root.path,
        priorIndex: prior,
      )).nodes.firstWhere((n) => n.path == 'pic.png');
      expect(again.imageDimensions, '1x1');
    });

    test('저장된 이미지 크기가 없으면(컬럼 신설 직후) 다시 읽어 채운다', () async {
      await writePng('pic.png');
      final first = (await const DirectoryScanner().scan(
        root.path,
      )).nodes.firstWhere((n) => n.path == 'pic.png');

      // 해시는 있으나 이미지 크기는 아직 null인 직전 인덱스.
      final prior = <String, FileNode>{
        'pic.png': FileNode(
          path: 'pic.png',
          isDirectory: false,
          size: first.size,
          modifiedAt: first.modifiedAt,
          contentHashPrefix: first.contentHashPrefix,
        ),
      };
      final again = (await const DirectoryScanner().scan(
        root.path,
        priorIndex: prior,
      )).nodes.firstWhere((n) => n.path == 'pic.png');
      expect(again.imageDimensions, '400x300');
    });
  });

  test('파일과 폴더를 루트 기준 상대 경로(/ 구분)로 인덱싱한다', () async {
    await touchFile('a.txt');
    await touchFile('sub/b.txt');

    // 루트를 재귀 관리로 열어 내부(sub/b.txt)까지 인덱싱한 뒤 경로 정규화를 확인한다
    // (기본은 직속만 관리라 하위 폴더 내부는 인덱싱되지 않는다 — 아래 별도 테스트).
    final result = await const DirectoryScanner().scan(
      root.path,
      rootManageMode: FolderManageMode.managedRecursive,
    );
    final paths = result.nodes.map((n) => n.path).toSet();

    expect(paths, containsAll(<String>['a.txt', 'sub', 'sub/b.txt']));
    expect(result.nodes.firstWhere((n) => n.path == 'sub').isDirectory, isTrue);
    expect(
      result.nodes.firstWhere((n) => n.path == 'a.txt').isDirectory,
      isFalse,
    );
  });

  group('폴더 관리 방식(상속)', () {
    test('루트 기본(managed)에선 처음 발견된 하위 폴더가 불투명이라 내부를 인덱싱하지 않는다', () async {
      await touchFile('top.txt');
      await touchFile('sub/inner.txt');

      // rootManageMode 기본 = managed(직속만). sub는 override 없어 상속→불투명.
      final result = await const DirectoryScanner().scan(root.path);
      final paths = result.nodes.map((n) => n.path).toSet();
      final sub = result.nodes.firstWhere((n) => n.path == 'sub');

      expect(paths, containsAll(<String>['top.txt', 'sub']));
      expect(paths, isNot(contains('sub/inner.txt')));
      // 저장값은 override(상속이면 null)다.
      expect(sub.manageMode, isNull);
      // 불투명 폴더라도 이동 추적용 자식 시그니처는 채워진다.
      expect(sub.childSignature, isNotNull);
    });

    test('override가 managed인 폴더는 직속 내용을 인덱싱한다', () async {
      await touchFile('sub/inner.txt');
      final prior = {
        'sub': const FileNode(
          path: 'sub',
          isDirectory: true,
          manageMode: FolderManageMode.managed,
        ),
      };

      final result = await const DirectoryScanner().scan(
        root.path,
        priorIndex: prior,
      );
      final paths = result.nodes.map((n) => n.path).toSet();

      expect(paths, containsAll(<String>['sub', 'sub/inner.txt']));
      // override는 그대로 보존된다.
      expect(
        result.nodes.firstWhere((n) => n.path == 'sub').manageMode,
        FolderManageMode.managed,
      );
    });

    test('루트 재귀 관리면 override 없는 하위가 깊이까지 상속되어 인덱싱된다', () async {
      await touchFile('sub/deep/inner.txt');

      final result = await const DirectoryScanner().scan(
        root.path,
        rootManageMode: FolderManageMode.managedRecursive,
      );
      final paths = result.nodes.map((n) => n.path).toSet();

      expect(
        paths,
        containsAll(<String>['sub', 'sub/deep', 'sub/deep/inner.txt']),
      );
      // 상속받은 하위는 override가 없다(null).
      expect(
        result.nodes.firstWhere((n) => n.path == 'sub/deep').manageMode,
        isNull,
      );
    });

    test('재귀 하위에서 managed override로 지정하면 그 지점부터 재귀가 멈춘다', () async {
      await touchFile('sub/deep/inner.txt');
      // 루트 재귀지만 sub를 managed(비재귀)로 지정 → sub/deep은 노드로 잡히되
      // 그 내부(sub/deep/inner.txt)는 인덱싱되지 않는다.
      final prior = {
        'sub': const FileNode(
          path: 'sub',
          isDirectory: true,
          manageMode: FolderManageMode.managed,
        ),
      };

      final result = await const DirectoryScanner().scan(
        root.path,
        priorIndex: prior,
        rootManageMode: FolderManageMode.managedRecursive,
      );
      final paths = result.nodes.map((n) => n.path).toSet();

      expect(paths, containsAll(<String>['sub', 'sub/deep']));
      expect(paths, isNot(contains('sub/deep/inner.txt')));
    });

    test('빈 폴더의 자식 시그니처는 null이다', () async {
      await Directory(p.join(root.path, 'empty')).create();

      final result = await const DirectoryScanner().scan(root.path);
      final empty = result.nodes.firstWhere((n) => n.path == 'empty');

      expect(empty.childSignature, isNull);
    });

    test('불투명 폴더 안의 중첩 .filetagger/도 병합 후보로 수집한다', () async {
      await touchFile('project/$filetaggerDirName/$databaseFileName');
      await touchFile('project/note.txt');

      // 'project'는 기본 불투명이라 내부(note.txt)는 인덱싱되지 않지만,
      // 직속 자식은 훑으므로 .filetagger/는 발견돼 병합 후보가 된다.
      final result = await const DirectoryScanner().scan(root.path);

      expect(result.nestedFiletaggerDirs, contains('project'));
      expect(
        result.nodes.map((n) => n.path).toSet(),
        isNot(contains('project/note.txt')),
      );
    });
  });

  test('루트 자신의 .filetagger/는 스캔에서 제외하고 병합 후보도 아니다', () async {
    await touchFile('$filetaggerDirName/$databaseFileName');
    await touchFile('keep.txt');

    final result = await const DirectoryScanner().scan(root.path);

    expect(
      result.nodes.map((n) => n.path),
      everyElement(isNot(contains(filetaggerDirName))),
    );
    expect(result.nestedFiletaggerDirs, isEmpty);
  });

  test('중첩된 .filetagger/는 소유 폴더를 병합 후보로 수집한다', () async {
    await touchFile('project/$filetaggerDirName/$databaseFileName');
    await touchFile('project/note.txt');

    final result = await const DirectoryScanner().scan(root.path);

    expect(result.nestedFiletaggerDirs, contains('project'));
    // 중첩 .filetagger 내부 파일은 노드로 잡히지 않는다.
    expect(
      result.nodes.map((n) => n.path),
      everyElement(isNot(contains(filetaggerDirName))),
    );
  });

  group('OS 숨김 파일/폴더 제외', () {
    test('POSIX: dot-prefix 파일/폴더는 인덱싱·재귀에서 제외한다', () async {
      await touchFile('visible.txt');
      await touchFile('.secret.txt');
      await touchFile('.secretdir/inner.txt');

      // 재귀 관리로 열어도 숨김 폴더 하위는 순회하지 않는다.
      final result = await const DirectoryScanner().scan(
        root.path,
        rootManageMode: FolderManageMode.managedRecursive,
      );
      final paths = result.nodes.map((n) => n.path).toSet();

      expect(paths, contains('visible.txt'));
      expect(paths, isNot(contains('.secret.txt')));
      expect(paths, isNot(contains('.secretdir')));
      expect(paths, isNot(contains('.secretdir/inner.txt')));
    }, skip: Platform.isWindows ? 'POSIX 이름 기반 판정 전용' : false);

    test('Windows: 숨김 속성 파일/폴더는 인덱싱·재귀에서 제외한다', () async {
      await touchFile('visible.txt');
      await touchFile('secret.txt');
      await touchFile('secretdir/inner.txt');
      _markHidden(p.join(root.path, 'secret.txt'));
      _markHidden(p.join(root.path, 'secretdir'));

      final result = await const DirectoryScanner().scan(
        root.path,
        rootManageMode: FolderManageMode.managedRecursive,
      );
      final paths = result.nodes.map((n) => n.path).toSet();

      expect(paths, contains('visible.txt'));
      expect(paths, isNot(contains('secret.txt')));
      expect(paths, isNot(contains('secretdir')));
      expect(paths, isNot(contains('secretdir/inner.txt')));
    }, skip: Platform.isWindows ? false : '숨김 속성 판정은 Windows 전용');
  });

  group('부분 해시 재사용(재해시 최적화)', () {
    // 재계산되면 절대 나올 수 없는 값 — 이 값이 그대로면 저장된 해시를 재사용한 것.
    const sentinel = 'reused-sentinel';

    Future<FileStat> writeFile(String relative, String content) async {
      final file = File(p.join(root.path, p.joinAll(relative.split('/'))));
      await file.create(recursive: true);
      await file.writeAsString(content);
      return file.stat();
    }

    test('크기·수정시각이 그대로면 저장된 해시를 재사용한다', () async {
      final stat = await writeFile('a.txt', 'hello');
      final prior = {
        'a.txt': FileNode(
          path: 'a.txt',
          isDirectory: false,
          size: stat.size,
          modifiedAt: stat.modified,
          contentHashPrefix: sentinel,
        ),
      };

      final result = await const DirectoryScanner().scan(
        root.path,
        priorIndex: prior,
      );
      final node = result.nodes.firstWhere((n) => n.path == 'a.txt');
      expect(node.contentHashPrefix, sentinel);
    });

    test('크기가 다르면 재사용하지 않고 새로 계산한다', () async {
      final stat = await writeFile('a.txt', 'hello');
      final prior = {
        'a.txt': FileNode(
          path: 'a.txt',
          isDirectory: false,
          size: stat.size + 1,
          modifiedAt: stat.modified,
          contentHashPrefix: sentinel,
        ),
      };

      final result = await const DirectoryScanner().scan(
        root.path,
        priorIndex: prior,
      );
      final node = result.nodes.firstWhere((n) => n.path == 'a.txt');
      expect(node.contentHashPrefix, isNot(sentinel));
      expect(node.contentHashPrefix, isNotNull);
    });

    test('수정시각이 다르면 재사용하지 않고 새로 계산한다', () async {
      final stat = await writeFile('a.txt', 'hello');
      final prior = {
        'a.txt': FileNode(
          path: 'a.txt',
          isDirectory: false,
          size: stat.size,
          modifiedAt: stat.modified.add(const Duration(seconds: 5)),
          contentHashPrefix: sentinel,
        ),
      };

      final result = await const DirectoryScanner().scan(
        root.path,
        priorIndex: prior,
      );
      final node = result.nodes.firstWhere((n) => n.path == 'a.txt');
      expect(node.contentHashPrefix, isNot(sentinel));
    });

    test('이전 해시가 없으면(null) 새로 계산한다', () async {
      final stat = await writeFile('a.txt', 'hello');
      final prior = {
        'a.txt': FileNode(
          path: 'a.txt',
          isDirectory: false,
          size: stat.size,
          modifiedAt: stat.modified,
          contentHashPrefix: null,
        ),
      };

      final result = await const DirectoryScanner().scan(
        root.path,
        priorIndex: prior,
      );
      final node = result.nodes.firstWhere((n) => n.path == 'a.txt');
      expect(node.contentHashPrefix, isNotNull);
    });
  });
}
