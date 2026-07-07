// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TagDefinitionsTable extends TagDefinitions
    with TableInfo<$TagDefinitionsTable, TagDefinitionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagDefinitionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<TagValueType, String> valueType =
      GeneratedColumn<String>(
        'value_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TagValueType>($TagDefinitionsTable.$convertervalueType);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _allowMultipleMeta = const VerificationMeta(
    'allowMultiple',
  );
  @override
  late final GeneratedColumn<bool> allowMultiple = GeneratedColumn<bool>(
    'allow_multiple',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("allow_multiple" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    valueType,
    color,
    allowMultiple,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tag_definitions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TagDefinitionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('allow_multiple')) {
      context.handle(
        _allowMultipleMeta,
        allowMultiple.isAcceptableOrUnknown(
          data['allow_multiple']!,
          _allowMultipleMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TagDefinitionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagDefinitionRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      valueType: $TagDefinitionsTable.$convertervalueType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}value_type'],
        )!,
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      ),
      allowMultiple:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}allow_multiple'],
          )!,
    );
  }

  @override
  $TagDefinitionsTable createAlias(String alias) {
    return $TagDefinitionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TagValueType, String, String> $convertervalueType =
      const EnumNameConverter<TagValueType>(TagValueType.values);
}

class TagDefinitionRow extends DataClass
    implements Insertable<TagDefinitionRow> {
  final int id;

  /// 사용자에게 보이는 태그 이름. 중복 정의를 막는다.
  final String name;

  /// 값 해석 방식. 이름 기반으로 저장해 enum 순서 변경에 영향받지 않는다.
  final TagValueType valueType;

  /// 표시용 색상(ARGB). 미지정 가능.
  final int? color;

  /// 한 파일에 이 태그를 여러 번 부여할 수 있는지. 태그 생성 시 사용자가 정한다.
  /// 불가면 (파일,태그)당 1회로 재부여 시 값이 갱신되고, 허용이면 다중 부여를
  /// 허용한다. 유형에 따라 달라 DB 유니크 인덱스로 못 걸어 저장소가 강제한다.
  final bool allowMultiple;
  const TagDefinitionRow({
    required this.id,
    required this.name,
    required this.valueType,
    this.color,
    required this.allowMultiple,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['value_type'] = Variable<String>(
        $TagDefinitionsTable.$convertervalueType.toSql(valueType),
      );
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    map['allow_multiple'] = Variable<bool>(allowMultiple);
    return map;
  }

  TagDefinitionsCompanion toCompanion(bool nullToAbsent) {
    return TagDefinitionsCompanion(
      id: Value(id),
      name: Value(name),
      valueType: Value(valueType),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      allowMultiple: Value(allowMultiple),
    );
  }

  factory TagDefinitionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagDefinitionRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      valueType: $TagDefinitionsTable.$convertervalueType.fromJson(
        serializer.fromJson<String>(json['valueType']),
      ),
      color: serializer.fromJson<int?>(json['color']),
      allowMultiple: serializer.fromJson<bool>(json['allowMultiple']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'valueType': serializer.toJson<String>(
        $TagDefinitionsTable.$convertervalueType.toJson(valueType),
      ),
      'color': serializer.toJson<int?>(color),
      'allowMultiple': serializer.toJson<bool>(allowMultiple),
    };
  }

  TagDefinitionRow copyWith({
    int? id,
    String? name,
    TagValueType? valueType,
    Value<int?> color = const Value.absent(),
    bool? allowMultiple,
  }) => TagDefinitionRow(
    id: id ?? this.id,
    name: name ?? this.name,
    valueType: valueType ?? this.valueType,
    color: color.present ? color.value : this.color,
    allowMultiple: allowMultiple ?? this.allowMultiple,
  );
  TagDefinitionRow copyWithCompanion(TagDefinitionsCompanion data) {
    return TagDefinitionRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      valueType: data.valueType.present ? data.valueType.value : this.valueType,
      color: data.color.present ? data.color.value : this.color,
      allowMultiple:
          data.allowMultiple.present
              ? data.allowMultiple.value
              : this.allowMultiple,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagDefinitionRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('valueType: $valueType, ')
          ..write('color: $color, ')
          ..write('allowMultiple: $allowMultiple')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, valueType, color, allowMultiple);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagDefinitionRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.valueType == this.valueType &&
          other.color == this.color &&
          other.allowMultiple == this.allowMultiple);
}

class TagDefinitionsCompanion extends UpdateCompanion<TagDefinitionRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<TagValueType> valueType;
  final Value<int?> color;
  final Value<bool> allowMultiple;
  const TagDefinitionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.valueType = const Value.absent(),
    this.color = const Value.absent(),
    this.allowMultiple = const Value.absent(),
  });
  TagDefinitionsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required TagValueType valueType,
    this.color = const Value.absent(),
    this.allowMultiple = const Value.absent(),
  }) : name = Value(name),
       valueType = Value(valueType);
  static Insertable<TagDefinitionRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? valueType,
    Expression<int>? color,
    Expression<bool>? allowMultiple,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (valueType != null) 'value_type': valueType,
      if (color != null) 'color': color,
      if (allowMultiple != null) 'allow_multiple': allowMultiple,
    });
  }

  TagDefinitionsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<TagValueType>? valueType,
    Value<int?>? color,
    Value<bool>? allowMultiple,
  }) {
    return TagDefinitionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      valueType: valueType ?? this.valueType,
      color: color ?? this.color,
      allowMultiple: allowMultiple ?? this.allowMultiple,
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
        $TagDefinitionsTable.$convertervalueType.toSql(valueType.value),
      );
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (allowMultiple.present) {
      map['allow_multiple'] = Variable<bool>(allowMultiple.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagDefinitionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('valueType: $valueType, ')
          ..write('color: $color, ')
          ..write('allowMultiple: $allowMultiple')
          ..write(')'))
        .toString();
  }
}

