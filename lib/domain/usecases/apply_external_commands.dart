import '../entities/external_tag_command.dart';
import '../entities/file_node.dart';
import '../entities/folder_manage_mode.dart';
import '../entities/system_tag.dart';
import '../entities/tag_value_format.dart';
import '../entities/tag_value_type.dart';
import '../repositories/command_environment.dart';
import '../repositories/command_queue_repository.dart';
import '../repositories/file_node_repository.dart';
import '../repositories/tag_repository.dart';
import 'folder_index_scope.dart';

/// 외부 앱이 떨궈 둔 명령들을 인덱스·태그에 적용하는 한 번의 "패스".
///
/// **스캔이 끝난 뒤**에 돌아야 한다 — 파일 추가와 태그 부여가 한 번에 성립하려면
/// 인덱스가 먼저 최신이어야 한다. 저장소·파일시스템 구현에 의존하지 않는 순수
/// 오케스트레이션이고, 판정(거부·보류) 규칙을 모두 여기서 정한다.
class ApplyExternalCommands {
  ApplyExternalCommands({
    required this.queue,
    required this.nodes,
    required this.tags,
    required this.environment,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final CommandQueueRepository queue;
  final FileNodeRepository nodes;
  final TagRepository tags;
  final CommandEnvironment environment;
  final DateTime Function() _now;

  /// [rootManageMode]는 루트 폴더의 관리 방식(뷰 설정에 저장된 값)이다. 대상이
  /// 인덱싱될 수 있는 자리인지 판정하는 데 쓴다.
  Future<ExternalCommandOutcome> call({
    FolderManageMode rootManageMode = FolderManageMode.managed,
  }) async {
    final pending = await queue.takePending();
    if (pending.isEmpty) return const ExternalCommandOutcome();

    final index = await nodes.indexByPath();
    final indexingDirs = indexingFolderPaths(index.values, rootManageMode);

    var applied = 0;
    var failed = 0;
    var held = 0;
    for (final item in pending) {
      switch (await _apply(item.command, index, indexingDirs)) {
        case _Applied():
          applied++;
          await queue.remove(item.id);
        // 성공도 실패도 아닌 항목은 **아무것도 하지 않는다** — 손대지 않은 큐 파일이
        // 곧 다음 패스로의 보류다(실패로 적으면 이후 건너뛰어 영구 실패가 된다).
        case _Held():
          held++;
        case _Failed(:final reason, :final message):
          failed++;
          await queue.markFailed(
            item.id,
            CommandFailure(reason: reason, at: _now(), message: message),
          );
      }
    }
    return ExternalCommandOutcome(applied: applied, failed: failed, held: held);
  }

  Future<_Verdict> _apply(
    ExternalTagCommand command,
    Map<String, FileNode> index,
    Set<String> indexingDirs,
  ) async {
    final path = normalizeWorkspaceRelPath(command.targetPath);
    if (path == null) {
      return const _Failed(CommandFailureReason.malformed, _msgBadPath);
    }

    final node = index[path];
    // 연결 끊김으로 보존된 노드는 디스크에 없으므로 대상으로 삼지 않는다.
    final nodeId = (node != null && node.missingSince == null) ? node.id : null;
    if (nodeId == null) {
      if (!await environment.targetExists(path)) {
        return const _Failed(CommandFailureReason.targetMissing, _msgNoTarget);
      }
      // 디스크엔 있으나 인덱싱될 수 없는 자리(불투명 폴더 안 등)면 기다려도 소용없다.
      if (!indexingDirs.contains(parentDirPath(path))) {
        return const _Failed(
          CommandFailureReason.targetNotManaged,
          _msgNotManaged,
        );
      }
      // 스캔이 아직 잡지 못한 순간일 뿐이다.
      return const _Held();
    }

    // 시스템 태그는 자동 파생이라 부여 대상이 아니고, 특히 이름 태그는 편집이
    // 디스크 rename이라 큐가 파일을 옮기는 통로가 된다.
    if (SystemTag.values.any((t) => t.displayName == command.tagName)) {
      return const _Failed(CommandFailureReason.systemTag, _msgSystemTag);
    }

    var definition = await tags.definitionByName(command.tagName);
    if (definition == null) {
      if (command.missingTag != MissingTagPolicy.create) {
        return const _Failed(CommandFailureReason.tagMissing, _msgNoTag);
      }
      final valueType = command.createValueType;
      if (valueType == null) {
        return const _Failed(
          CommandFailureReason.valueTypeMissing,
          _msgNoValueType,
        );
      }
      // 다중 부여 허용은 명령이 지정하지 않는다 — 여러 값을 붙일 태그는 사람이
      // 만드는 것이 안전하고, 기본값을 넓게 잡으면 되돌리기 어렵다.
      definition = await tags.createDefinition(
        name: command.tagName,
        valueType: valueType,
        allowMultiple: false,
      );
    } else {
      final wanted = command.createValueType;
      if (wanted != null && wanted != definition.valueType) {
        return const _Failed(
          CommandFailureReason.valueTypeMismatch,
          _msgTypeMismatch,
        );
      }
    }

    final tagId = definition.id;
    if (tagId == null) {
      return const _Failed(CommandFailureReason.tagMissing, _msgNoTag);
    }

    final resolved = await _resolveValue(command, definition.valueType, index);
    final error = resolved.error;
    if (error != null) {
      return _Failed(CommandFailureReason.invalidValue, error);
    }
    final value = resolved.value;

    final existing = [
      for (final assigned in await tags.assignmentsOfFile(nodeId))
        if (assigned.tagDefinitionId == tagId) assigned,
    ];

    // 같은 명령이 다시 들어와도 결과가 같도록(외부 앱의 재시도) 이미 그 상태면
    // 아무것도 쓰지 않는다 — 쓸데없는 갱신이 목록 스트림을 흔들지도 않는다.
    switch (command.operation) {
      case ExternalCommandOperation.add:
        if (existing.any((a) => a.value == value)) return const _Applied();
        await tags.assignToFiles(
          fileNodeIds: [nodeId],
          tagDefinitionId: tagId,
          value: value,
        );
      case ExternalCommandOperation.replace:
        if (existing.length == 1 && existing.first.value == value) {
          return const _Applied();
        }
        if (existing.isNotEmpty) {
          await tags.unassignFromFiles(
            fileNodeIds: [nodeId],
            tagDefinitionId: tagId,
          );
        }
        await tags.assignToFiles(
          fileNodeIds: [nodeId],
          tagDefinitionId: tagId,
          value: value,
        );
      case ExternalCommandOperation.remove:
        if (value == null) {
          if (existing.isNotEmpty) {
            await tags.unassignFromFiles(
              fileNodeIds: [nodeId],
              tagDefinitionId: tagId,
            );
          }
        } else {
          for (final assigned in existing) {
            final id = assigned.assignment.id;
            if (assigned.value == value && id != null) {
              await tags.unassign(id);
            }
          }
        }
    }
    return const _Applied();
  }

  /// 명령의 값을 태그의 값 유형에 맞는 **저장 표현**으로 바꾼다.
  ///
  /// 외부 앱은 캐시 키도 노드 id도 알 수 없으므로, image는 외부 이미지 파일 경로를,
  /// link는 대상의 워크스페이스 상대 경로를 받아 여기서 저장값으로 바꾼다.
  Future<({String? value, String? error})> _resolveValue(
    ExternalTagCommand command,
    TagValueType type,
    Map<String, FileNode> index,
  ) async {
    final raw = command.value;
    if (raw == null) return (value: null, error: null);
    switch (type) {
      case TagValueType.label:
        // 값이 없는 태그다 — 딸려 온 값은 조용히 버린다(제거는 태그 통째로).
        return (value: null, error: null);
      case TagValueType.text:
        return (value: raw, error: null);
      case TagValueType.number:
        if (num.tryParse(raw) == null) {
          return (value: null, error: '$_msgNotNumber$raw');
        }
        return (value: raw, error: null);
      case TagValueType.date:
        final parsed = DateTime.tryParse(raw);
        if (parsed == null) return (value: null, error: '$_msgNotDate$raw');
        return (value: dateToStoredValue(parsed), error: null);
      case TagValueType.link:
        final target = normalizeWorkspaceRelPath(raw);
        final id = target == null ? null : index[target]?.id;
        if (id == null) return (value: null, error: '$_msgNoLinkTarget$raw');
        return (value: '$id', error: null);
      case TagValueType.image:
        // 저장값이 불투명한 내용 해시라 외부 앱이 지울 값을 지목할 수 없다 —
        // 이미지 태그의 제거는 언제나 "그 태그를 통째로"다.
        if (command.operation == ExternalCommandOperation.remove) {
          return (value: null, error: null);
        }
        final key = await environment.registerImage(raw);
        if (key == null) return (value: null, error: '$_msgNoImage$raw');
        return (value: key, error: null);
    }
  }
}

/// 한 번의 패스가 무엇을 했는지. 상태표시줄이 조용한 변경·실패를 알리는 데 쓴다.
class ExternalCommandOutcome {
  const ExternalCommandOutcome({
    this.applied = 0,
    this.failed = 0,
    this.held = 0,
  });

  /// 적용하고 큐에서 지운 항목 수.
  final int applied;

  /// 실패 표식을 남긴 항목 수.
  final int failed;

  /// 손대지 않고 다음 패스로 넘긴 항목 수(스캔이 아직 잡지 못한 대상).
  final int held;

  bool get isEmpty => applied == 0 && failed == 0 && held == 0;
}

/// 외부 앱이 적어 보낸 경로를 인덱스 키(루트 기준 '/' 구분 상대 경로)로 맞춘다.
///
/// 외부 앱은 플랫폼 구분자나 `./`를 섞어 쓰기 마련이라 받아 정리한다. 다만 루트
/// 밖을 가리키는 경로는 고칠 방법이 없어 null이다 — 큐는 관리 폴더 안만 다룬다.
String? normalizeWorkspaceRelPath(String raw) {
  final parts = <String>[];
  for (final segment in raw.replaceAll(r'\', '/').split('/')) {
    if (segment.isEmpty || segment == '.') continue;
    if (segment == '..') {
      if (parts.isEmpty) return null;
      parts.removeLast();
      continue;
    }
    parts.add(segment);
  }
  return parts.isEmpty ? null : parts.join('/');
}

// ── 판정 ──

sealed class _Verdict {
  const _Verdict();
}

final class _Applied extends _Verdict {
  const _Applied();
}

final class _Held extends _Verdict {
  const _Held();
}

final class _Failed extends _Verdict {
  const _Failed(this.reason, [this.message]);

  final CommandFailureReason reason;
  final String? message;
}

const String _msgBadPath = '워크스페이스 안의 상대 경로가 아닙니다.';
const String _msgNoTarget = '대상 파일이 디스크에 없습니다.';
const String _msgNotManaged = '대상이 관리 범위 밖이라 인덱싱되지 않습니다.';
const String _msgSystemTag = '시스템 태그는 외부에서 바꿀 수 없습니다.';
const String _msgNoTag = '그 이름의 태그가 없습니다.';
const String _msgNoValueType = '태그를 만들려면 값 유형이 필요합니다.';
const String _msgTypeMismatch = '기존 태그의 값 유형이 다릅니다.';
const String _msgNotNumber = '숫자로 읽을 수 없습니다: ';
const String _msgNotDate = '날짜로 읽을 수 없습니다: ';
const String _msgNoLinkTarget = '링크 대상 노드를 찾을 수 없습니다: ';
const String _msgNoImage = '이미지를 등록하지 못했습니다: ';
