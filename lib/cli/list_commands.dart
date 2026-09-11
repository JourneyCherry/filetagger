/// `list` — 파일에 붙은 **부여**를 다룬다.
///
/// 정의(`tag`)와 갈라져 있으므로 여기서는 태그를 만들지 않는다. 없는 태그를 지목하면
/// 거부되고, `tag add`로 먼저 세우라고 답한다 — 부여하는 자리마다 정의의 성질을 함께
/// 적게 두면 같은 태그가 부르는 곳에 따라 다른 성질로 태어난다.
///
/// 대상은 **경로 위치인자**로 지목하거나(키워드는 `--keyword`로 이름을 준다),
/// `--filter`로 **집합을 지목**한다. 조건 문법은 화면의 조건 줄과 같다.
library;

import 'dart:io';

import '../data/commands/command_json.dart';
import '../data/db/app_database.dart';
import '../data/repositories/drift_file_node_repository.dart';
import '../data/repositories/drift_tag_repository.dart';
import '../domain/entities/assigned_tag.dart';
import '../domain/entities/external_tag_command.dart';
import '../domain/entities/file_node.dart';
import '../domain/entities/file_tree_node.dart';
import '../domain/entities/system_tag.dart';
import '../domain/usecases/apply_external_commands.dart';
import '../domain/usecases/build_grouped_tree.dart';
import '../domain/usecases/export_tag_commands.dart';
import '../domain/usecases/resolve_link_values.dart';
import '../l10n/console_strings.dart';
import '../l10n/system_tag_names.dart';
import 'cli_command.dart';
import 'cli_output.dart';
import 'output_window.dart';
import 'query_options.dart';
import 'workspace_query.dart';

class ListCommand extends CliCommandGroup {
  ListCommand(this.strings)
    : super([
        _ListAddCommand(strings),
        _ListModifyCommand(strings),
        _ListDeleteCommand(strings),
        _ListShowCommand(strings),
      ]);

  final ConsoleStrings strings;

  @override
  String get name => 'list';

  @override
  String get description => strings.listDescription;
}

/// 대상을 지목하는 명령들의 공통 앞머리.
abstract class _TargetCommand extends CliCommand {
  _TargetCommand(super.strings) {
    argParser.addFlag(
      _optKeyword,
      negatable: false,
      help: strings.optKeywordHelp,
    );
    addFilterOption(argParser, strings);
  }

  bool get targetIsKeyword => argResults![_optKeyword] as bool;

  ExternalNodeKind get targetKind =>
      targetIsKeyword ? ExternalNodeKind.keyword : ExternalNodeKind.file;

  /// 문법을 물어본 실행인지. **인자 검사보다 앞선다** — 문법을 모르니 묻는 것이라
  /// "인자가 모자란다"를 먼저 내면 답이 되지 않는다.
  bool get wantsFilterHelp => argResults![optFilterHelp] as bool;

  /// 조건 문법을 내고 끝낸다.
  int emitFilterHelp() {
    stdout.writeln(filterHelpText(strings, localeName: localeName));
    return exitOk;
  }

  /// 조건을 읽어 낸다. 읽지 못한 조각이 있으면 사유를 내고 null을 준다.
  QueryResolved? resolveConditions(WorkspaceQueryData data) {
    final spec = resolveQuery(
      argResults!,
      definitions: data.definitions,
      localeName: localeName,
    );
    switch (spec) {
      case QueryResolved():
        return spec;
      case QueryUnreadable(:final problems):
        for (final problem in problems) {
          fail(
            exitUsage,
            ConsoleFailure.badCondition,
            '${strings.labelBadCondition}\t$problem',
            subject: problem,
          );
        }
        return null;
    }
  }
}

/// 부여를 고치는 명령들의 공통 골격.
///
/// 셋의 차이는 [operation] 하나뿐이다 — 나머지는 모두 같은 [ExternalTagCommand]를
/// 세워 같은 해석기에 넘긴다. 판정 규칙이 콘솔·명령 파일에 갈라져 있지 않은 것이
/// 이 배치의 요점이다. **집합 지목도 같다** — 고른 노드마다 명령 하나를 세울 뿐이다.
abstract class _WriteCommand extends _TargetCommand {
  _WriteCommand(super.strings) {
    argParser
      ..addFlag(
        _optValueKeyword,
        negatable: false,
        help: strings.optValueKeywordHelp,
      )
      ..addFlag(
        _optCreateKeyword,
        negatable: false,
        help: strings.optCreateKeywordHelp,
      )
      ..addFlag(_optKeepLink, negatable: false, help: strings.optKeepLinkHelp);
    addAutoScanOption(argParser, strings);
  }

