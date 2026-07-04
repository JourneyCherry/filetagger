import 'dart:io';

import 'package:filetagger/core/constants.dart';
import 'package:filetagger/data/scanner/directory_scanner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

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

  test('파일과 폴더를 루트 기준 상대 경로(/ 구분)로 인덱싱한다', () async {
    await touchFile('a.txt');
    await touchFile('sub/b.txt');

    final result = await const DirectoryScanner().scan(root.path);
    final paths = result.nodes.map((n) => n.path).toSet();

    expect(paths, containsAll(<String>['a.txt', 'sub', 'sub/b.txt']));
    expect(
      result.nodes.firstWhere((n) => n.path == 'sub').isDirectory,
      isTrue,
    );
    expect(
      result.nodes.firstWhere((n) => n.path == 'a.txt').isDirectory,
      isFalse,
    );
  });

  test('루트 자신의 .filetagger/는 스캔에서 제외하고 병합 후보도 아니다', () async {
    await touchFile('$filetaggerDirName/$databaseFileName');
    await touchFile('keep.txt');

    final result = await const DirectoryScanner().scan(root.path);

    expect(result.nodes.map((n) => n.path), everyElement(isNot(contains(filetaggerDirName))));
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
}