class $FileNodesTable extends FileNodes
    with TableInfo<$FileNodesTable, FileNodeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FileNodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _isDirectoryMeta = const VerificationMeta(
    'isDirectory',
  );
  @override
  late final GeneratedColumn<bool> isDirectory = GeneratedColumn<bool>(
    'is_directory',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_directory" IN (0, 1))',
    ),
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentHashPrefixMeta = const VerificationMeta(
    'contentHashPrefix',
  );
  @override
  late final GeneratedColumn<String> contentHashPrefix =
      GeneratedColumn<String>(
        'content_hash_prefix',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<FolderManageMode?, String>
  manageMode = GeneratedColumn<String>(
    'manage_mode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<FolderManageMode?>($FileNodesTable.$convertermanageModen);
  static const VerificationMeta _childSignatureMeta = const VerificationMeta(
    'childSignature',
  );
  @override
  late final GeneratedColumn<String> childSignature = GeneratedColumn<String>(
    'child_signature',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageDimensionsMeta = const VerificationMeta(
    'imageDimensions',
  );
  @override
  late final GeneratedColumn<String> imageDimensions = GeneratedColumn<String>(
    'image_dimensions',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeenAt = GeneratedColumn<DateTime>(
    'last_seen_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _missingSinceMeta = const VerificationMeta(
    'missingSince',
  );
  @override
  late final GeneratedColumn<DateTime> missingSince = GeneratedColumn<DateTime>(
    'missing_since',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    path,
    isDirectory,
    size,
    modifiedAt,
    contentHashPrefix,
    manageMode,
    childSignature,
    imageDimensions,
    lastSeenAt,
    missingSince,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'file_nodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<FileNodeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('is_directory')) {
      context.handle(
        _isDirectoryMeta,
        isDirectory.isAcceptableOrUnknown(
          data['is_directory']!,
          _isDirectoryMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isDirectoryMeta);
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    }
    if (data.containsKey('content_hash_prefix')) {
      context.handle(
        _contentHashPrefixMeta,
        contentHashPrefix.isAcceptableOrUnknown(
          data['content_hash_prefix']!,
          _contentHashPrefixMeta,
        ),
      );
    }
    if (data.containsKey('child_signature')) {
      context.handle(
        _childSignatureMeta,
        childSignature.isAcceptableOrUnknown(
          data['child_signature']!,
          _childSignatureMeta,
        ),
      );
    }
    if (data.containsKey('image_dimensions')) {
      context.handle(
        _imageDimensionsMeta,
        imageDimensions.isAcceptableOrUnknown(
          data['image_dimensions']!,
          _imageDimensionsMeta,
        ),
      );
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSeenAtMeta);
    }
    if (data.containsKey('missing_since')) {
      context.handle(
        _missingSinceMeta,
        missingSince.isAcceptableOrUnknown(
          data['missing_since']!,
          _missingSinceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FileNodeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FileNodeRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      path:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}path'],
          )!,
      isDirectory:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_directory'],
          )!,
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      ),
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_at'],
      ),
      contentHashPrefix: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash_prefix'],
      ),
      manageMode: $FileNodesTable.$convertermanageModen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}manage_mode'],
        ),
      ),
      childSignature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}child_signature'],
      ),
      imageDimensions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_dimensions'],
      ),
      lastSeenAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}last_seen_at'],
          )!,
      missingSince: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}missing_since'],
      ),
    );
  }

  @override
  $FileNodesTable createAlias(String alias) {
    return $FileNodesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FolderManageMode, String, String>
  $convertermanageMode = const EnumNameConverter<FolderManageMode>(
    FolderManageMode.values,
  );
  static JsonTypeConverter2<FolderManageMode?, String?, String?>
  $convertermanageModen = JsonTypeConverter2.asNullable($convertermanageMode);
}

class FileNodeRow extends DataClass implements Insertable<FileNodeRow> {
  final int id;

  /// 관리 폴더 루트 기준 경로. 같은 노드를 한 번만 인덱싱한다.
  final String path;
  final bool isDirectory;

  /// 파일 크기. 폴더 등 의미 없는 경우 미지정.
  final int? size;
  final DateTime? modifiedAt;

  /// 이동 추적 시 동일 파일 후보를 가리기 위한 내용 부분 해시.
  final String? contentHashPrefix;

  /// 폴더의 관리 방식(불투명/관리). 폴더 노드에만 설정된다. 이름 기반 저장.
  /// 처음 발견되는 폴더는 불투명이 기본이며, null은 파일(또는 방식 미지정)이다.
  final FolderManageMode? manageMode;

  /// 폴더 이동 추적용, 직속 자식 구성의 부분 시그니처. 폴더 노드에만 채워진다.
  final String? childSignature;

  /// 이미지 파일의 픽셀 크기("가로x세로"). 스캐너가 헤더를 파싱해 채운다. 이미지가
  /// 아니거나 크기를 못 읽으면 미지정. 시스템 태그 '이미지 크기'의 원본.
  final String? imageDimensions;

  /// 마지막 스캔에서 관측된 시각. 삭제 감지/정리에 쓰인다.
  final DateTime lastSeenAt;