  ExternalCommandOperation get operation;

  @override
  String get invocation {
    final tail = '<${strings.tokenTag}> [${strings.tokenValue}]';
    return '$executableName list $name <${strings.tokenTarget}> $tail\n'
        '       $executableName list $name'
        ' --$optFilter <${strings.tokenCondition}> $tail';
  }

  @override
  Future<int> run() async {
    if (wantsFilterHelp) return emitFilterHelp();

    // 대상을 어떻게 지목했는지로 위치 인자의 자리가 하나 밀린다.
    final byFilter = argResults!.wasParsed(optFilter);
    final wanted = byFilter ? 1 : 2;
    if (rest.length < wanted || rest.length > wanted + 1) {
      usageException(byFilter ? strings.needTagName : strings.needTargetAndTag);
    }
    if (byFilter && targetIsKeyword) {
      usageException(strings.keywordWithFilter);
    }

    final tagName = rest[wanted - 1];
    final value = rest.length > wanted ? rest[wanted] : null;

    return withWorkspace((root, db) async {
      final List<String> targets;
      if (byFilter) {
        // 조건은 **인덱스**를 딛는다. 훑기로 했다면 고르기 전에 훑어야 새 파일이
        // 후보에 든다 — 보류를 보고 훑는 뒤늦은 길로는 애초에 고르지 못한 것을
        // 되찾을 수 없다.
        if (autoScan) await scanWorkspace(root, db);
        final data = await loadQueryData(db, localeName: localeName);
        final conditions = resolveConditions(data);
        if (conditions == null) return exitUsage;
        final chosen = _select(data, conditions);
        // 아무것도 고르지 못한 조건을 성공으로 넘기면, 오타 난 조건이 "다 됐다"로
        // 보인다. 판정할 것이 없었음을 그대로 말한다.
        if (chosen.isEmpty) {
          return fail(exitRejected, ConsoleFailure.noMatch, strings.noMatch);
        }
        targets = [for (final node in chosen) node.path];
      } else {
        targets = [rest.first];
      }

      final commands = [
        for (final target in targets)
          ExternalTagCommand(
            targetPath: target,
            tagName: tagName,
            operation: operation,
            value: value,
            // 조건으로 고른 것은 인덱스에 이미 있는 노드라, 키워드도 제 경로(이름)로
            // 그대로 찾힌다.
            targetKind: byFilter ? ExternalNodeKind.file : targetKind,
            valueKind: (argResults![_optValueKeyword] as bool)
                ? ExternalNodeKind.keyword
                : ExternalNodeKind.file,
            missingKeyword: (argResults![_optCreateKeyword] as bool)
                ? MissingKeywordPolicy.create
                : MissingKeywordPolicy.fail,
            missingLink: (argResults![_optKeepLink] as bool)
                ? MissingLinkPolicy.keep
                : MissingLinkPolicy.fail,
          ),
      ];

      final results = await applyCommandsScanningIfHeld(
        root,
        db,
        commands,
        // 상대 이미지 경로는 명령을 친 사람이 서 있는 자리를 기준으로 푼다.
        imageBaseDir: Directory.current.path,
      );
      return report(results);
    });
  }

  /// 조건에 걸린 노드들.
  ///
  /// 연결 끊김(미싱) 노드는 뺀다 — 디스크에 없는 것이라 해석기가 어차피 거부한다.
  List<FileNode> _select(WorkspaceQueryData data, QueryResolved conditions) => [
    for (final node in data.nodes)
      if (!node.isMissing &&
          conditions.filter.matches(
            data.assignmentsByFile[node.id] ?? const [],
          ))
        node,
  ];
}

class _ListAddCommand extends _WriteCommand {
  _ListAddCommand(super.strings);

  @override
  String get name => 'add';

  @override
  String get description => strings.listAddDescription;

  @override
  ExternalCommandOperation get operation => ExternalCommandOperation.add;
}

class _ListModifyCommand extends _WriteCommand {
  _ListModifyCommand(super.strings);

