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
          stderr.writeln('${strings.labelBadCondition}\t$problem');
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
          stderr.writeln(strings.noMatch);
          return exitRejected;
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
    argParser.addFlag(_optSystem, help: strings.optSystemHelp);
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

  /// 시스템 태그를 함께 낼지.
  ///
  /// 기본이 출력 형식에 따라 갈리는 이유는 두 형식의 쓰임이 다르기 때문이다 — 사람은
  /// 크기·확장자까지 다 보려 하고, 기계용은 **다른 관리 폴더에 그대로 먹일 수 있는**
  /// 명령 목록이라야 한다(시스템 태그는 밖에서 부여할 수 없어 거부된다).
  bool get includeSystem => argResults!.wasParsed(_optSystem)
      ? argResults![_optSystem] as bool
      : !asJson;

  @override
  Future<int> run() async {
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
      stderr.writeln(message);
      return exitUsage;
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
      stderr.writeln(strings.noSuchTarget(raw));
      return exitRejected;
    }

    final stored = {id: await tags.assignmentsOfFile(id)};
    final exported = buildExportCommands(
      nodes: [node],
      assignmentsByFile: stored,
      nodesById: {
        for (final n in [...index.values, ...keywords.values])
          if (n.id != null) n.id!: n,
      },
      tagIds: exportableTagIds(nodes: [node], assignmentsByFile: stored),
      includeValues: true,
      includeImages: true,
    );

    // 시스템 태그는 저장된 것이 아니라 **여기서 계산해** 낸다.
    final system = includeSystem
        ? systemAssignmentsFor(
            node,
            definitions: systemTagDefinitionsFor(localeName),
            assignments: stored[id] ?? const [],
          )
        : const <AssignedTag>[];

    // 두 갈래를 한 목록으로 이어 자른다 — 자르는 것은 "내는 줄"이지 갈래가 아니다.
    final rows = window.apply(<_TagRow>[
      for (final c in exported.commands)
        _TagRow(
          name: c.tagName,
          value: c.value,
          system: false,
          json: commandToJson(c),
        ),
      for (final a in system)
        _TagRow(
          name: a.definition.name,
          value: a.value,
          system: true,
          json: {
            _kPath: node.path,
            _kTag: a.definition.name,
            if (a.value != null) _kValue: a.value,
            _kSystem: true,
          },
        ),
    ]);

    if (asJson) {
      writeJson([for (final row in rows) row.json]);
    } else {
      writeHeader([
        strings.columnName,
        strings.columnValue,
        strings.columnSource,
      ]);
      for (final row in rows) {
        stdout.writeln(
          '${row.name}\t${row.value ?? strings.labelNone}\t'
          '${row.system ? strings.labelSystem : strings.labelUser}',
        );
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
    if (asJson) {
      writeJson(_treeToJson(roots, data));
    } else {
      _writeTree(roots, data, depth: 0);
    }
    return exitOk;
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
          // 그대로 다음 명령의 인자가 된다.
          stdout.writeln('$indent${node.path}');
        case GroupHeaderNode(
          :final tagDefinitionId,
          :final value,
          :final itemCount,
        ):
          final name = data.definitionsById[tagDefinitionId]?.name ?? '';
          stdout.writeln(
            '$indent$name: ${value ?? strings.labelUnclassified} ($itemCount)',
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
class _TagRow {
  const _TagRow({
    required this.name,
    required this.value,
    required this.system,
    required this.json,
  });

  final String name;
  final String? value;
  final bool system;
  final Map<String, dynamic> json;
}

const String _optKeyword = 'keyword';
const String _optValueKeyword = 'value-keyword';
const String _optCreateKeyword = 'create-keyword';
const String _optKeepLink = 'keep-link';
const String _optSystem = 'system';

const String _kPath = 'path';
const String _kKind = 'kind';
const String _kTag = 'tag';
const String _kValue = 'value';
const String _kSystem = 'system';
const String _kGroup = 'group';
const String _kCount = 'count';
const String _kChildren = 'children';

const String _indentUnit = '  ';
