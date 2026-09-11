/// 콘솔 문구의 영어 번역본. 원문은 [ConsoleStringsKo]다.
library;

import '../domain/entities/file_filter.dart';
import 'console_strings.dart';

class ConsoleStringsEn extends ConsoleStrings {
  const ConsoleStringsEn();

  @override
  String get languageCode => 'en';

  @override
  String get tokenPath => 'path';
  @override
  String get tokenTarget => 'target';
  @override
  String get tokenTag => 'tag';
  @override
  String get tokenTagName => 'name';
  @override
  String get tokenNewName => 'new name';
  @override
  String get tokenChanges => 'changes';
  @override
  String get tokenValue => 'value';
  @override
  String get tokenValueType => 'value type';
  @override
  String get tokenCondition => 'condition';
  @override
  String get tokenCriterion => 'criteria';
  @override
  String get tokenCount => 'count';
  @override
  String get tokenRange => 'start:end';
  @override
  String get tokenFile => 'file';
  @override
  String get tokenImageFile => 'image file';
  @override
  String get tokenLanguage => 'language';
  @override
  String get tokenKey => 'key';

  @override
  String get runnerDescription =>
      'Manage the tags of a File Tagger folder from one command line.';

  @override
  String get optWorkspaceHelp =>
      'Managed folder. Falls back to the workspace setting, then the current directory.';
  @override
  String get optJsonHelp => 'Emit JSON for machines instead of people.';
  @override
  String get optLangHelp =>
      'Language of the console output. Falls back to the settings, then the OS.';
  @override
  String get optAutoScanHelp =>
      'Scan once and judge again when the index does not know the target.';
  @override
  String get optCountHelp => 'Emit just the count instead of the listing.';
  @override
  String get labelTotal => 'total';

  @override
  String get optFilterHelp =>
      'Pick targets by tag condition. Same syntax as the filter row in the app.';
  @override
  String get optFilterHelpHelp =>
      'Emit the syntax of conditions, sorting and grouping.';
  @override
  String get filterHelpHeading =>
      'Condition syntax — the same as the condition row in the app.';
  @override
  String filterHelpChunks(String quote, String escape) =>
      'One chunk is one condition, and chunks are split on whitespace.\n'
      'Wrap names and values holding a space in $quote. '
      'Put $escape before a $quote or a $escape of your own.';
  @override
  String filterHelpConditions(String excludePrefix, String orPrefix) =>
      '  <tag>                     the tag is attached\n'
      '  <tag><operator><value>    compare the value\n'
      '  $excludePrefix<tag condition>           hide what matches (exclude)\n'
      '  $orPrefix<tag condition>           join the previous condition (OR)\n'
      '\n'
      '  Every condition must hold; joined ones need only one of them.\n'
      '\n'
      '  operators';
  @override
  String filterHelpAlias(String aliases, String canonical) =>
      '($aliases reads as $canonical too)';
  @override
  String filterOperatorName(FilterOperator op) => switch (op) {
    FilterOperator.exists => 'exists',
    FilterOperator.equals => 'equals',
    FilterOperator.notEquals => 'differs',
    FilterOperator.lessThan => 'less than',
    FilterOperator.lessOrEqual => 'at most',
    FilterOperator.greaterThan => 'greater than',
    FilterOperator.greaterOrEqual => 'at least',
    FilterOperator.contains => 'contains',
    FilterOperator.notContains => 'does not contain',
  };
  @override
  String filterHelpSort(String descendingPrefix, String randomPrefix) =>
      '  <tag>                     ascending\n'
      '  $descendingPrefix<tag>                    descending\n'
      '  $randomPrefix<tag>                    random';
  @override
  String filterHelpGroup(String folderHierarchyName) =>
      '  <tag>                     group by that tag value\n'
      '  $folderHierarchyName          group by folder hierarchy';
  @override
  String get optSortHelp => 'Sort by tag value (earlier criteria win).';
  @override
  String get optGroupHelp => 'Group by tag value or folder hierarchy.';

  @override
  String get labelBadCondition => 'bad condition';

  @override
  String get optTopHelp => 'Emit only this many from the start.';
  @override
  String get optTailHelp => 'Emit only this many from the end.';
  @override
  String get optRangeHelp =>
      'Emit this position through that one (1-based, both ends included).';
  @override
  String get windowConflict =>
      'Only one of the options that limit how much is emitted may be used.';
  @override
  String badRange(String raw) =>
      'A range must be "$tokenRange" of integers 1 or greater: $raw';
  @override
  String badCount(String option, String raw) =>
      '--$option must be an integer 1 or greater: $raw';

