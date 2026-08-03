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

/// 큐 파일의 확장자. **이 확장자만 요청으로 읽는다** — 큐 폴더에는 요청과 함께
/// 딸려 오는 파일(내보내기가 동봉한 이미지 등)이 놓일 수 있는데, 모든 파일을
/// 요청으로 읽으면 그런 파일에 실패 표식을 덮어써 망가뜨린다.
const String commandFileExtension = '.json';

/// 드롭인 큐를 워크스페이스의 `.filetagger/` 안 폴더로 다루는 저장소.
///
/// 파일 하나에 명령 하나 또는 여럿(최상위 배열)이 들어가고, 항목의 손잡이
/// ([QueuedCommand.id])는 파일 이름과 그 안의 자리를 함께 가리킨다. 형식이 깨진
/// 항목이 있어도 나머지 패스는 계속된다(조건 프리셋 저장소와 같은 태도) — 큐는
/// 외부가 쓰는 자리라 무엇이 들어와도 앱이 멈추면 안 된다.
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

  /// 이번 패스에서 읽어 둔 파일들(커밋이 이걸 보고 되쓴다).
  final Map<String, _LoadedFile> _loaded = {};

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
    _loaded.clear();

    final files = await _listFiles();
    final at = _now();
    final pending = <QueuedCommand>[];

    for (final file in files) {
      final text = await _read(file);
      // 읽지 못한 파일(외부 앱이 쓰는 중 등)은 손대지 않고 다음 패스로 넘긴다.
      if (text == null) continue;

      final name = p.basename(file.path);
      final loaded = _LoadedFile(file, decodeCommandFile(text));
      _loaded[name] = loaded;

      // 형식 오류는 **여기서 바로** 표식을 남긴다. 커밋까지 미루면, 적용할 항목이
      // 하나도 없어 패스가 일찍 끝나는 판에서는 표식이 영영 적히지 않는다.
      if (loaded.records.any((r) => r is UnreadableCommand)) {
        await _markUnreadable(loaded, at);
      }

      for (var i = 0; i < loaded.records.length; i++) {
        final record = loaded.records[i];
        if (record is! PendingCommand) continue;
        pending.add(
          QueuedCommand(id: _idFor(name, i, loaded), command: record.command),
        );
      }
    }

    await _cleanUp(at);
    return pending;
  }

  @override
  Future<void> markApplied(String id) async => _record(id, const _Applied());

  @override
  Future<void> markFailed(String id, CommandFailure failure) async =>
      _record(id, _Failed(failure));

  @override
  Future<void> commit() async {
    for (final loaded in _loaded.values) {
      if (loaded.outcomes.isEmpty) continue;

      final kept = <Map<String, dynamic>>[];
      for (var i = 0; i < loaded.records.length; i++) {
        final outcome = loaded.outcomes[i];
        if (outcome is _Applied) continue;
        kept.add(
          loaded.records[i].toJson(
            failure: outcome is _Failed ? outcome.failure : null,
          ),
        );
      }

      if (kept.isEmpty) {
        await _delete(loaded.file);
        continue;
      }
      await _write(
        loaded.file,
        encodeCommandObjects(kept, asArray: loaded.isArray),
      );
    }
    _loaded.clear();
  }

  /// 항목 손잡이 → (파일 이름, 자리). 파일에 항목이 하나뿐이면 파일 이름만 쓴다 —
  /// 옛 형식(객체 하나)의 손잡이가 그대로 유지되어 읽기도 쉽다.
  String _idFor(String name, int index, _LoadedFile loaded) =>
      loaded.records.length == 1 ? name : '$name$_indexSeparator$index';

  void _record(String id, _Outcome outcome) {
    final cut = id.lastIndexOf(_indexSeparator);
    final name = cut < 0 ? id : id.substring(0, cut);
    final index = cut < 0 ? 0 : (int.tryParse(id.substring(cut + 1)) ?? -1);
    final loaded = _loaded[name];
    if (loaded == null || index < 0 || index >= loaded.records.length) return;
    loaded.outcomes[index] = outcome;
  }

  /// 명령으로 읽히지 않은 항목에 형식 오류 표식을 적어 파일을 되쓴다. 표식을 단
  /// 항목은 이후 패스에서 건너뛰도록 읽은 결과도 함께 갈아 끼운다.
  Future<void> _markUnreadable(_LoadedFile loaded, DateTime at) async {
    final objects = <Map<String, dynamic>>[];
    final updated = <ExternalCommandRecord>[];
    for (final record in loaded.records) {
      if (record is UnreadableCommand) {
        final failure = record.toFailure(at);
        final json = record.toJson(failure: failure);
        objects.add(json);
        updated.add(MarkedCommand(failure: failure, source: json));
      } else {
        objects.add(record.toJson());
        updated.add(record);
      }
    }
    if (!await _write(
      loaded.file,
      encodeCommandObjects(objects, asArray: loaded.isArray),
    )) {
      return;
    }
    loaded.records
      ..clear()
      ..addAll(updated);
  }

  /// 큐 파일만, 이름순으로 훑는다. 외부 앱은 대개 시각·일련번호를 이름에 담으므로
  /// 이 순서가 곧 떨군 순서에 가깝고, 무엇보다 패스마다 순서가 같다.
  Future<List<File>> _listFiles() async {
    try {
      final entries = await directory.list(followLinks: false).toList();
      final files = [
        for (final entry in entries)
          if (entry is File &&
              p.extension(entry.path).toLowerCase() == commandFileExtension)
            entry,
      ];
      files.sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
      return files;
    } catch (_) {
      return const [];
    }
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
  /// 여러 항목을 담은 파일은 **전부 표식이 붙었을 때만** 정리 대상이고, 나이는 그
  /// 중 가장 최근 표식으로 센다(항목 하나짜리 파일에서는 예전과 같다).
  Future<void> _cleanUp(DateTime at) async {
    final marked = <_MarkedItem>[];
    for (final loaded in _loaded.values) {
      final times = <DateTime>[];
      for (final record in loaded.records) {
        if (record is! MarkedCommand) {
          times.clear();
          break;
        }
        times.add(record.failure.at);
      }
      if (times.isEmpty) continue;
      times.sort();
      marked.add(_MarkedItem(loaded, times.last));
    }

    final survivors = <_MarkedItem>[];
    for (final item in marked) {
      if (at.difference(item.at) >= retention) {
        await _delete(item.loaded.file);
        _loaded.remove(p.basename(item.loaded.file.path));
      } else {
        survivors.add(item);
      }
    }
    if (survivors.length > maxRetainedFailures) {
      survivors.sort((a, b) => b.at.compareTo(a.at));
      for (final item in survivors.skip(maxRetainedFailures)) {
        await _delete(item.loaded.file);
        _loaded.remove(p.basename(item.loaded.file.path));
      }
    }
    await _cleanUpAttachments(at);
  }

  /// 요청과 함께 딸려 온 파일(내보내기가 동봉한 이미지 등)을 **나이로만** 치운다.
  ///
  /// "참조하는 요청이 사라지면 곧바로 지운다"로 하지 않는 이유는, 파일을 여러 개
  /// 떨구는 쪽이 이미지를 먼저 복사하고 요청 파일을 나중에 쓰기 때문이다 — 그 사이에
  /// 패스가 돌면(큐 감시자는 폴더가 바뀔 때마다 깬다) 아직 쓰이지도 않은 이미지를
  /// 지우게 된다. 실패 표식과 같은 보존 기간을 쓰면 그 경합이 원리적으로 없다.
  Future<void> _cleanUpAttachments(DateTime at) async {
    try {
      final entries = await directory.list(followLinks: false).toList();
      for (final entry in entries) {
        if (entry is! File) continue;
        if (p.extension(entry.path).toLowerCase() == commandFileExtension) {
          continue;
        }
        final modified = (await entry.stat()).modified;
        if (at.difference(modified) >= retention) await _delete(entry);
      }
    } catch (_) {
      // 정리는 부수적이라 실패해도 패스를 막지 않는다.
    }
  }
}

