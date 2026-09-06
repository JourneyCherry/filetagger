/// `status` — 관리 폴더가 무엇을 담고 있는지 한눈에.
///
/// 스캔하지 않는다. 인덱스에 **이미 들어 있는 것**만 세므로, 디스크와 어긋나 있는지를
/// 알려면 `scan`을 먼저 돌려야 한다.
library;

import 'dart:io';

import '../data/repositories/drift_file_node_repository.dart';
import '../data/repositories/drift_tag_repository.dart';
import 'cli_command.dart';
import 'cli_output.dart';

class StatusCommand extends CliCommand {
  StatusCommand(super.strings);

  @override
  String get name => 'status';

  @override
  String get description => strings.statusDescription;

  @override
  String get invocation => '$executableName $name';

  @override
  Future<int> run() async {
    if (rest.isNotEmpty) usageException(strings.takesNoArguments(name));

    return withWorkspace((root, db) async {
      final nodes = DriftFileNodeRepository(db);
      final tags = DriftTagRepository(db);
      final index = await nodes.indexByPath();
      final keywords = await nodes.keywordIndexByName();
      final definitions = await tags.watchDefinitions().first;
      final assignments = await tags.watchAssignments().first;

      if (asJson) {
        writeJson({
          _kRoot: root,
          _kNodes: index.length,
          _kKeywords: keywords.length,
          _kTags: definitions.length,
          _kAssignments: assignments.length,
        });
      } else {
        stdout
          ..writeln(root)
          ..writeln('${strings.labelNodes}\t${index.length}')
          ..writeln('${strings.labelKeywords}\t${keywords.length}')
          ..writeln('${strings.labelTagDefinitions}\t${definitions.length}')
          ..writeln('${strings.labelAssignments}\t${assignments.length}');
      }
      return exitOk;
    });
  }
}

const String _kRoot = 'root';
const String _kNodes = 'nodes';
const String _kKeywords = 'keywords';
const String _kTags = 'tags';
const String _kAssignments = 'assignments';