  @override
  String notWorkspace(String path) => 'Not a managed folder: $path';

  @override
  String get markApplied => 'applied';
  @override
  String get markHeld => 'held';
  @override
  String get markRejected => 'rejected';
  @override
  String get markUnreadable => 'unreadable';

  @override
  String get notIndexed =>
      'The index does not know the target yet. Run scan first.';

  @override
  String get columnScope => 'scope';
  @override
  String get columnKey => 'key';
  @override
  String get columnValue => 'value';
  @override
  String get columnName => 'name';
  @override
  String get columnValueType => 'value type';
  @override
  String get columnMultiple => 'multiple';
  @override
  String get columnColor => 'color';
  @override
  String get columnAssignments => 'assignments';
  @override
  String get columnSource => 'source';
  @override
  String get columnFile => 'file';
  @override
  String get columnEditable => 'editable';
  @override
  String get columnId => 'id';
  @override
  String get columnTagId => 'tag id';

  @override
  String get tagDescription =>
      'Create, modify, delete and inspect tag definitions.';
  @override
  String get tagAddDescription =>
      'Create a tag definition. Kept as is if the same name and value type exist.';
  @override
  String get tagModifyDescription =>
      'Change the name, value type, multiplicity or color of a tag definition.';
  @override
  String get tagDeleteDescription =>
      'Delete a tag definition. Its assignments go with it.';
  @override
  String get tagShowDescription =>
      'Emit the tag definitions you made (derived system tags come from systemtags).';

  @override
  String get optMultipleAddHelp =>
      'Allow assigning it more than once per file.';
  @override
  String get optMultipleModifyHelp =>
      'Whether it may be assigned more than once per file.';
  @override
  String get optColorHelp => 'Chip color.';
  @override
  String get optClearColorHelp => 'Clear the chip color.';
  @override
  String get optRenameHelp => 'Rename the tag.';
  @override
  String get optTypeHelp =>
      'Change the value type. Existing values stay, so they may not read as the new type.';
  @override
  String get valueTypesHeading => 'Value types:';

  @override
  String get verbAdded => 'added';
  @override
  String get verbKept => 'kept';
  @override
  String get verbUpdated => 'updated';
  @override
  String get verbDeleted => 'deleted';

  @override
  String get labelMultiple => 'multiple';
  @override
  String get labelNone => '-';
  @override
  String get labelRemovedAssignments => 'assignments removed';

  @override
  String get needTagName => 'A tag name is required.';
  @override
  String get needNameAndType => 'A tag name and a value type are required.';
  @override
  String get tooManyNames => 'Only one tag name is accepted.';
  @override
  String systemTagNotEditable(String name) =>
      'System tags cannot be handled from the console: $name';
  @override
  String noSuchTag(String name) => 'No tag by that name: $name';
  @override
  String nameTaken(String name) => 'A tag by that name already exists: $name';
  @override
  String typeMismatch(String type) =>
      'A tag by the same name already exists with another value type: $type';
  @override
  String unknownValueType(String raw) => 'Unknown value type: $raw';
  @override
  String badColor(String raw) => 'Could not read the color as hex: $raw';
  @override
  String get colorConflict => 'A color cannot be set and cleared at once.';

  @override
  String get listDescription =>
      'Assign, change, remove and inspect the tags on files and keywords.';
  @override
  String get listAddDescription =>
      'Assign a tag. On a tag that allows multiples, one more value is added.';
  @override
  String get listModifyDescription =>
      'Drop the existing assignments of that tag and leave the given value alone.';
  @override
  String get listDeleteDescription =>
      'Remove assignments. With a value only matching ones, without it all of them.';
  @override
  String get listShowDescription =>
      'Emit the tags on a target, or the targets a condition picks.';

  @override
  String get optKeywordHelp => 'Read the target as a keyword name, not a path.';
  @override
  String get optValueKeywordHelp =>
      'Read the link value as a keyword name, not a path.';
  @override
  String get optCreateKeywordHelp =>
      'Create the named keyword if it does not exist and go on.';
  @override
  String get optKeepLinkHelp =>
      'Keep what was written as an unresolved link when the target is not found.';
  @override
  String get optSystemHelp =>
      'Emit derived system tags too. By default they show when listing and not when exporting.';
  @override
  String get optExportHelp =>
      'Emit a command file (JSON) another workspace can eat. import reads this format.';

