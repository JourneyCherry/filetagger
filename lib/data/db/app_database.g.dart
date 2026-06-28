// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TagDefinitionsTable extends TagDefinitions
    with TableInfo<$TagDefinitionsTable, TagDefinition> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagDefinitionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  @override
  late final GeneratedColumnWithTypeConverter<TagValueType, String> valueType =
      GeneratedColumn<String>('value_type', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<TagValueType>(
              $TagDefinitionsTable.$convertervalueType);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
      'color', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, name, valueType, color];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tag_definitions';
  @override
  VerificationContext validateIntegrity(Insertable<TagDefinition> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TagDefinition map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagDefinition(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      valueType: $TagDefinitionsTable.$convertervalueType.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}value_type'])!),
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color']),
    );
  }

  @override
  $TagDefinitionsTable createAlias(String alias) {
    return $TagDefinitionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TagValueType, String, String> $convertervalueType =
      const EnumNameConverter<TagValueType>(TagValueType.values);
}

class TagDefinition extends DataClass implements Insertable<TagDefinition> {
  final int id;

  /// 사용자에게 보이는 태그 이름. 중복 정의를 막는다.
  final String name;

  /// 값 해석 방식. 이름 기반으로 저장해 enum 순서 변경에 영향받지 않는다.
  final TagValueType valueType;

