import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:filetagger/core/constants.dart';
import 'package:filetagger/data/scanner/directory_scanner.dart';
import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/node_kind.dart';
import 'package:filetagger/domain/entities/scan_progress.dart';
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
      expect(pic.imageWidth, 400);
      expect(pic.imageHeight, 300);
      expect(note.imageWidth, isNull);
      expect(note.imageHeight, isNull);
    });

    test('크기·수정시각이 그대로면 저장된 이미지 크기를 재사용한다(재파싱 안 함)', () async {
      await writePng('pic.png');
      final first = (await const DirectoryScanner().scan(
        root.path,
      )).nodes.firstWhere((n) => n.path == 'pic.png');

      // 같은 파일이지만 저장값이 다른 척. 재사용되면 이 값이 그대로 나온다.
      final prior = <String, FileNode>{
        'pic.png': FileNode(
          path: 'pic.png',
          kind: NodeKind.file,
          size: first.size,
          modifiedAt: first.modifiedAt,
          contentHashPrefix: first.contentHashPrefix,
          imageWidth: 1,
          imageHeight: 1,
        ),
      };
      final again = (await const DirectoryScanner().scan(
        root.path,
        priorIndex: prior,
      )).nodes.firstWhere((n) => n.path == 'pic.png');
      expect(again.imageWidth, 1);
      expect(again.imageHeight, 1);
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
          kind: NodeKind.file,
          size: first.size,
          modifiedAt: first.modifiedAt,
          contentHashPrefix: first.contentHashPrefix,
        ),
      };
      final again = (await const DirectoryScanner().scan(
        root.path,
        priorIndex: prior,
      )).nodes.firstWhere((n) => n.path == 'pic.png');
      expect(again.imageWidth, 400);
      expect(again.imageHeight, 300);
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
          kind: NodeKind.directory,
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
          kind: NodeKind.directory,
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

    test('내부를 인덱싱하지 않는 불투명 폴더도 직속 파일 수는 센다', () async {
      await touchFile('box/a.txt');
      await touchFile('box/b.txt');
      // 하위 폴더와 그 안의 파일은 세지 않는다(직속 파일만).
      await touchFile('box/deep/c.txt');
      await Directory(p.join(root.path, 'empty')).create();

      final result = await const DirectoryScanner().scan(root.path);
      final box = result.nodes.firstWhere((n) => n.path == 'box');
      final empty = result.nodes.firstWhere((n) => n.path == 'empty');

      // 'box'는 기본 불투명이라 내부는 인덱싱되지 않지만 수량은 채워진다.
      expect(result.nodes.map((n) => n.path), isNot(contains('box/a.txt')));
      expect(box.childFileCount, 2);
      // 빈 폴더는 시그니처와 달리 0으로 남는다(폴더 표식을 겸하기 때문).
      expect(empty.childFileCount, 0);
    });

    test('파일 노드는 내부 파일 수량을 갖지 않는다', () async {
      await touchFile('note.txt');

      final result = await const DirectoryScanner().scan(root.path);
      final note = result.nodes.firstWhere((n) => n.path == 'note.txt');

      expect(note.childFileCount, isNull);
    });

    test('내부 파일 수량은 .filetagger/를 세지 않는다', () async {
      await touchFile('project/$filetaggerDirName/$databaseFileName');
      await touchFile('project/note.txt');

      final result = await const DirectoryScanner().scan(root.path);
      final project = result.nodes.firstWhere((n) => n.path == 'project');

      // .filetagger/는 디렉토리라 파일 수에 애초에 들지 않는다.
      expect(project.childFileCount, 1);
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
    test(
      'POSIX: dot-prefix 파일/폴더는 인덱싱·재귀에서 제외한다',
      () async {
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
      },
      skip: Platform.isWindows ? 'POSIX 이름 기반 판정 전용' : false,
    );

    test(
      'Windows: 숨김 속성 파일/폴더는 인덱싱·재귀에서 제외한다',
      () async {
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
      },
      skip: Platform.isWindows ? false : '숨김 속성 판정은 Windows 전용',
    );
  });

  test('파일이 동시성 상한보다 많아도 빠짐·겹침 없이 각자 제 값을 갖는다', () async {
    // 파일 인덱싱은 순회가 끝난 뒤 여러 일꾼이 나눠 도는데, 일꾼끼리 결과가 섞이면
    // 크기·해시가 남의 파일 것이 된다. 상한을 넉넉히 넘는 수를 여러 폴더에 흩어
    // 두고, 파일마다 다른 길이의 내용을 넣어 제 값이 제자리에 왔는지 본다.
    const count = 60;
    for (var i = 0; i < count; i++) {
      final file = File(p.join(root.path, 'dir${i % 5}', 'f$i.txt'));
      await file.create(recursive: true);
      await file.writeAsString('x' * (i + 1));
    }

    final result = await const DirectoryScanner().scan(
      root.path,
      rootManageMode: FolderManageMode.managedRecursive,
    );
    final byPath = {
      for (final n in result.nodes.where((n) => n.isFile)) n.path: n,
    };

    expect(byPath, hasLength(count));
    for (var i = 0; i < count; i++) {
      final node = byPath['dir${i % 5}/f$i.txt'];
      expect(node, isNotNull, reason: 'f$i.txt가 빠졌다');
      expect(node!.size, i + 1, reason: 'f$i.txt의 크기가 남의 것이다');
      expect(node.contentHashPrefix, isNotNull);
    }
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
          kind: NodeKind.file,
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
          kind: NodeKind.file,
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
          kind: NodeKind.file,
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
          kind: NodeKind.file,
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

  // 스캔은 화면과 다른 isolate에서 돌기 때문에, 진행 상태는 보고로만 건너온다.
  // 보고가 끊기면 화면은 "작업 중"을 알 길이 없으므로 최종 집계까지 확인한다.
  group('진행 보고', () {
    test('훑은 항목 수와 읽은 파일 수를 알린다', () async {
      await touchFile('a.txt');
      await touchFile('b.txt');
      // 하위 폴더는 기본(관리)에서 불투명이라 나열은 하되 내부를 인덱싱하지 않는다.
      await touchFile('sub/c.txt');

      final reports = <ScanProgress>[];
      await const DirectoryScanner().scan(root.path, onProgress: reports.add);

      expect(reports, isNotEmpty);
      final last = reports.last;
      // 루트 직속 셋(a.txt, b.txt, sub) + sub 직속 하나(c.txt).
      expect(last.entriesSeen, 4);
      // 내용을 읽는 것은 인덱싱 대상인 루트 직속 파일뿐이다.
      expect(last.filesIndexed, 2);
    });

    // 목록에 미리 보여 주는 근거가 이 노드들이다. 빠지면 그 노드는 스캔이 끝날
    // 때까지 안 보이고, 겹치면 같은 것을 두 번 저장하게 된다.
    test('보고에 실린 노드는 최종 결과와 정확히 같다(빠짐·중복 없음)', () async {
      await touchFile('a.txt');
      await touchFile('b.txt');
      await touchFile('sub/c.txt');

      final streamed = <String>[];
      final result = await const DirectoryScanner().scan(
        root.path,
        onProgress: (progress) =>
            streamed.addAll(progress.newNodes.map((n) => n.path)),
      );

      expect(streamed.toSet(), result.nodes.map((n) => n.path).toSet());
      expect(streamed.length, result.nodes.length);
    });

    // 파일 노드가 순회를 다 마친 뒤에야 나오면, 순회하는 내내 인덱스에는 폴더밖에
    // 없다. 태그값 그룹은 폴더를 값 버킷에 담지 않으므로 그동안 목록이 통째로 비어
    // 스캔 표시가 자리를 차지한다 — 파일도 순회 도중에 나와야 한다.
    test('파일 보고는 순회가 끝나기를 기다리지 않는다', () async {
      // 층마다 나열을 한 번씩 기다리는 깊은 사슬. 위층 파일이 아래층을 나열하는
      // 동안 인덱싱을 마칠 자리를 준다.
      var dir = '';
      for (var depth = 0; depth < 6; depth++) {
        dir = depth == 0 ? 'd0' : '$dir/d$depth';
        for (var i = 0; i < 3; i++) {
          await touchFile('$dir/f$i.txt');
        }
      }

      final kinds = <bool>[];
      await const DirectoryScanner().scan(
        root.path,
        rootManageMode: FolderManageMode.managedRecursive,
        onProgress: (progress) =>
            kinds.addAll(progress.newNodes.map((n) => n.isDirectory)),
      );

      final lastDirectory = kinds.lastIndexOf(true);
      final firstFile = kinds.indexOf(false);
      expect(firstFile, isNonNegative, reason: '파일 노드가 하나도 보고되지 않았다');
      expect(
        firstFile,
        lessThan(lastDirectory),
        reason: '마지막 폴더보다 먼저 나온 파일이 하나도 없다(순회가 끝난 뒤에야 파일이 나온다)',
      );
    });

    // 스캔 본체는 다른 isolate로 건너가는데, 클로저는 변수 하나가 아니라 스코프
    // 컨텍스트를 통째로 캡처한다. 진행 콜백이 보낼 수 없는 것(화면 상태 등)을 붙들고
    // 있어도 그것이 스캔 인자에 딸려가면 안 된다 — 딸려가면 스캔 자체가 실패한다.
    test('진행 콜백이 보낼 수 없는 것을 붙들고 있어도 스캔은 돈다', () async {
      await touchFile('a.txt');
      // Completer는 isolate로 보낼 수 없는 객체다(화면 상태를 대신하는 표본).
      final unsendable = Completer<void>();
      final reports = <ScanProgress>[];

      final result = await const DirectoryScanner().scan(
        root.path,
        onProgress: (progress) {
          if (!unsendable.isCompleted) unsendable.complete();
          reports.add(progress);
        },
      );

      expect(result.nodes.map((n) => n.path), contains('a.txt'));
      expect(reports, isNotEmpty);
    });

    test('진행 보고를 원하지 않아도 결과는 같다', () async {
      await touchFile('a.txt');
      await touchFile('sub/c.txt');

      final withReports = await const DirectoryScanner().scan(
        root.path,
        onProgress: (_) {},
      );
      final without = await const DirectoryScanner().scan(root.path);

      expect(
        without.nodes.map((n) => n.path).toList(),
        withReports.nodes.map((n) => n.path).toList(),
      );
    });
  });
}