  @override
  String get labelUser => 'user';
  @override
  String get labelSystem => 'system';
  @override
  String get labelUnclassified => '(unclassified)';

  @override
  String get oneTargetOnly => 'Only one target is accepted.';
  @override
  String get needTargetAndTag => 'A target and a tag name are required.';
  @override
  String get targetOrFilter =>
      'A target and a condition cannot be given together.';
  @override
  String get keywordWithFilter =>
      'A keyword target cannot be used when picking by condition.';
  @override
  String noSuchTarget(String raw) => 'Target not found: $raw';
  @override
  String get noMatch => 'No target matched the condition.';

  @override
  String get scanDescription =>
      'Walk the managed folder and bring the index up to date.';
  @override
  String get labelNodes => 'nodes';
  @override
  String get labelUnreadableDirs => 'unreadable folders';
  @override
  String get labelNestedWorkspaces => 'nested managed folders';
  @override
  String get labelScanning => 'walking';
  @override
  String get labelIndexed => 'indexed';
  @override
  String get scanBusy =>
      'Skipped: another program is already walking this folder.';
  @override
  String workspaceUnreadable(String root) =>
      'Could not list the managed folder: $root';

  @override
  String get importDescription =>
      'Read an exported command file and apply it as written.';
  @override
  String get needCommandFile => 'One command file to read is required.';
  @override
  String fileUnreadable(String path) => 'Could not read the file: $path';

  @override
  String get imageDescription =>
      'Register an outside image in the cache and emit its cache key and folder-relative path.';
  @override
  String get needImageFile => 'One image file to register is required.';
  @override
  String notAnImage(String path) => 'Could not read it as an image: $path';

  @override
  String get pruneDescription =>
      'Drop stale references to retired system tags from view settings and presets.';
  @override
  String get labelViewSettings => 'view settings';
  @override
  String get labelPresets => 'presets';

  @override
  String get statusDescription =>
      'Emit how many nodes, keywords and tags the index holds.';
  @override
  String get labelKeywords => 'keywords';
  @override
  String get labelTagDefinitions => 'tag definitions';
  @override
  String get labelAssignments => 'assignments';

  @override
  String get systemTagsDescription =>
      'Emit the system tags usable in conditions and what they are.';
  @override
  String get labelEditable => 'editable';
  @override
  String get labelReadOnly => 'read-only';

  @override
  String get configDescription => 'Inspect and change the console settings.';
  @override
  String get configShowDescription =>
      'Emit the settings in force and where the two settings files sit.';
  @override
  String get configSetDescription =>
      'Write one setting. Without a scope it goes to the per-account one.';
  @override
  String get configUnsetDescription =>
      'Remove one setting. Without a scope it goes to the per-account one.';

  @override
  String get configKeysHeading => 'Settings keys:';
  @override
  String get configKeyLangHelp =>
      'Language the console speaks. Used by runs that pass no --lang.';
  @override
  String get configKeyWorkspaceHelp =>
      'Default managed folder. Opened by commands that pass no -C.';

  @override
  String get optGlobalScopeHelp =>
      'Write to the global settings next to the executable.';
  @override
  String get optUserScopeHelp =>
      'Write to the per-account OS settings (default).';

  @override
  String get labelGlobalScope => 'global';
  @override
  String get labelUserScope => 'user';
  @override
  String get labelInForce => 'in force';
  @override
  String get labelAccount => 'account';
  @override
  String get labelFromSystem => 'OS setting';
  @override
  String get labelFromCurrentDir => 'current directory';
  @override
  String get labelNoAccount => '(unknown account)';

  @override
  String get needConfigKey => 'A settings key is required.';
  @override
  String get needKeyAndValue => 'A settings key and a value are required.';
  @override
  String unknownConfigKey(String key) => 'Unknown settings key: $key';
  @override
  String unknownLanguage(String raw, Iterable<String> known) =>
      'No console strings for that language: $raw (${known.join(' ')})';
  @override
  String configWriteFailed(String path) =>
      'Could not write the settings: $path';
  @override
  String get noAccountToWrite =>
      'Cannot write per-account: this account has no name the environment knows.';

  @override
  String takesNoArguments(String command) => '$command takes no arguments.';
}
