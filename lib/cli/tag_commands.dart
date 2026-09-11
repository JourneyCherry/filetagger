/// `tag` — 태그 **정의**를 다룬다.
///
/// 부여(`list`)와 갈라 둔 것이 이 표면의 요점이다. 예전에는 부여 명령이 "없으면
/// 만들어라"를 함께 실어 정의의 성질(값 유형·다중 허용·색)을 옵션으로 끌고 다녔는데,
/// 그러면 같은 태그가 부르는 자리마다 다른 성질로 태어날 수 있었다. 정의를 만드는
/// 입구는 여기 하나다.
library;

import 'dart:io';

import '../data/db/app_database.dart';
import '../data/repositories/drift_tag_repository.dart';
import '../domain/entities/assigned_tag.dart';
import '../domain/entities/tag_color_format.dart';
import '../domain/entities/tag_definition.dart';
import '../domain/entities/tag_value_type.dart';
import '../l10n/console_strings.dart';
import '../l10n/system_tag_names.dart';
import 'cli_command.dart';
import 'cli_output.dart';
import 'output_window.dart';

class TagCommand extends CliCommandGroup {
  TagCommand(this.strings)
    : super([
        _TagAddCommand(strings),
        _TagModifyCommand(strings),
        _TagDeleteCommand(strings),
        _TagShowCommand(strings),
      ]);

  final ConsoleStrings strings;

  @override
  String get name => 'tag';

  @override
  String get description => strings.tagDescription;
}

/// 정의를 상대하는 명령들의 공통 앞머리 — 이름을 받아 시스템 태그를 걸러 낸다.
abstract class _TagCommand extends CliCommand {
  _TagCommand(super.strings);

  /// [rest]의 첫 자리에 있는 태그 이름. 없거나 시스템 태그면 null이고 사유는 이미 냈다.
  ///
  /// 시스템 태그는 파일에서 파생되는 것이라 정의를 만들 수도 고칠 수도 없다. 특히
  /// 이름 태그는 값 편집이 디스크 rename이라, 손댈 수 있게 두면 태그 명령이 파일을
  /// 옮기는 통로가 된다.
  String? tagName() {
    final name = rest.isEmpty ? null : rest.first;
    if (name == null || name.isEmpty) {
      usageException(strings.needTagName);
    }
    if (allSystemTagNames.contains(name)) {
      fail(
        exitRejected,
        ConsoleFailure.systemTag,
        strings.systemTagNotEditable(name),
        subject: name,
      );
      return null;
    }
    return name;
  }

  /// `--color`를 저장 표현으로 읽는다. 적지 않았으면 둘 다 비어 있고, 읽지 못했으면
  /// [_Color.invalid]가 참이며 사유는 이미 냈다. **옵션을 단 명령만 부른다.**
  _Color readColor() {
    final raw = argResults![_optColor] as String?;
    if (raw == null) return const _Color();
    final parsed = parseTagColorHex(raw);
    if (parsed == null) {
      fail(
        exitRejected,
        ConsoleFailure.badColor,
        strings.badColor(raw),
        subject: raw,
      );
      return const _Color(invalid: true);
    }
    return _Color(value: parsed);
  }
}

/// 태그 정의를 만든다.
class _TagAddCommand extends _TagCommand {
  _TagAddCommand(super.strings) {
    argParser
      ..addFlag(
        _optMultiple,
        negatable: false,
        help: strings.optMultipleAddHelp,
      )
      ..addOption(
        _optColor,
        valueHelp: _colorValueHelp,
        help: strings.optColorHelp,
      );
  }

  @override
  String get name => 'add';

  @override
  String get description => strings.tagAddDescription;

  @override
  String get invocation =>
      '$executableName tag add <${strings.tokenTagName}>'
      ' <${strings.tokenValueType}>';

  /// 값 유형이 **위치 인자**라 파서가 후보를 내주지 못한다(`--type`은 `allowed`가
  /// 대신 낸다). 사용법 꼬리에 직접 붙여 두 자리의 안내를 맞춘다.
  @override
  String get usageFooter => valueTypesHelp(strings);

