import 'dart:io';

import 'package:filetagger/core/constants.dart';
import 'package:filetagger/data/queue/command_json.dart';
import 'package:filetagger/data/queue/command_queue_store.dart';
import 'package:filetagger/domain/entities/external_tag_command.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late DateTime now;

  FileCommandQueueStore store({Duration? retention, int? maxRetained}) =>
      FileCommandQueueStore(
        root.path,
        retention: retention ?? const Duration(days: 1),
        maxRetainedFailures: maxRetained ?? 100,
        now: () => now,
      );

  Directory queueDir() =>
      Directory(p.join(root.path, filetaggerDirName, commandQueueDirName));

  File drop(String name, String text) {
    final file = File(p.join(queueDir().path, name))
      ..createSync(recursive: true)
      ..writeAsStringSync(text);
    return file;
  }

  File dropCommand(String name, ExternalTagCommand command) =>
      drop(name, encodeCommandFile(command));

  String markedText(ExternalTagCommand command, DateTime at) =>
      (decodeCommandFile(encodeCommandFile(command))).withFailure(
        CommandFailure(reason: CommandFailureReason.targetMissing, at: at),
      );

  setUp(() {
    root = Directory.systemTemp.createTempSync('filetagger_queue_test');
    now = DateTime(2026, 8, 1, 12);
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test('큐 폴더가 없으면 빈 목록이되, 자리는 만들어 둔다', () async {
    expect(queueDir().existsSync(), isFalse);

    expect(await store().takePending(), isEmpty);

    // 없는 폴더는 외부 앱이 찾을 수도, 감시자가 붙을 수도 없다.
    expect(queueDir().existsSync(), isTrue);
  });

  test('항목을 파일 이름순으로 돌려준다', () async {
    dropCommand('20260801-002.json', _command('b.png'));
    dropCommand('20260801-001.json', _command('a.png'));

    final pending = await store().takePending();

    expect(pending.map((e) => e.command.targetPath), ['a.png', 'b.png']);
    expect(pending.map((e) => e.id), [
      '20260801-001.json',
      '20260801-002.json',
    ]);
  });

  test('성공한 항목은 지우고, 손대지 않은 항목은 다음 패스에 다시 온다', () async {
    dropCommand('a.json', _command('a.png'));
    dropCommand('b.json', _command('b.png'));
    final queue = store();

    await queue.takePending();
    await queue.remove('a.json');

    final again = await queue.takePending();
    expect(again.map((e) => e.id), ['b.json']);
  });

  test('실패는 제자리에 표식만 남고, 다음 패스에서 건너뛴다', () async {
    dropCommand('a.json', _command('a.png'));
    final queue = store();
    await queue.takePending();

    await queue.markFailed(
      'a.json',
      CommandFailure(
        reason: CommandFailureReason.targetMissing,
        at: now,
        message: '없는 파일입니다.',
      ),
    );

    // 파일은 그 자리에 그대로 있어야 외부 앱이 자기 경로로 원인을 읽는다.
    final file = File(p.join(queueDir().path, 'a.json'));
    expect(file.existsSync(), isTrue);
    final record = decodeCommandFile(file.readAsStringSync());
    expect(record, isA<MarkedCommand>());
    expect((record as MarkedCommand).source['path'], 'a.png');
    expect(record.failure.message, '없는 파일입니다.');

    expect(await queue.takePending(), isEmpty);
  });

  test('명령으로 읽히지 않는 항목은 패스가 스스로 표식을 붙인다', () async {
    drop('broken.json', '{반쯤 쓰다 만');

    final queue = store();
    expect(await queue.takePending(), isEmpty);

    final file = File(p.join(queueDir().path, 'broken.json'));
    final marked = file.readAsStringSync();
    final record = decodeCommandFile(marked);
    expect(
      (record as MarkedCommand).failure.reason,
      CommandFailureReason.malformed,
    );
    // 원문이 남아 있어야 외부 앱이 자기가 쓴 것을 볼 수 있다.
    expect(record.source['raw'], '{반쯤 쓰다 만');

    // 두 번째 패스는 건너뛰기만 하고 아무것도 쓰지 않는다. 앱이 쓸 때마다 큐
    // 감시자가 깨므로, 여기서 멈추지 않으면 되풀이가 된다.
    expect(await queue.takePending(), isEmpty);
    expect(file.readAsStringSync(), marked);
  });

  test('경로 조각이 섞인 손잡이는 큐 밖을 건드리지 않는다', () async {
    final outside = File(p.join(root.path, filetaggerDirName, 'view.json'))
      ..createSync(recursive: true)
      ..writeAsStringSync('{}');

    await store().remove(p.join('..', 'view.json'));

    expect(outside.existsSync(), isTrue);
  });

  group('실패 항목 정리', () {
    test('보존 기간이 지난 표식 항목만 지운다', () async {
      drop(
        'old.json',
        markedText(_command('a.png'), now.subtract(const Duration(days: 2))),
      );
      drop(
        'fresh.json',
        markedText(_command('b.png'), now.subtract(const Duration(hours: 1))),
      );
      // 표식 없는 오래된 항목은 미처리분일 뿐이라 나이로 지우지 않는다.
      dropCommand('pending.json', _command('c.png'));

      final pending = await store().takePending();

      expect(pending.map((e) => e.id), ['pending.json']);
      final left = queueDir().listSync().map((e) => p.basename(e.path)).toSet();
      expect(left, {'fresh.json', 'pending.json'});
    });

    test('상한을 넘으면 오래된 표식부터 지운다', () async {
      for (var i = 0; i < 4; i++) {
        drop(
          'f$i.json',
          markedText(_command('$i.png'), now.subtract(Duration(minutes: i))),
        );
      }

      await store(maxRetained: 2).takePending();

      final left = queueDir().listSync().map((e) => p.basename(e.path)).toSet();
      expect(left, {'f0.json', 'f1.json'});
    });
  });

  group('중첩 워크스페이스 흡수 이관', () {
    late Directory child;

    Directory childQueueDir() =>
        Directory(p.join(child.path, filetaggerDirName, commandQueueDirName));

    setUp(() {
      child = Directory(p.join(root.path, 'sub'))..createSync(recursive: true);
    });

    void dropInChild(String name, String text) {
      File(p.join(childQueueDir().path, name))
        ..createSync(recursive: true)
        ..writeAsStringSync(text);
    }

    test('대기 항목만 접두를 붙여 옮기고 원본은 지운다', () async {
      dropInChild('a.json', encodeCommandFile(_command('01.png')));
      dropInChild('failed.json', markedText(_command('02.png'), now));

      await migrateCommandQueue(
        fromRoot: child.path,
        toRoot: root.path,
        childRelPath: 'sub',
      );

      final pending = await store().takePending();
      expect(pending.map((e) => e.command.targetPath), ['sub/01.png']);
      // 판정이 끝난 진단 기록까지 상위로 데려가지 않는다.
      expect(childQueueDir().listSync().map((e) => p.basename(e.path)), [
        'failed.json',
      ]);
    });

    test('이름이 겹쳐도 상위의 기존 항목을 덮어쓰지 않는다', () async {
      dropCommand('a.json', _command('mine.png'));
      dropInChild('a.json', encodeCommandFile(_command('theirs.png')));

      await migrateCommandQueue(
        fromRoot: child.path,
        toRoot: root.path,
        childRelPath: 'sub',
      );

      final pending = await store().takePending();
      expect(pending.map((e) => e.command.targetPath).toSet(), {
        'mine.png',
        'sub/theirs.png',
      });
    });
  });
}

ExternalTagCommand _command(String path) =>
    ExternalTagCommand(targetPath: path, tagName: '읽음');
