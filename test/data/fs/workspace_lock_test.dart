import 'dart:io';

import 'package:filetagger/core/constants.dart';
import 'package:filetagger/data/fs/workspace_lock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('filetagger_lock_test');
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  group('워크스페이스 락', () {
    test('락 파일은 메타데이터 폴더 안에 있다', () {
      expect(
        workspaceLockFilePath(root.path),
        p.join(root.path, filetaggerDirName, workspaceLockFileName),
      );
    });

    test('메타데이터 폴더가 없어도 잡고 파일을 남긴다', () {
      final lock = WorkspaceLock.tryAcquire(
        root.path,
        mode: FileLock.exclusive,
      );
      addTearDown(() => lock?.release());

      expect(lock, isNotNull);
      expect(File(workspaceLockFilePath(root.path)).existsSync(), isTrue);
    });

    test('푼 뒤에 다시 잡을 수 있다', () {
      WorkspaceLock.tryAcquire(root.path, mode: FileLock.exclusive)!.release();

      final again = WorkspaceLock.tryAcquire(root.path, mode: FileLock.shared);
      addTearDown(() => again?.release());
      expect(again, isNotNull);
    });

    test('두 번 풀어도 터지지 않는다', () {
      final lock = WorkspaceLock.tryAcquire(
        root.path,
        mode: FileLock.exclusive,
      )!;
      lock.release();
      expect(lock.release, returnsNormally);
    });

    test('락 파일에는 아무것도 쓰지 않는다', () {
      // 뜻을 갖는 것은 내용이 아니라 잠금 상태다. 내용을 쓰기 시작하면 덧붙이기로
      // 여는 지금의 방식이 파일을 계속 불리게 된다.
      final lock = WorkspaceLock.tryAcquire(
        root.path,
        mode: FileLock.exclusive,
      )!;
      addTearDown(lock.release);

      expect(File(workspaceLockFilePath(root.path)).lengthSync(), 0);
    });

    test('폴더를 만들 수 없는 자리에서는 조용히 null이다', () {
      // 관리 폴더 자리에 파일이 놓여 있으면 메타데이터 폴더를 만들 수 없다.
      // 락은 안전장치이지 기능이 아니므로 예외를 던지지 않고 null로 접혀야 한다.
      final blocked = Directory(p.join(root.path, 'blocked'))..createSync();
      File(p.join(blocked.path, filetaggerDirName)).writeAsStringSync('');

      expect(
        WorkspaceLock.tryAcquire(blocked.path, mode: FileLock.exclusive),
        isNull,
      );
    });
  });
}