  @override
  Future<int> run() async {
    if (rest.length != 2) usageException(strings.needNameAndType);
    final name = tagName();
    if (name == null) return exitRejected;
    final valueType = _valueTypeByName(rest[1]);
    if (valueType == null) {
      return fail(
        exitRejected,
        ConsoleFailure.unknownValueType,
        '${strings.unknownValueType(rest[1])}\n${valueTypesHelp(strings)}',
        subject: rest[1],
      );
    }
    final color = readColor();
    if (color.invalid) return exitRejected;

    return withWorkspace((root, db) async {
      final tags = DriftTagRepository(db);
      final existing = await tags.definitionByName(name);
      if (existing != null) {
        // 같은 명령을 두 번 쳐도 결과가 같아야 스크립트가 앞에 두고 쓸 수 있다.
        // 다만 값 유형이 다르면 조용히 넘어가면 안 된다 — 뒤따르는 부여가 엉뚱한
        // 유형으로 해석된다.
        if (existing.valueType != valueType) {
          return fail(
            exitRejected,
            ConsoleFailure.valueTypeMismatch,
            strings.typeMismatch(existing.valueType.name),
            subject: existing.valueType.name,
          );
        }
        return _emit(
          existing,
          await _countsByTag(db),
          verb: strings.verbKept,
          action: actionKept,
        );
      }
      final created = await tags.createDefinition(
        name: name,
        valueType: valueType,
        allowMultiple: argResults![_optMultiple] as bool,
        color: color.value,
      );
      return _emit(
        created,
        const {},
        verb: strings.verbAdded,
        action: actionAdded,
      );
    });
  }

  int _emit(
    TagDefinition definition,
    Map<int, int> counts, {
    required String verb,
    required String action,
  }) {
    if (asJson) {
      writeJson({...definitionToJson(definition, counts), _kAction: action});
    } else {
      stdout.writeln('$verb\t${definitionLine(definition, counts, strings)}');
    }
    return exitOk;
  }
}

/// 태그 정의를 고친다. **적은 것만 바꾼다** — 주지 않은 성질은 그대로 둔다.
class _TagModifyCommand extends _TagCommand {
  _TagModifyCommand(super.strings) {
    argParser
      ..addOption(
        _optRename,
        valueHelp: strings.tokenNewName,
        help: strings.optRenameHelp,
      )
      ..addOption(
        _optType,
        valueHelp: strings.tokenValueType,
        allowed: [for (final t in TagValueType.values) t.name],
        help: strings.optTypeHelp,
      )
      ..addFlag(_optMultiple, help: strings.optMultipleModifyHelp)
      ..addOption(
        _optColor,
        valueHelp: _colorValueHelp,
        help: strings.optColorHelp,
      )
      ..addFlag(
        _optClearColor,
        negatable: false,
        help: strings.optClearColorHelp,
      );
  }

  @override
  String get name => 'modify';

  @override
  String get description => strings.tagModifyDescription;

  @override
  String get invocation =>
      '$executableName tag modify <${strings.tokenTagName}>'
      ' [${strings.tokenChanges}]';

  @override
  Future<int> run() async {
    if (rest.length != 1) usageException(strings.needTagName);
    final name = tagName();
    if (name == null) return exitRejected;

    final rename = argResults![_optRename] as String?;
    if (rename != null && allSystemTagNames.contains(rename)) {
      return fail(
        exitRejected,
        ConsoleFailure.systemTag,
        strings.systemTagNotEditable(rename),
        subject: rename,
      );
    }
    final color = readColor();
    if (color.invalid) return exitRejected;
    final clearColor = argResults![_optClearColor] as bool;
    if (clearColor && color.value != null) {
      usageException(strings.colorConflict);
    }
    final type = _valueTypeByName(argResults![_optType] as String?);

    return withWorkspace((root, db) async {
      final tags = DriftTagRepository(db);
      final existing = await tags.definitionByName(name);
      if (existing == null) {
        return fail(
          exitRejected,
          ConsoleFailure.tagMissing,
          strings.noSuchTag(name),
          subject: name,
        );
      }
      // 이름을 옮길 자리가 이미 차 있으면 유니크 제약에 걸린다. 예외로 터지기 전에
      // 사유를 말한다.
      if (rename != null && rename != name) {
        if (await tags.definitionByName(rename) != null) {
          return fail(
            exitRejected,
            ConsoleFailure.nameTaken,
            strings.nameTaken(rename),
            subject: rename,
          );
        }
      }
      final updated = existing.copyWith(
        name: rename,
        valueType: type,
        color: color.value,
        clearColor: clearColor,
        allowMultiple: argResults!.wasParsed(_optMultiple)
            ? argResults![_optMultiple] as bool
            : null,
      );
      await tags.updateDefinition(updated);

      final counts = await _countsByTag(db);
      if (asJson) {
        writeJson({
          ...definitionToJson(updated, counts),
          _kAction: actionUpdated,
        });
      } else {
        stdout.writeln(
          '${strings.verbUpdated}\t${definitionLine(updated, counts, strings)}',
        );
      }
      return exitOk;
    });
  }
}

