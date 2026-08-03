import '../entities/assigned_tag.dart';
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
import 'keyword_name.dart';

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
    // 키워드는 경로 계층 밖이라 키 공간이 아예 다르다 — 이름이 같은 파일과 키워드가
    // 서로를 밀어내지 않도록 맵을 따로 든다.
    final keywordIndex = await nodes.keywordIndexByName();
    final indexingDirs = indexingFolderPaths(index.values, rootManageMode);

    var applied = 0;
    var failed = 0;
    var held = 0;
    for (final item in pending) {
      switch (await _apply(item.command, index, keywordIndex, indexingDirs)) {
        case _Applied():
          applied++;
          await queue.markApplied(item.id);
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
    // 기록해 둔 결과를 한 번에 반영한다(한 파일이 여러 항목을 담을 수 있어, 항목마다
    // 쓰면 큰 파일에서 쓰기가 제곱으로 늘고 "성공한 것만 빼기"를 판단할 수도 없다).
    await queue.commit();
    return ExternalCommandOutcome(applied: applied, failed: failed, held: held);
  }

  Future<_Verdict> _apply(
    ExternalTagCommand command,
    Map<String, FileNode> index,
    Map<String, FileNode> keywordIndex,
    Set<String> indexingDirs,
  ) async {
    final int nodeId;
    if (command.targetKind == ExternalNodeKind.keyword) {
      final resolved = await _resolveKeyword(
        command.targetPath,
        keywordIndex,
        command.missingKeyword,
      );
      final failure = resolved.failure;
      if (failure != null) return failure;
      nodeId = resolved.id!;
    } else {
      final resolved = await _resolveDiskTarget(
        command.targetPath,
        index,
        indexingDirs,
      );
      final failure = resolved.failure;
      if (failure != null) return failure;
      nodeId = resolved.id!;
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
      // 다중 부여 허용·색상은 **적은 대로** 따른다(기본값은 좁게). 받지 않으면
      // 다중값 태그를 내보내 되받을 때 값 여럿이 마지막 하나로 조용히 접힌다 —
      // 단일값 태그는 재부여가 갱신이기 때문이다.
      definition = await tags.createDefinition(
        name: command.tagName,
        valueType: valueType,
        allowMultiple: command.createAllowMultiple ?? false,
        color: command.createColor,
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

    final resolved = await _resolveValue(
      command,
      definition.valueType,
      index,
      keywordIndex,
    );
    final error = resolved.error;
    if (error != null) {
      return _Failed(CommandFailureReason.invalidValue, error);
    }
    final value = resolved.value;
    final unresolved = resolved.unresolved;

    final existing = [
      for (final assigned in await tags.assignmentsOfFile(nodeId))
        if (assigned.tagDefinitionId == tagId) assigned,
    ];
    // 재시도가 같은 결과를 내려면 미해결 여부까지 같아야 한다 — 값만 대조하면 그
    // 사이에 사용자가 재연결한 부여를 다시 미해결로 되돌린다.
    bool same(AssignedTag a) =>
        a.value == value && a.valueUnresolved == unresolved;

    // 같은 명령이 다시 들어와도 결과가 같도록(외부 앱의 재시도) 이미 그 상태면
    // 아무것도 쓰지 않는다 — 쓸데없는 갱신이 목록 스트림을 흔들지도 않는다.
    switch (command.operation) {
      case ExternalCommandOperation.add:
        if (existing.any(same)) return const _Applied();
        await tags.assignToFiles(
          fileNodeIds: [nodeId],
          tagDefinitionId: tagId,
          value: value,
          valueUnresolved: unresolved,
        );
      case ExternalCommandOperation.replace:
        if (existing.length == 1 && same(existing.first)) {
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
          valueUnresolved: unresolved,
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

  /// 디스크 노드(파일·폴더)를 경로로 찾는다.
  ///
  /// 세 갈래가 이 계층의 핵심이다: **디스크에 없으면 즉시 실패**(외부 앱은 파일을
  /// 먼저 쓰기로 약속돼 있다), **디스크엔 있고 인덱스에만 없으면 보류**(스캔이 아직
  /// 잡지 못한 경합 — 실패로 적으면 이후 건너뛰어 경합 한 번이 영구 실패로 굳는다),
  /// **관리 범위 밖이면 실패**(기다려도 인덱싱되지 않는다).
  Future<({int? id, _Verdict? failure})> _resolveDiskTarget(
    String raw,
    Map<String, FileNode> index,
    Set<String> indexingDirs,
  ) async {
    final path = normalizeWorkspaceRelPath(raw);
    if (path == null) {
      return (
        id: null,
        failure: const _Failed(CommandFailureReason.malformed, _msgBadPath),
      );
    }
    final node = index[path];
    // 연결 끊김으로 보존된 노드는 디스크에 없으므로 대상으로 삼지 않는다.
    final id = (node != null && node.missingSince == null) ? node.id : null;
    if (id != null) return (id: id, failure: null);

    if (!await environment.targetExists(path)) {
      return (
        id: null,
        failure: const _Failed(
          CommandFailureReason.targetMissing,
          _msgNoTarget,
        ),
      );
    }
    if (!indexingDirs.contains(parentDirPath(path))) {
      return (
        id: null,
        failure: const _Failed(
          CommandFailureReason.targetNotManaged,
          _msgNotManaged,
        ),
      );
    }
    return (id: null, failure: const _Held());
  }

  /// 키워드를 이름으로 찾고, 없으면 정책에 따라 만든다.
  ///
  /// 디스크 대상과 달리 **보류가 없다** — 키워드는 앱이 만들어야만 존재하므로 스캔과
  /// 경합할 일이 없고, 지금 없으면 다음 패스에도 없다. 이름은 경로가 아니므로
  /// 경로 정규화를 태우지 않는다(구분자가 든 이름은 고쳐 받는 것이 아니라 거절한다).
  Future<({int? id, _Verdict? failure})> _resolveKeyword(
    String raw,
    Map<String, FileNode> keywordIndex,
    MissingKeywordPolicy policy,
  ) async {
    final normalized = normalizeKeywordName(raw);
    final name = normalized.name;
    if (name == null) {
      return (
        id: null,
        failure: _Failed(
          CommandFailureReason.malformed,
          normalized.error?.message,
        ),
      );
    }

    final existing = keywordIndex[name]?.id;
    if (existing != null) return (id: existing, failure: null);

    if (policy != MissingKeywordPolicy.create) {
      return (
        id: null,
        failure: const _Failed(
          CommandFailureReason.targetMissing,
          _msgNoKeyword,
        ),
      );
    }
    final created = await nodes.createKeyword(name);
    final id = created.node?.id;
    if (id == null) {
      return (
        id: null,
        failure: _Failed(
          CommandFailureReason.targetMissing,
          created.error?.message ?? _msgNoKeyword,
        ),
      );
    }
    // 같은 패스의 뒤 항목이 이 키워드를 다시 가리킬 수 있다(작가 키워드에 태그 여럿).
    keywordIndex[name] = created.node!;
    return (id: id, failure: null);
  }

  /// 명령의 값을 태그의 값 유형에 맞는 **저장 표현**으로 바꾼다.
  ///
  /// 외부 앱은 캐시 키도 노드 id도 알 수 없으므로, image는 외부 이미지 파일 경로를,
  /// link는 대상의 워크스페이스 상대 경로를 받아 여기서 저장값으로 바꾼다.
  ///
  /// [_Resolved.unresolved]는 link에서만 참이 될 수 있다 — 대상을 못 찾았지만
  /// [MissingLinkPolicy.keep]이라 원문을 그대로 남기기로 한 경우다.
  Future<_Resolved> _resolveValue(
    ExternalTagCommand command,
    TagValueType type,
    Map<String, FileNode> index,
    Map<String, FileNode> keywordIndex,
  ) async {
    final raw = command.value;
    if (raw == null) return const _Resolved();
    switch (type) {
      case TagValueType.label:
        // 값이 없는 태그다 — 딸려 온 값은 조용히 버린다(제거는 태그 통째로).
        return const _Resolved();
      case TagValueType.text:
        return _Resolved(value: raw);
      case TagValueType.number:
        if (num.tryParse(raw) == null) {
          return _Resolved(error: '$_msgNotNumber$raw');
        }
        return _Resolved(value: raw);
      case TagValueType.date:
        final parsed = DateTime.tryParse(raw);
        if (parsed == null) return _Resolved(error: '$_msgNotDate$raw');
        return _Resolved(value: dateToStoredValue(parsed));
      case TagValueType.link:
        return _resolveLink(command, raw, index, keywordIndex);
      case TagValueType.image:
        // 저장값이 불투명한 내용 해시라 외부 앱이 지울 값을 지목할 수 없다 —
        // 이미지 태그의 제거는 언제나 "그 태그를 통째로"다.
        if (command.operation == ExternalCommandOperation.remove) {
          return const _Resolved();
        }
        final key = await environment.registerImage(raw);
        if (key == null) return _Resolved(error: '$_msgNoImage$raw');
        return _Resolved(value: key);
    }
  }

  /// link 값을 노드 id로 푼다. 못 찾으면 [MissingLinkPolicy]에 따라 실패하거나,
  /// 적어 온 원문을 그대로 둔 채 **미해결 링크**로 남긴다.
  ///
  /// 제거는 원문 대조로 충분하므로 정책을 태우지 않는다 — 대상이 없다고 실패시키면
  /// "가리키던 것이 사라진 부여를 떼어 내는" 조작이 막히고, 미해결로 새로 만들어
  /// 붙이는 것도 뜻이 없다.
  Future<_Resolved> _resolveLink(
    ExternalTagCommand command,
    String raw,
    Map<String, FileNode> index,
    Map<String, FileNode> keywordIndex,
  ) async {
    final keep = command.missingLink == MissingLinkPolicy.keep;
    // 대상 판별과 따로 본다 — 그림 **파일**에 작가 **키워드**를 거는 것이 주 용도라
    // 둘이 대개 다르다. 키워드면 없을 때 만들 수도 있다(대상과 같은 정책).
    if (command.valueKind == ExternalNodeKind.keyword) {
      final normalized = normalizeKeywordName(raw);
      final name = normalized.name;
      if (name == null) {
        // 이름 자체가 잘못됐다면(구분자가 든 이름 등) 남겨 둘 원문도 없다.
        return _Resolved(error: normalized.error?.message);
      }
      final resolved = await _resolveKeyword(
        name,
        keywordIndex,
        command.missingKeyword,
      );
      final id = resolved.id;
      if (id != null) return _Resolved(value: '$id');
      if (keep) return _Resolved(value: name, unresolved: true);
      return _Resolved(error: '$_msgNoLinkKeyword$raw');
    }
    final target = normalizeWorkspaceRelPath(raw);
    if (target == null) return _Resolved(error: _msgBadPath);
    final id = index[target]?.id;
    if (id != null) return _Resolved(value: '$id');
    if (keep) return _Resolved(value: target, unresolved: true);
    return _Resolved(error: '$_msgNoLinkTarget$raw');
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

/// 명령의 값을 저장 표현으로 바꾼 결과.
class _Resolved {
  const _Resolved({this.value, this.unresolved = false, this.error});

  final String? value;

  /// [value]가 아직 대상을 가리키지 못하는 링크 원문인지(미해결 링크).
  final bool unresolved;

  /// 값을 태그의 값 유형으로 읽지 못한 사유. null이면 성공이다.
  final String? error;
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
const String _msgNoKeyword = '그 이름의 키워드가 없습니다.';
const String _msgNoLinkKeyword = '링크 대상 키워드를 찾을 수 없습니다: ';
const String _msgNoLinkTarget = '링크 대상 노드를 찾을 수 없습니다: ';
const String _msgNoImage = '이미지를 등록하지 못했습니다: ';