  /// 표시용 색상(ARGB). 미지정 가능.
  final int? color;
  const TagDefinition(
      {required this.id,
      required this.name,
      required this.valueType,
      this.color});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['value_type'] = Variable<String>(
          $TagDefinitionsTable.$convertervalueType.toSql(valueType));
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    return map;
  }

  TagDefinitionsCompanion toCompanion(bool nullToAbsent) {
    return TagDefinitionsCompanion(
      id: Value(id),
      name: Value(name),
      valueType: Value(valueType),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
    );
  }

  factory TagDefinition.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagDefinition(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      valueType: $TagDefinitionsTable.$convertervalueType
          .fromJson(serializer.fromJson<String>(json['valueType'])),
      color: serializer.fromJson<int?>(json['color']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'valueType': serializer.toJson<String>(
          $TagDefinitionsTable.$convertervalueType.toJson(valueType)),
      'color': serializer.toJson<int?>(color),
    };
  }

  TagDefinition copyWith(
          {int? id,
          String? name,
          TagValueType? valueType,
          Value<int?> color = const Value.absent()}) =>
      TagDefinition(
        id: id ?? this.id,
        name: name ?? this.name,
        valueType: valueType ?? this.valueType,
        color: color.present ? color.value : this.color,
      );
  TagDefinition copyWithCompanion(TagDefinitionsCompanion data) {
    return TagDefinition(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      valueType: data.valueType.present ? data.valueType.value : this.valueType,
      color: data.color.present ? data.color.value : this.color,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagDefinition(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('valueType: $valueType, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, valueType, color);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagDefinition &&
          other.id == this.id &&
          other.name == this.name &&
          other.valueType == this.valueType &&
          other.color == this.color);
}

class TagDefinitionsCompanion extends UpdateCompanion<TagDefinition> {
  final Value<int> id;
  final Value<String> name;
  final Value<TagValueType> valueType;
  final Value<int?> color;
  const TagDefinitionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.valueType = const Value.absent(),
    this.color = const Value.absent(),
  });
  TagDefinitionsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required TagValueType valueType,
    this.color = const Value.absent(),
  })  : name = Value(name),
        valueType = Value(valueType);
  static Insertable<TagDefinition> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? valueType,
    Expression<int>? color,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (valueType != null) 'value_type': valueType,
      if (color != null) 'color': color,
    });
  }

  TagDefinitionsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<TagValueType>? valueType,
      Value<int?>? color}) {
    return TagDefinitionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      valueType: valueType ?? this.valueType,
      color: color ?? this.color,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (valueType.present) {
      map['value_type'] = Variable<String>(
          $TagDefinitionsTable.$convertervalueType.toSql(valueType.value));
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagDefinitionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('valueType: $valueType, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }
}

class $FileNodesTable extends FileNodes
    with TableInfo<$FileNodesTable, FileNode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FileNodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
      'path', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _isDirectoryMeta =
      const VerificationMeta('isDirectory');
  @override
  late final GeneratedColumn<bool> isDirectory = GeneratedColumn<bool>(
      'is_directory', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_directory" IN (0, 1))'));
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
      'size', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _modifiedAtMeta =
      const VerificationMeta('modifiedAt');
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
      'modified_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _contentHashPrefixMeta =
      const VerificationMeta('contentHashPrefix');
  @override
  late final GeneratedColumn<String> contentHashPrefix =
      GeneratedColumn<String>('content_hash_prefix', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastSeenAtMeta =
      const VerificationMeta('lastSeenAt');
  @override
  late final GeneratedColumn<DateTime> lastSeenAt = GeneratedColumn<DateTime>(
      'last_seen_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, path, isDirectory, size, modifiedAt, contentHashPrefix, lastSeenAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'file_nodes';
  @override
  VerificationContext validateIntegrity(Insertable<FileNode> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('path')) {
      context.handle(
          _pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('is_directory')) {
      context.handle(
          _isDirectoryMeta,
          isDirectory.isAcceptableOrUnknown(
              data['is_directory']!, _isDirectoryMeta));
    } else if (isInserting) {
      context.missing(_isDirectoryMeta);
    }
    if (data.containsKey('size')) {
      context.handle(
          _sizeMeta, size.isAcceptableOrUnknown(data['size']!, _sizeMeta));
    }
    if (data.containsKey('modified_at')) {
      context.handle(
          _modifiedAtMeta,
          modifiedAt.isAcceptableOrUnknown(
              data['modified_at']!, _modifiedAtMeta));
    }
    if (data.containsKey('content_hash_prefix')) {
      context.handle(
          _contentHashPrefixMeta,
          contentHashPrefix.isAcceptableOrUnknown(
              data['content_hash_prefix']!, _contentHashPrefixMeta));
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
          _lastSeenAtMeta,
          lastSeenAt.isAcceptableOrUnknown(
              data['last_seen_at']!, _lastSeenAtMeta));
    } else if (isInserting) {
      context.missing(_lastSeenAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FileNode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FileNode(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      path: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}path'])!,
      isDirectory: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_directory'])!,
      size: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}size']),
      modifiedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}modified_at']),
      contentHashPrefix: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}content_hash_prefix']),
      lastSeenAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_seen_at'])!,
    );
  }

  @override
  $FileNodesTable createAlias(String alias) {
    return $FileNodesTable(attachedDatabase, alias);
  }
}

class FileNode extends DataClass implements Insertable<FileNode> {
  final int id;

  /// 관리 폴더 루트 기준 경로. 같은 노드를 한 번만 인덱싱한다.
  final String path;
  final bool isDirectory;

  /// 파일 크기. 폴더 등 의미 없는 경우 미지정.
  final int? size;
  final DateTime? modifiedAt;

  /// 이동 추적 시 동일 파일 후보를 가리기 위한 내용 부분 해시.
  final String? contentHashPrefix;

  /// 마지막 스캔에서 관측된 시각. 삭제 감지/정리에 쓰인다.
  final DateTime lastSeenAt;
  const FileNode(
      {required this.id,
      required this.path,
      required this.isDirectory,
      this.size,
      this.modifiedAt,
      this.contentHashPrefix,
      required this.lastSeenAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['path'] = Variable<String>(path);
    map['is_directory'] = Variable<bool>(isDirectory);
    if (!nullToAbsent || size != null) {
      map['size'] = Variable<int>(size);
    }
    if (!nullToAbsent || modifiedAt != null) {
      map['modified_at'] = Variable<DateTime>(modifiedAt);
    }
    if (!nullToAbsent || contentHashPrefix != null) {
      map['content_hash_prefix'] = Variable<String>(contentHashPrefix);
    }
    map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    return map;
  }

  FileNodesCompanion toCompanion(bool nullToAbsent) {
    return FileNodesCompanion(
      id: Value(id),
      path: Value(path),
      isDirectory: Value(isDirectory),
      size: size == null && nullToAbsent ? const Value.absent() : Value(size),
      modifiedAt: modifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(modifiedAt),
      contentHashPrefix: contentHashPrefix == null && nullToAbsent
          ? const Value.absent()
          : Value(contentHashPrefix),
      lastSeenAt: Value(lastSeenAt),
    );
  }

  factory FileNode.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FileNode(
      id: serializer.fromJson<int>(json['id']),
      path: serializer.fromJson<String>(json['path']),
      isDirectory: serializer.fromJson<bool>(json['isDirectory']),
      size: serializer.fromJson<int?>(json['size']),
      modifiedAt: serializer.fromJson<DateTime?>(json['modifiedAt']),
      contentHashPrefix:
          serializer.fromJson<String?>(json['contentHashPrefix']),
      lastSeenAt: serializer.fromJson<DateTime>(json['lastSeenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'path': serializer.toJson<String>(path),
      'isDirectory': serializer.toJson<bool>(isDirectory),
      'size': serializer.toJson<int?>(size),
      'modifiedAt': serializer.toJson<DateTime?>(modifiedAt),
      'contentHashPrefix': serializer.toJson<String?>(contentHashPrefix),
      'lastSeenAt': serializer.toJson<DateTime>(lastSeenAt),
    };
  }

  FileNode copyWith(
          {int? id,
          String? path,
          bool? isDirectory,
          Value<int?> size = const Value.absent(),
          Value<DateTime?> modifiedAt = const Value.absent(),
          Value<String?> contentHashPrefix = const Value.absent(),
          DateTime? lastSeenAt}) =>
      FileNode(
        id: id ?? this.id,
        path: path ?? this.path,
        isDirectory: isDirectory ?? this.isDirectory,
        size: size.present ? size.value : this.size,
        modifiedAt: modifiedAt.present ? modifiedAt.value : this.modifiedAt,
        contentHashPrefix: contentHashPrefix.present
            ? contentHashPrefix.value
            : this.contentHashPrefix,
        lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      );
  FileNode copyWithCompanion(FileNodesCompanion data) {
    return FileNode(
      id: data.id.present ? data.id.value : this.id,
      path: data.path.present ? data.path.value : this.path,
      isDirectory:
          data.isDirectory.present ? data.isDirectory.value : this.isDirectory,
      size: data.size.present ? data.size.value : this.size,
      modifiedAt:
          data.modifiedAt.present ? data.modifiedAt.value : this.modifiedAt,
      contentHashPrefix: data.contentHashPrefix.present
          ? data.contentHashPrefix.value
          : this.contentHashPrefix,
      lastSeenAt:
          data.lastSeenAt.present ? data.lastSeenAt.value : this.lastSeenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FileNode(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('isDirectory: $isDirectory, ')
          ..write('size: $size, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('contentHashPrefix: $contentHashPrefix, ')
          ..write('lastSeenAt: $lastSeenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, path, isDirectory, size, modifiedAt, contentHashPrefix, lastSeenAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FileNode &&
          other.id == this.id &&
          other.path == this.path &&
          other.isDirectory == this.isDirectory &&
          other.size == this.size &&
          other.modifiedAt == this.modifiedAt &&
          other.contentHashPrefix == this.contentHashPrefix &&
          other.lastSeenAt == this.lastSeenAt);
}

class FileNodesCompanion extends UpdateCompanion<FileNode> {
  final Value<int> id;
  final Value<String> path;
  final Value<bool> isDirectory;
  final Value<int?> size;
  final Value<DateTime?> modifiedAt;
  final Value<String?> contentHashPrefix;
  final Value<DateTime> lastSeenAt;
  const FileNodesCompanion({
    this.id = const Value.absent(),
    this.path = const Value.absent(),
    this.isDirectory = const Value.absent(),
    this.size = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.contentHashPrefix = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
  });
  FileNodesCompanion.insert({
    this.id = const Value.absent(),
    required String path,
    required bool isDirectory,
    this.size = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.contentHashPrefix = const Value.absent(),
    required DateTime lastSeenAt,
  })  : path = Value(path),
        isDirectory = Value(isDirectory),
        lastSeenAt = Value(lastSeenAt);
  static Insertable<FileNode> custom({
    Expression<int>? id,
    Expression<String>? path,
    Expression<bool>? isDirectory,
    Expression<int>? size,
    Expression<DateTime>? modifiedAt,
    Expression<String>? contentHashPrefix,
    Expression<DateTime>? lastSeenAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (path != null) 'path': path,
      if (isDirectory != null) 'is_directory': isDirectory,
      if (size != null) 'size': size,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (contentHashPrefix != null) 'content_hash_prefix': contentHashPrefix,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
    });
  }

  FileNodesCompanion copyWith(
      {Value<int>? id,
      Value<String>? path,
      Value<bool>? isDirectory,
      Value<int?>? size,
      Value<DateTime?>? modifiedAt,
      Value<String?>? contentHashPrefix,
      Value<DateTime>? lastSeenAt}) {
    return FileNodesCompanion(
      id: id ?? this.id,
      path: path ?? this.path,
      isDirectory: isDirectory ?? this.isDirectory,
      size: size ?? this.size,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      contentHashPrefix: contentHashPrefix ?? this.contentHashPrefix,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (isDirectory.present) {
      map['is_directory'] = Variable<bool>(isDirectory.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (contentHashPrefix.present) {
      map['content_hash_prefix'] = Variable<String>(contentHashPrefix.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FileNodesCompanion(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('isDirectory: $isDirectory, ')
          ..write('size: $size, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('contentHashPrefix: $contentHashPrefix, ')
          ..write('lastSeenAt: $lastSeenAt')
          ..write(')'))
        .toString();
  }
}

class $TagAssignmentsTable extends TagAssignments
    with TableInfo<$TagAssignmentsTable, TagAssignment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagAssignmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _fileNodeIdMeta =
      const VerificationMeta('fileNodeId');
  @override
  late final GeneratedColumn<int> fileNodeId = GeneratedColumn<int>(
      'file_node_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES file_nodes (id) ON DELETE CASCADE'));
  static const VerificationMeta _tagDefinitionIdMeta =
      const VerificationMeta('tagDefinitionId');
  @override
  late final GeneratedColumn<int> tagDefinitionId = GeneratedColumn<int>(
      'tag_definition_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES tag_definitions (id) ON DELETE CASCADE'));
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, fileNodeId, tagDefinitionId, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tag_assignments';
  @override
  VerificationContext validateIntegrity(Insertable<TagAssignment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('file_node_id')) {
      context.handle(
          _fileNodeIdMeta,
          fileNodeId.isAcceptableOrUnknown(
              data['file_node_id']!, _fileNodeIdMeta));
    } else if (isInserting) {
      context.missing(_fileNodeIdMeta);
    }
    if (data.containsKey('tag_definition_id')) {
      context.handle(
          _tagDefinitionIdMeta,
          tagDefinitionId.isAcceptableOrUnknown(
              data['tag_definition_id']!, _tagDefinitionIdMeta));
    } else if (isInserting) {
      context.missing(_tagDefinitionIdMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TagAssignment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagAssignment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      fileNodeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_node_id'])!,
      tagDefinitionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tag_definition_id'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value']),
    );
  }

  @override
  $TagAssignmentsTable createAlias(String alias) {
    return $TagAssignmentsTable(attachedDatabase, alias);
  }
}

class TagAssignment extends DataClass implements Insertable<TagAssignment> {
  final int id;
  final int fileNodeId;
  final int tagDefinitionId;

  /// 부여된 값. label 유형 등 값이 없으면 미지정.
  final String? value;
  const TagAssignment(
      {required this.id,
      required this.fileNodeId,
      required this.tagDefinitionId,
      this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['file_node_id'] = Variable<int>(fileNodeId);
    map['tag_definition_id'] = Variable<int>(tagDefinitionId);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  TagAssignmentsCompanion toCompanion(bool nullToAbsent) {
    return TagAssignmentsCompanion(
      id: Value(id),
      fileNodeId: Value(fileNodeId),
      tagDefinitionId: Value(tagDefinitionId),
      value:
          value == null && nullToAbsent ? const Value.absent() : Value(value),
    );
  }

  factory TagAssignment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagAssignment(
      id: serializer.fromJson<int>(json['id']),
      fileNodeId: serializer.fromJson<int>(json['fileNodeId']),
      tagDefinitionId: serializer.fromJson<int>(json['tagDefinitionId']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fileNodeId': serializer.toJson<int>(fileNodeId),
      'tagDefinitionId': serializer.toJson<int>(tagDefinitionId),
      'value': serializer.toJson<String?>(value),
    };
  }

  TagAssignment copyWith(
          {int? id,
          int? fileNodeId,
          int? tagDefinitionId,
          Value<String?> value = const Value.absent()}) =>
      TagAssignment(
        id: id ?? this.id,
        fileNodeId: fileNodeId ?? this.fileNodeId,
        tagDefinitionId: tagDefinitionId ?? this.tagDefinitionId,
        value: value.present ? value.value : this.value,
      );
  TagAssignment copyWithCompanion(TagAssignmentsCompanion data) {
    return TagAssignment(
      id: data.id.present ? data.id.value : this.id,
      fileNodeId:
          data.fileNodeId.present ? data.fileNodeId.value : this.fileNodeId,
      tagDefinitionId: data.tagDefinitionId.present
          ? data.tagDefinitionId.value
          : this.tagDefinitionId,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagAssignment(')
          ..write('id: $id, ')
          ..write('fileNodeId: $fileNodeId, ')
          ..write('tagDefinitionId: $tagDefinitionId, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fileNodeId, tagDefinitionId, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagAssignment &&
          other.id == this.id &&
          other.fileNodeId == this.fileNodeId &&
          other.tagDefinitionId == this.tagDefinitionId &&
          other.value == this.value);
}

class TagAssignmentsCompanion extends UpdateCompanion<TagAssignment> {
  final Value<int> id;
  final Value<int> fileNodeId;
  final Value<int> tagDefinitionId;
  final Value<String?> value;
  const TagAssignmentsCompanion({
    this.id = const Value.absent(),
    this.fileNodeId = const Value.absent(),
    this.tagDefinitionId = const Value.absent(),
    this.value = const Value.absent(),
  });
  TagAssignmentsCompanion.insert({
    this.id = const Value.absent(),
    required int fileNodeId,
    required int tagDefinitionId,
    this.value = const Value.absent(),
  })  : fileNodeId = Value(fileNodeId),
        tagDefinitionId = Value(tagDefinitionId);
  static Insertable<TagAssignment> custom({
    Expression<int>? id,
    Expression<int>? fileNodeId,
    Expression<int>? tagDefinitionId,
    Expression<String>? value,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fileNodeId != null) 'file_node_id': fileNodeId,
      if (tagDefinitionId != null) 'tag_definition_id': tagDefinitionId,
      if (value != null) 'value': value,
    });
  }

  TagAssignmentsCompanion copyWith(
      {Value<int>? id,
      Value<int>? fileNodeId,
      Value<int>? tagDefinitionId,
      Value<String?>? value}) {
    return TagAssignmentsCompanion(
      id: id ?? this.id,
      fileNodeId: fileNodeId ?? this.fileNodeId,
      tagDefinitionId: tagDefinitionId ?? this.tagDefinitionId,
      value: value ?? this.value,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fileNodeId.present) {
      map['file_node_id'] = Variable<int>(fileNodeId.value);
    }
    if (tagDefinitionId.present) {
      map['tag_definition_id'] = Variable<int>(tagDefinitionId.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagAssignmentsCompanion(')
          ..write('id: $id, ')
          ..write('fileNodeId: $fileNodeId, ')
          ..write('tagDefinitionId: $tagDefinitionId, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TagDefinitionsTable tagDefinitions = $TagDefinitionsTable(this);
  late final $FileNodesTable fileNodes = $FileNodesTable(this);
  late final $TagAssignmentsTable tagAssignments = $TagAssignmentsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [tagDefinitions, fileNodes, tagAssignments];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('file_nodes',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('tag_assignments', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('tag_definitions',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('tag_assignments', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$TagDefinitionsTableCreateCompanionBuilder = TagDefinitionsCompanion
    Function({
  Value<int> id,
  required String name,
  required TagValueType valueType,
  Value<int?> color,
});
typedef $$TagDefinitionsTableUpdateCompanionBuilder = TagDefinitionsCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<TagValueType> valueType,
  Value<int?> color,
});

final class $$TagDefinitionsTableReferences
    extends BaseReferences<_$AppDatabase, $TagDefinitionsTable, TagDefinition> {
  $$TagDefinitionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TagAssignmentsTable, List<TagAssignment>>
      _tagAssignmentsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.tagAssignments,
              aliasName: $_aliasNameGenerator(
                  db.tagDefinitions.id, db.tagAssignments.tagDefinitionId));

  $$TagAssignmentsTableProcessedTableManager get tagAssignmentsRefs {
    final manager = $$TagAssignmentsTableTableManager($_db, $_db.tagAssignments)
        .filter(
            (f) => f.tagDefinitionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_tagAssignmentsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TagDefinitionsTableFilterComposer
    extends Composer<_$AppDatabase, $TagDefinitionsTable> {
  $$TagDefinitionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<TagValueType, TagValueType, String>
      get valueType => $composableBuilder(
          column: $table.valueType,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  Expression<bool> tagAssignmentsRefs(
      Expression<bool> Function($$TagAssignmentsTableFilterComposer f) f) {
    final $$TagAssignmentsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.tagAssignments,
        getReferencedColumn: (t) => t.tagDefinitionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TagAssignmentsTableFilterComposer(
              $db: $db,
              $table: $db.tagAssignments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TagDefinitionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TagDefinitionsTable> {
  $$TagDefinitionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get valueType => $composableBuilder(
      column: $table.valueType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));
}

class $$TagDefinitionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagDefinitionsTable> {
  $$TagDefinitionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TagValueType, String> get valueType =>
      $composableBuilder(column: $table.valueType, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  Expression<T> tagAssignmentsRefs<T extends Object>(
      Expression<T> Function($$TagAssignmentsTableAnnotationComposer a) f) {
    final $$TagAssignmentsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.tagAssignments,
        getReferencedColumn: (t) => t.tagDefinitionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TagAssignmentsTableAnnotationComposer(
              $db: $db,
              $table: $db.tagAssignments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TagDefinitionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TagDefinitionsTable,
    TagDefinition,
    $$TagDefinitionsTableFilterComposer,
    $$TagDefinitionsTableOrderingComposer,
    $$TagDefinitionsTableAnnotationComposer,
    $$TagDefinitionsTableCreateCompanionBuilder,
    $$TagDefinitionsTableUpdateCompanionBuilder,
    (TagDefinition, $$TagDefinitionsTableReferences),
    TagDefinition,
    PrefetchHooks Function({bool tagAssignmentsRefs})> {
  $$TagDefinitionsTableTableManager(
      _$AppDatabase db, $TagDefinitionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagDefinitionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagDefinitionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagDefinitionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<TagValueType> valueType = const Value.absent(),
            Value<int?> color = const Value.absent(),
          }) =>
              TagDefinitionsCompanion(
            id: id,
            name: name,
            valueType: valueType,
            color: color,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required TagValueType valueType,
            Value<int?> color = const Value.absent(),
          }) =>
              TagDefinitionsCompanion.insert(
            id: id,
            name: name,
            valueType: valueType,
            color: color,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TagDefinitionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({tagAssignmentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (tagAssignmentsRefs) db.tagAssignments
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (tagAssignmentsRefs)
                    await $_getPrefetchedData<TagDefinition,
                            $TagDefinitionsTable, TagAssignment>(
                        currentTable: table,
                        referencedTable: $$TagDefinitionsTableReferences
                            ._tagAssignmentsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TagDefinitionsTableReferences(db, table, p0)
                                .tagAssignmentsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.tagDefinitionId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TagDefinitionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TagDefinitionsTable,
    TagDefinition,
    $$TagDefinitionsTableFilterComposer,
    $$TagDefinitionsTableOrderingComposer,
    $$TagDefinitionsTableAnnotationComposer,
    $$TagDefinitionsTableCreateCompanionBuilder,
    $$TagDefinitionsTableUpdateCompanionBuilder,
    (TagDefinition, $$TagDefinitionsTableReferences),
    TagDefinition,
    PrefetchHooks Function({bool tagAssignmentsRefs})>;
typedef $$FileNodesTableCreateCompanionBuilder = FileNodesCompanion Function({
  Value<int> id,
  required String path,
  required bool isDirectory,
  Value<int?> size,
  Value<DateTime?> modifiedAt,
  Value<String?> contentHashPrefix,
  required DateTime lastSeenAt,
});
typedef $$FileNodesTableUpdateCompanionBuilder = FileNodesCompanion Function({
  Value<int> id,
  Value<String> path,
  Value<bool> isDirectory,
  Value<int?> size,
  Value<DateTime?> modifiedAt,
  Value<String?> contentHashPrefix,
  Value<DateTime> lastSeenAt,
});

final class $$FileNodesTableReferences
    extends BaseReferences<_$AppDatabase, $FileNodesTable, FileNode> {
  $$FileNodesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TagAssignmentsTable, List<TagAssignment>>
      _tagAssignmentsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.tagAssignments,
              aliasName: $_aliasNameGenerator(
                  db.fileNodes.id, db.tagAssignments.fileNodeId));

  $$TagAssignmentsTableProcessedTableManager get tagAssignmentsRefs {
    final manager = $$TagAssignmentsTableTableManager($_db, $_db.tagAssignments)
        .filter((f) => f.fileNodeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_tagAssignmentsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$FileNodesTableFilterComposer
    extends Composer<_$AppDatabase, $FileNodesTable> {
  $$FileNodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDirectory => $composableBuilder(
      column: $table.isDirectory, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get size => $composableBuilder(
      column: $table.size, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
      column: $table.modifiedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentHashPrefix => $composableBuilder(
      column: $table.contentHashPrefix,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSeenAt => $composableBuilder(
      column: $table.lastSeenAt, builder: (column) => ColumnFilters(column));

  Expression<bool> tagAssignmentsRefs(
      Expression<bool> Function($$TagAssignmentsTableFilterComposer f) f) {
    final $$TagAssignmentsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.tagAssignments,
        getReferencedColumn: (t) => t.fileNodeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TagAssignmentsTableFilterComposer(
              $db: $db,
              $table: $db.tagAssignments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$FileNodesTableOrderingComposer
    extends Composer<_$AppDatabase, $FileNodesTable> {
  $$FileNodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDirectory => $composableBuilder(
      column: $table.isDirectory, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get size => $composableBuilder(
      column: $table.size, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
      column: $table.modifiedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentHashPrefix => $composableBuilder(
      column: $table.contentHashPrefix,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSeenAt => $composableBuilder(
      column: $table.lastSeenAt, builder: (column) => ColumnOrderings(column));
}

class $$FileNodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FileNodesTable> {
  $$FileNodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<bool> get isDirectory => $composableBuilder(
      column: $table.isDirectory, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
      column: $table.modifiedAt, builder: (column) => column);

  GeneratedColumn<String> get contentHashPrefix => $composableBuilder(
      column: $table.contentHashPrefix, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSeenAt => $composableBuilder(
      column: $table.lastSeenAt, builder: (column) => column);

  Expression<T> tagAssignmentsRefs<T extends Object>(
      Expression<T> Function($$TagAssignmentsTableAnnotationComposer a) f) {
    final $$TagAssignmentsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.tagAssignments,
        getReferencedColumn: (t) => t.fileNodeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TagAssignmentsTableAnnotationComposer(
              $db: $db,
              $table: $db.tagAssignments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$FileNodesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FileNodesTable,
    FileNode,
    $$FileNodesTableFilterComposer,
    $$FileNodesTableOrderingComposer,
    $$FileNodesTableAnnotationComposer,
    $$FileNodesTableCreateCompanionBuilder,
    $$FileNodesTableUpdateCompanionBuilder,
    (FileNode, $$FileNodesTableReferences),
    FileNode,
    PrefetchHooks Function({bool tagAssignmentsRefs})> {
  $$FileNodesTableTableManager(_$AppDatabase db, $FileNodesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FileNodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FileNodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FileNodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> path = const Value.absent(),
            Value<bool> isDirectory = const Value.absent(),
            Value<int?> size = const Value.absent(),
            Value<DateTime?> modifiedAt = const Value.absent(),
            Value<String?> contentHashPrefix = const Value.absent(),
            Value<DateTime> lastSeenAt = const Value.absent(),
          }) =>
              FileNodesCompanion(
            id: id,
            path: path,
            isDirectory: isDirectory,
            size: size,
            modifiedAt: modifiedAt,
            contentHashPrefix: contentHashPrefix,
            lastSeenAt: lastSeenAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String path,
            required bool isDirectory,
            Value<int?> size = const Value.absent(),
            Value<DateTime?> modifiedAt = const Value.absent(),
            Value<String?> contentHashPrefix = const Value.absent(),
            required DateTime lastSeenAt,
          }) =>
              FileNodesCompanion.insert(
            id: id,
            path: path,
            isDirectory: isDirectory,
            size: size,
            modifiedAt: modifiedAt,
            contentHashPrefix: contentHashPrefix,
            lastSeenAt: lastSeenAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$FileNodesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({tagAssignmentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (tagAssignmentsRefs) db.tagAssignments
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (tagAssignmentsRefs)
                    await $_getPrefetchedData<FileNode, $FileNodesTable,
                            TagAssignment>(
                        currentTable: table,
                        referencedTable: $$FileNodesTableReferences
                            ._tagAssignmentsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$FileNodesTableReferences(db, table, p0)
                                .tagAssignmentsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.fileNodeId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$FileNodesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FileNodesTable,
    FileNode,
    $$FileNodesTableFilterComposer,
    $$FileNodesTableOrderingComposer,
    $$FileNodesTableAnnotationComposer,
    $$FileNodesTableCreateCompanionBuilder,
    $$FileNodesTableUpdateCompanionBuilder,
    (FileNode, $$FileNodesTableReferences),
    FileNode,
    PrefetchHooks Function({bool tagAssignmentsRefs})>;
typedef $$TagAssignmentsTableCreateCompanionBuilder = TagAssignmentsCompanion
    Function({
  Value<int> id,
  required int fileNodeId,
  required int tagDefinitionId,
  Value<String?> value,
});
typedef $$TagAssignmentsTableUpdateCompanionBuilder = TagAssignmentsCompanion
    Function({
  Value<int> id,
  Value<int> fileNodeId,
  Value<int> tagDefinitionId,
  Value<String?> value,
});

final class $$TagAssignmentsTableReferences
    extends BaseReferences<_$AppDatabase, $TagAssignmentsTable, TagAssignment> {
  $$TagAssignmentsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $FileNodesTable _fileNodeIdTable(_$AppDatabase db) =>
      db.fileNodes.createAlias(
          $_aliasNameGenerator(db.tagAssignments.fileNodeId, db.fileNodes.id));

  $$FileNodesTableProcessedTableManager get fileNodeId {
    final $_column = $_itemColumn<int>('file_node_id')!;

    final manager = $$FileNodesTableTableManager($_db, $_db.fileNodes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fileNodeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $TagDefinitionsTable _tagDefinitionIdTable(_$AppDatabase db) =>
      db.tagDefinitions.createAlias($_aliasNameGenerator(
          db.tagAssignments.tagDefinitionId, db.tagDefinitions.id));

  $$TagDefinitionsTableProcessedTableManager get tagDefinitionId {
    final $_column = $_itemColumn<int>('tag_definition_id')!;

    final manager = $$TagDefinitionsTableTableManager($_db, $_db.tagDefinitions)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagDefinitionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TagAssignmentsTableFilterComposer
    extends Composer<_$AppDatabase, $TagAssignmentsTable> {
  $$TagAssignmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  $$FileNodesTableFilterComposer get fileNodeId {
    final $$FileNodesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fileNodeId,
        referencedTable: $db.fileNodes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FileNodesTableFilterComposer(
              $db: $db,
              $table: $db.fileNodes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TagDefinitionsTableFilterComposer get tagDefinitionId {
    final $$TagDefinitionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tagDefinitionId,
        referencedTable: $db.tagDefinitions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TagDefinitionsTableFilterComposer(
              $db: $db,
              $table: $db.tagDefinitions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TagAssignmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $TagAssignmentsTable> {
  $$TagAssignmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  $$FileNodesTableOrderingComposer get fileNodeId {
    final $$FileNodesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fileNodeId,
        referencedTable: $db.fileNodes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FileNodesTableOrderingComposer(
              $db: $db,
              $table: $db.fileNodes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TagDefinitionsTableOrderingComposer get tagDefinitionId {
    final $$TagDefinitionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tagDefinitionId,
        referencedTable: $db.tagDefinitions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TagDefinitionsTableOrderingComposer(
              $db: $db,
              $table: $db.tagDefinitions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TagAssignmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagAssignmentsTable> {
  $$TagAssignmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  $$FileNodesTableAnnotationComposer get fileNodeId {
    final $$FileNodesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fileNodeId,
        referencedTable: $db.fileNodes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FileNodesTableAnnotationComposer(
              $db: $db,
              $table: $db.fileNodes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TagDefinitionsTableAnnotationComposer get tagDefinitionId {
    final $$TagDefinitionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tagDefinitionId,
        referencedTable: $db.tagDefinitions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TagDefinitionsTableAnnotationComposer(
              $db: $db,
              $table: $db.tagDefinitions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TagAssignmentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TagAssignmentsTable,
    TagAssignment,
    $$TagAssignmentsTableFilterComposer,
    $$TagAssignmentsTableOrderingComposer,
    $$TagAssignmentsTableAnnotationComposer,
    $$TagAssignmentsTableCreateCompanionBuilder,
    $$TagAssignmentsTableUpdateCompanionBuilder,
    (TagAssignment, $$TagAssignmentsTableReferences),
    TagAssignment,
    PrefetchHooks Function({bool fileNodeId, bool tagDefinitionId})> {
  $$TagAssignmentsTableTableManager(
      _$AppDatabase db, $TagAssignmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagAssignmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagAssignmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagAssignmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> fileNodeId = const Value.absent(),
            Value<int> tagDefinitionId = const Value.absent(),
            Value<String?> value = const Value.absent(),
          }) =>
              TagAssignmentsCompanion(
            id: id,
            fileNodeId: fileNodeId,
            tagDefinitionId: tagDefinitionId,
            value: value,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int fileNodeId,
            required int tagDefinitionId,
            Value<String?> value = const Value.absent(),
          }) =>
              TagAssignmentsCompanion.insert(
            id: id,
            fileNodeId: fileNodeId,
            tagDefinitionId: tagDefinitionId,
            value: value,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TagAssignmentsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {fileNodeId = false, tagDefinitionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (fileNodeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.fileNodeId,
                    referencedTable:
                        $$TagAssignmentsTableReferences._fileNodeIdTable(db),
                    referencedColumn:
                        $$TagAssignmentsTableReferences._fileNodeIdTable(db).id,
                  ) as T;
                }
                if (tagDefinitionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.tagDefinitionId,
                    referencedTable: $$TagAssignmentsTableReferences
                        ._tagDefinitionIdTable(db),
                    referencedColumn: $$TagAssignmentsTableReferences
                        ._tagDefinitionIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TagAssignmentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TagAssignmentsTable,
    TagAssignment,
    $$TagAssignmentsTableFilterComposer,
    $$TagAssignmentsTableOrderingComposer,
    $$TagAssignmentsTableAnnotationComposer,
    $$TagAssignmentsTableCreateCompanionBuilder,
    $$TagAssignmentsTableUpdateCompanionBuilder,
    (TagAssignment, $$TagAssignmentsTableReferences),
    TagAssignment,
    PrefetchHooks Function({bool fileNodeId, bool tagDefinitionId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TagDefinitionsTableTableManager get tagDefinitions =>
      $$TagDefinitionsTableTableManager(_db, _db.tagDefinitions);
  $$FileNodesTableTableManager get fileNodes =>
      $$FileNodesTableTableManager(_db, _db.fileNodes);
  $$TagAssignmentsTableTableManager get tagAssignments =>
      $$TagAssignmentsTableTableManager(_db, _db.tagAssignments);
}