/// 손잡이에서 파일 이름과 항목 자리를 가르는 문자. 파일 이름에 쓰이지 않는 것을
/// 골라, 이름 안의 글자와 섞이지 않게 한다.
const String _indexSeparator = '#';

/// 이번 패스에서 읽어 둔 큐 파일 하나와, 항목별로 적어 둔 결과.
class _LoadedFile {
  _LoadedFile(this.file, CommandFile decoded)
    : records = [...decoded.items],
      isArray = decoded.isArray;

  final File file;
  final List<ExternalCommandRecord> records;
  final bool isArray;

  /// 항목 자리 → 결과. 없는 자리는 보류(다음 패스로).
  final Map<int, _Outcome> outcomes = {};
}

sealed class _Outcome {
  const _Outcome();
}

final class _Applied extends _Outcome {
  const _Applied();
}

final class _Failed extends _Outcome {
  const _Failed(this.failure);

  final CommandFailure failure;
}

/// 전부 표식이 붙은 큐 파일과 그 중 가장 최근 표식 시각(정리 판단용).
class _MarkedItem {
  const _MarkedItem(this.loaded, this.at);

  final _LoadedFile loaded;
  final DateTime at;
}

/// 중첩 워크스페이스를 흡수할 때, 하위 태거의 **대기 중인** 큐 항목을 상위로 옮긴다.
///
/// 옮기지 않으면 하위 `.filetagger/`와 함께 조용히 사라진다(썸네일 캐시를 복사하는
/// 것과 같은 이유). 대상 경로는 루트 상대 표기이므로 하위 폴더 경로를 접두로 붙여
/// 다시 쓴다. **키워드 대상은 경로가 아니라 이름이라 접두를 붙이지 않는다.**
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
    final decoded = decodeCommandFile(text);

    final moved = <Map<String, dynamic>>[];
    for (final record in decoded.items) {
      if (record is! PendingCommand) continue;
      final command = record.command;
      moved.add(
        commandToJson(
          ExternalTagCommand(
            targetPath: command.targetKind == ExternalNodeKind.keyword
                ? command.targetPath
                : '$childRelPath/${command.targetPath}',
            tagName: command.tagName,
            operation: command.operation,
            value: command.value,
            missingTag: command.missingTag,
            createValueType: command.createValueType,
            targetKind: command.targetKind,
            valueKind: command.valueKind,
            missingKeyword: command.missingKeyword,
            createAllowMultiple: command.createAllowMultiple,
            createColor: command.createColor,
          ),
        ),
      );
    }
    if (moved.isEmpty) continue;

    final name = _freeName(target.directory, p.basename(file.path));
    if (await target._write(
      File(p.join(target.directory.path, name)),
      encodeCommandObjects(moved, asArray: decoded.isArray),
    )) {
      // 옮긴 뒤에야 원본을 지운다 — 하위 태거가 남더라도 같은 명령이 두 번
      // 적용되지 않게 한다. 실패 표식만 남은 파일은 옮기지 않았으므로 그대로 둔다.
      if (decoded.items.every((r) => r is PendingCommand)) {
        await source._delete(file);
      }
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
