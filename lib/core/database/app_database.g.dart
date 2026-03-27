// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CharactersTable extends Characters
    with TableInfo<$CharactersTable, Character> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharactersTable(this.attachedDatabase, [this._alias]);
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
  );
  static const VerificationMeta _originalImagePathMeta = const VerificationMeta(
    'originalImagePath',
  );
  @override
  late final GeneratedColumn<String> originalImagePath =
      GeneratedColumn<String>(
        'original_image_path',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _transparentImagePathMeta =
      const VerificationMeta('transparentImagePath');
  @override
  late final GeneratedColumn<String> transparentImagePath =
      GeneratedColumn<String>(
        'transparent_image_path',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _thumbnailPathMeta = const VerificationMeta(
    'thumbnailPath',
  );
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
    'thumbnail_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    originalImagePath,
    transparentImagePath,
    thumbnailPath,
    width,
    height,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'characters';
  @override
  VerificationContext validateIntegrity(
    Insertable<Character> instance, {
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
    if (data.containsKey('original_image_path')) {
      context.handle(
        _originalImagePathMeta,
        originalImagePath.isAcceptableOrUnknown(
          data['original_image_path']!,
          _originalImagePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalImagePathMeta);
    }
    if (data.containsKey('transparent_image_path')) {
      context.handle(
        _transparentImagePathMeta,
        transparentImagePath.isAcceptableOrUnknown(
          data['transparent_image_path']!,
          _transparentImagePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transparentImagePathMeta);
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
        _thumbnailPathMeta,
        thumbnailPath.isAcceptableOrUnknown(
          data['thumbnail_path']!,
          _thumbnailPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_thumbnailPathMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    } else if (isInserting) {
      context.missing(_widthMeta);
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Character map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Character(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      originalImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_image_path'],
      )!,
      transparentImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transparent_image_path'],
      )!,
      thumbnailPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_path'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CharactersTable createAlias(String alias) {
    return $CharactersTable(attachedDatabase, alias);
  }
}

class Character extends DataClass implements Insertable<Character> {
  final int id;
  final String name;
  final String originalImagePath;
  final String transparentImagePath;
  final String thumbnailPath;
  final int width;
  final int height;
  final DateTime createdAt;
  const Character({
    required this.id,
    required this.name,
    required this.originalImagePath,
    required this.transparentImagePath,
    required this.thumbnailPath,
    required this.width,
    required this.height,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['original_image_path'] = Variable<String>(originalImagePath);
    map['transparent_image_path'] = Variable<String>(transparentImagePath);
    map['thumbnail_path'] = Variable<String>(thumbnailPath);
    map['width'] = Variable<int>(width);
    map['height'] = Variable<int>(height);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CharactersCompanion toCompanion(bool nullToAbsent) {
    return CharactersCompanion(
      id: Value(id),
      name: Value(name),
      originalImagePath: Value(originalImagePath),
      transparentImagePath: Value(transparentImagePath),
      thumbnailPath: Value(thumbnailPath),
      width: Value(width),
      height: Value(height),
      createdAt: Value(createdAt),
    );
  }

  factory Character.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Character(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      originalImagePath: serializer.fromJson<String>(json['originalImagePath']),
      transparentImagePath: serializer.fromJson<String>(
        json['transparentImagePath'],
      ),
      thumbnailPath: serializer.fromJson<String>(json['thumbnailPath']),
      width: serializer.fromJson<int>(json['width']),
      height: serializer.fromJson<int>(json['height']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'originalImagePath': serializer.toJson<String>(originalImagePath),
      'transparentImagePath': serializer.toJson<String>(transparentImagePath),
      'thumbnailPath': serializer.toJson<String>(thumbnailPath),
      'width': serializer.toJson<int>(width),
      'height': serializer.toJson<int>(height),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Character copyWith({
    int? id,
    String? name,
    String? originalImagePath,
    String? transparentImagePath,
    String? thumbnailPath,
    int? width,
    int? height,
    DateTime? createdAt,
  }) => Character(
    id: id ?? this.id,
    name: name ?? this.name,
    originalImagePath: originalImagePath ?? this.originalImagePath,
    transparentImagePath: transparentImagePath ?? this.transparentImagePath,
    thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    width: width ?? this.width,
    height: height ?? this.height,
    createdAt: createdAt ?? this.createdAt,
  );
  Character copyWithCompanion(CharactersCompanion data) {
    return Character(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      originalImagePath: data.originalImagePath.present
          ? data.originalImagePath.value
          : this.originalImagePath,
      transparentImagePath: data.transparentImagePath.present
          ? data.transparentImagePath.value
          : this.transparentImagePath,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Character(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('originalImagePath: $originalImagePath, ')
          ..write('transparentImagePath: $transparentImagePath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    originalImagePath,
    transparentImagePath,
    thumbnailPath,
    width,
    height,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Character &&
          other.id == this.id &&
          other.name == this.name &&
          other.originalImagePath == this.originalImagePath &&
          other.transparentImagePath == this.transparentImagePath &&
          other.thumbnailPath == this.thumbnailPath &&
          other.width == this.width &&
          other.height == this.height &&
          other.createdAt == this.createdAt);
}

class CharactersCompanion extends UpdateCompanion<Character> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> originalImagePath;
  final Value<String> transparentImagePath;
  final Value<String> thumbnailPath;
  final Value<int> width;
  final Value<int> height;
  final Value<DateTime> createdAt;
  const CharactersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.originalImagePath = const Value.absent(),
    this.transparentImagePath = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CharactersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String originalImagePath,
    required String transparentImagePath,
    required String thumbnailPath,
    required int width,
    required int height,
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       originalImagePath = Value(originalImagePath),
       transparentImagePath = Value(transparentImagePath),
       thumbnailPath = Value(thumbnailPath),
       width = Value(width),
       height = Value(height);
  static Insertable<Character> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? originalImagePath,
    Expression<String>? transparentImagePath,
    Expression<String>? thumbnailPath,
    Expression<int>? width,
    Expression<int>? height,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (originalImagePath != null) 'original_image_path': originalImagePath,
      if (transparentImagePath != null)
        'transparent_image_path': transparentImagePath,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CharactersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? originalImagePath,
    Value<String>? transparentImagePath,
    Value<String>? thumbnailPath,
    Value<int>? width,
    Value<int>? height,
    Value<DateTime>? createdAt,
  }) {
    return CharactersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      transparentImagePath: transparentImagePath ?? this.transparentImagePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      width: width ?? this.width,
      height: height ?? this.height,
      createdAt: createdAt ?? this.createdAt,
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
    if (originalImagePath.present) {
      map['original_image_path'] = Variable<String>(originalImagePath.value);
    }
    if (transparentImagePath.present) {
      map['transparent_image_path'] = Variable<String>(
        transparentImagePath.value,
      );
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharactersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('originalImagePath: $originalImagePath, ')
          ..write('transparentImagePath: $transparentImagePath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CharactersTable characters = $CharactersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [characters];
}

typedef $$CharactersTableCreateCompanionBuilder =
    CharactersCompanion Function({
      Value<int> id,
      required String name,
      required String originalImagePath,
      required String transparentImagePath,
      required String thumbnailPath,
      required int width,
      required int height,
      Value<DateTime> createdAt,
    });
typedef $$CharactersTableUpdateCompanionBuilder =
    CharactersCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> originalImagePath,
      Value<String> transparentImagePath,
      Value<String> thumbnailPath,
      Value<int> width,
      Value<int> height,
      Value<DateTime> createdAt,
    });

class $$CharactersTableFilterComposer
    extends Composer<_$AppDatabase, $CharactersTable> {
  $$CharactersTableFilterComposer({
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

  ColumnFilters<String> get originalImagePath => $composableBuilder(
    column: $table.originalImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transparentImagePath => $composableBuilder(
    column: $table.transparentImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CharactersTableOrderingComposer
    extends Composer<_$AppDatabase, $CharactersTable> {
  $$CharactersTableOrderingComposer({
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

  ColumnOrderings<String> get originalImagePath => $composableBuilder(
    column: $table.originalImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transparentImagePath => $composableBuilder(
    column: $table.transparentImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CharactersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CharactersTable> {
  $$CharactersTableAnnotationComposer({
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

  GeneratedColumn<String> get originalImagePath => $composableBuilder(
    column: $table.originalImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transparentImagePath => $composableBuilder(
    column: $table.transparentImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CharactersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CharactersTable,
          Character,
          $$CharactersTableFilterComposer,
          $$CharactersTableOrderingComposer,
          $$CharactersTableAnnotationComposer,
          $$CharactersTableCreateCompanionBuilder,
          $$CharactersTableUpdateCompanionBuilder,
          (
            Character,
            BaseReferences<_$AppDatabase, $CharactersTable, Character>,
          ),
          Character,
          PrefetchHooks Function()
        > {
  $$CharactersTableTableManager(_$AppDatabase db, $CharactersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharactersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharactersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CharactersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> originalImagePath = const Value.absent(),
                Value<String> transparentImagePath = const Value.absent(),
                Value<String> thumbnailPath = const Value.absent(),
                Value<int> width = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CharactersCompanion(
                id: id,
                name: name,
                originalImagePath: originalImagePath,
                transparentImagePath: transparentImagePath,
                thumbnailPath: thumbnailPath,
                width: width,
                height: height,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String originalImagePath,
                required String transparentImagePath,
                required String thumbnailPath,
                required int width,
                required int height,
                Value<DateTime> createdAt = const Value.absent(),
              }) => CharactersCompanion.insert(
                id: id,
                name: name,
                originalImagePath: originalImagePath,
                transparentImagePath: transparentImagePath,
                thumbnailPath: thumbnailPath,
                width: width,
                height: height,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CharactersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CharactersTable,
      Character,
      $$CharactersTableFilterComposer,
      $$CharactersTableOrderingComposer,
      $$CharactersTableAnnotationComposer,
      $$CharactersTableCreateCompanionBuilder,
      $$CharactersTableUpdateCompanionBuilder,
      (Character, BaseReferences<_$AppDatabase, $CharactersTable, Character>),
      Character,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CharactersTableTableManager get characters =>
      $$CharactersTableTableManager(_db, _db.characters);
}
