import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/constants.dart';
import '../../domain/entities/external_tag_command.dart';
import '../../domain/repositories/command_queue_repository.dart';
import 'command_json.dart';

/// 실패 표식이 붙은 항목을 큐에 남겨 두는 기간.
///
/// 성공 항목과 달리 바로 지우지 않는 이유는 외부 앱이 원인을 읽을 시간을 주기
/// 위함이고, 영원히 두지 않는 이유는 아무도 읽지 않는 실패가 쌓이기 때문이다.
const Duration failedCommandRetention = Duration(days: 30);

/// 남겨 둘 실패 항목 수의 상한. 보존 기간 안에 실패가 몰아치는 경우(잘못 만든
/// 확장이 수천 건을 떨구는 등)를 위해 기간과 함께 둔다.
const int maxRetainedFailedCommands = 200;

/// 드롭인 큐를 워크스페이스의 `.filetagger/` 안 폴더로 다루는 저장소.
///
/// 항목당 파일 하나이고 파일 이름이 곧 [QueuedCommand.id]다. 형식이 깨진 항목이
/// 있어도 나머지 패스는 계속된다(조건 프리셋 저장소와 같은 태도) — 큐는 외부가
/// 쓰는 자리라 무엇이 들어와도 앱이 멈추면 안 된다.
class FileCommandQueueStore implements CommandQueueRepository {
  FileCommandQueueStore(
    this.workspaceRoot, {
    this.retention = failedCommandRetention,
    this.maxRetainedFailures = maxRetainedFailedCommands,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final String workspaceRoot;
  final Duration retention;
  final int maxRetainedFailures;
  final DateTime Function() _now;

  /// 큐 폴더. 외부 앱이 명령을 떨구는 자리이자 큐 감시자가 붙는 자리다.
  Directory get directory =>
      Directory(p.join(workspaceRoot, filetaggerDirName, commandQueueDirName));

  /// 큐 폴더가 없으면 만든다. 없는 폴더는 외부 앱이 찾을 수도, 감시자가 붙을 수도
  /// 없으므로 워크스페이스를 여는 것만으로 자리가 나 있게 한다.
  Future<void> ensureDirectory() async {
    try {
      await directory.create(recursive: true);
    } catch (_) {
      // 만들지 못해도(권한 등) 앱은 계속 뜬다. 다음 패스에서 다시 시도한다.
    }
  }

  @override
  Future<List<QueuedCommand>> takePending() async {
    await ensureDirectory();

    final files = await _listFiles();
    final at = _now();
    final pending = <QueuedCommand>[];
    final marked = <_MarkedItem>[];

    for (final file in files) {
      final text = await _read(file);
      // 읽지 못한 파일(외부 앱이 쓰는 중 등)은 손대지 않고 다음 패스로 넘긴다.
      if (text == null) continue;

      switch (decodeCommandFile(text)) {
        case PendingCommand(:final command):
          pending.add(
            QueuedCommand(id: p.basename(file.path), command: command),
          );
        case MarkedCommand(:final failure):
          marked.add(_MarkedItem(file, failure.at));
        case UnreadableCommand record:
          // 형식 오류도 큐 항목의 실패라 같은 자리에 같은 방식으로 적는다.
          if (await _write(file, record.withFailure(record.toFailure(at)))) {
            marked.add(_MarkedItem(file, at));
          }
      }
    }

    await _cleanUp(marked, at);
    return pending;
  }

  @override
  Future<void> remove(String id) async {
    final file = _fileFor(id);
    if (file == null) return;
    await _delete(file);
  }

  @override
  Future<void> markFailed(String id, CommandFailure failure) async {
    final file = _fileFor(id);
    if (file == null) return;
    final text = await _read(file);
    if (text == null) return;
    // 원본을 다시 읽어 얹는다 — 앱이 해석하지 않는 키까지 그대로 남긴다.
    await _write(file, decodeCommandFile(text).withFailure(failure));
  }

  /// 파일 이름순으로 훑는다. 외부 앱은 대개 시각·일련번호를 이름에 담으므로
  /// 이 순서가 곧 떨군 순서에 가깝고, 무엇보다 패스마다 순서가 같다.
  Future<List<File>> _listFiles() async {
    try {
      final entries = await directory.list(followLinks: false).toList();
      final files = entries.whereType<File>().toList();
      files.sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
      return files;
    } catch (_) {
      return const [];
    }
  }

  /// 손잡이는 큐 폴더 안의 파일 이름이다. 경로 조각이 섞여 들어오면 큐 밖을
  /// 건드리게 되므로 받지 않는다.
  File? _fileFor(String id) {
    if (id.isEmpty || p.basename(id) != id) return null;
    return File(p.join(directory.path, id));
  }

  Future<String?> _read(File file) async {
    try {
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }

  Future<bool> _write(File file, String text) async {
    try {
      // 표식은 JSON 앞머리에 끼워 넣을 수 없어 파일 전체를 다시 쓴다.
      await file.writeAsString(text);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _delete(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // 지우지 못해도 다음 패스에서 다시 시도한다.
    }
  }

  /// 실패 항목만 나이와 수로 정리한다. **표식 없는 항목은 건드리지 않는다** —
  /// 아직 처리되지 않았을 뿐이고(앱을 오래 켜지 않은 경우) 이번 패스가 소비한다.
  Future<void> _cleanUp(List<_MarkedItem> marked, DateTime at) async {
    final survivors = <_MarkedItem>[];
    for (final item in marked) {
      if (at.difference(item.at) >= retention) {
        await _delete(item.file);
      } else {
        survivors.add(item);
      }
    }
    if (survivors.length <= maxRetainedFailures) return;
    survivors.sort((a, b) => b.at.compareTo(a.at));
    for (final item in survivors.skip(maxRetainedFailures)) {
      await _delete(item.file);
    }
  }
}

/// 중첩 워크스페이스를 흡수할 때, 하위 태거의 **대기 중인** 큐 항목을 상위로 옮긴다.
///
/// 옮기지 않으면 하위 `.filetagger/`와 함께 조용히 사라진다(썸네일 캐시를 복사하는
/// 것과 같은 이유). 대상 경로는 루트 상대 표기이므로 하위 폴더 경로를 접두로 붙여
/// 다시 쓴다.
///
/// **실패 표식이 붙은 항목은 옮기지 않는다** — 이미 판정이 끝난 진단 기록이라
/// 상위로 데려가면 남의 실패가 상위 큐에 쌓인다. 또한 **링크 값의 상대 경로는
/// 다시 쓰지 못한다** — 값의 뜻은 태그의 값 유형이 정하는데 큐는 태그 이름만 알아,
/// 경로처럼 보이는 텍스트 값을 잘못 건드리는 쪽이 더 나쁘다.
Future<void> migrateCommandQueue({
  required String fromRoot,
  required String toRoot,
  required String childRelPath,
}) async {
  final source = FileCommandQueueStore(fromRoot);
  final target = FileCommandQueueStore(toRoot);
  if (!await source.directory.exists()) return;

  final files = await source._listFiles();
  if (files.isEmpty) return;
  await target.ensureDirectory();

  for (final file in files) {
    final text = await source._read(file);
    if (text == null) continue;
    final record = decodeCommandFile(text);
    if (record is! PendingCommand) continue;

    final command = record.command;
    final moved = ExternalTagCommand(
      targetPath: '$childRelPath/${command.targetPath}',
      tagName: command.tagName,
      operation: command.operation,
      value: command.value,
      missingTag: command.missingTag,
      createValueType: command.createValueType,
    );
    final name = _freeName(target.directory, p.basename(file.path));
    if (await target._write(
      File(p.join(target.directory.path, name)),
      encodeCommandFile(moved),
    )) {
      // 옮긴 뒤에야 원본을 지운다 — 하위 태거가 남더라도 같은 명령이 두 번
      // 적용되지 않게 한다.
      await source._delete(file);
    }
  }
}

/// [dir] 안에서 아직 쓰이지 않은 파일 이름. 겹치면 일련번호를 덧붙인다.
String _freeName(Directory dir, String preferred) {
  if (!File(p.join(dir.path, preferred)).existsSync()) return preferred;
  final ext = p.extension(preferred);
  final base = p.basenameWithoutExtension(preferred);
  var i = 2;
  while (File(p.join(dir.path, '$base ($i)$ext')).existsSync()) {
    i++;
  }
  return '$base ($i)$ext';
}

/// 실패 표식이 붙어 있는 큐 파일과 그 표식 시각(정리 판단용).
class _MarkedItem {
  const _MarkedItem(this.file, this.at);

  final File file;
  final DateTime at;
}