  @override
  String get name => 'modify';

  @override
  String get description => strings.listModifyDescription;

  @override
  ExternalCommandOperation get operation => ExternalCommandOperation.replace;
}

class _ListDeleteCommand extends _WriteCommand {
  _ListDeleteCommand(super.strings);

  @override
  String get name => 'delete';

  @override
  String get description => strings.listDeleteDescription;

  @override
  ExternalCommandOperation get operation => ExternalCommandOperation.remove;
}

/// 붙은 태그를 낸다 — 대상 하나의 태그이거나, 조건에 걸린 대상들의 목록이다.
///
/// 위치 인자를 주면 앞이고, 주지 않으면 뒤다. 둘을 겹쳐 쓸 수는 없다.
class _ListShowCommand extends _TargetCommand {
  _ListShowCommand(super.strings) {
    addSortGroupOptions(argParser, strings);
    addWindowOptions(argParser, strings);
    addCountOption(argParser, strings);
    argParser
      ..addFlag(_optSystem, help: strings.optSystemHelp)
      ..addFlag(_optExport, negatable: false, help: strings.optExportHelp);
  }

  @override
  String get name => 'show';

  @override
  String get description => strings.listShowDescription;

  @override
  String get invocation =>
      '$executableName list show <${strings.tokenTarget}>\n'
      '       $executableName list show'
      ' [--$optFilter <${strings.tokenCondition}>]'
      ' [--$optSort <${strings.tokenCriterion}>]'
      ' [--$optGroup <${strings.tokenCriterion}>]';

  /// 붙은 태그를 **다른 관리 폴더에 먹일 수 있는 명령 목록**으로 낼지.
  ///
  /// 한때는 `--json`이 늘 이 모양이었다. 조회 하나에 적용 방침(`op`·`missing…`)까지
  /// 실려 "무엇이 붙어 있나"를 묻는 쪽이 읽을 것이 아니었으므로, 기본은 부여를 그대로
  /// 비추는 모양이 되고 명령 목록은 이 옵션으로 옮겼다.
  bool get asExport => argResults![_optExport] as bool;

  /// 내보내기가 내는 것은 명령 **파일**이라 늘 기계용이다 — `--$optJson`을 따로 적지
  /// 않아도 되고, 적지 않았다고 사람용 줄(머리글·갯수)이 섞여 파일을 망가뜨려서도
  /// 안 된다.
  @override
  bool get asJson => asExport || super.asJson;

  /// 시스템 태그를 함께 낼지.
  ///
  /// **내보내기에서만 기본이 갈린다** — 명령 목록은 받는 쪽이 그대로 먹을 수 있어야
  /// 하는데 시스템 태그는 밖에서 부여할 수 없어 거부된다. 조회는 두 형식 모두
  /// 함께 낸다(줄마다 출처가 적혀 있어 받는 쪽이 가릴 수 있다).
  bool get includeSystem => argResults!.wasParsed(_optSystem)
      ? argResults![_optSystem] as bool
      : !asExport;

  @override
  Future<int> run() async {
    if (wantsFilterHelp) return emitFilterHelp();
    if (rest.length > 1) usageException(strings.oneTargetOnly);
    final hasConditions =
        argResults!.wasParsed(optFilter) ||
        argResults!.wasParsed(optSort) ||
        argResults!.wasParsed(optGroup);
    if (rest.isNotEmpty && hasConditions) {
      usageException(strings.targetOrFilter);
    }
    if (rest.isEmpty && targetIsKeyword) {
      usageException(strings.keywordWithFilter);
    }

    final spec = resolveWindow(argResults!, strings);
    if (spec case WindowUnreadable(:final message)) {
      return fail(exitUsage, ConsoleFailure.badWindow, message);
    }
    final window = (spec as WindowResolved).window;

    return withWorkspace((root, db) async {
      if (rest.isEmpty) return _showSet(db, window);
      return _showOne(db, rest.first, window);
    });
  }