/// 태그 정의를 지운다. 그 태그의 **부여도 함께** 사라진다.
class _TagDeleteCommand extends _TagCommand {
  _TagDeleteCommand(super.strings);

  @override
  String get name => 'delete';

  @override
  String get description => strings.tagDeleteDescription;

  @override
  String get invocation =>
      '$executableName tag delete <${strings.tokenTagName}>';

  @override
  Future<int> run() async {
    if (rest.length != 1) usageException(strings.needTagName);
    final name = tagName();
    if (name == null) return exitRejected;

    return withWorkspace((root, db) async {
      final tags = DriftTagRepository(db);
      final existing = await tags.definitionByName(name);
      final id = existing?.id;
      if (existing == null || id == null) {
        return fail(
          exitRejected,
          ConsoleFailure.tagMissing,
          strings.noSuchTag(name),
          subject: name,
        );
      }
      // 함께 지워지는 부여의 수를 **지우기 전에** 센다. 되돌릴 수 없는 조작이라
      // 무엇이 사라졌는지는 말해 줘야 한다.
      final removed = (await _countsByTag(db))[id] ?? 0;
      await tags.deleteDefinition(id);

      if (asJson) {
        writeJson({
          ...definitionToJson(existing, const {}),
          _kAction: actionDeleted,
          _kRemovedAssignments: removed,
        });
      } else {
        stdout.writeln(
          '${strings.verbDeleted}\t${existing.name}\t'
          '${existing.valueType.name}\t'
          '${strings.labelRemovedAssignments} $removed',
        );
      }
      return exitOk;
    });
  }
}

/// 태그 정의를 낸다. 이름을 주면 그 하나만, 주지 않으면 전부.
class _TagShowCommand extends CliCommand {
  _TagShowCommand(super.strings) {
    addWindowOptions(argParser, strings);
    addCountOption(argParser, strings);
  }

  @override
  String get name => 'show';

  @override
  String get description => strings.tagShowDescription;

  @override
  String get invocation => '$executableName tag show [${strings.tokenTagName}]';

  @override
  Future<int> run() async {
    if (rest.length > 1) usageException(strings.tooManyNames);

    final window = resolveWindow(argResults!, strings);
    if (window case WindowUnreadable(:final message)) {
      return fail(exitUsage, ConsoleFailure.badWindow, message);
    }

    return withWorkspace((root, db) async {
      final tags = DriftTagRepository(db);
      final counts = await _countsByTag(db);
      final List<TagDefinition> definitions;
      if (rest.isEmpty) {
        definitions = (window as WindowResolved).window.apply(
          await tags.watchDefinitions().first,
        );
      } else {
        final one = await tags.definitionByName(rest.first);
        if (one == null) {
          return fail(
            exitRejected,
            ConsoleFailure.tagMissing,
            strings.noSuchTag(rest.first),
            subject: rest.first,
          );
        }
        definitions = [one];
      }

      if (!writeCount(definitions.length)) return exitOk;
      if (asJson) {
        writeJson([for (final d in definitions) definitionToJson(d, counts)]);
      } else {
        writeHeader(definitionColumns(strings));
        for (final d in definitions) {
          stdout.writeln(definitionLine(d, counts, strings));
        }
      }
      return exitOk;
    });
  }
}

