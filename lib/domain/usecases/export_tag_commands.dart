import '../entities/assigned_tag.dart';
import '../entities/external_tag_command.dart';
import '../entities/file_node.dart';
import '../entities/system_tag.dart';
import '../entities/tag_value_type.dart';

/// 고른 항목의 태그를 **요청함이 그대로 읽는 명령 목록**으로 바꾼다.
///
/// 내보내기에 별도 형식을 만들지 않는 것이 이 기능의 요점이다 — 큐가 이미 "이 항목에
/// 이 태그를 이 값으로 붙여라"를 말할 수 있으므로, 받는 쪽은 파일을 `.filetagger/`의
/// 요청함에 넣기만 하면 되고 **import 코드가 아예 없다**.
///
/// 순수 계산이라 파일 I/O를 모른다. 이미지 값은 캐시 키만 모아 돌려주고, 실제 캐시
/// 파일 복사는 데이터 계층이 한다.
class ExportedCommands {
  const ExportedCommands({required this.commands, required this.imageKeys});

  final List<ExternalTagCommand> commands;

  /// 명령이 참조하는 커스텀 이미지의 캐시 키. 내보낸 파일 **옆에** 같은 이름으로
  /// 놓아야 한다(큐가 상대 경로를 요청함 폴더 기준으로 찾는다).
  final Set<String> imageKeys;
}

/// [nodes]에 붙은 태그 중 [tagIds]에 든 것만 명령으로 만든다.
///
/// - **시스템 태그는 담지 않는다**(자동 파생이고 큐가 거부한다). 후보 계산
///   ([exportableTagIds])과 여기 둘 다에서 걸러, 호출부가 잊어도 새어 나가지 않는다.
/// - 태그가 없으면 만들도록 `missingTag: create`와 **정의의 성질을 함께 싣는다**
///   (값 유형·다중 허용·색). 다중 허용을 빠뜨리면 값 여럿이 마지막 하나로 접힌다.
/// - 조작은 **`add`**다. `replace`는 받는 쪽에 이미 있던 값을 걷어내는데, 내보내기는
///   "이 태그들을 준다"이지 "이대로 맞춰라"가 아니다. 큐의 재적용 판정 덕에 같은
///   파일을 두 번 넣어도 중복이 쌓이지 않는다.
/// - 링크 값은 노드 id를 **대상의 경로(키워드는 이름)**로 풀고 `missingLink: keep`을
///   단다 — 대상이 선택 밖이어도 값을 빼지 않는다. 받는 쪽이 미해결 링크로 들고 있으면
///   사용자가 나중에 재연결할 수 있지만, 값을 버리면 그 기회가 사라진다.
ExportedCommands buildExportCommands({
  required List<FileNode> nodes,
  required Map<int, List<AssignedTag>> assignmentsByFile,
  required Map<int, FileNode> nodesById,
  required Set<int> tagIds,
  required bool includeValues,
  required bool includeImages,
}) {
  final commands = <ExternalTagCommand>[];
  final imageKeys = <String>{};

  for (final node in nodes) {
    final id = node.id;
    if (id == null) continue;
    for (final a in assignmentsByFile[id] ?? const <AssignedTag>[]) {
      if (isSystemTagId(a.tagDefinitionId)) continue;
      if (!tagIds.contains(a.tagDefinitionId)) continue;
      final def = a.definition;

      String? value;
      var valueKind = ExternalNodeKind.file;
      if (includeValues) {
        switch (def.valueType) {
          case TagValueType.label:
            break;
          case TagValueType.image:
            if (!includeImages) break;
            final key = a.value;
            if (key == null || key.isEmpty) break;
            // 값은 캐시 키 그대로다 — 파일을 옆에 같은 이름으로 놓으면 큐가 요청함
            // 폴더 기준 상대 경로로 찾아 자기 캐시에 다시 등록한다.
            imageKeys.add(key);
            value = key;
          case TagValueType.link:
            final resolved = _linkValue(a, nodesById);
            // 가리키는 것을 말할 수 없는 링크(대상이 지워져 뜬 id)는 담지 않는다 —
            // 옛 id는 받는 쪽에서 뜻이 없어 미해결로도 쓸모가 없다.
            if (resolved == null) continue;
            value = resolved.path;
            valueKind = resolved.kind;
          case TagValueType.text:
          case TagValueType.number:
          case TagValueType.date:
            value = a.value;
        }
      }

      commands.add(
        ExternalTagCommand(
          targetPath: node.path,
          targetKind: _kindOf(node),
          tagName: def.name,
          value: value,
          valueKind: valueKind,
          missingTag: MissingTagPolicy.create,
          createValueType: def.valueType,
          createAllowMultiple: def.allowMultiple,
          createColor: def.color,
          missingLink: MissingLinkPolicy.keep,
        ),
      );
    }
  }
  return ExportedCommands(commands: commands, imageKeys: imageKeys);
}

/// [nodes]가 실제로 가진, 내보낼 수 있는 태그 정의 id. 다이얼로그의 후보 목록이다 —
/// 워크스페이스의 모든 태그를 내걸면 고를 것이 태반 쓸모없다.
Set<int> exportableTagIds({
  required List<FileNode> nodes,
  required Map<int, List<AssignedTag>> assignmentsByFile,
}) => {
  for (final node in nodes)
    if (node.id != null)
      for (final a in assignmentsByFile[node.id]!)
        if (!isSystemTagId(a.tagDefinitionId)) a.tagDefinitionId,
};

/// 링크 부여의 값을 받는 쪽이 읽을 수 있는 지목으로 바꾼다. 가리키는 것을 말할 수
/// 없으면 null.
({String path, ExternalNodeKind kind})? _linkValue(
  AssignedTag a,
  Map<int, FileNode> nodesById,
) {
  final raw = a.value;
  if (raw == null || raw.isEmpty) return null;
  // 이미 미해결인 값은 id가 아니라 원문이라 그대로 내보낸다. 그것이 경로였는지
  // 키워드 이름이었는지는 부여에 남지 않아 경로로 적는다 — 받는 쪽에서도 대개 다시
  // 미해결이 되므로, 잘못 짚어도 사용자가 재연결할 것이 하나 더 늘지는 않는다.
  if (a.valueUnresolved) return (path: raw, kind: ExternalNodeKind.file);
  final target = nodesById[int.tryParse(raw)];
  if (target == null) return null;
  return (path: target.path, kind: _kindOf(target));
}

ExternalNodeKind _kindOf(FileNode node) {
  if (node.isKeyword) return ExternalNodeKind.keyword;
  return node.isDirectory ? ExternalNodeKind.directory : ExternalNodeKind.file;
}