  /// 대상 하나에 붙은 태그.
  ///
  /// 인덱스의 부여를 통째로 읽지 않는다 — 한 항목을 묻는 명령이 폴더 전체의 부여를
  /// 끌어올 이유가 없다.
  Future<int> _showOne(AppDatabase db, String raw, OutputWindow window) async {
    final nodes = DriftFileNodeRepository(db);
    final tags = DriftTagRepository(db);
    final index = await nodes.indexByPath();
    final keywords = await nodes.keywordIndexByName();

    final FileNode? node;
    if (targetIsKeyword) {
      node = keywords[raw];
    } else {
      final path = normalizeWorkspaceRelPath(raw);
      node = path == null ? null : index[path];
    }
    final id = node?.id;
    if (node == null || id == null) {
      return fail(
        exitRejected,
        ConsoleFailure.noSuchTarget,
        strings.noSuchTarget(raw),
        subject: raw,
      );
    }

    final stored = {id: await tags.assignmentsOfFile(id)};
    final nodesById = {
      for (final n in [...index.values, ...keywords.values])
        if (n.id != null) n.id!: n,
    };

    if (asExport) {
      final exported = buildExportCommands(
        nodes: [node],
        assignmentsByFile: stored,
        nodesById: nodesById,
        tagIds: exportableTagIds(nodes: [node], assignmentsByFile: stored),
        includeValues: true,
        includeImages: true,
      );
      final commands = window.apply(exported.commands);
      if (!writeCount(commands.length)) return exitOk;
      writeJson([for (final c in commands) commandToJson(c)]);
      return exitOk;
    }

    // 링크는 저장은 대상 id로, 보이는 것은 대상 **이름**이다(화면과 같은 해석).
    final resolved = resolveLinkAssignments(
      stored,
      (raw) => nodesById[int.tryParse(raw)]?.name,
    )[id];
    final own = resolved ?? const <AssignedTag>[];

    // 시스템 태그는 저장된 것이 아니라 **여기서 계산해** 낸다.
    final system = includeSystem
        ? systemAssignmentsFor(
            node,
            definitions: systemTagDefinitionsFor(localeName),
            assignments: own,
          )
        : const <AssignedTag>[];

    // 두 갈래를 한 목록으로 이어 자른다 — 자르는 것은 "내는 줄"이지 갈래가 아니다.
    final rows = window.apply(<_TagRow>[
      for (final a in own) _TagRow(node.path, a, system: false),
      for (final a in system) _TagRow(node.path, a, system: true),
    ]);

    if (!writeCount(rows.length)) return exitOk;
    if (asJson) {
      writeJson([for (final row in rows) row.toJson()]);
    } else {
      writeHeader([
        strings.columnName,
        strings.columnValue,
        strings.columnValueType,
        strings.columnSource,
        strings.columnTagId,
        strings.columnId,
      ]);
      for (final row in rows) {
        stdout.writeln(row.line(strings));
      }
    }
    return exitOk;
  }

  /// 조건에 걸린 대상들.
  ///
  /// **태그가 아니라 대상을 낸다** — 이어지는 파이프가 경로를 받아 다음 명령에 넘기는
  /// 것이 이 형태의 쓰임이다. 어느 태그가 붙어 있는지는 대상 하나를 물어 본다.
  Future<int> _showSet(AppDatabase db, OutputWindow window) async {
    final data = await loadQueryData(db, localeName: localeName);
    final conditions = resolveConditions(data);
    if (conditions == null) return exitUsage;

    // 그룹이 비어 있으면 정렬된 평면 목록이 나오므로, 두 모양을 한 길로 만든다.
    final tree = const BuildGroupedTree()(
      files: [
        for (final node in data.nodes)
          if (!node.isMissing) node,
      ],
      assignmentsByFile: data.assignmentsByFile,
      filter: conditions.filter,
      grouping: conditions.grouping,
      sort: conditions.sort,
      definitionsById: data.definitionsById,
    );

    // 자르는 것은 **맨 윗줄들**이다. 묶어서 낼 때 그 아래 딸린 것까지 세면 "몇 개를
    // 볼지"가 트리 모양에 따라 흔들린다.
    final roots = window.apply(tree);
    // **세는 것은 파일이지 줄이 아니다** — 묶어서 낼 때 그룹 머리글까지 세면 같은
    // 집합인데도 `--$optGroup`을 주었는지에 따라 수가 달라진다.
    if (!writeCount(_countFiles(roots))) return exitOk;
    if (asJson) {
      writeJson(_treeToJson(roots, data));
    } else {
      _writeTree(roots, data, depth: 0);
    }
    return exitOk;
  }

  int _countFiles(List<TreeItem> items) {
    var count = 0;
    for (final item in items) {
      if (item is FileTreeNode) count++;
      count += _countFiles(item.children);
    }
    return count;
  }