// ── 정의의 두 표현 ──

/// 정의 하나의 사람용 한 줄. 없는 성질은 자리를 비우지 않고 표식을 둔다 — 열이 밀리면
/// `cut`·`awk`로 집어 쓸 수 없다.
///
/// **id는 맨 뒤에 둔다** — 앞에 끼우면 이름을 집던 자리가 밀린다.
String definitionLine(
  TagDefinition definition,
  Map<int, int> counts,
  ConsoleStrings strings,
) {
  final color = definition.color;
  final id = definition.id;
  return [
    definition.name,
    definition.valueType.name,
    definition.allowMultiple ? strings.labelMultiple : strings.labelNone,
    color == null ? strings.labelNone : tagColorToHex(color),
    '${id == null ? 0 : counts[id] ?? 0}',
    id == null ? strings.labelNone : '$id',
  ].join('\t');
}

/// 정의 한 줄의 열 이름. [definitionLine]과 같은 차례여야 한다.
List<String> definitionColumns(ConsoleStrings strings) => [
  strings.columnName,
  strings.columnValueType,
  strings.columnMultiple,
  strings.columnColor,
  strings.columnAssignments,
  strings.columnId,
];

/// 정의 하나의 기계용 표현.
Map<String, dynamic> definitionToJson(
  TagDefinition definition,
  Map<int, int> counts,
) {
  final color = definition.color;
  final id = definition.id;
  return {
    _kName: definition.name,
    _kValueType: definition.valueType.name,
    _kAllowMultiple: definition.allowMultiple,
    if (color != null) _kColor: tagColorToHex(color),
    _kAssignments: id == null ? 0 : counts[id] ?? 0,
    // 저장된 정의를 짚는 내부 식별자. 아직 저장 전이면 없다.
    if (id != null) _kId: id,
  };
}

// ── 세부 ──

/// 태그 정의 id → 그 태그가 붙은 부여의 수.
Future<Map<int, int>> _countsByTag(AppDatabase db) async {
  final assignments = await DriftTagRepository(db).watchAssignments().first;
  final counts = <int, int>{};
  for (final AssignedTag a in assignments) {
    counts[a.tagDefinitionId] = (counts[a.tagDefinitionId] ?? 0) + 1;
  }
  return counts;
}

/// 고를 수 있는 값 유형의 목록. **이름은 열거에서 뽑는다** — 손으로 적어 두면 유형이
/// 늘었을 때 도움말만 옛것으로 남는다.
String valueTypesHelp(ConsoleStrings strings) =>
    '${strings.valueTypesHeading}\n'
    '  ${[for (final t in TagValueType.values) t.name].join(', ')}';

TagValueType? _valueTypeByName(String? name) {
  if (name == null) return null;
  for (final type in TagValueType.values) {
    if (type.name == name) return type;
  }
  return null;
}

class _Color {
  const _Color({this.value, this.invalid = false});

  final int? value;
  final bool invalid;
}

const String _optMultiple = 'multiple';
const String _optColor = 'color';
const String _optClearColor = 'clear-color';
const String _optRename = 'rename';
const String _optType = 'type';

/// 색 옵션의 자리 이름. **번역하지 않는다** — 값의 꼴 자체라 언어를 타지 않는다.
const String _colorValueHelp = '#RRGGBB';

const String _kName = 'name';
const String _kValueType = 'valueType';
const String _kAllowMultiple = 'allowMultiple';
const String _kColor = 'color';
const String _kAssignments = 'assignments';
const String _kId = 'id';
const String _kAction = 'action';

// 기계용 출력이 무엇을 했는지 말하는 값. **사람용 동사와 갈라 둔다** — 받는 쪽이
// 분기하는 값이라 콘솔이 고른 언어에 따라 달라지면 안 된다.
const String actionAdded = 'added';
const String actionKept = 'kept';
const String actionUpdated = 'updated';
const String actionDeleted = 'deleted';
const String _kRemovedAssignments = 'removedAssignments';