  /// 태그가 달린 채로 스캔에서 사라졌지만(이동+수정 등으로 자동 재연결 실패)
  /// 태그를 잃지 않으려 보존한 "연결 끊김" 상태의 시각. null이면 정상(존재)
  /// 노드다. 파일이 같은 경로로 다시 나타나거나 사용자가 수동 재연결하면 지워진다.
  final DateTime? missingSince;
  const FileNodeRow({
    required this.id,
    required this.path,
    required this.isDirectory,
    this.size,
    this.modifiedAt,
    this.contentHashPrefix,
    this.manageMode,
    this.childSignature,
    this.imageDimensions,
    required this.lastSeenAt,
    this.missingSince,
  });
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
    if (!nullToAbsent || manageMode != null) {
      map['manage_mode'] = Variable<String>(
        $FileNodesTable.$convertermanageModen.toSql(manageMode),
      );
    }
    if (!nullToAbsent || childSignature != null) {
      map['child_signature'] = Variable<String>(childSignature);
    }
    if (!nullToAbsent || imageDimensions != null) {
      map['image_dimensions'] = Variable<String>(imageDimensions);
    }
    map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    if (!nullToAbsent || missingSince != null) {
      map['missing_since'] = Variable<DateTime>(missingSince);
    }
    return map;
  }

  FileNodesCompanion toCompanion(bool nullToAbsent) {
    return FileNodesCompanion(
      id: Value(id),
      path: Value(path),
      isDirectory: Value(isDirectory),
      size: size == null && nullToAbsent ? const Value.absent() : Value(size),
      modifiedAt:
          modifiedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(modifiedAt),
      contentHashPrefix:
          contentHashPrefix == null && nullToAbsent
              ? const Value.absent()
              : Value(contentHashPrefix),
      manageMode:
          manageMode == null && nullToAbsent
              ? const Value.absent()
              : Value(manageMode),
      childSignature:
          childSignature == null && nullToAbsent
              ? const Value.absent()
              : Value(childSignature),
      imageDimensions:
          imageDimensions == null && nullToAbsent
              ? const Value.absent()
              : Value(imageDimensions),
      lastSeenAt: Value(lastSeenAt),
      missingSince:
          missingSince == null && nullToAbsent
              ? const Value.absent()
              : Value(missingSince),
    );
  }

  factory FileNodeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FileNodeRow(
      id: serializer.fromJson<int>(json['id']),
      path: serializer.fromJson<String>(json['path']),
      isDirectory: serializer.fromJson<bool>(json['isDirectory']),
      size: serializer.fromJson<int?>(json['size']),
      modifiedAt: serializer.fromJson<DateTime?>(json['modifiedAt']),
      contentHashPrefix: serializer.fromJson<String?>(
        json['contentHashPrefix'],
      ),
      manageMode: $FileNodesTable.$convertermanageModen.fromJson(
        serializer.fromJson<String?>(json['manageMode']),
      ),
      childSignature: serializer.fromJson<String?>(json['childSignature']),
      imageDimensions: serializer.fromJson<String?>(json['imageDimensions']),
      lastSeenAt: serializer.fromJson<DateTime>(json['lastSeenAt']),
      missingSince: serializer.fromJson<DateTime?>(json['missingSince']),
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
      'manageMode': serializer.toJson<String?>(
        $FileNodesTable.$convertermanageModen.toJson(manageMode),
      ),
      'childSignature': serializer.toJson<String?>(childSignature),
      'imageDimensions': serializer.toJson<String?>(imageDimensions),
      'lastSeenAt': serializer.toJson<DateTime>(lastSeenAt),
      'missingSince': serializer.toJson<DateTime?>(missingSince),
    };
  }

  FileNodeRow copyWith({
    int? id,
    String? path,
    bool? isDirectory,
    Value<int?> size = const Value.absent(),
    Value<DateTime?> modifiedAt = const Value.absent(),
    Value<String?> contentHashPrefix = const Value.absent(),
    Value<FolderManageMode?> manageMode = const Value.absent(),
    Value<String?> childSignature = const Value.absent(),
    Value<String?> imageDimensions = const Value.absent(),
    DateTime? lastSeenAt,
    Value<DateTime?> missingSince = const Value.absent(),
  }) => FileNodeRow(
    id: id ?? this.id,
    path: path ?? this.path,
    isDirectory: isDirectory ?? this.isDirectory,
    size: size.present ? size.value : this.size,
    modifiedAt: modifiedAt.present ? modifiedAt.value : this.modifiedAt,
    contentHashPrefix:
        contentHashPrefix.present
            ? contentHashPrefix.value
            : this.contentHashPrefix,
    manageMode: manageMode.present ? manageMode.value : this.manageMode,
    childSignature:
        childSignature.present ? childSignature.value : this.childSignature,
    imageDimensions:
        imageDimensions.present ? imageDimensions.value : this.imageDimensions,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    missingSince: missingSince.present ? missingSince.value : this.missingSince,
  );
  FileNodeRow copyWithCompanion(FileNodesCompanion data) {
    return FileNodeRow(
      id: data.id.present ? data.id.value : this.id,
      path: data.path.present ? data.path.value : this.path,
      isDirectory:
          data.isDirectory.present ? data.isDirectory.value : this.isDirectory,
      size: data.size.present ? data.size.value : this.size,
      modifiedAt:
          data.modifiedAt.present ? data.modifiedAt.value : this.modifiedAt,
      contentHashPrefix:
          data.contentHashPrefix.present
              ? data.contentHashPrefix.value
              : this.contentHashPrefix,
      manageMode:
          data.manageMode.present ? data.manageMode.value : this.manageMode,
      childSignature:
          data.childSignature.present
              ? data.childSignature.value
              : this.childSignature,
      imageDimensions:
          data.imageDimensions.present
              ? data.imageDimensions.value
              : this.imageDimensions,
      lastSeenAt:
          data.lastSeenAt.present ? data.lastSeenAt.value : this.lastSeenAt,
      missingSince:
          data.missingSince.present
              ? data.missingSince.value
              : this.missingSince,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FileNodeRow(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('isDirectory: $isDirectory, ')
          ..write('size: $size, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('contentHashPrefix: $contentHashPrefix, ')
          ..write('manageMode: $manageMode, ')
          ..write('childSignature: $childSignature, ')
          ..write('imageDimensions: $imageDimensions, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('missingSince: $missingSince')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    path,
    isDirectory,
    size,
    modifiedAt,
    contentHashPrefix,
    manageMode,
    childSignature,
    imageDimensions,
    lastSeenAt,
    missingSince,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FileNodeRow &&
          other.id == this.id &&
          other.path == this.path &&
          other.isDirectory == this.isDirectory &&
          other.size == this.size &&
          other.modifiedAt == this.modifiedAt &&
          other.contentHashPrefix == this.contentHashPrefix &&
          other.manageMode == this.manageMode &&
          other.childSignature == this.childSignature &&
          other.imageDimensions == this.imageDimensions &&
          other.lastSeenAt == this.lastSeenAt &&
          other.missingSince == this.missingSince);
}

class FileNodesCompanion extends UpdateCompanion<FileNodeRow> {
  final Value<int> id;
  final Value<String> path;
  final Value<bool> isDirectory;
  final Value<int?> size;
  final Value<DateTime?> modifiedAt;
  final Value<String?> contentHashPrefix;
  final Value<FolderManageMode?> manageMode;
  final Value<String?> childSignature;
  final Value<String?> imageDimensions;
  final Value<DateTime> lastSeenAt;
  final Value<DateTime?> missingSince;
  const FileNodesCompanion({
    this.id = const Value.absent(),
    this.path = const Value.absent(),
    this.isDirectory = const Value.absent(),
    this.size = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.contentHashPrefix = const Value.absent(),
    this.manageMode = const Value.absent(),
    this.childSignature = const Value.absent(),
    this.imageDimensions = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.missingSince = const Value.absent(),
  });
  FileNodesCompanion.insert({
    this.id = const Value.absent(),
    required String path,
    required bool isDirectory,
    this.size = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.contentHashPrefix = const Value.absent(),
    this.manageMode = const Value.absent(),
    this.childSignature = const Value.absent(),
    this.imageDimensions = const Value.absent(),
    required DateTime lastSeenAt,
    this.missingSince = const Value.absent(),
  }) : path = Value(path),
       isDirectory = Value(isDirectory),
       lastSeenAt = Value(lastSeenAt);
  static Insertable<FileNodeRow> custom({
    Expression<int>? id,
    Expression<String>? path,
    Expression<bool>? isDirectory,
    Expression<int>? size,
    Expression<DateTime>? modifiedAt,
    Expression<String>? contentHashPrefix,
    Expression<String>? manageMode,
    Expression<String>? childSignature,
    Expression<String>? imageDimensions,
    Expression<DateTime>? lastSeenAt,
    Expression<DateTime>? missingSince,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (path != null) 'path': path,
      if (isDirectory != null) 'is_directory': isDirectory,
      if (size != null) 'size': size,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (contentHashPrefix != null) 'content_hash_prefix': contentHashPrefix,
      if (manageMode != null) 'manage_mode': manageMode,
      if (childSignature != null) 'child_signature': childSignature,
      if (imageDimensions != null) 'image_dimensions': imageDimensions,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (missingSince != null) 'missing_since': missingSince,
    });
  }

  FileNodesCompanion copyWith({
    Value<int>? id,
    Value<String>? path,
    Value<bool>? isDirectory,
    Value<int?>? size,
    Value<DateTime?>? modifiedAt,
    Value<String?>? contentHashPrefix,
    Value<FolderManageMode?>? manageMode,
    Value<String?>? childSignature,
    Value<String?>? imageDimensions,
    Value<DateTime>? lastSeenAt,
    Value<DateTime?>? missingSince,
  }) {
    return FileNodesCompanion(
      id: id ?? this.id,
      path: path ?? this.path,
      isDirectory: isDirectory ?? this.isDirectory,
      size: size ?? this.size,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      contentHashPrefix: contentHashPrefix ?? this.contentHashPrefix,
      manageMode: manageMode ?? this.manageMode,
      childSignature: childSignature ?? this.childSignature,
      imageDimensions: imageDimensions ?? this.imageDimensions,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      missingSince: missingSince ?? this.missingSince,
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
    if (manageMode.present) {
      map['manage_mode'] = Variable<String>(
        $FileNodesTable.$convertermanageModen.toSql(manageMode.value),
      );
    }
    if (childSignature.present) {
      map['child_signature'] = Variable<String>(childSignature.value);
    }
    if (imageDimensions.present) {
      map['image_dimensions'] = Variable<String>(imageDimensions.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt.value);
    }
    if (missingSince.present) {
      map['missing_since'] = Variable<DateTime>(missingSince.value);
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
          ..write('manageMode: $manageMode, ')
          ..write('childSignature: $childSignature, ')
          ..write('imageDimensions: $imageDimensions, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('missingSince: $missingSince')
          ..write(')'))
        .toString();
  }
}

class $TagAssignmentsTable extends TagAssignments
    with TableInfo<$TagAssignmentsTable, TagAssignmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagAssignmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fileNodeIdMeta = const VerificationMeta(
    'fileNodeId',
  );
  @override
  late final GeneratedColumn<int> fileNodeId = GeneratedColumn<int>(
    'file_node_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES file_nodes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tagDefinitionIdMeta = const VerificationMeta(
    'tagDefinitionId',
  );
  @override
  late final GeneratedColumn<int> tagDefinitionId = GeneratedColumn<int>(
    'tag_definition_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tag_definitions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fileNodeId,
    tagDefinitionId,
    value,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tag_assignments';
  @override
  VerificationContext validateIntegrity(
    Insertable<TagAssignmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('file_node_id')) {
      context.handle(
        _fileNodeIdMeta,
        fileNodeId.isAcceptableOrUnknown(
          data['file_node_id']!,
          _fileNodeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fileNodeIdMeta);
    }
    if (data.containsKey('tag_definition_id')) {
      context.handle(
        _tagDefinitionIdMeta,
        tagDefinitionId.isAcceptableOrUnknown(
          data['tag_definition_id']!,
          _tagDefinitionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tagDefinitionIdMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TagAssignmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagAssignmentRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      fileNodeId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}file_node_id'],
          )!,
      tagDefinitionId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}tag_definition_id'],
          )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
    );
  }

  @override
  $TagAssignmentsTable createAlias(String alias) {
    return $TagAssignmentsTable(attachedDatabase, alias);
  }
}

class TagAssignmentRow extends DataClass
    implements Insertable<TagAssignmentRow> {
  final int id;
  final int fileNodeId;
  final int tagDefinitionId;

  /// 부여된 값. label 유형 등 값이 없으면 미지정.
  final String? value;
  const TagAssignmentRow({
    required this.id,
    required this.fileNodeId,
    required this.tagDefinitionId,
    this.value,
  });
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

  factory TagAssignmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagAssignmentRow(
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

  TagAssignmentRow copyWith({
    int? id,
    int? fileNodeId,
    int? tagDefinitionId,
    Value<String?> value = const Value.absent(),
  }) => TagAssignmentRow(
    id: id ?? this.id,
    fileNodeId: fileNodeId ?? this.fileNodeId,
    tagDefinitionId: tagDefinitionId ?? this.tagDefinitionId,
    value: value.present ? value.value : this.value,
  );
  TagAssignmentRow copyWithCompanion(TagAssignmentsCompanion data) {
    return TagAssignmentRow(
      id: data.id.present ? data.id.value : this.id,
      fileNodeId:
          data.fileNodeId.present ? data.fileNodeId.value : this.fileNodeId,
      tagDefinitionId:
          data.tagDefinitionId.present
              ? data.tagDefinitionId.value
              : this.tagDefinitionId,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagAssignmentRow(')
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
      (other is TagAssignmentRow &&
          other.id == this.id &&
          other.fileNodeId == this.fileNodeId &&
          other.tagDefinitionId == this.tagDefinitionId &&
          other.value == this.value);
}

class TagAssignmentsCompanion extends UpdateCompanion<TagAssignmentRow> {
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
  }) : fileNodeId = Value(fileNodeId),
       tagDefinitionId = Value(tagDefinitionId);
  static Insertable<TagAssignmentRow> custom({
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

  TagAssignmentsCompanion copyWith({
    Value<int>? id,
    Value<int>? fileNodeId,
    Value<int>? tagDefinitionId,
    Value<String?>? value,
  }) {
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

class $NestedWorkspacesTable extends NestedWorkspaces
    with TableInfo<$NestedWorkspacesTable, NestedWorkspaceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NestedWorkspacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<NestedTaggerMode, String> mode =
      GeneratedColumn<String>(
        'mode',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<NestedTaggerMode>($NestedWorkspacesTable.$convertermode);
  @override
  List<GeneratedColumn> get $columns => [id, path, mode];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nested_workspaces';
  @override
  VerificationContext validateIntegrity(
    Insertable<NestedWorkspaceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NestedWorkspaceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NestedWorkspaceRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      path:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}path'],
          )!,
      mode: $NestedWorkspacesTable.$convertermode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}mode'],
        )!,
      ),
    );
  }

  @override
  $NestedWorkspacesTable createAlias(String alias) {
    return $NestedWorkspacesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<NestedTaggerMode, String, String> $convertermode =
      const EnumNameConverter<NestedTaggerMode>(NestedTaggerMode.values);
}

class NestedWorkspaceRow extends DataClass
    implements Insertable<NestedWorkspaceRow> {
  final int id;

  /// 관리 폴더 루트 기준, `.filetagger/`를 소유한 하위 폴더의 상대 경로.
  final String path;

  /// 확정된 병합 유형. 이름 기반 저장.
  final NestedTaggerMode mode;
  const NestedWorkspaceRow({
    required this.id,
    required this.path,
    required this.mode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['path'] = Variable<String>(path);
    {
      map['mode'] = Variable<String>(
        $NestedWorkspacesTable.$convertermode.toSql(mode),
      );
    }
    return map;
  }

  NestedWorkspacesCompanion toCompanion(bool nullToAbsent) {
    return NestedWorkspacesCompanion(
      id: Value(id),
      path: Value(path),
      mode: Value(mode),
    );
  }

  factory NestedWorkspaceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NestedWorkspaceRow(
      id: serializer.fromJson<int>(json['id']),
      path: serializer.fromJson<String>(json['path']),
      mode: $NestedWorkspacesTable.$convertermode.fromJson(
        serializer.fromJson<String>(json['mode']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'path': serializer.toJson<String>(path),
      'mode': serializer.toJson<String>(
        $NestedWorkspacesTable.$convertermode.toJson(mode),
      ),
    };
  }

  NestedWorkspaceRow copyWith({
    int? id,
    String? path,
    NestedTaggerMode? mode,
  }) => NestedWorkspaceRow(
    id: id ?? this.id,
    path: path ?? this.path,
    mode: mode ?? this.mode,
  );
  NestedWorkspaceRow copyWithCompanion(NestedWorkspacesCompanion data) {
    return NestedWorkspaceRow(
      id: data.id.present ? data.id.value : this.id,
      path: data.path.present ? data.path.value : this.path,
      mode: data.mode.present ? data.mode.value : this.mode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NestedWorkspaceRow(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('mode: $mode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, path, mode);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NestedWorkspaceRow &&
          other.id == this.id &&
          other.path == this.path &&
          other.mode == this.mode);
}

class NestedWorkspacesCompanion extends UpdateCompanion<NestedWorkspaceRow> {
  final Value<int> id;
  final Value<String> path;
  final Value<NestedTaggerMode> mode;
  const NestedWorkspacesCompanion({
    this.id = const Value.absent(),
    this.path = const Value.absent(),
    this.mode = const Value.absent(),
  });
  NestedWorkspacesCompanion.insert({
    this.id = const Value.absent(),
    required String path,
    required NestedTaggerMode mode,
  }) : path = Value(path),
       mode = Value(mode);
  static Insertable<NestedWorkspaceRow> custom({
    Expression<int>? id,
    Expression<String>? path,
    Expression<String>? mode,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (path != null) 'path': path,
      if (mode != null) 'mode': mode,
    });
  }

  NestedWorkspacesCompanion copyWith({
    Value<int>? id,
    Value<String>? path,
    Value<NestedTaggerMode>? mode,
  }) {
    return NestedWorkspacesCompanion(
      id: id ?? this.id,
      path: path ?? this.path,
      mode: mode ?? this.mode,
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
    if (mode.present) {
      map['mode'] = Variable<String>(
        $NestedWorkspacesTable.$convertermode.toSql(mode.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NestedWorkspacesCompanion(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('mode: $mode')
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
  late final $NestedWorkspacesTable nestedWorkspaces = $NestedWorkspacesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tagDefinitions,
    fileNodes,
    tagAssignments,
    nestedWorkspaces,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'file_nodes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tag_assignments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tag_definitions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tag_assignments', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$TagDefinitionsTableCreateCompanionBuilder =
    TagDefinitionsCompanion Function({
      Value<int> id,
      required String name,
      required TagValueType valueType,
      Value<int?> color,
      Value<bool> allowMultiple,
    });
typedef $$TagDefinitionsTableUpdateCompanionBuilder =
    TagDefinitionsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<TagValueType> valueType,
      Value<int?> color,
      Value<bool> allowMultiple,
    });

final class $$TagDefinitionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $TagDefinitionsTable, TagDefinitionRow> {
  $$TagDefinitionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$TagAssignmentsTable, List<TagAssignmentRow>>
  _tagAssignmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.tagAssignments,
    aliasName: $_aliasNameGenerator(
      db.tagDefinitions.id,
      db.tagAssignments.tagDefinitionId,
    ),
  );

  $$TagAssignmentsTableProcessedTableManager get tagAssignmentsRefs {
    final manager = $$TagAssignmentsTableTableManager(
      $_db,
      $_db.tagAssignments,
    ).filter((f) => f.tagDefinitionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_tagAssignmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
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
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TagValueType, TagValueType, String>
  get valueType => $composableBuilder(
    column: $table.valueType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allowMultiple => $composableBuilder(
    column: $table.allowMultiple,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> tagAssignmentsRefs(
    Expression<bool> Function($$TagAssignmentsTableFilterComposer f) f,
  ) {
    final $$TagAssignmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tagAssignments,
      getReferencedColumn: (t) => t.tagDefinitionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagAssignmentsTableFilterComposer(
            $db: $db,
            $table: $db.tagAssignments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
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
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueType => $composableBuilder(
    column: $table.valueType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allowMultiple => $composableBuilder(
    column: $table.allowMultiple,
    builder: (column) => ColumnOrderings(column),
  );
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

  GeneratedColumn<bool> get allowMultiple => $composableBuilder(
    column: $table.allowMultiple,
    builder: (column) => column,
  );

  Expression<T> tagAssignmentsRefs<T extends Object>(
    Expression<T> Function($$TagAssignmentsTableAnnotationComposer a) f,
  ) {
    final $$TagAssignmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tagAssignments,
      getReferencedColumn: (t) => t.tagDefinitionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagAssignmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.tagAssignments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagDefinitionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagDefinitionsTable,
          TagDefinitionRow,
          $$TagDefinitionsTableFilterComposer,
          $$TagDefinitionsTableOrderingComposer,
          $$TagDefinitionsTableAnnotationComposer,
          $$TagDefinitionsTableCreateCompanionBuilder,
          $$TagDefinitionsTableUpdateCompanionBuilder,
          (TagDefinitionRow, $$TagDefinitionsTableReferences),
          TagDefinitionRow,
          PrefetchHooks Function({bool tagAssignmentsRefs})
        > {
  $$TagDefinitionsTableTableManager(
    _$AppDatabase db,
    $TagDefinitionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$TagDefinitionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$TagDefinitionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$TagDefinitionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<TagValueType> valueType = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<bool> allowMultiple = const Value.absent(),
              }) => TagDefinitionsCompanion(
                id: id,
                name: name,
                valueType: valueType,
                color: color,
                allowMultiple: allowMultiple,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required TagValueType valueType,
                Value<int?> color = const Value.absent(),
                Value<bool> allowMultiple = const Value.absent(),
              }) => TagDefinitionsCompanion.insert(
                id: id,
                name: name,
                valueType: valueType,
                color: color,
                allowMultiple: allowMultiple,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$TagDefinitionsTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({tagAssignmentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (tagAssignmentsRefs) db.tagAssignments,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (tagAssignmentsRefs)
                    await $_getPrefetchedData<
                      TagDefinitionRow,
                      $TagDefinitionsTable,
                      TagAssignmentRow
                    >(
                      currentTable: table,
                      referencedTable: $$TagDefinitionsTableReferences
                          ._tagAssignmentsRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$TagDefinitionsTableReferences(
                                db,
                                table,
                                p0,
                              ).tagAssignmentsRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.tagDefinitionId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TagDefinitionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagDefinitionsTable,
      TagDefinitionRow,
      $$TagDefinitionsTableFilterComposer,
      $$TagDefinitionsTableOrderingComposer,
      $$TagDefinitionsTableAnnotationComposer,
      $$TagDefinitionsTableCreateCompanionBuilder,
      $$TagDefinitionsTableUpdateCompanionBuilder,
      (TagDefinitionRow, $$TagDefinitionsTableReferences),
      TagDefinitionRow,
      PrefetchHooks Function({bool tagAssignmentsRefs})
    >;
typedef $$FileNodesTableCreateCompanionBuilder =
    FileNodesCompanion Function({
      Value<int> id,
      required String path,
      required bool isDirectory,
      Value<int?> size,
      Value<DateTime?> modifiedAt,
      Value<String?> contentHashPrefix,
      Value<FolderManageMode?> manageMode,
      Value<String?> childSignature,
      Value<String?> imageDimensions,
      required DateTime lastSeenAt,
      Value<DateTime?> missingSince,
    });
typedef $$FileNodesTableUpdateCompanionBuilder =
    FileNodesCompanion Function({
      Value<int> id,
      Value<String> path,
      Value<bool> isDirectory,
      Value<int?> size,
      Value<DateTime?> modifiedAt,
      Value<String?> contentHashPrefix,
      Value<FolderManageMode?> manageMode,
      Value<String?> childSignature,
      Value<String?> imageDimensions,
      Value<DateTime> lastSeenAt,
      Value<DateTime?> missingSince,
    });

final class $$FileNodesTableReferences
    extends BaseReferences<_$AppDatabase, $FileNodesTable, FileNodeRow> {
  $$FileNodesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TagAssignmentsTable, List<TagAssignmentRow>>
  _tagAssignmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.tagAssignments,
    aliasName: $_aliasNameGenerator(
      db.fileNodes.id,
      db.tagAssignments.fileNodeId,
    ),
  );

  $$TagAssignmentsTableProcessedTableManager get tagAssignmentsRefs {
    final manager = $$TagAssignmentsTableTableManager(
      $_db,
      $_db.tagAssignments,
    ).filter((f) => f.fileNodeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_tagAssignmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
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
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirectory => $composableBuilder(
    column: $table.isDirectory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentHashPrefix => $composableBuilder(
    column: $table.contentHashPrefix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FolderManageMode?, FolderManageMode, String>
  get manageMode => $composableBuilder(
    column: $table.manageMode,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get childSignature => $composableBuilder(
    column: $table.childSignature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageDimensions => $composableBuilder(
    column: $table.imageDimensions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get missingSince => $composableBuilder(
    column: $table.missingSince,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> tagAssignmentsRefs(
    Expression<bool> Function($$TagAssignmentsTableFilterComposer f) f,
  ) {
    final $$TagAssignmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tagAssignments,
      getReferencedColumn: (t) => t.fileNodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagAssignmentsTableFilterComposer(
            $db: $db,
            $table: $db.tagAssignments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
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
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirectory => $composableBuilder(
    column: $table.isDirectory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentHashPrefix => $composableBuilder(
    column: $table.contentHashPrefix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manageMode => $composableBuilder(
    column: $table.manageMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get childSignature => $composableBuilder(
    column: $table.childSignature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageDimensions => $composableBuilder(
    column: $table.imageDimensions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get missingSince => $composableBuilder(
    column: $table.missingSince,
    builder: (column) => ColumnOrderings(column),
  );
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
    column: $table.isDirectory,
    builder: (column) => column,
  );

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentHashPrefix => $composableBuilder(
    column: $table.contentHashPrefix,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<FolderManageMode?, String> get manageMode =>
      $composableBuilder(
        column: $table.manageMode,
        builder: (column) => column,
      );

  GeneratedColumn<String> get childSignature => $composableBuilder(
    column: $table.childSignature,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageDimensions => $composableBuilder(
    column: $table.imageDimensions,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get missingSince => $composableBuilder(
    column: $table.missingSince,
    builder: (column) => column,
  );

  Expression<T> tagAssignmentsRefs<T extends Object>(
    Expression<T> Function($$TagAssignmentsTableAnnotationComposer a) f,
  ) {
    final $$TagAssignmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tagAssignments,
      getReferencedColumn: (t) => t.fileNodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagAssignmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.tagAssignments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FileNodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FileNodesTable,
          FileNodeRow,
          $$FileNodesTableFilterComposer,
          $$FileNodesTableOrderingComposer,
          $$FileNodesTableAnnotationComposer,
          $$FileNodesTableCreateCompanionBuilder,
          $$FileNodesTableUpdateCompanionBuilder,
          (FileNodeRow, $$FileNodesTableReferences),
          FileNodeRow,
          PrefetchHooks Function({bool tagAssignmentsRefs})
        > {
  $$FileNodesTableTableManager(_$AppDatabase db, $FileNodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$FileNodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$FileNodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$FileNodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<bool> isDirectory = const Value.absent(),
                Value<int?> size = const Value.absent(),
                Value<DateTime?> modifiedAt = const Value.absent(),
                Value<String?> contentHashPrefix = const Value.absent(),
                Value<FolderManageMode?> manageMode = const Value.absent(),
                Value<String?> childSignature = const Value.absent(),
                Value<String?> imageDimensions = const Value.absent(),
                Value<DateTime> lastSeenAt = const Value.absent(),
                Value<DateTime?> missingSince = const Value.absent(),
              }) => FileNodesCompanion(
                id: id,
                path: path,
                isDirectory: isDirectory,
                size: size,
                modifiedAt: modifiedAt,
                contentHashPrefix: contentHashPrefix,
                manageMode: manageMode,
                childSignature: childSignature,
                imageDimensions: imageDimensions,
                lastSeenAt: lastSeenAt,
                missingSince: missingSince,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String path,
                required bool isDirectory,
                Value<int?> size = const Value.absent(),
                Value<DateTime?> modifiedAt = const Value.absent(),
                Value<String?> contentHashPrefix = const Value.absent(),
                Value<FolderManageMode?> manageMode = const Value.absent(),
                Value<String?> childSignature = const Value.absent(),
                Value<String?> imageDimensions = const Value.absent(),
                required DateTime lastSeenAt,
                Value<DateTime?> missingSince = const Value.absent(),
              }) => FileNodesCompanion.insert(
                id: id,
                path: path,
                isDirectory: isDirectory,
                size: size,
                modifiedAt: modifiedAt,
                contentHashPrefix: contentHashPrefix,
                manageMode: manageMode,
                childSignature: childSignature,
                imageDimensions: imageDimensions,
                lastSeenAt: lastSeenAt,
                missingSince: missingSince,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$FileNodesTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({tagAssignmentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (tagAssignmentsRefs) db.tagAssignments,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (tagAssignmentsRefs)
                    await $_getPrefetchedData<
                      FileNodeRow,
                      $FileNodesTable,
                      TagAssignmentRow
                    >(
                      currentTable: table,
                      referencedTable: $$FileNodesTableReferences
                          ._tagAssignmentsRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$FileNodesTableReferences(
                                db,
                                table,
                                p0,
                              ).tagAssignmentsRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.fileNodeId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FileNodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FileNodesTable,
      FileNodeRow,
      $$FileNodesTableFilterComposer,
      $$FileNodesTableOrderingComposer,
      $$FileNodesTableAnnotationComposer,
      $$FileNodesTableCreateCompanionBuilder,
      $$FileNodesTableUpdateCompanionBuilder,
      (FileNodeRow, $$FileNodesTableReferences),
      FileNodeRow,
      PrefetchHooks Function({bool tagAssignmentsRefs})
    >;
typedef $$TagAssignmentsTableCreateCompanionBuilder =
    TagAssignmentsCompanion Function({
      Value<int> id,
      required int fileNodeId,
      required int tagDefinitionId,
      Value<String?> value,
    });
typedef $$TagAssignmentsTableUpdateCompanionBuilder =
    TagAssignmentsCompanion Function({
      Value<int> id,
      Value<int> fileNodeId,
      Value<int> tagDefinitionId,
      Value<String?> value,
    });

final class $$TagAssignmentsTableReferences
    extends
        BaseReferences<_$AppDatabase, $TagAssignmentsTable, TagAssignmentRow> {
  $$TagAssignmentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FileNodesTable _fileNodeIdTable(_$AppDatabase db) =>
      db.fileNodes.createAlias(
        $_aliasNameGenerator(db.tagAssignments.fileNodeId, db.fileNodes.id),
      );

  $$FileNodesTableProcessedTableManager get fileNodeId {
    final $_column = $_itemColumn<int>('file_node_id')!;

    final manager = $$FileNodesTableTableManager(
      $_db,
      $_db.fileNodes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fileNodeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagDefinitionsTable _tagDefinitionIdTable(_$AppDatabase db) =>
      db.tagDefinitions.createAlias(
        $_aliasNameGenerator(
          db.tagAssignments.tagDefinitionId,
          db.tagDefinitions.id,
        ),
      );

  $$TagDefinitionsTableProcessedTableManager get tagDefinitionId {
    final $_column = $_itemColumn<int>('tag_definition_id')!;

    final manager = $$TagDefinitionsTableTableManager(
      $_db,
      $_db.tagDefinitions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagDefinitionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
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
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  $$FileNodesTableFilterComposer get fileNodeId {
    final $$FileNodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fileNodeId,
      referencedTable: $db.fileNodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FileNodesTableFilterComposer(
            $db: $db,
            $table: $db.fileNodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagDefinitionsTableFilterComposer get tagDefinitionId {
    final $$TagDefinitionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagDefinitionId,
      referencedTable: $db.tagDefinitions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagDefinitionsTableFilterComposer(
            $db: $db,
            $table: $db.tagDefinitions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
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
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  $$FileNodesTableOrderingComposer get fileNodeId {
    final $$FileNodesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fileNodeId,
      referencedTable: $db.fileNodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FileNodesTableOrderingComposer(
            $db: $db,
            $table: $db.fileNodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagDefinitionsTableOrderingComposer get tagDefinitionId {
    final $$TagDefinitionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagDefinitionId,
      referencedTable: $db.tagDefinitions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagDefinitionsTableOrderingComposer(
            $db: $db,
            $table: $db.tagDefinitions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
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
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FileNodesTableAnnotationComposer(
            $db: $db,
            $table: $db.fileNodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagDefinitionsTableAnnotationComposer get tagDefinitionId {
    final $$TagDefinitionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagDefinitionId,
      referencedTable: $db.tagDefinitions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagDefinitionsTableAnnotationComposer(
            $db: $db,
            $table: $db.tagDefinitions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TagAssignmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagAssignmentsTable,
          TagAssignmentRow,
          $$TagAssignmentsTableFilterComposer,
          $$TagAssignmentsTableOrderingComposer,
          $$TagAssignmentsTableAnnotationComposer,
          $$TagAssignmentsTableCreateCompanionBuilder,
          $$TagAssignmentsTableUpdateCompanionBuilder,
          (TagAssignmentRow, $$TagAssignmentsTableReferences),
          TagAssignmentRow,
          PrefetchHooks Function({bool fileNodeId, bool tagDefinitionId})
        > {
  $$TagAssignmentsTableTableManager(
    _$AppDatabase db,
    $TagAssignmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$TagAssignmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$TagAssignmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$TagAssignmentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> fileNodeId = const Value.absent(),
                Value<int> tagDefinitionId = const Value.absent(),
                Value<String?> value = const Value.absent(),
              }) => TagAssignmentsCompanion(
                id: id,
                fileNodeId: fileNodeId,
                tagDefinitionId: tagDefinitionId,
                value: value,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int fileNodeId,
                required int tagDefinitionId,
                Value<String?> value = const Value.absent(),
              }) => TagAssignmentsCompanion.insert(
                id: id,
                fileNodeId: fileNodeId,
                tagDefinitionId: tagDefinitionId,
                value: value,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$TagAssignmentsTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({
            fileNodeId = false,
            tagDefinitionId = false,
          }) {
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
                  dynamic
                >
              >(state) {
                if (fileNodeId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.fileNodeId,
                            referencedTable: $$TagAssignmentsTableReferences
                                ._fileNodeIdTable(db),
                            referencedColumn:
                                $$TagAssignmentsTableReferences
                                    ._fileNodeIdTable(db)
                                    .id,
                          )
                          as T;
                }
                if (tagDefinitionId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.tagDefinitionId,
                            referencedTable: $$TagAssignmentsTableReferences
                                ._tagDefinitionIdTable(db),
                            referencedColumn:
                                $$TagAssignmentsTableReferences
                                    ._tagDefinitionIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TagAssignmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagAssignmentsTable,
      TagAssignmentRow,
      $$TagAssignmentsTableFilterComposer,
      $$TagAssignmentsTableOrderingComposer,
      $$TagAssignmentsTableAnnotationComposer,
      $$TagAssignmentsTableCreateCompanionBuilder,
      $$TagAssignmentsTableUpdateCompanionBuilder,
      (TagAssignmentRow, $$TagAssignmentsTableReferences),
      TagAssignmentRow,
      PrefetchHooks Function({bool fileNodeId, bool tagDefinitionId})
    >;
typedef $$NestedWorkspacesTableCreateCompanionBuilder =
    NestedWorkspacesCompanion Function({
      Value<int> id,
      required String path,
      required NestedTaggerMode mode,
    });
typedef $$NestedWorkspacesTableUpdateCompanionBuilder =
    NestedWorkspacesCompanion Function({
      Value<int> id,
      Value<String> path,
      Value<NestedTaggerMode> mode,
    });

class $$NestedWorkspacesTableFilterComposer
    extends Composer<_$AppDatabase, $NestedWorkspacesTable> {
  $$NestedWorkspacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<NestedTaggerMode, NestedTaggerMode, String>
  get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$NestedWorkspacesTableOrderingComposer
    extends Composer<_$AppDatabase, $NestedWorkspacesTable> {
  $$NestedWorkspacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NestedWorkspacesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NestedWorkspacesTable> {
  $$NestedWorkspacesTableAnnotationComposer({
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

  GeneratedColumnWithTypeConverter<NestedTaggerMode, String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);
}

class $$NestedWorkspacesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NestedWorkspacesTable,
          NestedWorkspaceRow,
          $$NestedWorkspacesTableFilterComposer,
          $$NestedWorkspacesTableOrderingComposer,
          $$NestedWorkspacesTableAnnotationComposer,
          $$NestedWorkspacesTableCreateCompanionBuilder,
          $$NestedWorkspacesTableUpdateCompanionBuilder,
          (
            NestedWorkspaceRow,
            BaseReferences<
              _$AppDatabase,
              $NestedWorkspacesTable,
              NestedWorkspaceRow
            >,
          ),
          NestedWorkspaceRow,
          PrefetchHooks Function()
        > {
  $$NestedWorkspacesTableTableManager(
    _$AppDatabase db,
    $NestedWorkspacesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$NestedWorkspacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$NestedWorkspacesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$NestedWorkspacesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<NestedTaggerMode> mode = const Value.absent(),
              }) => NestedWorkspacesCompanion(id: id, path: path, mode: mode),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String path,
                required NestedTaggerMode mode,
              }) => NestedWorkspacesCompanion.insert(
                id: id,
                path: path,
                mode: mode,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NestedWorkspacesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NestedWorkspacesTable,
      NestedWorkspaceRow,
      $$NestedWorkspacesTableFilterComposer,
      $$NestedWorkspacesTableOrderingComposer,
      $$NestedWorkspacesTableAnnotationComposer,
      $$NestedWorkspacesTableCreateCompanionBuilder,
      $$NestedWorkspacesTableUpdateCompanionBuilder,
      (
        NestedWorkspaceRow,
        BaseReferences<
          _$AppDatabase,
          $NestedWorkspacesTable,
          NestedWorkspaceRow
        >,
      ),
      NestedWorkspaceRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TagDefinitionsTableTableManager get tagDefinitions =>
      $$TagDefinitionsTableTableManager(_db, _db.tagDefinitions);
  $$FileNodesTableTableManager get fileNodes =>
      $$FileNodesTableTableManager(_db, _db.fileNodes);
  $$TagAssignmentsTableTableManager get tagAssignments =>
      $$TagAssignmentsTableTableManager(_db, _db.tagAssignments);
  $$NestedWorkspacesTableTableManager get nestedWorkspaces =>
      $$NestedWorkspacesTableTableManager(_db, _db.nestedWorkspaces);
}