  void _writeTree(
    List<TreeItem> items,
    WorkspaceQueryData data, {
    required int depth,
  }) {
    final indent = _indentUnit * depth;
    for (final item in items) {
      switch (item) {
        case FileTreeNode(:final node):
          // 이름이 아니라 **경로 전부**를 낸다 — 들여쓰기가 구조를 보이고, 줄 하나가
          // 그대로 다음 명령의 인자가 된다. id는 그 뒤에 붙어 앞자리를 밀지 않는다.
          stdout.writeln(
            '$indent${node.path}\t${node.id ?? strings.labelNone}',
          );
        case GroupHeaderNode(
          :final tagDefinitionId,
          :final value,
          :final itemCount,
        ):
          final name = data.definitionsById[tagDefinitionId]?.name ?? '';
          stdout.writeln(
            '$indent$name: ${value ?? strings.labelUnclassified} ($itemCount)'
            '\t$tagDefinitionId',
          );
      }
      _writeTree(item.children, data, depth: depth + 1);
    }
  }

  List<Map<String, dynamic>> _treeToJson(
    List<TreeItem> items,
    WorkspaceQueryData data,
  ) => [
    for (final item in items)
      switch (item) {
        FileTreeNode(:final node) => {
          _kPath: node.path,
          _kKind: node.kind.name,
          if (node.id != null) _kId: node.id,
          if (item.children.isNotEmpty)
            _kChildren: _treeToJson(item.children, data),
        },
        GroupHeaderNode(
          :final tagDefinitionId,
          :final value,
          :final itemCount,
        ) =>
          {
            _kGroup: data.definitionsById[tagDefinitionId]?.name,
            _kTagId: tagDefinitionId,
            _kValue: value,
            _kCount: itemCount,
            if (item.children.isNotEmpty)
              _kChildren: _treeToJson(item.children, data),
          },
      },
  ];
}

/// 대상 하나에 붙은 태그 한 줄. 사람용·기계용 두 표현을 함께 들어, 자르는 자리가
/// 갈래를 가리지 않아도 되게 한다.
///
/// **두 갈래가 같은 모양이다** — 시스템 태그도 사용자 태그와 같은 열·키를 갖는다.
/// 갈래는 `system` 한 칸이 말한다. 예전처럼 모양을 갈라 두면 한 배열에 스키마 둘이
/// 섞여 받는 쪽이 가리지 못한다.
class _TagRow {
  const _TagRow(this.path, this.tag, {required this.system});

  final String path;
  final AssignedTag tag;
  final bool system;

  /// 저장된 부여를 짚는 내부 식별자. 계산으로만 서는 시스템 태그에는 없다.
  int? get assignmentId => tag.assignment.id;

  Map<String, dynamic> toJson() => {
    _kPath: path,
    _kTag: tag.definition.name,
    _kTagId: tag.tagDefinitionId,
    _kValueType: tag.definition.valueType.name,
    if (tag.value != null) _kValue: tag.value,
    _kSystem: system,
    if (assignmentId != null) _kId: assignmentId,
    // 참일 때만 낸다 — 대부분의 부여에 뜻이 없는 칸이다.
    if (tag.valueUnresolved) _kUnresolved: true,
  };

  String line(ConsoleStrings strings) => [
    tag.definition.name,
    tag.value ?? strings.labelNone,
    tag.definition.valueType.name,
    system ? strings.labelSystem : strings.labelUser,
    '${tag.tagDefinitionId}',
    assignmentId == null ? strings.labelNone : '$assignmentId',
  ].join('\t');
}

const String _optKeyword = 'keyword';
const String _optValueKeyword = 'value-keyword';
const String _optCreateKeyword = 'create-keyword';
const String _optKeepLink = 'keep-link';
const String _optSystem = 'system';
const String _optExport = 'export';

const String _kPath = 'path';
const String _kKind = 'kind';
const String _kTag = 'tag';
const String _kTagId = 'tagId';
const String _kValue = 'value';
const String _kValueType = 'valueType';
const String _kSystem = 'system';
const String _kUnresolved = 'unresolved';
const String _kId = 'id';
const String _kGroup = 'group';
const String _kCount = 'count';
const String _kChildren = 'children';

const String _indentUnit = '  ';
