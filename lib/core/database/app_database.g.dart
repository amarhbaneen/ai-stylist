// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UserProfileTable extends UserProfile
    with TableInfo<$UserProfileTable, UserProfileData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfileTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _preferredStylesMeta = const VerificationMeta(
    'preferredStyles',
  );
  @override
  late final GeneratedColumn<String> preferredStyles = GeneratedColumn<String>(
    'preferred_styles',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _favoredColorsMeta = const VerificationMeta(
    'favoredColors',
  );
  @override
  late final GeneratedColumn<String> favoredColors = GeneratedColumn<String>(
    'favored_colors',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _avoidedColorsMeta = const VerificationMeta(
    'avoidedColors',
  );
  @override
  late final GeneratedColumn<String> avoidedColors = GeneratedColumn<String>(
    'avoided_colors',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _fitPreferenceMeta = const VerificationMeta(
    'fitPreference',
  );
  @override
  late final GeneratedColumn<String> fitPreference = GeneratedColumn<String>(
    'fit_preference',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _formalityPreferenceMeta =
      const VerificationMeta('formalityPreference');
  @override
  late final GeneratedColumn<int> formalityPreference = GeneratedColumn<int>(
    'formality_preference',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    preferredStyles,
    favoredColors,
    avoidedColors,
    fitPreference,
    formalityPreference,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profile';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserProfileData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('preferred_styles')) {
      context.handle(
        _preferredStylesMeta,
        preferredStyles.isAcceptableOrUnknown(
          data['preferred_styles']!,
          _preferredStylesMeta,
        ),
      );
    }
    if (data.containsKey('favored_colors')) {
      context.handle(
        _favoredColorsMeta,
        favoredColors.isAcceptableOrUnknown(
          data['favored_colors']!,
          _favoredColorsMeta,
        ),
      );
    }
    if (data.containsKey('avoided_colors')) {
      context.handle(
        _avoidedColorsMeta,
        avoidedColors.isAcceptableOrUnknown(
          data['avoided_colors']!,
          _avoidedColorsMeta,
        ),
      );
    }
    if (data.containsKey('fit_preference')) {
      context.handle(
        _fitPreferenceMeta,
        fitPreference.isAcceptableOrUnknown(
          data['fit_preference']!,
          _fitPreferenceMeta,
        ),
      );
    }
    if (data.containsKey('formality_preference')) {
      context.handle(
        _formalityPreferenceMeta,
        formalityPreference.isAcceptableOrUnknown(
          data['formality_preference']!,
          _formalityPreferenceMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProfileData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfileData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      preferredStyles: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_styles'],
      )!,
      favoredColors: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}favored_colors'],
      )!,
      avoidedColors: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avoided_colors'],
      )!,
      fitPreference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fit_preference'],
      ),
      formalityPreference: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}formality_preference'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UserProfileTable createAlias(String alias) {
    return $UserProfileTable(attachedDatabase, alias);
  }
}

class UserProfileData extends DataClass implements Insertable<UserProfileData> {
  final String id;

  /// JSON array of style codes.
  final String preferredStyles;

  /// JSON array of colour codes to favour.
  final String favoredColors;

  /// JSON array of colour codes to avoid.
  final String avoidedColors;
  final String? fitPreference;
  final int? formalityPreference;
  final int createdAt;
  final int updatedAt;
  const UserProfileData({
    required this.id,
    required this.preferredStyles,
    required this.favoredColors,
    required this.avoidedColors,
    this.fitPreference,
    this.formalityPreference,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['preferred_styles'] = Variable<String>(preferredStyles);
    map['favored_colors'] = Variable<String>(favoredColors);
    map['avoided_colors'] = Variable<String>(avoidedColors);
    if (!nullToAbsent || fitPreference != null) {
      map['fit_preference'] = Variable<String>(fitPreference);
    }
    if (!nullToAbsent || formalityPreference != null) {
      map['formality_preference'] = Variable<int>(formalityPreference);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  UserProfileCompanion toCompanion(bool nullToAbsent) {
    return UserProfileCompanion(
      id: Value(id),
      preferredStyles: Value(preferredStyles),
      favoredColors: Value(favoredColors),
      avoidedColors: Value(avoidedColors),
      fitPreference: fitPreference == null && nullToAbsent
          ? const Value.absent()
          : Value(fitPreference),
      formalityPreference: formalityPreference == null && nullToAbsent
          ? const Value.absent()
          : Value(formalityPreference),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserProfileData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfileData(
      id: serializer.fromJson<String>(json['id']),
      preferredStyles: serializer.fromJson<String>(json['preferredStyles']),
      favoredColors: serializer.fromJson<String>(json['favoredColors']),
      avoidedColors: serializer.fromJson<String>(json['avoidedColors']),
      fitPreference: serializer.fromJson<String?>(json['fitPreference']),
      formalityPreference: serializer.fromJson<int?>(
        json['formalityPreference'],
      ),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'preferredStyles': serializer.toJson<String>(preferredStyles),
      'favoredColors': serializer.toJson<String>(favoredColors),
      'avoidedColors': serializer.toJson<String>(avoidedColors),
      'fitPreference': serializer.toJson<String?>(fitPreference),
      'formalityPreference': serializer.toJson<int?>(formalityPreference),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  UserProfileData copyWith({
    String? id,
    String? preferredStyles,
    String? favoredColors,
    String? avoidedColors,
    Value<String?> fitPreference = const Value.absent(),
    Value<int?> formalityPreference = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => UserProfileData(
    id: id ?? this.id,
    preferredStyles: preferredStyles ?? this.preferredStyles,
    favoredColors: favoredColors ?? this.favoredColors,
    avoidedColors: avoidedColors ?? this.avoidedColors,
    fitPreference: fitPreference.present
        ? fitPreference.value
        : this.fitPreference,
    formalityPreference: formalityPreference.present
        ? formalityPreference.value
        : this.formalityPreference,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserProfileData copyWithCompanion(UserProfileCompanion data) {
    return UserProfileData(
      id: data.id.present ? data.id.value : this.id,
      preferredStyles: data.preferredStyles.present
          ? data.preferredStyles.value
          : this.preferredStyles,
      favoredColors: data.favoredColors.present
          ? data.favoredColors.value
          : this.favoredColors,
      avoidedColors: data.avoidedColors.present
          ? data.avoidedColors.value
          : this.avoidedColors,
      fitPreference: data.fitPreference.present
          ? data.fitPreference.value
          : this.fitPreference,
      formalityPreference: data.formalityPreference.present
          ? data.formalityPreference.value
          : this.formalityPreference,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileData(')
          ..write('id: $id, ')
          ..write('preferredStyles: $preferredStyles, ')
          ..write('favoredColors: $favoredColors, ')
          ..write('avoidedColors: $avoidedColors, ')
          ..write('fitPreference: $fitPreference, ')
          ..write('formalityPreference: $formalityPreference, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    preferredStyles,
    favoredColors,
    avoidedColors,
    fitPreference,
    formalityPreference,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfileData &&
          other.id == this.id &&
          other.preferredStyles == this.preferredStyles &&
          other.favoredColors == this.favoredColors &&
          other.avoidedColors == this.avoidedColors &&
          other.fitPreference == this.fitPreference &&
          other.formalityPreference == this.formalityPreference &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UserProfileCompanion extends UpdateCompanion<UserProfileData> {
  final Value<String> id;
  final Value<String> preferredStyles;
  final Value<String> favoredColors;
  final Value<String> avoidedColors;
  final Value<String?> fitPreference;
  final Value<int?> formalityPreference;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const UserProfileCompanion({
    this.id = const Value.absent(),
    this.preferredStyles = const Value.absent(),
    this.favoredColors = const Value.absent(),
    this.avoidedColors = const Value.absent(),
    this.fitPreference = const Value.absent(),
    this.formalityPreference = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserProfileCompanion.insert({
    required String id,
    this.preferredStyles = const Value.absent(),
    this.favoredColors = const Value.absent(),
    this.avoidedColors = const Value.absent(),
    this.fitPreference = const Value.absent(),
    this.formalityPreference = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<UserProfileData> custom({
    Expression<String>? id,
    Expression<String>? preferredStyles,
    Expression<String>? favoredColors,
    Expression<String>? avoidedColors,
    Expression<String>? fitPreference,
    Expression<int>? formalityPreference,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (preferredStyles != null) 'preferred_styles': preferredStyles,
      if (favoredColors != null) 'favored_colors': favoredColors,
      if (avoidedColors != null) 'avoided_colors': avoidedColors,
      if (fitPreference != null) 'fit_preference': fitPreference,
      if (formalityPreference != null)
        'formality_preference': formalityPreference,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserProfileCompanion copyWith({
    Value<String>? id,
    Value<String>? preferredStyles,
    Value<String>? favoredColors,
    Value<String>? avoidedColors,
    Value<String?>? fitPreference,
    Value<int?>? formalityPreference,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return UserProfileCompanion(
      id: id ?? this.id,
      preferredStyles: preferredStyles ?? this.preferredStyles,
      favoredColors: favoredColors ?? this.favoredColors,
      avoidedColors: avoidedColors ?? this.avoidedColors,
      fitPreference: fitPreference ?? this.fitPreference,
      formalityPreference: formalityPreference ?? this.formalityPreference,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (preferredStyles.present) {
      map['preferred_styles'] = Variable<String>(preferredStyles.value);
    }
    if (favoredColors.present) {
      map['favored_colors'] = Variable<String>(favoredColors.value);
    }
    if (avoidedColors.present) {
      map['avoided_colors'] = Variable<String>(avoidedColors.value);
    }
    if (fitPreference.present) {
      map['fit_preference'] = Variable<String>(fitPreference.value);
    }
    if (formalityPreference.present) {
      map['formality_preference'] = Variable<int>(formalityPreference.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileCompanion(')
          ..write('id: $id, ')
          ..write('preferredStyles: $preferredStyles, ')
          ..write('favoredColors: $favoredColors, ')
          ..write('avoidedColors: $avoidedColors, ')
          ..write('fitPreference: $fitPreference, ')
          ..write('formalityPreference: $formalityPreference, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClothingItemsTable extends ClothingItems
    with TableInfo<$ClothingItemsTable, ClothingItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClothingItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subcategoryMeta = const VerificationMeta(
    'subcategory',
  );
  @override
  late final GeneratedColumn<String> subcategory = GeneratedColumn<String>(
    'subcategory',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _primaryColorMeta = const VerificationMeta(
    'primaryColor',
  );
  @override
  late final GeneratedColumn<String> primaryColor = GeneratedColumn<String>(
    'primary_color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _patternMeta = const VerificationMeta(
    'pattern',
  );
  @override
  late final GeneratedColumn<String> pattern = GeneratedColumn<String>(
    'pattern',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _formalityMeta = const VerificationMeta(
    'formality',
  );
  @override
  late final GeneratedColumn<int> formality = GeneratedColumn<int>(
    'formality',
    aliasedName,
    true,
    check: () =>
        formality.isNull() | ComparableExpr(formality).isBetweenValues(1, 5),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fitMeta = const VerificationMeta('fit');
  @override
  late final GeneratedColumn<String> fit = GeneratedColumn<String>(
    'fit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _warmthMeta = const VerificationMeta('warmth');
  @override
  late final GeneratedColumn<int> warmth = GeneratedColumn<int>(
    'warmth',
    aliasedName,
    true,
    check: () => warmth.isNull() | ComparableExpr(warmth).isBetweenValues(1, 3),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentSha256Meta = const VerificationMeta(
    'contentSha256',
  );
  @override
  late final GeneratedColumn<String> contentSha256 = GeneratedColumn<String>(
    'content_sha256',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    category,
    subcategory,
    displayName,
    notes,
    primaryColor,
    pattern,
    formality,
    fit,
    brand,
    warmth,
    status,
    contentSha256,
    deletedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clothing_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClothingItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('subcategory')) {
      context.handle(
        _subcategoryMeta,
        subcategory.isAcceptableOrUnknown(
          data['subcategory']!,
          _subcategoryMeta,
        ),
      );
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('primary_color')) {
      context.handle(
        _primaryColorMeta,
        primaryColor.isAcceptableOrUnknown(
          data['primary_color']!,
          _primaryColorMeta,
        ),
      );
    }
    if (data.containsKey('pattern')) {
      context.handle(
        _patternMeta,
        pattern.isAcceptableOrUnknown(data['pattern']!, _patternMeta),
      );
    }
    if (data.containsKey('formality')) {
      context.handle(
        _formalityMeta,
        formality.isAcceptableOrUnknown(data['formality']!, _formalityMeta),
      );
    }
    if (data.containsKey('fit')) {
      context.handle(
        _fitMeta,
        fit.isAcceptableOrUnknown(data['fit']!, _fitMeta),
      );
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('warmth')) {
      context.handle(
        _warmthMeta,
        warmth.isAcceptableOrUnknown(data['warmth']!, _warmthMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('content_sha256')) {
      context.handle(
        _contentSha256Meta,
        contentSha256.isAcceptableOrUnknown(
          data['content_sha256']!,
          _contentSha256Meta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClothingItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClothingItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      subcategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subcategory'],
      ),
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      primaryColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}primary_color'],
      ),
      pattern: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pattern'],
      ),
      formality: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}formality'],
      ),
      fit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fit'],
      ),
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      warmth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}warmth'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      contentSha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_sha256'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ClothingItemsTable createAlias(String alias) {
    return $ClothingItemsTable(attachedDatabase, alias);
  }
}

class ClothingItem extends DataClass implements Insertable<ClothingItem> {
  final String id;
  final String category;
  final String? subcategory;
  final String? displayName;
  final String? notes;
  final String? primaryColor;
  final String? pattern;

  /// Formality level 1–5; null when unknown.
  final int? formality;
  final String? fit;
  final String? brand;

  /// Warmth level 1–3; null when unknown (proposed addition for weather).
  final int? warmth;

  /// DRAFT, ACTIVE or ARCHIVED (ItemStatus codes).
  final String status;

  /// SHA-256 of the original image bytes, used for duplicate detection.
  final String? contentSha256;

  /// Set when the user deletes an item that outfit history still references.
  /// Such tombstones are never shown or used for new outfits.
  final int? deletedAt;
  final int createdAt;
  final int updatedAt;
  const ClothingItem({
    required this.id,
    required this.category,
    this.subcategory,
    this.displayName,
    this.notes,
    this.primaryColor,
    this.pattern,
    this.formality,
    this.fit,
    this.brand,
    this.warmth,
    required this.status,
    this.contentSha256,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || subcategory != null) {
      map['subcategory'] = Variable<String>(subcategory);
    }
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || primaryColor != null) {
      map['primary_color'] = Variable<String>(primaryColor);
    }
    if (!nullToAbsent || pattern != null) {
      map['pattern'] = Variable<String>(pattern);
    }
    if (!nullToAbsent || formality != null) {
      map['formality'] = Variable<int>(formality);
    }
    if (!nullToAbsent || fit != null) {
      map['fit'] = Variable<String>(fit);
    }
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    if (!nullToAbsent || warmth != null) {
      map['warmth'] = Variable<int>(warmth);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || contentSha256 != null) {
      map['content_sha256'] = Variable<String>(contentSha256);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ClothingItemsCompanion toCompanion(bool nullToAbsent) {
    return ClothingItemsCompanion(
      id: Value(id),
      category: Value(category),
      subcategory: subcategory == null && nullToAbsent
          ? const Value.absent()
          : Value(subcategory),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      primaryColor: primaryColor == null && nullToAbsent
          ? const Value.absent()
          : Value(primaryColor),
      pattern: pattern == null && nullToAbsent
          ? const Value.absent()
          : Value(pattern),
      formality: formality == null && nullToAbsent
          ? const Value.absent()
          : Value(formality),
      fit: fit == null && nullToAbsent ? const Value.absent() : Value(fit),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      warmth: warmth == null && nullToAbsent
          ? const Value.absent()
          : Value(warmth),
      status: Value(status),
      contentSha256: contentSha256 == null && nullToAbsent
          ? const Value.absent()
          : Value(contentSha256),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ClothingItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClothingItem(
      id: serializer.fromJson<String>(json['id']),
      category: serializer.fromJson<String>(json['category']),
      subcategory: serializer.fromJson<String?>(json['subcategory']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      notes: serializer.fromJson<String?>(json['notes']),
      primaryColor: serializer.fromJson<String?>(json['primaryColor']),
      pattern: serializer.fromJson<String?>(json['pattern']),
      formality: serializer.fromJson<int?>(json['formality']),
      fit: serializer.fromJson<String?>(json['fit']),
      brand: serializer.fromJson<String?>(json['brand']),
      warmth: serializer.fromJson<int?>(json['warmth']),
      status: serializer.fromJson<String>(json['status']),
      contentSha256: serializer.fromJson<String?>(json['contentSha256']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'category': serializer.toJson<String>(category),
      'subcategory': serializer.toJson<String?>(subcategory),
      'displayName': serializer.toJson<String?>(displayName),
      'notes': serializer.toJson<String?>(notes),
      'primaryColor': serializer.toJson<String?>(primaryColor),
      'pattern': serializer.toJson<String?>(pattern),
      'formality': serializer.toJson<int?>(formality),
      'fit': serializer.toJson<String?>(fit),
      'brand': serializer.toJson<String?>(brand),
      'warmth': serializer.toJson<int?>(warmth),
      'status': serializer.toJson<String>(status),
      'contentSha256': serializer.toJson<String?>(contentSha256),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ClothingItem copyWith({
    String? id,
    String? category,
    Value<String?> subcategory = const Value.absent(),
    Value<String?> displayName = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> primaryColor = const Value.absent(),
    Value<String?> pattern = const Value.absent(),
    Value<int?> formality = const Value.absent(),
    Value<String?> fit = const Value.absent(),
    Value<String?> brand = const Value.absent(),
    Value<int?> warmth = const Value.absent(),
    String? status,
    Value<String?> contentSha256 = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => ClothingItem(
    id: id ?? this.id,
    category: category ?? this.category,
    subcategory: subcategory.present ? subcategory.value : this.subcategory,
    displayName: displayName.present ? displayName.value : this.displayName,
    notes: notes.present ? notes.value : this.notes,
    primaryColor: primaryColor.present ? primaryColor.value : this.primaryColor,
    pattern: pattern.present ? pattern.value : this.pattern,
    formality: formality.present ? formality.value : this.formality,
    fit: fit.present ? fit.value : this.fit,
    brand: brand.present ? brand.value : this.brand,
    warmth: warmth.present ? warmth.value : this.warmth,
    status: status ?? this.status,
    contentSha256: contentSha256.present
        ? contentSha256.value
        : this.contentSha256,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ClothingItem copyWithCompanion(ClothingItemsCompanion data) {
    return ClothingItem(
      id: data.id.present ? data.id.value : this.id,
      category: data.category.present ? data.category.value : this.category,
      subcategory: data.subcategory.present
          ? data.subcategory.value
          : this.subcategory,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      notes: data.notes.present ? data.notes.value : this.notes,
      primaryColor: data.primaryColor.present
          ? data.primaryColor.value
          : this.primaryColor,
      pattern: data.pattern.present ? data.pattern.value : this.pattern,
      formality: data.formality.present ? data.formality.value : this.formality,
      fit: data.fit.present ? data.fit.value : this.fit,
      brand: data.brand.present ? data.brand.value : this.brand,
      warmth: data.warmth.present ? data.warmth.value : this.warmth,
      status: data.status.present ? data.status.value : this.status,
      contentSha256: data.contentSha256.present
          ? data.contentSha256.value
          : this.contentSha256,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClothingItem(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('subcategory: $subcategory, ')
          ..write('displayName: $displayName, ')
          ..write('notes: $notes, ')
          ..write('primaryColor: $primaryColor, ')
          ..write('pattern: $pattern, ')
          ..write('formality: $formality, ')
          ..write('fit: $fit, ')
          ..write('brand: $brand, ')
          ..write('warmth: $warmth, ')
          ..write('status: $status, ')
          ..write('contentSha256: $contentSha256, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    category,
    subcategory,
    displayName,
    notes,
    primaryColor,
    pattern,
    formality,
    fit,
    brand,
    warmth,
    status,
    contentSha256,
    deletedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClothingItem &&
          other.id == this.id &&
          other.category == this.category &&
          other.subcategory == this.subcategory &&
          other.displayName == this.displayName &&
          other.notes == this.notes &&
          other.primaryColor == this.primaryColor &&
          other.pattern == this.pattern &&
          other.formality == this.formality &&
          other.fit == this.fit &&
          other.brand == this.brand &&
          other.warmth == this.warmth &&
          other.status == this.status &&
          other.contentSha256 == this.contentSha256 &&
          other.deletedAt == this.deletedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ClothingItemsCompanion extends UpdateCompanion<ClothingItem> {
  final Value<String> id;
  final Value<String> category;
  final Value<String?> subcategory;
  final Value<String?> displayName;
  final Value<String?> notes;
  final Value<String?> primaryColor;
  final Value<String?> pattern;
  final Value<int?> formality;
  final Value<String?> fit;
  final Value<String?> brand;
  final Value<int?> warmth;
  final Value<String> status;
  final Value<String?> contentSha256;
  final Value<int?> deletedAt;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const ClothingItemsCompanion({
    this.id = const Value.absent(),
    this.category = const Value.absent(),
    this.subcategory = const Value.absent(),
    this.displayName = const Value.absent(),
    this.notes = const Value.absent(),
    this.primaryColor = const Value.absent(),
    this.pattern = const Value.absent(),
    this.formality = const Value.absent(),
    this.fit = const Value.absent(),
    this.brand = const Value.absent(),
    this.warmth = const Value.absent(),
    this.status = const Value.absent(),
    this.contentSha256 = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClothingItemsCompanion.insert({
    required String id,
    required String category,
    this.subcategory = const Value.absent(),
    this.displayName = const Value.absent(),
    this.notes = const Value.absent(),
    this.primaryColor = const Value.absent(),
    this.pattern = const Value.absent(),
    this.formality = const Value.absent(),
    this.fit = const Value.absent(),
    this.brand = const Value.absent(),
    this.warmth = const Value.absent(),
    required String status,
    this.contentSha256 = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       category = Value(category),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ClothingItem> custom({
    Expression<String>? id,
    Expression<String>? category,
    Expression<String>? subcategory,
    Expression<String>? displayName,
    Expression<String>? notes,
    Expression<String>? primaryColor,
    Expression<String>? pattern,
    Expression<int>? formality,
    Expression<String>? fit,
    Expression<String>? brand,
    Expression<int>? warmth,
    Expression<String>? status,
    Expression<String>? contentSha256,
    Expression<int>? deletedAt,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (category != null) 'category': category,
      if (subcategory != null) 'subcategory': subcategory,
      if (displayName != null) 'display_name': displayName,
      if (notes != null) 'notes': notes,
      if (primaryColor != null) 'primary_color': primaryColor,
      if (pattern != null) 'pattern': pattern,
      if (formality != null) 'formality': formality,
      if (fit != null) 'fit': fit,
      if (brand != null) 'brand': brand,
      if (warmth != null) 'warmth': warmth,
      if (status != null) 'status': status,
      if (contentSha256 != null) 'content_sha256': contentSha256,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClothingItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? category,
    Value<String?>? subcategory,
    Value<String?>? displayName,
    Value<String?>? notes,
    Value<String?>? primaryColor,
    Value<String?>? pattern,
    Value<int?>? formality,
    Value<String?>? fit,
    Value<String?>? brand,
    Value<int?>? warmth,
    Value<String>? status,
    Value<String?>? contentSha256,
    Value<int?>? deletedAt,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return ClothingItemsCompanion(
      id: id ?? this.id,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      displayName: displayName ?? this.displayName,
      notes: notes ?? this.notes,
      primaryColor: primaryColor ?? this.primaryColor,
      pattern: pattern ?? this.pattern,
      formality: formality ?? this.formality,
      fit: fit ?? this.fit,
      brand: brand ?? this.brand,
      warmth: warmth ?? this.warmth,
      status: status ?? this.status,
      contentSha256: contentSha256 ?? this.contentSha256,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (subcategory.present) {
      map['subcategory'] = Variable<String>(subcategory.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (primaryColor.present) {
      map['primary_color'] = Variable<String>(primaryColor.value);
    }
    if (pattern.present) {
      map['pattern'] = Variable<String>(pattern.value);
    }
    if (formality.present) {
      map['formality'] = Variable<int>(formality.value);
    }
    if (fit.present) {
      map['fit'] = Variable<String>(fit.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (warmth.present) {
      map['warmth'] = Variable<int>(warmth.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (contentSha256.present) {
      map['content_sha256'] = Variable<String>(contentSha256.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClothingItemsCompanion(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('subcategory: $subcategory, ')
          ..write('displayName: $displayName, ')
          ..write('notes: $notes, ')
          ..write('primaryColor: $primaryColor, ')
          ..write('pattern: $pattern, ')
          ..write('formality: $formality, ')
          ..write('fit: $fit, ')
          ..write('brand: $brand, ')
          ..write('warmth: $warmth, ')
          ..write('status: $status, ')
          ..write('contentSha256: $contentSha256, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClothingItemColorsTable extends ClothingItemColors
    with TableInfo<$ClothingItemColorsTable, ClothingItemColor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClothingItemColorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES clothing_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [itemId, color, role];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clothing_item_colors';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClothingItemColor> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId, color, role};
  @override
  ClothingItemColor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClothingItemColor(
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
    );
  }

  @override
  $ClothingItemColorsTable createAlias(String alias) {
    return $ClothingItemColorsTable(attachedDatabase, alias);
  }
}

class ClothingItemColor extends DataClass
    implements Insertable<ClothingItemColor> {
  final String itemId;
  final String color;

  /// PRIMARY or SECONDARY.
  final String role;
  const ClothingItemColor({
    required this.itemId,
    required this.color,
    required this.role,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<String>(itemId);
    map['color'] = Variable<String>(color);
    map['role'] = Variable<String>(role);
    return map;
  }

  ClothingItemColorsCompanion toCompanion(bool nullToAbsent) {
    return ClothingItemColorsCompanion(
      itemId: Value(itemId),
      color: Value(color),
      role: Value(role),
    );
  }

  factory ClothingItemColor.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClothingItemColor(
      itemId: serializer.fromJson<String>(json['itemId']),
      color: serializer.fromJson<String>(json['color']),
      role: serializer.fromJson<String>(json['role']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<String>(itemId),
      'color': serializer.toJson<String>(color),
      'role': serializer.toJson<String>(role),
    };
  }

  ClothingItemColor copyWith({String? itemId, String? color, String? role}) =>
      ClothingItemColor(
        itemId: itemId ?? this.itemId,
        color: color ?? this.color,
        role: role ?? this.role,
      );
  ClothingItemColor copyWithCompanion(ClothingItemColorsCompanion data) {
    return ClothingItemColor(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      color: data.color.present ? data.color.value : this.color,
      role: data.role.present ? data.role.value : this.role,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClothingItemColor(')
          ..write('itemId: $itemId, ')
          ..write('color: $color, ')
          ..write('role: $role')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(itemId, color, role);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClothingItemColor &&
          other.itemId == this.itemId &&
          other.color == this.color &&
          other.role == this.role);
}

class ClothingItemColorsCompanion extends UpdateCompanion<ClothingItemColor> {
  final Value<String> itemId;
  final Value<String> color;
  final Value<String> role;
  final Value<int> rowid;
  const ClothingItemColorsCompanion({
    this.itemId = const Value.absent(),
    this.color = const Value.absent(),
    this.role = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClothingItemColorsCompanion.insert({
    required String itemId,
    required String color,
    required String role,
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       color = Value(color),
       role = Value(role);
  static Insertable<ClothingItemColor> custom({
    Expression<String>? itemId,
    Expression<String>? color,
    Expression<String>? role,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (color != null) 'color': color,
      if (role != null) 'role': role,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClothingItemColorsCompanion copyWith({
    Value<String>? itemId,
    Value<String>? color,
    Value<String>? role,
    Value<int>? rowid,
  }) {
    return ClothingItemColorsCompanion(
      itemId: itemId ?? this.itemId,
      color: color ?? this.color,
      role: role ?? this.role,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClothingItemColorsCompanion(')
          ..write('itemId: $itemId, ')
          ..write('color: $color, ')
          ..write('role: $role, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClothingItemSeasonsTable extends ClothingItemSeasons
    with TableInfo<$ClothingItemSeasonsTable, ClothingItemSeason> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClothingItemSeasonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES clothing_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _seasonMeta = const VerificationMeta('season');
  @override
  late final GeneratedColumn<String> season = GeneratedColumn<String>(
    'season',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [itemId, season];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clothing_item_seasons';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClothingItemSeason> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('season')) {
      context.handle(
        _seasonMeta,
        season.isAcceptableOrUnknown(data['season']!, _seasonMeta),
      );
    } else if (isInserting) {
      context.missing(_seasonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId, season};
  @override
  ClothingItemSeason map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClothingItemSeason(
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      season: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}season'],
      )!,
    );
  }

  @override
  $ClothingItemSeasonsTable createAlias(String alias) {
    return $ClothingItemSeasonsTable(attachedDatabase, alias);
  }
}

class ClothingItemSeason extends DataClass
    implements Insertable<ClothingItemSeason> {
  final String itemId;

  /// Season code.
  final String season;
  const ClothingItemSeason({required this.itemId, required this.season});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<String>(itemId);
    map['season'] = Variable<String>(season);
    return map;
  }

  ClothingItemSeasonsCompanion toCompanion(bool nullToAbsent) {
    return ClothingItemSeasonsCompanion(
      itemId: Value(itemId),
      season: Value(season),
    );
  }

  factory ClothingItemSeason.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClothingItemSeason(
      itemId: serializer.fromJson<String>(json['itemId']),
      season: serializer.fromJson<String>(json['season']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<String>(itemId),
      'season': serializer.toJson<String>(season),
    };
  }

  ClothingItemSeason copyWith({String? itemId, String? season}) =>
      ClothingItemSeason(
        itemId: itemId ?? this.itemId,
        season: season ?? this.season,
      );
  ClothingItemSeason copyWithCompanion(ClothingItemSeasonsCompanion data) {
    return ClothingItemSeason(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      season: data.season.present ? data.season.value : this.season,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClothingItemSeason(')
          ..write('itemId: $itemId, ')
          ..write('season: $season')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(itemId, season);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClothingItemSeason &&
          other.itemId == this.itemId &&
          other.season == this.season);
}

class ClothingItemSeasonsCompanion extends UpdateCompanion<ClothingItemSeason> {
  final Value<String> itemId;
  final Value<String> season;
  final Value<int> rowid;
  const ClothingItemSeasonsCompanion({
    this.itemId = const Value.absent(),
    this.season = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClothingItemSeasonsCompanion.insert({
    required String itemId,
    required String season,
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       season = Value(season);
  static Insertable<ClothingItemSeason> custom({
    Expression<String>? itemId,
    Expression<String>? season,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (season != null) 'season': season,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClothingItemSeasonsCompanion copyWith({
    Value<String>? itemId,
    Value<String>? season,
    Value<int>? rowid,
  }) {
    return ClothingItemSeasonsCompanion(
      itemId: itemId ?? this.itemId,
      season: season ?? this.season,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (season.present) {
      map['season'] = Variable<String>(season.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClothingItemSeasonsCompanion(')
          ..write('itemId: $itemId, ')
          ..write('season: $season, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClothingImagesTable extends ClothingImages
    with TableInfo<$ClothingImagesTable, ClothingImage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClothingImagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES clothing_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relativePathMeta = const VerificationMeta(
    'relativePath',
  );
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
    'relative_path',
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
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _byteSizeMeta = const VerificationMeta(
    'byteSize',
  );
  @override
  late final GeneratedColumn<int> byteSize = GeneratedColumn<int>(
    'byte_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    kind,
    relativePath,
    width,
    height,
    byteSize,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clothing_images';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClothingImage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
        _relativePathMeta,
        relativePath.isAcceptableOrUnknown(
          data['relative_path']!,
          _relativePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('byte_size')) {
      context.handle(
        _byteSizeMeta,
        byteSize.isAcceptableOrUnknown(data['byte_size']!, _byteSizeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClothingImage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClothingImage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      relativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_path'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      ),
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      ),
      byteSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_size'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ClothingImagesTable createAlias(String alias) {
    return $ClothingImagesTable(attachedDatabase, alias);
  }
}

class ClothingImage extends DataClass implements Insertable<ClothingImage> {
  final String id;
  final String itemId;

  /// ORIGINAL, WORKING, THUMBNAIL or CUTOUT.
  final String kind;

  /// Path relative to the app's private storage root. Never absolute.
  final String relativePath;
  final int? width;
  final int? height;
  final int? byteSize;
  final int createdAt;
  const ClothingImage({
    required this.id,
    required this.itemId,
    required this.kind,
    required this.relativePath,
    this.width,
    this.height,
    this.byteSize,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['item_id'] = Variable<String>(itemId);
    map['kind'] = Variable<String>(kind);
    map['relative_path'] = Variable<String>(relativePath);
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || byteSize != null) {
      map['byte_size'] = Variable<int>(byteSize);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  ClothingImagesCompanion toCompanion(bool nullToAbsent) {
    return ClothingImagesCompanion(
      id: Value(id),
      itemId: Value(itemId),
      kind: Value(kind),
      relativePath: Value(relativePath),
      width: width == null && nullToAbsent
          ? const Value.absent()
          : Value(width),
      height: height == null && nullToAbsent
          ? const Value.absent()
          : Value(height),
      byteSize: byteSize == null && nullToAbsent
          ? const Value.absent()
          : Value(byteSize),
      createdAt: Value(createdAt),
    );
  }

  factory ClothingImage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClothingImage(
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      kind: serializer.fromJson<String>(json['kind']),
      relativePath: serializer.fromJson<String>(json['relativePath']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      byteSize: serializer.fromJson<int?>(json['byteSize']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String>(itemId),
      'kind': serializer.toJson<String>(kind),
      'relativePath': serializer.toJson<String>(relativePath),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'byteSize': serializer.toJson<int?>(byteSize),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  ClothingImage copyWith({
    String? id,
    String? itemId,
    String? kind,
    String? relativePath,
    Value<int?> width = const Value.absent(),
    Value<int?> height = const Value.absent(),
    Value<int?> byteSize = const Value.absent(),
    int? createdAt,
  }) => ClothingImage(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    kind: kind ?? this.kind,
    relativePath: relativePath ?? this.relativePath,
    width: width.present ? width.value : this.width,
    height: height.present ? height.value : this.height,
    byteSize: byteSize.present ? byteSize.value : this.byteSize,
    createdAt: createdAt ?? this.createdAt,
  );
  ClothingImage copyWithCompanion(ClothingImagesCompanion data) {
    return ClothingImage(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      kind: data.kind.present ? data.kind.value : this.kind,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      byteSize: data.byteSize.present ? data.byteSize.value : this.byteSize,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClothingImage(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('kind: $kind, ')
          ..write('relativePath: $relativePath, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('byteSize: $byteSize, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    kind,
    relativePath,
    width,
    height,
    byteSize,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClothingImage &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.kind == this.kind &&
          other.relativePath == this.relativePath &&
          other.width == this.width &&
          other.height == this.height &&
          other.byteSize == this.byteSize &&
          other.createdAt == this.createdAt);
}

class ClothingImagesCompanion extends UpdateCompanion<ClothingImage> {
  final Value<String> id;
  final Value<String> itemId;
  final Value<String> kind;
  final Value<String> relativePath;
  final Value<int?> width;
  final Value<int?> height;
  final Value<int?> byteSize;
  final Value<int> createdAt;
  final Value<int> rowid;
  const ClothingImagesCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.kind = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClothingImagesCompanion.insert({
    required String id,
    required String itemId,
    required String kind,
    required String relativePath,
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.byteSize = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itemId = Value(itemId),
       kind = Value(kind),
       relativePath = Value(relativePath),
       createdAt = Value(createdAt);
  static Insertable<ClothingImage> custom({
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<String>? kind,
    Expression<String>? relativePath,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? byteSize,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (kind != null) 'kind': kind,
      if (relativePath != null) 'relative_path': relativePath,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (byteSize != null) 'byte_size': byteSize,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClothingImagesCompanion copyWith({
    Value<String>? id,
    Value<String>? itemId,
    Value<String>? kind,
    Value<String>? relativePath,
    Value<int?>? width,
    Value<int?>? height,
    Value<int?>? byteSize,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return ClothingImagesCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      kind: kind ?? this.kind,
      relativePath: relativePath ?? this.relativePath,
      width: width ?? this.width,
      height: height ?? this.height,
      byteSize: byteSize ?? this.byteSize,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (byteSize.present) {
      map['byte_size'] = Variable<int>(byteSize.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClothingImagesCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('kind: $kind, ')
          ..write('relativePath: $relativePath, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('byteSize: $byteSize, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClothingAttributesTable extends ClothingAttributes
    with TableInfo<$ClothingAttributesTable, ClothingAttribute> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClothingAttributesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES clothing_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _attributeMeta = const VerificationMeta(
    'attribute',
  );
  @override
  late final GeneratedColumn<String> attribute = GeneratedColumn<String>(
    'attribute',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    true,
    check: () =>
        confidence.isNull() | ComparableExpr(confidence).isBetweenValues(0, 1),
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelIdMeta = const VerificationMeta(
    'modelId',
  );
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
    'model_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelVersionMeta = const VerificationMeta(
    'modelVersion',
  );
  @override
  late final GeneratedColumn<String> modelVersion = GeneratedColumn<String>(
    'model_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _analyzedAtMeta = const VerificationMeta(
    'analyzedAt',
  );
  @override
  late final GeneratedColumn<int> analyzedAt = GeneratedColumn<int>(
    'analyzed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userConfirmedMeta = const VerificationMeta(
    'userConfirmed',
  );
  @override
  late final GeneratedColumn<bool> userConfirmed = GeneratedColumn<bool>(
    'user_confirmed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("user_confirmed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    attribute,
    value,
    confidence,
    modelId,
    modelVersion,
    analyzedAt,
    userConfirmed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clothing_attributes';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClothingAttribute> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('attribute')) {
      context.handle(
        _attributeMeta,
        attribute.isAcceptableOrUnknown(data['attribute']!, _attributeMeta),
      );
    } else if (isInserting) {
      context.missing(_attributeMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    if (data.containsKey('model_id')) {
      context.handle(
        _modelIdMeta,
        modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta),
      );
    }
    if (data.containsKey('model_version')) {
      context.handle(
        _modelVersionMeta,
        modelVersion.isAcceptableOrUnknown(
          data['model_version']!,
          _modelVersionMeta,
        ),
      );
    }
    if (data.containsKey('analyzed_at')) {
      context.handle(
        _analyzedAtMeta,
        analyzedAt.isAcceptableOrUnknown(data['analyzed_at']!, _analyzedAtMeta),
      );
    }
    if (data.containsKey('user_confirmed')) {
      context.handle(
        _userConfirmedMeta,
        userConfirmed.isAcceptableOrUnknown(
          data['user_confirmed']!,
          _userConfirmedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClothingAttribute map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClothingAttribute(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      attribute: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attribute'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      ),
      modelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_id'],
      ),
      modelVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_version'],
      ),
      analyzedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}analyzed_at'],
      ),
      userConfirmed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}user_confirmed'],
      )!,
    );
  }

  @override
  $ClothingAttributesTable createAlias(String alias) {
    return $ClothingAttributesTable(attachedDatabase, alias);
  }
}

class ClothingAttribute extends DataClass
    implements Insertable<ClothingAttribute> {
  final String id;
  final String itemId;
  final String attribute;
  final String value;
  final double? confidence;
  final String? modelId;
  final String? modelVersion;
  final int? analyzedAt;
  final bool userConfirmed;
  const ClothingAttribute({
    required this.id,
    required this.itemId,
    required this.attribute,
    required this.value,
    this.confidence,
    this.modelId,
    this.modelVersion,
    this.analyzedAt,
    required this.userConfirmed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['item_id'] = Variable<String>(itemId);
    map['attribute'] = Variable<String>(attribute);
    map['value'] = Variable<String>(value);
    if (!nullToAbsent || confidence != null) {
      map['confidence'] = Variable<double>(confidence);
    }
    if (!nullToAbsent || modelId != null) {
      map['model_id'] = Variable<String>(modelId);
    }
    if (!nullToAbsent || modelVersion != null) {
      map['model_version'] = Variable<String>(modelVersion);
    }
    if (!nullToAbsent || analyzedAt != null) {
      map['analyzed_at'] = Variable<int>(analyzedAt);
    }
    map['user_confirmed'] = Variable<bool>(userConfirmed);
    return map;
  }

  ClothingAttributesCompanion toCompanion(bool nullToAbsent) {
    return ClothingAttributesCompanion(
      id: Value(id),
      itemId: Value(itemId),
      attribute: Value(attribute),
      value: Value(value),
      confidence: confidence == null && nullToAbsent
          ? const Value.absent()
          : Value(confidence),
      modelId: modelId == null && nullToAbsent
          ? const Value.absent()
          : Value(modelId),
      modelVersion: modelVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(modelVersion),
      analyzedAt: analyzedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(analyzedAt),
      userConfirmed: Value(userConfirmed),
    );
  }

  factory ClothingAttribute.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClothingAttribute(
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      attribute: serializer.fromJson<String>(json['attribute']),
      value: serializer.fromJson<String>(json['value']),
      confidence: serializer.fromJson<double?>(json['confidence']),
      modelId: serializer.fromJson<String?>(json['modelId']),
      modelVersion: serializer.fromJson<String?>(json['modelVersion']),
      analyzedAt: serializer.fromJson<int?>(json['analyzedAt']),
      userConfirmed: serializer.fromJson<bool>(json['userConfirmed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String>(itemId),
      'attribute': serializer.toJson<String>(attribute),
      'value': serializer.toJson<String>(value),
      'confidence': serializer.toJson<double?>(confidence),
      'modelId': serializer.toJson<String?>(modelId),
      'modelVersion': serializer.toJson<String?>(modelVersion),
      'analyzedAt': serializer.toJson<int?>(analyzedAt),
      'userConfirmed': serializer.toJson<bool>(userConfirmed),
    };
  }

  ClothingAttribute copyWith({
    String? id,
    String? itemId,
    String? attribute,
    String? value,
    Value<double?> confidence = const Value.absent(),
    Value<String?> modelId = const Value.absent(),
    Value<String?> modelVersion = const Value.absent(),
    Value<int?> analyzedAt = const Value.absent(),
    bool? userConfirmed,
  }) => ClothingAttribute(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    attribute: attribute ?? this.attribute,
    value: value ?? this.value,
    confidence: confidence.present ? confidence.value : this.confidence,
    modelId: modelId.present ? modelId.value : this.modelId,
    modelVersion: modelVersion.present ? modelVersion.value : this.modelVersion,
    analyzedAt: analyzedAt.present ? analyzedAt.value : this.analyzedAt,
    userConfirmed: userConfirmed ?? this.userConfirmed,
  );
  ClothingAttribute copyWithCompanion(ClothingAttributesCompanion data) {
    return ClothingAttribute(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      attribute: data.attribute.present ? data.attribute.value : this.attribute,
      value: data.value.present ? data.value.value : this.value,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      modelVersion: data.modelVersion.present
          ? data.modelVersion.value
          : this.modelVersion,
      analyzedAt: data.analyzedAt.present
          ? data.analyzedAt.value
          : this.analyzedAt,
      userConfirmed: data.userConfirmed.present
          ? data.userConfirmed.value
          : this.userConfirmed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClothingAttribute(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('attribute: $attribute, ')
          ..write('value: $value, ')
          ..write('confidence: $confidence, ')
          ..write('modelId: $modelId, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('analyzedAt: $analyzedAt, ')
          ..write('userConfirmed: $userConfirmed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    attribute,
    value,
    confidence,
    modelId,
    modelVersion,
    analyzedAt,
    userConfirmed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClothingAttribute &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.attribute == this.attribute &&
          other.value == this.value &&
          other.confidence == this.confidence &&
          other.modelId == this.modelId &&
          other.modelVersion == this.modelVersion &&
          other.analyzedAt == this.analyzedAt &&
          other.userConfirmed == this.userConfirmed);
}

class ClothingAttributesCompanion extends UpdateCompanion<ClothingAttribute> {
  final Value<String> id;
  final Value<String> itemId;
  final Value<String> attribute;
  final Value<String> value;
  final Value<double?> confidence;
  final Value<String?> modelId;
  final Value<String?> modelVersion;
  final Value<int?> analyzedAt;
  final Value<bool> userConfirmed;
  final Value<int> rowid;
  const ClothingAttributesCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.attribute = const Value.absent(),
    this.value = const Value.absent(),
    this.confidence = const Value.absent(),
    this.modelId = const Value.absent(),
    this.modelVersion = const Value.absent(),
    this.analyzedAt = const Value.absent(),
    this.userConfirmed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClothingAttributesCompanion.insert({
    required String id,
    required String itemId,
    required String attribute,
    required String value,
    this.confidence = const Value.absent(),
    this.modelId = const Value.absent(),
    this.modelVersion = const Value.absent(),
    this.analyzedAt = const Value.absent(),
    this.userConfirmed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itemId = Value(itemId),
       attribute = Value(attribute),
       value = Value(value);
  static Insertable<ClothingAttribute> custom({
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<String>? attribute,
    Expression<String>? value,
    Expression<double>? confidence,
    Expression<String>? modelId,
    Expression<String>? modelVersion,
    Expression<int>? analyzedAt,
    Expression<bool>? userConfirmed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (attribute != null) 'attribute': attribute,
      if (value != null) 'value': value,
      if (confidence != null) 'confidence': confidence,
      if (modelId != null) 'model_id': modelId,
      if (modelVersion != null) 'model_version': modelVersion,
      if (analyzedAt != null) 'analyzed_at': analyzedAt,
      if (userConfirmed != null) 'user_confirmed': userConfirmed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClothingAttributesCompanion copyWith({
    Value<String>? id,
    Value<String>? itemId,
    Value<String>? attribute,
    Value<String>? value,
    Value<double?>? confidence,
    Value<String?>? modelId,
    Value<String?>? modelVersion,
    Value<int?>? analyzedAt,
    Value<bool>? userConfirmed,
    Value<int>? rowid,
  }) {
    return ClothingAttributesCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      attribute: attribute ?? this.attribute,
      value: value ?? this.value,
      confidence: confidence ?? this.confidence,
      modelId: modelId ?? this.modelId,
      modelVersion: modelVersion ?? this.modelVersion,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      userConfirmed: userConfirmed ?? this.userConfirmed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (attribute.present) {
      map['attribute'] = Variable<String>(attribute.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (modelVersion.present) {
      map['model_version'] = Variable<String>(modelVersion.value);
    }
    if (analyzedAt.present) {
      map['analyzed_at'] = Variable<int>(analyzedAt.value);
    }
    if (userConfirmed.present) {
      map['user_confirmed'] = Variable<bool>(userConfirmed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClothingAttributesCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('attribute: $attribute, ')
          ..write('value: $value, ')
          ..write('confidence: $confidence, ')
          ..write('modelId: $modelId, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('analyzedAt: $analyzedAt, ')
          ..write('userConfirmed: $userConfirmed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutfitsTable extends Outfits with TableInfo<$OutfitsTable, Outfit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutfitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _signatureMeta = const VerificationMeta(
    'signature',
  );
  @override
  late final GeneratedColumn<String> signature = GeneratedColumn<String>(
    'signature',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occasionMeta = const VerificationMeta(
    'occasion',
  );
  @override
  late final GeneratedColumn<String> occasion = GeneratedColumn<String>(
    'occasion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requestJsonMeta = const VerificationMeta(
    'requestJson',
  );
  @override
  late final GeneratedColumn<String> requestJson = GeneratedColumn<String>(
    'request_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalScoreMeta = const VerificationMeta(
    'totalScore',
  );
  @override
  late final GeneratedColumn<double> totalScore = GeneratedColumn<double>(
    'total_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _breakdownJsonMeta = const VerificationMeta(
    'breakdownJson',
  );
  @override
  late final GeneratedColumn<String> breakdownJson = GeneratedColumn<String>(
    'breakdown_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonsJsonMeta = const VerificationMeta(
    'reasonsJson',
  );
  @override
  late final GeneratedColumn<String> reasonsJson = GeneratedColumn<String>(
    'reasons_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weatherConsideredMeta = const VerificationMeta(
    'weatherConsidered',
  );
  @override
  late final GeneratedColumn<bool> weatherConsidered = GeneratedColumn<bool>(
    'weather_considered',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("weather_considered" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    signature,
    occasion,
    requestJson,
    totalScore,
    breakdownJson,
    reasonsJson,
    weatherConsidered,
    isFavorite,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outfits';
  @override
  VerificationContext validateIntegrity(
    Insertable<Outfit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('signature')) {
      context.handle(
        _signatureMeta,
        signature.isAcceptableOrUnknown(data['signature']!, _signatureMeta),
      );
    } else if (isInserting) {
      context.missing(_signatureMeta);
    }
    if (data.containsKey('occasion')) {
      context.handle(
        _occasionMeta,
        occasion.isAcceptableOrUnknown(data['occasion']!, _occasionMeta),
      );
    } else if (isInserting) {
      context.missing(_occasionMeta);
    }
    if (data.containsKey('request_json')) {
      context.handle(
        _requestJsonMeta,
        requestJson.isAcceptableOrUnknown(
          data['request_json']!,
          _requestJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requestJsonMeta);
    }
    if (data.containsKey('total_score')) {
      context.handle(
        _totalScoreMeta,
        totalScore.isAcceptableOrUnknown(data['total_score']!, _totalScoreMeta),
      );
    } else if (isInserting) {
      context.missing(_totalScoreMeta);
    }
    if (data.containsKey('breakdown_json')) {
      context.handle(
        _breakdownJsonMeta,
        breakdownJson.isAcceptableOrUnknown(
          data['breakdown_json']!,
          _breakdownJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_breakdownJsonMeta);
    }
    if (data.containsKey('reasons_json')) {
      context.handle(
        _reasonsJsonMeta,
        reasonsJson.isAcceptableOrUnknown(
          data['reasons_json']!,
          _reasonsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reasonsJsonMeta);
    }
    if (data.containsKey('weather_considered')) {
      context.handle(
        _weatherConsideredMeta,
        weatherConsidered.isAcceptableOrUnknown(
          data['weather_considered']!,
          _weatherConsideredMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_weatherConsideredMeta);
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Outfit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Outfit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      signature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signature'],
      )!,
      occasion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occasion'],
      )!,
      requestJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request_json'],
      )!,
      totalScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_score'],
      )!,
      breakdownJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}breakdown_json'],
      )!,
      reasonsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reasons_json'],
      )!,
      weatherConsidered: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}weather_considered'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OutfitsTable createAlias(String alias) {
    return $OutfitsTable(attachedDatabase, alias);
  }
}

class Outfit extends DataClass implements Insertable<Outfit> {
  final String id;

  /// Stable hash of the sorted item IDs, used for de-duplication.
  final String signature;
  final String occasion;
  final String requestJson;
  final double totalScore;
  final String breakdownJson;
  final String reasonsJson;
  final bool weatherConsidered;
  final bool isFavorite;
  final int createdAt;
  const Outfit({
    required this.id,
    required this.signature,
    required this.occasion,
    required this.requestJson,
    required this.totalScore,
    required this.breakdownJson,
    required this.reasonsJson,
    required this.weatherConsidered,
    required this.isFavorite,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['signature'] = Variable<String>(signature);
    map['occasion'] = Variable<String>(occasion);
    map['request_json'] = Variable<String>(requestJson);
    map['total_score'] = Variable<double>(totalScore);
    map['breakdown_json'] = Variable<String>(breakdownJson);
    map['reasons_json'] = Variable<String>(reasonsJson);
    map['weather_considered'] = Variable<bool>(weatherConsidered);
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  OutfitsCompanion toCompanion(bool nullToAbsent) {
    return OutfitsCompanion(
      id: Value(id),
      signature: Value(signature),
      occasion: Value(occasion),
      requestJson: Value(requestJson),
      totalScore: Value(totalScore),
      breakdownJson: Value(breakdownJson),
      reasonsJson: Value(reasonsJson),
      weatherConsidered: Value(weatherConsidered),
      isFavorite: Value(isFavorite),
      createdAt: Value(createdAt),
    );
  }

  factory Outfit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Outfit(
      id: serializer.fromJson<String>(json['id']),
      signature: serializer.fromJson<String>(json['signature']),
      occasion: serializer.fromJson<String>(json['occasion']),
      requestJson: serializer.fromJson<String>(json['requestJson']),
      totalScore: serializer.fromJson<double>(json['totalScore']),
      breakdownJson: serializer.fromJson<String>(json['breakdownJson']),
      reasonsJson: serializer.fromJson<String>(json['reasonsJson']),
      weatherConsidered: serializer.fromJson<bool>(json['weatherConsidered']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'signature': serializer.toJson<String>(signature),
      'occasion': serializer.toJson<String>(occasion),
      'requestJson': serializer.toJson<String>(requestJson),
      'totalScore': serializer.toJson<double>(totalScore),
      'breakdownJson': serializer.toJson<String>(breakdownJson),
      'reasonsJson': serializer.toJson<String>(reasonsJson),
      'weatherConsidered': serializer.toJson<bool>(weatherConsidered),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Outfit copyWith({
    String? id,
    String? signature,
    String? occasion,
    String? requestJson,
    double? totalScore,
    String? breakdownJson,
    String? reasonsJson,
    bool? weatherConsidered,
    bool? isFavorite,
    int? createdAt,
  }) => Outfit(
    id: id ?? this.id,
    signature: signature ?? this.signature,
    occasion: occasion ?? this.occasion,
    requestJson: requestJson ?? this.requestJson,
    totalScore: totalScore ?? this.totalScore,
    breakdownJson: breakdownJson ?? this.breakdownJson,
    reasonsJson: reasonsJson ?? this.reasonsJson,
    weatherConsidered: weatherConsidered ?? this.weatherConsidered,
    isFavorite: isFavorite ?? this.isFavorite,
    createdAt: createdAt ?? this.createdAt,
  );
  Outfit copyWithCompanion(OutfitsCompanion data) {
    return Outfit(
      id: data.id.present ? data.id.value : this.id,
      signature: data.signature.present ? data.signature.value : this.signature,
      occasion: data.occasion.present ? data.occasion.value : this.occasion,
      requestJson: data.requestJson.present
          ? data.requestJson.value
          : this.requestJson,
      totalScore: data.totalScore.present
          ? data.totalScore.value
          : this.totalScore,
      breakdownJson: data.breakdownJson.present
          ? data.breakdownJson.value
          : this.breakdownJson,
      reasonsJson: data.reasonsJson.present
          ? data.reasonsJson.value
          : this.reasonsJson,
      weatherConsidered: data.weatherConsidered.present
          ? data.weatherConsidered.value
          : this.weatherConsidered,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Outfit(')
          ..write('id: $id, ')
          ..write('signature: $signature, ')
          ..write('occasion: $occasion, ')
          ..write('requestJson: $requestJson, ')
          ..write('totalScore: $totalScore, ')
          ..write('breakdownJson: $breakdownJson, ')
          ..write('reasonsJson: $reasonsJson, ')
          ..write('weatherConsidered: $weatherConsidered, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    signature,
    occasion,
    requestJson,
    totalScore,
    breakdownJson,
    reasonsJson,
    weatherConsidered,
    isFavorite,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Outfit &&
          other.id == this.id &&
          other.signature == this.signature &&
          other.occasion == this.occasion &&
          other.requestJson == this.requestJson &&
          other.totalScore == this.totalScore &&
          other.breakdownJson == this.breakdownJson &&
          other.reasonsJson == this.reasonsJson &&
          other.weatherConsidered == this.weatherConsidered &&
          other.isFavorite == this.isFavorite &&
          other.createdAt == this.createdAt);
}

class OutfitsCompanion extends UpdateCompanion<Outfit> {
  final Value<String> id;
  final Value<String> signature;
  final Value<String> occasion;
  final Value<String> requestJson;
  final Value<double> totalScore;
  final Value<String> breakdownJson;
  final Value<String> reasonsJson;
  final Value<bool> weatherConsidered;
  final Value<bool> isFavorite;
  final Value<int> createdAt;
  final Value<int> rowid;
  const OutfitsCompanion({
    this.id = const Value.absent(),
    this.signature = const Value.absent(),
    this.occasion = const Value.absent(),
    this.requestJson = const Value.absent(),
    this.totalScore = const Value.absent(),
    this.breakdownJson = const Value.absent(),
    this.reasonsJson = const Value.absent(),
    this.weatherConsidered = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutfitsCompanion.insert({
    required String id,
    required String signature,
    required String occasion,
    required String requestJson,
    required double totalScore,
    required String breakdownJson,
    required String reasonsJson,
    required bool weatherConsidered,
    this.isFavorite = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       signature = Value(signature),
       occasion = Value(occasion),
       requestJson = Value(requestJson),
       totalScore = Value(totalScore),
       breakdownJson = Value(breakdownJson),
       reasonsJson = Value(reasonsJson),
       weatherConsidered = Value(weatherConsidered),
       createdAt = Value(createdAt);
  static Insertable<Outfit> custom({
    Expression<String>? id,
    Expression<String>? signature,
    Expression<String>? occasion,
    Expression<String>? requestJson,
    Expression<double>? totalScore,
    Expression<String>? breakdownJson,
    Expression<String>? reasonsJson,
    Expression<bool>? weatherConsidered,
    Expression<bool>? isFavorite,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (signature != null) 'signature': signature,
      if (occasion != null) 'occasion': occasion,
      if (requestJson != null) 'request_json': requestJson,
      if (totalScore != null) 'total_score': totalScore,
      if (breakdownJson != null) 'breakdown_json': breakdownJson,
      if (reasonsJson != null) 'reasons_json': reasonsJson,
      if (weatherConsidered != null) 'weather_considered': weatherConsidered,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutfitsCompanion copyWith({
    Value<String>? id,
    Value<String>? signature,
    Value<String>? occasion,
    Value<String>? requestJson,
    Value<double>? totalScore,
    Value<String>? breakdownJson,
    Value<String>? reasonsJson,
    Value<bool>? weatherConsidered,
    Value<bool>? isFavorite,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return OutfitsCompanion(
      id: id ?? this.id,
      signature: signature ?? this.signature,
      occasion: occasion ?? this.occasion,
      requestJson: requestJson ?? this.requestJson,
      totalScore: totalScore ?? this.totalScore,
      breakdownJson: breakdownJson ?? this.breakdownJson,
      reasonsJson: reasonsJson ?? this.reasonsJson,
      weatherConsidered: weatherConsidered ?? this.weatherConsidered,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (signature.present) {
      map['signature'] = Variable<String>(signature.value);
    }
    if (occasion.present) {
      map['occasion'] = Variable<String>(occasion.value);
    }
    if (requestJson.present) {
      map['request_json'] = Variable<String>(requestJson.value);
    }
    if (totalScore.present) {
      map['total_score'] = Variable<double>(totalScore.value);
    }
    if (breakdownJson.present) {
      map['breakdown_json'] = Variable<String>(breakdownJson.value);
    }
    if (reasonsJson.present) {
      map['reasons_json'] = Variable<String>(reasonsJson.value);
    }
    if (weatherConsidered.present) {
      map['weather_considered'] = Variable<bool>(weatherConsidered.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutfitsCompanion(')
          ..write('id: $id, ')
          ..write('signature: $signature, ')
          ..write('occasion: $occasion, ')
          ..write('requestJson: $requestJson, ')
          ..write('totalScore: $totalScore, ')
          ..write('breakdownJson: $breakdownJson, ')
          ..write('reasonsJson: $reasonsJson, ')
          ..write('weatherConsidered: $weatherConsidered, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutfitItemsTable extends OutfitItems
    with TableInfo<$OutfitItemsTable, OutfitItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutfitItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _outfitIdMeta = const VerificationMeta(
    'outfitId',
  );
  @override
  late final GeneratedColumn<String> outfitId = GeneratedColumn<String>(
    'outfit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES outfits (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES clothing_items (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<String> slot = GeneratedColumn<String>(
    'slot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [outfitId, itemId, slot];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outfit_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutfitItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('outfit_id')) {
      context.handle(
        _outfitIdMeta,
        outfitId.isAcceptableOrUnknown(data['outfit_id']!, _outfitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_outfitIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('slot')) {
      context.handle(
        _slotMeta,
        slot.isAcceptableOrUnknown(data['slot']!, _slotMeta),
      );
    } else if (isInserting) {
      context.missing(_slotMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {outfitId, itemId};
  @override
  OutfitItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutfitItem(
      outfitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outfit_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      slot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slot'],
      )!,
    );
  }

  @override
  $OutfitItemsTable createAlias(String alias) {
    return $OutfitItemsTable(attachedDatabase, alias);
  }
}

class OutfitItem extends DataClass implements Insertable<OutfitItem> {
  final String outfitId;

  /// RESTRICT keeps outfit history intact; deleting a referenced garment
  /// becomes a tombstone (ClothingItems.deletedAt) instead.
  final String itemId;
  final String slot;
  const OutfitItem({
    required this.outfitId,
    required this.itemId,
    required this.slot,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['outfit_id'] = Variable<String>(outfitId);
    map['item_id'] = Variable<String>(itemId);
    map['slot'] = Variable<String>(slot);
    return map;
  }

  OutfitItemsCompanion toCompanion(bool nullToAbsent) {
    return OutfitItemsCompanion(
      outfitId: Value(outfitId),
      itemId: Value(itemId),
      slot: Value(slot),
    );
  }

  factory OutfitItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutfitItem(
      outfitId: serializer.fromJson<String>(json['outfitId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      slot: serializer.fromJson<String>(json['slot']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'outfitId': serializer.toJson<String>(outfitId),
      'itemId': serializer.toJson<String>(itemId),
      'slot': serializer.toJson<String>(slot),
    };
  }

  OutfitItem copyWith({String? outfitId, String? itemId, String? slot}) =>
      OutfitItem(
        outfitId: outfitId ?? this.outfitId,
        itemId: itemId ?? this.itemId,
        slot: slot ?? this.slot,
      );
  OutfitItem copyWithCompanion(OutfitItemsCompanion data) {
    return OutfitItem(
      outfitId: data.outfitId.present ? data.outfitId.value : this.outfitId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      slot: data.slot.present ? data.slot.value : this.slot,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutfitItem(')
          ..write('outfitId: $outfitId, ')
          ..write('itemId: $itemId, ')
          ..write('slot: $slot')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(outfitId, itemId, slot);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutfitItem &&
          other.outfitId == this.outfitId &&
          other.itemId == this.itemId &&
          other.slot == this.slot);
}

class OutfitItemsCompanion extends UpdateCompanion<OutfitItem> {
  final Value<String> outfitId;
  final Value<String> itemId;
  final Value<String> slot;
  final Value<int> rowid;
  const OutfitItemsCompanion({
    this.outfitId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.slot = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutfitItemsCompanion.insert({
    required String outfitId,
    required String itemId,
    required String slot,
    this.rowid = const Value.absent(),
  }) : outfitId = Value(outfitId),
       itemId = Value(itemId),
       slot = Value(slot);
  static Insertable<OutfitItem> custom({
    Expression<String>? outfitId,
    Expression<String>? itemId,
    Expression<String>? slot,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (outfitId != null) 'outfit_id': outfitId,
      if (itemId != null) 'item_id': itemId,
      if (slot != null) 'slot': slot,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutfitItemsCompanion copyWith({
    Value<String>? outfitId,
    Value<String>? itemId,
    Value<String>? slot,
    Value<int>? rowid,
  }) {
    return OutfitItemsCompanion(
      outfitId: outfitId ?? this.outfitId,
      itemId: itemId ?? this.itemId,
      slot: slot ?? this.slot,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (outfitId.present) {
      map['outfit_id'] = Variable<String>(outfitId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (slot.present) {
      map['slot'] = Variable<String>(slot.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutfitItemsCompanion(')
          ..write('outfitId: $outfitId, ')
          ..write('itemId: $itemId, ')
          ..write('slot: $slot, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutfitFeedbackTable extends OutfitFeedback
    with TableInfo<$OutfitFeedbackTable, OutfitFeedbackData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutfitFeedbackTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outfitIdMeta = const VerificationMeta(
    'outfitId',
  );
  @override
  late final GeneratedColumn<String> outfitId = GeneratedColumn<String>(
    'outfit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES outfits (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonCodeMeta = const VerificationMeta(
    'reasonCode',
  );
  @override
  late final GeneratedColumn<String> reasonCode = GeneratedColumn<String>(
    'reason_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reasonTextMeta = const VerificationMeta(
    'reasonText',
  );
  @override
  late final GeneratedColumn<String> reasonText = GeneratedColumn<String>(
    'reason_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    outfitId,
    kind,
    reasonCode,
    reasonText,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outfit_feedback';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutfitFeedbackData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('outfit_id')) {
      context.handle(
        _outfitIdMeta,
        outfitId.isAcceptableOrUnknown(data['outfit_id']!, _outfitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_outfitIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('reason_code')) {
      context.handle(
        _reasonCodeMeta,
        reasonCode.isAcceptableOrUnknown(data['reason_code']!, _reasonCodeMeta),
      );
    }
    if (data.containsKey('reason_text')) {
      context.handle(
        _reasonTextMeta,
        reasonText.isAcceptableOrUnknown(data['reason_text']!, _reasonTextMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutfitFeedbackData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutfitFeedbackData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      outfitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outfit_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      reasonCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason_code'],
      ),
      reasonText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason_text'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OutfitFeedbackTable createAlias(String alias) {
    return $OutfitFeedbackTable(attachedDatabase, alias);
  }
}

class OutfitFeedbackData extends DataClass
    implements Insertable<OutfitFeedbackData> {
  final String id;
  final String outfitId;

  /// LIKE or DISLIKE.
  final String kind;
  final String? reasonCode;
  final String? reasonText;
  final int createdAt;
  const OutfitFeedbackData({
    required this.id,
    required this.outfitId,
    required this.kind,
    this.reasonCode,
    this.reasonText,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['outfit_id'] = Variable<String>(outfitId);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || reasonCode != null) {
      map['reason_code'] = Variable<String>(reasonCode);
    }
    if (!nullToAbsent || reasonText != null) {
      map['reason_text'] = Variable<String>(reasonText);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  OutfitFeedbackCompanion toCompanion(bool nullToAbsent) {
    return OutfitFeedbackCompanion(
      id: Value(id),
      outfitId: Value(outfitId),
      kind: Value(kind),
      reasonCode: reasonCode == null && nullToAbsent
          ? const Value.absent()
          : Value(reasonCode),
      reasonText: reasonText == null && nullToAbsent
          ? const Value.absent()
          : Value(reasonText),
      createdAt: Value(createdAt),
    );
  }

  factory OutfitFeedbackData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutfitFeedbackData(
      id: serializer.fromJson<String>(json['id']),
      outfitId: serializer.fromJson<String>(json['outfitId']),
      kind: serializer.fromJson<String>(json['kind']),
      reasonCode: serializer.fromJson<String?>(json['reasonCode']),
      reasonText: serializer.fromJson<String?>(json['reasonText']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'outfitId': serializer.toJson<String>(outfitId),
      'kind': serializer.toJson<String>(kind),
      'reasonCode': serializer.toJson<String?>(reasonCode),
      'reasonText': serializer.toJson<String?>(reasonText),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  OutfitFeedbackData copyWith({
    String? id,
    String? outfitId,
    String? kind,
    Value<String?> reasonCode = const Value.absent(),
    Value<String?> reasonText = const Value.absent(),
    int? createdAt,
  }) => OutfitFeedbackData(
    id: id ?? this.id,
    outfitId: outfitId ?? this.outfitId,
    kind: kind ?? this.kind,
    reasonCode: reasonCode.present ? reasonCode.value : this.reasonCode,
    reasonText: reasonText.present ? reasonText.value : this.reasonText,
    createdAt: createdAt ?? this.createdAt,
  );
  OutfitFeedbackData copyWithCompanion(OutfitFeedbackCompanion data) {
    return OutfitFeedbackData(
      id: data.id.present ? data.id.value : this.id,
      outfitId: data.outfitId.present ? data.outfitId.value : this.outfitId,
      kind: data.kind.present ? data.kind.value : this.kind,
      reasonCode: data.reasonCode.present
          ? data.reasonCode.value
          : this.reasonCode,
      reasonText: data.reasonText.present
          ? data.reasonText.value
          : this.reasonText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutfitFeedbackData(')
          ..write('id: $id, ')
          ..write('outfitId: $outfitId, ')
          ..write('kind: $kind, ')
          ..write('reasonCode: $reasonCode, ')
          ..write('reasonText: $reasonText, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, outfitId, kind, reasonCode, reasonText, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutfitFeedbackData &&
          other.id == this.id &&
          other.outfitId == this.outfitId &&
          other.kind == this.kind &&
          other.reasonCode == this.reasonCode &&
          other.reasonText == this.reasonText &&
          other.createdAt == this.createdAt);
}

class OutfitFeedbackCompanion extends UpdateCompanion<OutfitFeedbackData> {
  final Value<String> id;
  final Value<String> outfitId;
  final Value<String> kind;
  final Value<String?> reasonCode;
  final Value<String?> reasonText;
  final Value<int> createdAt;
  final Value<int> rowid;
  const OutfitFeedbackCompanion({
    this.id = const Value.absent(),
    this.outfitId = const Value.absent(),
    this.kind = const Value.absent(),
    this.reasonCode = const Value.absent(),
    this.reasonText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutfitFeedbackCompanion.insert({
    required String id,
    required String outfitId,
    required String kind,
    this.reasonCode = const Value.absent(),
    this.reasonText = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       outfitId = Value(outfitId),
       kind = Value(kind),
       createdAt = Value(createdAt);
  static Insertable<OutfitFeedbackData> custom({
    Expression<String>? id,
    Expression<String>? outfitId,
    Expression<String>? kind,
    Expression<String>? reasonCode,
    Expression<String>? reasonText,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (outfitId != null) 'outfit_id': outfitId,
      if (kind != null) 'kind': kind,
      if (reasonCode != null) 'reason_code': reasonCode,
      if (reasonText != null) 'reason_text': reasonText,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutfitFeedbackCompanion copyWith({
    Value<String>? id,
    Value<String>? outfitId,
    Value<String>? kind,
    Value<String?>? reasonCode,
    Value<String?>? reasonText,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return OutfitFeedbackCompanion(
      id: id ?? this.id,
      outfitId: outfitId ?? this.outfitId,
      kind: kind ?? this.kind,
      reasonCode: reasonCode ?? this.reasonCode,
      reasonText: reasonText ?? this.reasonText,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (outfitId.present) {
      map['outfit_id'] = Variable<String>(outfitId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (reasonCode.present) {
      map['reason_code'] = Variable<String>(reasonCode.value);
    }
    if (reasonText.present) {
      map['reason_text'] = Variable<String>(reasonText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutfitFeedbackCompanion(')
          ..write('id: $id, ')
          ..write('outfitId: $outfitId, ')
          ..write('kind: $kind, ')
          ..write('reasonCode: $reasonCode, ')
          ..write('reasonText: $reasonText, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LearnedPreferencesTable extends LearnedPreferences
    with TableInfo<$LearnedPreferencesTable, LearnedPreference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LearnedPreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
    'weight',
    aliasedName,
    false,
    check: () => ComparableExpr(weight).isBetweenValues(-0.3, 0.3),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, weight, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'learned_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<LearnedPreference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    } else if (isInserting) {
      context.missing(_weightMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  LearnedPreference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LearnedPreference(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LearnedPreferencesTable createAlias(String alias) {
    return $LearnedPreferencesTable(attachedDatabase, alias);
  }
}

class LearnedPreference extends DataClass
    implements Insertable<LearnedPreference> {
  /// For example `color:navy` or `style:minimal`.
  final String key;
  final double weight;
  final int updatedAt;
  const LearnedPreference({
    required this.key,
    required this.weight,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['weight'] = Variable<double>(weight);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  LearnedPreferencesCompanion toCompanion(bool nullToAbsent) {
    return LearnedPreferencesCompanion(
      key: Value(key),
      weight: Value(weight),
      updatedAt: Value(updatedAt),
    );
  }

  factory LearnedPreference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LearnedPreference(
      key: serializer.fromJson<String>(json['key']),
      weight: serializer.fromJson<double>(json['weight']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'weight': serializer.toJson<double>(weight),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  LearnedPreference copyWith({String? key, double? weight, int? updatedAt}) =>
      LearnedPreference(
        key: key ?? this.key,
        weight: weight ?? this.weight,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LearnedPreference copyWithCompanion(LearnedPreferencesCompanion data) {
    return LearnedPreference(
      key: data.key.present ? data.key.value : this.key,
      weight: data.weight.present ? data.weight.value : this.weight,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LearnedPreference(')
          ..write('key: $key, ')
          ..write('weight: $weight, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, weight, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearnedPreference &&
          other.key == this.key &&
          other.weight == this.weight &&
          other.updatedAt == this.updatedAt);
}

class LearnedPreferencesCompanion extends UpdateCompanion<LearnedPreference> {
  final Value<String> key;
  final Value<double> weight;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const LearnedPreferencesCompanion({
    this.key = const Value.absent(),
    this.weight = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LearnedPreferencesCompanion.insert({
    required String key,
    required double weight,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       weight = Value(weight),
       updatedAt = Value(updatedAt);
  static Insertable<LearnedPreference> custom({
    Expression<String>? key,
    Expression<double>? weight,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (weight != null) 'weight': weight,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LearnedPreferencesCompanion copyWith({
    Value<String>? key,
    Value<double>? weight,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return LearnedPreferencesCompanion(
      key: key ?? this.key,
      weight: weight ?? this.weight,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LearnedPreferencesCompanion(')
          ..write('key: $key, ')
          ..write('weight: $weight, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ModelInstallationsTable extends ModelInstallations
    with TableInfo<$ModelInstallationsTable, ModelInstallation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ModelInstallationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _modelIdMeta = const VerificationMeta(
    'modelId',
  );
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
    'model_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relativePathMeta = const VerificationMeta(
    'relativePath',
  );
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
    'relative_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _byteSizeMeta = const VerificationMeta(
    'byteSize',
  );
  @override
  late final GeneratedColumn<int> byteSize = GeneratedColumn<int>(
    'byte_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _licenseMeta = const VerificationMeta(
    'license',
  );
  @override
  late final GeneratedColumn<String> license = GeneratedColumn<String>(
    'license',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _installedAtMeta = const VerificationMeta(
    'installedAt',
  );
  @override
  late final GeneratedColumn<int> installedAt = GeneratedColumn<int>(
    'installed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    modelId,
    version,
    relativePath,
    sha256,
    byteSize,
    license,
    state,
    installedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'model_installations';
  @override
  VerificationContext validateIntegrity(
    Insertable<ModelInstallation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('model_id')) {
      context.handle(
        _modelIdMeta,
        modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_modelIdMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
        _relativePathMeta,
        relativePath.isAcceptableOrUnknown(
          data['relative_path']!,
          _relativePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('byte_size')) {
      context.handle(
        _byteSizeMeta,
        byteSize.isAcceptableOrUnknown(data['byte_size']!, _byteSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_byteSizeMeta);
    }
    if (data.containsKey('license')) {
      context.handle(
        _licenseMeta,
        license.isAcceptableOrUnknown(data['license']!, _licenseMeta),
      );
    } else if (isInserting) {
      context.missing(_licenseMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('installed_at')) {
      context.handle(
        _installedAtMeta,
        installedAt.isAcceptableOrUnknown(
          data['installed_at']!,
          _installedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {modelId, version};
  @override
  ModelInstallation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ModelInstallation(
      modelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      )!,
      relativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_path'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      byteSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_size'],
      )!,
      license: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}license'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      installedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}installed_at'],
      ),
    );
  }

  @override
  $ModelInstallationsTable createAlias(String alias) {
    return $ModelInstallationsTable(attachedDatabase, alias);
  }
}

class ModelInstallation extends DataClass
    implements Insertable<ModelInstallation> {
  final String modelId;
  final String version;
  final String relativePath;
  final String sha256;
  final int byteSize;
  final String license;

  /// INSTALLED, STAGED or FAILED.
  final String state;
  final int? installedAt;
  const ModelInstallation({
    required this.modelId,
    required this.version,
    required this.relativePath,
    required this.sha256,
    required this.byteSize,
    required this.license,
    required this.state,
    this.installedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['model_id'] = Variable<String>(modelId);
    map['version'] = Variable<String>(version);
    map['relative_path'] = Variable<String>(relativePath);
    map['sha256'] = Variable<String>(sha256);
    map['byte_size'] = Variable<int>(byteSize);
    map['license'] = Variable<String>(license);
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || installedAt != null) {
      map['installed_at'] = Variable<int>(installedAt);
    }
    return map;
  }

  ModelInstallationsCompanion toCompanion(bool nullToAbsent) {
    return ModelInstallationsCompanion(
      modelId: Value(modelId),
      version: Value(version),
      relativePath: Value(relativePath),
      sha256: Value(sha256),
      byteSize: Value(byteSize),
      license: Value(license),
      state: Value(state),
      installedAt: installedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(installedAt),
    );
  }

  factory ModelInstallation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ModelInstallation(
      modelId: serializer.fromJson<String>(json['modelId']),
      version: serializer.fromJson<String>(json['version']),
      relativePath: serializer.fromJson<String>(json['relativePath']),
      sha256: serializer.fromJson<String>(json['sha256']),
      byteSize: serializer.fromJson<int>(json['byteSize']),
      license: serializer.fromJson<String>(json['license']),
      state: serializer.fromJson<String>(json['state']),
      installedAt: serializer.fromJson<int?>(json['installedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'modelId': serializer.toJson<String>(modelId),
      'version': serializer.toJson<String>(version),
      'relativePath': serializer.toJson<String>(relativePath),
      'sha256': serializer.toJson<String>(sha256),
      'byteSize': serializer.toJson<int>(byteSize),
      'license': serializer.toJson<String>(license),
      'state': serializer.toJson<String>(state),
      'installedAt': serializer.toJson<int?>(installedAt),
    };
  }

  ModelInstallation copyWith({
    String? modelId,
    String? version,
    String? relativePath,
    String? sha256,
    int? byteSize,
    String? license,
    String? state,
    Value<int?> installedAt = const Value.absent(),
  }) => ModelInstallation(
    modelId: modelId ?? this.modelId,
    version: version ?? this.version,
    relativePath: relativePath ?? this.relativePath,
    sha256: sha256 ?? this.sha256,
    byteSize: byteSize ?? this.byteSize,
    license: license ?? this.license,
    state: state ?? this.state,
    installedAt: installedAt.present ? installedAt.value : this.installedAt,
  );
  ModelInstallation copyWithCompanion(ModelInstallationsCompanion data) {
    return ModelInstallation(
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      version: data.version.present ? data.version.value : this.version,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      byteSize: data.byteSize.present ? data.byteSize.value : this.byteSize,
      license: data.license.present ? data.license.value : this.license,
      state: data.state.present ? data.state.value : this.state,
      installedAt: data.installedAt.present
          ? data.installedAt.value
          : this.installedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ModelInstallation(')
          ..write('modelId: $modelId, ')
          ..write('version: $version, ')
          ..write('relativePath: $relativePath, ')
          ..write('sha256: $sha256, ')
          ..write('byteSize: $byteSize, ')
          ..write('license: $license, ')
          ..write('state: $state, ')
          ..write('installedAt: $installedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    modelId,
    version,
    relativePath,
    sha256,
    byteSize,
    license,
    state,
    installedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ModelInstallation &&
          other.modelId == this.modelId &&
          other.version == this.version &&
          other.relativePath == this.relativePath &&
          other.sha256 == this.sha256 &&
          other.byteSize == this.byteSize &&
          other.license == this.license &&
          other.state == this.state &&
          other.installedAt == this.installedAt);
}

class ModelInstallationsCompanion extends UpdateCompanion<ModelInstallation> {
  final Value<String> modelId;
  final Value<String> version;
  final Value<String> relativePath;
  final Value<String> sha256;
  final Value<int> byteSize;
  final Value<String> license;
  final Value<String> state;
  final Value<int?> installedAt;
  final Value<int> rowid;
  const ModelInstallationsCompanion({
    this.modelId = const Value.absent(),
    this.version = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.license = const Value.absent(),
    this.state = const Value.absent(),
    this.installedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ModelInstallationsCompanion.insert({
    required String modelId,
    required String version,
    required String relativePath,
    required String sha256,
    required int byteSize,
    required String license,
    required String state,
    this.installedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : modelId = Value(modelId),
       version = Value(version),
       relativePath = Value(relativePath),
       sha256 = Value(sha256),
       byteSize = Value(byteSize),
       license = Value(license),
       state = Value(state);
  static Insertable<ModelInstallation> custom({
    Expression<String>? modelId,
    Expression<String>? version,
    Expression<String>? relativePath,
    Expression<String>? sha256,
    Expression<int>? byteSize,
    Expression<String>? license,
    Expression<String>? state,
    Expression<int>? installedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (modelId != null) 'model_id': modelId,
      if (version != null) 'version': version,
      if (relativePath != null) 'relative_path': relativePath,
      if (sha256 != null) 'sha256': sha256,
      if (byteSize != null) 'byte_size': byteSize,
      if (license != null) 'license': license,
      if (state != null) 'state': state,
      if (installedAt != null) 'installed_at': installedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ModelInstallationsCompanion copyWith({
    Value<String>? modelId,
    Value<String>? version,
    Value<String>? relativePath,
    Value<String>? sha256,
    Value<int>? byteSize,
    Value<String>? license,
    Value<String>? state,
    Value<int?>? installedAt,
    Value<int>? rowid,
  }) {
    return ModelInstallationsCompanion(
      modelId: modelId ?? this.modelId,
      version: version ?? this.version,
      relativePath: relativePath ?? this.relativePath,
      sha256: sha256 ?? this.sha256,
      byteSize: byteSize ?? this.byteSize,
      license: license ?? this.license,
      state: state ?? this.state,
      installedAt: installedAt ?? this.installedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (byteSize.present) {
      map['byte_size'] = Variable<int>(byteSize.value);
    }
    if (license.present) {
      map['license'] = Variable<String>(license.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (installedAt.present) {
      map['installed_at'] = Variable<int>(installedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ModelInstallationsCompanion(')
          ..write('modelId: $modelId, ')
          ..write('version: $version, ')
          ..write('relativePath: $relativePath, ')
          ..write('sha256: $sha256, ')
          ..write('byteSize: $byteSize, ')
          ..write('license: $license, ')
          ..write('state: $state, ')
          ..write('installedAt: $installedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UserProfileTable userProfile = $UserProfileTable(this);
  late final $ClothingItemsTable clothingItems = $ClothingItemsTable(this);
  late final $ClothingItemColorsTable clothingItemColors =
      $ClothingItemColorsTable(this);
  late final $ClothingItemSeasonsTable clothingItemSeasons =
      $ClothingItemSeasonsTable(this);
  late final $ClothingImagesTable clothingImages = $ClothingImagesTable(this);
  late final $ClothingAttributesTable clothingAttributes =
      $ClothingAttributesTable(this);
  late final $OutfitsTable outfits = $OutfitsTable(this);
  late final $OutfitItemsTable outfitItems = $OutfitItemsTable(this);
  late final $OutfitFeedbackTable outfitFeedback = $OutfitFeedbackTable(this);
  late final $LearnedPreferencesTable learnedPreferences =
      $LearnedPreferencesTable(this);
  late final $ModelInstallationsTable modelInstallations =
      $ModelInstallationsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final Index idxClothingItemsStatus = Index(
    'idx_clothing_items_status',
    'CREATE INDEX idx_clothing_items_status ON clothing_items (status)',
  );
  late final Index idxClothingItemsCategory = Index(
    'idx_clothing_items_category',
    'CREATE INDEX idx_clothing_items_category ON clothing_items (category)',
  );
  late final Index idxClothingItemsSha256 = Index(
    'idx_clothing_items_sha256',
    'CREATE INDEX idx_clothing_items_sha256 ON clothing_items (content_sha256)',
  );
  late final Index idxClothingImagesItem = Index(
    'idx_clothing_images_item',
    'CREATE INDEX idx_clothing_images_item ON clothing_images (item_id)',
  );
  late final Index idxClothingAttributesItem = Index(
    'idx_clothing_attributes_item',
    'CREATE INDEX idx_clothing_attributes_item ON clothing_attributes (item_id)',
  );
  late final Index idxOutfitsSignature = Index(
    'idx_outfits_signature',
    'CREATE INDEX idx_outfits_signature ON outfits (signature)',
  );
  late final Index idxOutfitsCreated = Index(
    'idx_outfits_created',
    'CREATE INDEX idx_outfits_created ON outfits (created_at)',
  );
  late final Index idxOutfitFeedbackOutfit = Index(
    'idx_outfit_feedback_outfit',
    'CREATE INDEX idx_outfit_feedback_outfit ON outfit_feedback (outfit_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    userProfile,
    clothingItems,
    clothingItemColors,
    clothingItemSeasons,
    clothingImages,
    clothingAttributes,
    outfits,
    outfitItems,
    outfitFeedback,
    learnedPreferences,
    modelInstallations,
    appSettings,
    idxClothingItemsStatus,
    idxClothingItemsCategory,
    idxClothingItemsSha256,
    idxClothingImagesItem,
    idxClothingAttributesItem,
    idxOutfitsSignature,
    idxOutfitsCreated,
    idxOutfitFeedbackOutfit,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'clothing_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('clothing_item_colors', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'clothing_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('clothing_item_seasons', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'clothing_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('clothing_images', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'clothing_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('clothing_attributes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'outfits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('outfit_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'outfits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('outfit_feedback', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$UserProfileTableCreateCompanionBuilder =
    UserProfileCompanion Function({
      required String id,
      Value<String> preferredStyles,
      Value<String> favoredColors,
      Value<String> avoidedColors,
      Value<String?> fitPreference,
      Value<int?> formalityPreference,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$UserProfileTableUpdateCompanionBuilder =
    UserProfileCompanion Function({
      Value<String> id,
      Value<String> preferredStyles,
      Value<String> favoredColors,
      Value<String> avoidedColors,
      Value<String?> fitPreference,
      Value<int?> formalityPreference,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$UserProfileTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfileTable> {
  $$UserProfileTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredStyles => $composableBuilder(
    column: $table.preferredStyles,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get favoredColors => $composableBuilder(
    column: $table.favoredColors,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avoidedColors => $composableBuilder(
    column: $table.avoidedColors,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fitPreference => $composableBuilder(
    column: $table.fitPreference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get formalityPreference => $composableBuilder(
    column: $table.formalityPreference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserProfileTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfileTable> {
  $$UserProfileTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredStyles => $composableBuilder(
    column: $table.preferredStyles,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get favoredColors => $composableBuilder(
    column: $table.favoredColors,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avoidedColors => $composableBuilder(
    column: $table.avoidedColors,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fitPreference => $composableBuilder(
    column: $table.fitPreference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get formalityPreference => $composableBuilder(
    column: $table.formalityPreference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserProfileTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfileTable> {
  $$UserProfileTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get preferredStyles => $composableBuilder(
    column: $table.preferredStyles,
    builder: (column) => column,
  );

  GeneratedColumn<String> get favoredColors => $composableBuilder(
    column: $table.favoredColors,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avoidedColors => $composableBuilder(
    column: $table.avoidedColors,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fitPreference => $composableBuilder(
    column: $table.fitPreference,
    builder: (column) => column,
  );

  GeneratedColumn<int> get formalityPreference => $composableBuilder(
    column: $table.formalityPreference,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserProfileTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserProfileTable,
          UserProfileData,
          $$UserProfileTableFilterComposer,
          $$UserProfileTableOrderingComposer,
          $$UserProfileTableAnnotationComposer,
          $$UserProfileTableCreateCompanionBuilder,
          $$UserProfileTableUpdateCompanionBuilder,
          (
            UserProfileData,
            BaseReferences<_$AppDatabase, $UserProfileTable, UserProfileData>,
          ),
          UserProfileData,
          PrefetchHooks Function()
        > {
  $$UserProfileTableTableManager(_$AppDatabase db, $UserProfileTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfileTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfileTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfileTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> preferredStyles = const Value.absent(),
                Value<String> favoredColors = const Value.absent(),
                Value<String> avoidedColors = const Value.absent(),
                Value<String?> fitPreference = const Value.absent(),
                Value<int?> formalityPreference = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserProfileCompanion(
                id: id,
                preferredStyles: preferredStyles,
                favoredColors: favoredColors,
                avoidedColors: avoidedColors,
                fitPreference: fitPreference,
                formalityPreference: formalityPreference,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> preferredStyles = const Value.absent(),
                Value<String> favoredColors = const Value.absent(),
                Value<String> avoidedColors = const Value.absent(),
                Value<String?> fitPreference = const Value.absent(),
                Value<int?> formalityPreference = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => UserProfileCompanion.insert(
                id: id,
                preferredStyles: preferredStyles,
                favoredColors: favoredColors,
                avoidedColors: avoidedColors,
                fitPreference: fitPreference,
                formalityPreference: formalityPreference,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserProfileTable, UserProfileData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $UserProfileTable,
                    UserProfileData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserProfileTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserProfileTable,
      UserProfileData,
      $$UserProfileTableFilterComposer,
      $$UserProfileTableOrderingComposer,
      $$UserProfileTableAnnotationComposer,
      $$UserProfileTableCreateCompanionBuilder,
      $$UserProfileTableUpdateCompanionBuilder,
      (
        UserProfileData,
        BaseReferences<_$AppDatabase, $UserProfileTable, UserProfileData>,
      ),
      UserProfileData,
      PrefetchHooks Function()
    >;
typedef $$ClothingItemsTableCreateCompanionBuilder =
    ClothingItemsCompanion Function({
      required String id,
      required String category,
      Value<String?> subcategory,
      Value<String?> displayName,
      Value<String?> notes,
      Value<String?> primaryColor,
      Value<String?> pattern,
      Value<int?> formality,
      Value<String?> fit,
      Value<String?> brand,
      Value<int?> warmth,
      required String status,
      Value<String?> contentSha256,
      Value<int?> deletedAt,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$ClothingItemsTableUpdateCompanionBuilder =
    ClothingItemsCompanion Function({
      Value<String> id,
      Value<String> category,
      Value<String?> subcategory,
      Value<String?> displayName,
      Value<String?> notes,
      Value<String?> primaryColor,
      Value<String?> pattern,
      Value<int?> formality,
      Value<String?> fit,
      Value<String?> brand,
      Value<int?> warmth,
      Value<String> status,
      Value<String?> contentSha256,
      Value<int?> deletedAt,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$ClothingItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ClothingItemsTable, ClothingItem> {
  $$ClothingItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ClothingItemColorsTable, List<ClothingItemColor>>
  _clothingItemColorsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.clothingItemColors,
        aliasName: 'clothing_items__id__clothing_item_colors__item_id',
      );

  $$ClothingItemColorsTableProcessedTableManager get clothingItemColorsRefs {
    final manager = $$ClothingItemColorsTableTableManager(
      $_db,
      $_db.clothingItemColors,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _clothingItemColorsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ClothingItemSeasonsTable,
    List<ClothingItemSeason>
  >
  _clothingItemSeasonsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.clothingItemSeasons,
        aliasName: 'clothing_items__id__clothing_item_seasons__item_id',
      );

  $$ClothingItemSeasonsTableProcessedTableManager get clothingItemSeasonsRefs {
    final manager = $$ClothingItemSeasonsTableTableManager(
      $_db,
      $_db.clothingItemSeasons,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _clothingItemSeasonsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ClothingImagesTable, List<ClothingImage>>
  _clothingImagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.clothingImages,
    aliasName: 'clothing_items__id__clothing_images__item_id',
  );

  $$ClothingImagesTableProcessedTableManager get clothingImagesRefs {
    final manager = $$ClothingImagesTableTableManager(
      $_db,
      $_db.clothingImages,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_clothingImagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ClothingAttributesTable, List<ClothingAttribute>>
  _clothingAttributesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.clothingAttributes,
        aliasName: 'clothing_items__id__clothing_attributes__item_id',
      );

  $$ClothingAttributesTableProcessedTableManager get clothingAttributesRefs {
    final manager = $$ClothingAttributesTableTableManager(
      $_db,
      $_db.clothingAttributes,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _clothingAttributesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$OutfitItemsTable, List<OutfitItem>>
  _outfitItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.outfitItems,
    aliasName: 'clothing_items__id__outfit_items__item_id',
  );

  $$OutfitItemsTableProcessedTableManager get outfitItemsRefs {
    final manager = $$OutfitItemsTableTableManager(
      $_db,
      $_db.outfitItems,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_outfitItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ClothingItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ClothingItemsTable> {
  $$ClothingItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subcategory => $composableBuilder(
    column: $table.subcategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get primaryColor => $composableBuilder(
    column: $table.primaryColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pattern => $composableBuilder(
    column: $table.pattern,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get formality => $composableBuilder(
    column: $table.formality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fit => $composableBuilder(
    column: $table.fit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get warmth => $composableBuilder(
    column: $table.warmth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentSha256 => $composableBuilder(
    column: $table.contentSha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> clothingItemColorsRefs(
    Expression<bool> Function($$ClothingItemColorsTableFilterComposer f) f,
  ) {
    final $$ClothingItemColorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.clothingItemColors,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClothingItemColorsTableFilterComposer(
            $db: $db,
            $table: $db.clothingItemColors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> clothingItemSeasonsRefs(
    Expression<bool> Function($$ClothingItemSeasonsTableFilterComposer f) f,
  ) {
    final $$ClothingItemSeasonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.clothingItemSeasons,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClothingItemSeasonsTableFilterComposer(
            $db: $db,
            $table: $db.clothingItemSeasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> clothingImagesRefs(
    Expression<bool> Function($$ClothingImagesTableFilterComposer f) f,
  ) {
    final $$ClothingImagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.clothingImages,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClothingImagesTableFilterComposer(
            $db: $db,
            $table: $db.clothingImages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> clothingAttributesRefs(
    Expression<bool> Function($$ClothingAttributesTableFilterComposer f) f,
  ) {
    final $$ClothingAttributesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.clothingAttributes,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClothingAttributesTableFilterComposer(
            $db: $db,
            $table: $db.clothingAttributes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> outfitItemsRefs(
    Expression<bool> Function($$OutfitItemsTableFilterComposer f) f,
  ) {
    final $$OutfitItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.outfitItems,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OutfitItemsTableFilterComposer(
            $db: $db,
            $table: $db.outfitItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ClothingItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClothingItemsTable> {
  $$ClothingItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subcategory => $composableBuilder(
    column: $table.subcategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get primaryColor => $composableBuilder(
    column: $table.primaryColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pattern => $composableBuilder(
    column: $table.pattern,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get formality => $composableBuilder(
    column: $table.formality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fit => $composableBuilder(
    column: $table.fit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get warmth => $composableBuilder(
    column: $table.warmth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentSha256 => $composableBuilder(
    column: $table.contentSha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClothingItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClothingItemsTable> {
  $$ClothingItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get subcategory => $composableBuilder(
    column: $table.subcategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get primaryColor => $composableBuilder(
    column: $table.primaryColor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pattern =>
      $composableBuilder(column: $table.pattern, builder: (column) => column);

  GeneratedColumn<int> get formality =>
      $composableBuilder(column: $table.formality, builder: (column) => column);

  GeneratedColumn<String> get fit =>
      $composableBuilder(column: $table.fit, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<int> get warmth =>
      $composableBuilder(column: $table.warmth, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get contentSha256 => $composableBuilder(
    column: $table.contentSha256,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> clothingItemColorsRefs<T extends Object>(
    Expression<T> Function($$ClothingItemColorsTableAnnotationComposer a) f,
  ) {
    final $$ClothingItemColorsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.clothingItemColors,
          getReferencedColumn: (t) => t.itemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ClothingItemColorsTableAnnotationComposer(
                $db: $db,
                $table: $db.clothingItemColors,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> clothingItemSeasonsRefs<T extends Object>(
    Expression<T> Function($$ClothingItemSeasonsTableAnnotationComposer a) f,
  ) {
    final $$ClothingItemSeasonsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.clothingItemSeasons,
          getReferencedColumn: (t) => t.itemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ClothingItemSeasonsTableAnnotationComposer(
                $db: $db,
                $table: $db.clothingItemSeasons,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> clothingImagesRefs<T extends Object>(
    Expression<T> Function($$ClothingImagesTableAnnotationComposer a) f,
  ) {
    final $$ClothingImagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.clothingImages,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClothingImagesTableAnnotationComposer(
            $db: $db,
            $table: $db.clothingImages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> clothingAttributesRefs<T extends Object>(
    Expression<T> Function($$ClothingAttributesTableAnnotationComposer a) f,
  ) {
    final $$ClothingAttributesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.clothingAttributes,
          getReferencedColumn: (t) => t.itemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ClothingAttributesTableAnnotationComposer(
                $db: $db,
                $table: $db.clothingAttributes,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> outfitItemsRefs<T extends Object>(
    Expression<T> Function($$OutfitItemsTableAnnotationComposer a) f,
  ) {
    final $$OutfitItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.outfitItems,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OutfitItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.outfitItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ClothingItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClothingItemsTable,
          ClothingItem,
          $$ClothingItemsTableFilterComposer,
          $$ClothingItemsTableOrderingComposer,
          $$ClothingItemsTableAnnotationComposer,
          $$ClothingItemsTableCreateCompanionBuilder,
          $$ClothingItemsTableUpdateCompanionBuilder,
          (ClothingItem, $$ClothingItemsTableReferences),
          ClothingItem,
          PrefetchHooks Function({
            bool clothingItemColorsRefs,
            bool clothingItemSeasonsRefs,
            bool clothingImagesRefs,
            bool clothingAttributesRefs,
            bool outfitItemsRefs,
          })
        > {
  $$ClothingItemsTableTableManager(_$AppDatabase db, $ClothingItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClothingItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClothingItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClothingItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> subcategory = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> primaryColor = const Value.absent(),
                Value<String?> pattern = const Value.absent(),
                Value<int?> formality = const Value.absent(),
                Value<String?> fit = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<int?> warmth = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> contentSha256 = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClothingItemsCompanion(
                id: id,
                category: category,
                subcategory: subcategory,
                displayName: displayName,
                notes: notes,
                primaryColor: primaryColor,
                pattern: pattern,
                formality: formality,
                fit: fit,
                brand: brand,
                warmth: warmth,
                status: status,
                contentSha256: contentSha256,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String category,
                Value<String?> subcategory = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> primaryColor = const Value.absent(),
                Value<String?> pattern = const Value.absent(),
                Value<int?> formality = const Value.absent(),
                Value<String?> fit = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<int?> warmth = const Value.absent(),
                required String status,
                Value<String?> contentSha256 = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ClothingItemsCompanion.insert(
                id: id,
                category: category,
                subcategory: subcategory,
                displayName: displayName,
                notes: notes,
                primaryColor: primaryColor,
                pattern: pattern,
                formality: formality,
                fit: fit,
                brand: brand,
                warmth: warmth,
                status: status,
                contentSha256: contentSha256,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ClothingItemsTable, ClothingItem>(table),
                  $$ClothingItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                clothingItemColorsRefs = false,
                clothingItemSeasonsRefs = false,
                clothingImagesRefs = false,
                clothingAttributesRefs = false,
                outfitItemsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (clothingItemColorsRefs) db.clothingItemColors,
                    if (clothingItemSeasonsRefs) db.clothingItemSeasons,
                    if (clothingImagesRefs) db.clothingImages,
                    if (clothingAttributesRefs) db.clothingAttributes,
                    if (outfitItemsRefs) db.outfitItems,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (clothingItemColorsRefs)
                        await $_getPrefetchedDataByColumns<
                          ClothingItem,
                          $ClothingItemsTable,
                          ClothingItemColor,
                          $ClothingItemColorsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ClothingItemsTableReferences
                              ._clothingItemColorsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ClothingItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).clothingItemColorsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'item_id',
                          typedResults: items,
                        ),
                      if (clothingItemSeasonsRefs)
                        await $_getPrefetchedDataByColumns<
                          ClothingItem,
                          $ClothingItemsTable,
                          ClothingItemSeason,
                          $ClothingItemSeasonsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ClothingItemsTableReferences
                              ._clothingItemSeasonsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ClothingItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).clothingItemSeasonsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'item_id',
                          typedResults: items,
                        ),
                      if (clothingImagesRefs)
                        await $_getPrefetchedDataByColumns<
                          ClothingItem,
                          $ClothingItemsTable,
                          ClothingImage,
                          $ClothingImagesTable
                        >(
                          currentTable: table,
                          referencedTable: $$ClothingItemsTableReferences
                              ._clothingImagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ClothingItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).clothingImagesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'item_id',
                          typedResults: items,
                        ),
                      if (clothingAttributesRefs)
                        await $_getPrefetchedDataByColumns<
                          ClothingItem,
                          $ClothingItemsTable,
                          ClothingAttribute,
                          $ClothingAttributesTable
                        >(
                          currentTable: table,
                          referencedTable: $$ClothingItemsTableReferences
                              ._clothingAttributesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ClothingItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).clothingAttributesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'item_id',
                          typedResults: items,
                        ),
                      if (outfitItemsRefs)
                        await $_getPrefetchedDataByColumns<
                          ClothingItem,
                          $ClothingItemsTable,
                          OutfitItem,
                          $OutfitItemsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ClothingItemsTableReferences
                              ._outfitItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ClothingItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).outfitItemsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'item_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ClothingItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClothingItemsTable,
      ClothingItem,
      $$ClothingItemsTableFilterComposer,
      $$ClothingItemsTableOrderingComposer,
      $$ClothingItemsTableAnnotationComposer,
      $$ClothingItemsTableCreateCompanionBuilder,
      $$ClothingItemsTableUpdateCompanionBuilder,
      (ClothingItem, $$ClothingItemsTableReferences),
      ClothingItem,
      PrefetchHooks Function({
        bool clothingItemColorsRefs,
        bool clothingItemSeasonsRefs,
        bool clothingImagesRefs,
        bool clothingAttributesRefs,
        bool outfitItemsRefs,
      })
    >;
typedef $$ClothingItemColorsTableCreateCompanionBuilder =
    ClothingItemColorsCompanion Function({
      required String itemId,
      required String color,
      required String role,
      Value<int> rowid,
    });
typedef $$ClothingItemColorsTableUpdateCompanionBuilder =
    ClothingItemColorsCompanion Function({
      Value<String> itemId,
      Value<String> color,
      Value<String> role,
      Value<int> rowid,
    });

final class $$ClothingItemColorsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ClothingItemColorsTable,
          ClothingItemColor
        > {
  $$ClothingItemColorsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ClothingItemsTable _itemIdTable(_$AppDatabase db) => db.clothingItems
      .createAlias('clothing_item_colors__item_id__clothing_items__id');

  $$ClothingItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ClothingItemsTableTableManager(
      $_db,
      $_db.clothingItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ClothingItemColorsTableFilterComposer
    extends Composer<_$AppDatabase, $ClothingItemColorsTable> {
  $$ClothingItemColorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  $$ClothingItemsTableFilterComposer get itemId {
    final $$ClothingItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.clothingItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClothingItemsTableFilterComposer(
            $db: $db,
            $table: $db.clothingItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClothingItemColorsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClothingItemColorsTable> {
  $$ClothingItemColorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  $$ClothingItemsTableOrderingComposer get itemId {
    final $$ClothingItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.clothingItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClothingItemsTableOrderingComposer(
            $db: $db,
            $table: $db.clothingItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClothingItemColorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClothingItemColorsTable> {
  $$ClothingItemColorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  $$ClothingItemsTableAnnotationComposer get itemId {
    final $$ClothingItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.clothingItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClothingItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.clothingItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClothingItemColorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClothingItemColorsTable,
          ClothingItemColor,
          $$ClothingItemColorsTableFilterComposer,
          $$ClothingItemColorsTableOrderingComposer,
          $$ClothingItemColorsTableAnnotationComposer,
          $$ClothingItemColorsTableCreateCompanionBuilder,
          $$ClothingItemColorsTableUpdateCompanionBuilder,
          (ClothingItemColor, $$ClothingItemColorsTableReferences),
          ClothingItemColor,
          PrefetchHooks Function({bool itemId})
        > {
  $$ClothingItemColorsTableTableManager(
    _$AppDatabase db,
    $ClothingItemColorsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClothingItemColorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClothingItemColorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClothingItemColorsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> itemId = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClothingItemColorsCompanion(
                itemId: itemId,
                color: color,
                role: role,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String itemId,
                required String color,
                required String role,
                Value<int> rowid = const Value.absent(),
              }) => ClothingItemColorsCompanion.insert(
                itemId: itemId,
                color: color,
                role: role,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ClothingItemColorsTable, ClothingItemColor>(
                    table,
                  ),
                  $$ClothingItemColorsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                    if (itemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.itemId,
                        referencedTable: $$ClothingItemColorsTableReferences
                            ._itemIdTable(db),
                        referencedColumn: $$ClothingItemColorsTableReferences
                            ._itemIdTable(db)
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
        ),
      );
}

typedef $$ClothingItemColorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClothingItemColorsTable,
      ClothingItemColor,
      $$ClothingItemColorsTableFilterComposer,
      $$ClothingItemColorsTableOrderingComposer,
      $$ClothingItemColorsTableAnnotationComposer,
      $$ClothingItemColorsTableCreateCompanionBuilder,
      $$ClothingItemColorsTableUpdateCompanionBuilder,
      (ClothingItemColor, $$ClothingItemColorsTableReferences),
      ClothingItemColor,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$ClothingItemSeasonsTableCreateCompanionBuilder =
    ClothingItemSeasonsCompanion Function({
      required String itemId,
      required String season,
      Value<int> rowid,
    });
typedef $$ClothingItemSeasonsTableUpdateCompanionBuilder =
    ClothingItemSeasonsCompanion Function({
      Value<String> itemId,
      Value<String> season,
      Value<int> rowid,
    });

final class $$ClothingItemSeasonsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ClothingItemSeasonsTable,
          ClothingItemSeason
        > {
  $$ClothingItemSeasonsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ClothingItemsTable _itemIdTable(_$AppDatabase db) => db.clothingItems
      .createAlias('clothing_item_seasons__item_id__clothing_items__id');

  $$ClothingItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ClothingItemsTableTableManager(
      $_db,
      $_db.clothingItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ClothingItemSeasonsTableFilterComposer
    extends Composer<_$AppDatabase, $ClothingItemSeasonsTable> {
  $$ClothingItemSeasonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get season => $composableBuilder(
    column: $table.season,
    builder: (column) => ColumnFilters(column),
  );

  $$ClothingItemsTableFilterComposer get itemId {
    final $$ClothingItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.clothingItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClothingItemsTableFilterComposer(
            $db: $db,
            $table: $db.clothingItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClothingItemSeasonsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClothingItemSeasonsTable> {
  $$ClothingItemSeasonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get season => $composableBuilder(
    column: $table.season,
    builder: (column) => ColumnOrderings(column),
  );

  $$ClothingItemsTableOrderingComposer get itemId {
    final $$ClothingItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.clothingItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClothingItemsTableOrderingComposer(
            $db: $db,
            $table: $db.clothingItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClothingItemSeasonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClothingItemSeasonsTable> {
  $$ClothingItemSeasonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get season =>
      $composableBuilder(column: $table.season, builder: (column) => column);

  $$ClothingItemsTableAnnotationComposer get itemId {
    final $$ClothingItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.clothingItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClothingItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.clothingItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClothingItemSeasonsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClothingItemSeasonsTable,
          ClothingItemSeason,
          $$ClothingItemSeasonsTableFilterComposer,
          $$ClothingItemSeasonsTableOrderingComposer,
          $$ClothingItemSeasonsTableAnnotationComposer,
          $$ClothingItemSeasonsTableCreateCompanionBuilder,
          $$ClothingItemSeasonsTableUpdateCompanionBuilder,
          (ClothingItemSeason, $$ClothingItemSeasonsTableReferences),
          ClothingItemSeason,
          PrefetchHooks Function({bool itemId})
        > {
  $$ClothingItemSeasonsTableTableManager(
    _$AppDatabase db,
    $ClothingItemSeasonsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClothingItemSeasonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClothingItemSeasonsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ClothingItemSeasonsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> itemId = const Value.absent(),
                Value<String> season = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClothingItemSeasonsCompanion(
                itemId: itemId,
                season: season,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String itemId,
                required String season,
                Value<int> rowid = const Value.absent(),
              }) => ClothingItemSeasonsCompanion.insert(
                itemId: itemId,
                season: season,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ClothingItemSeasonsTable, ClothingItemSeason>(
                    table,
                  ),
                  $$ClothingItemSeasonsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                    if (itemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.itemId,
                        referencedTable: $$ClothingItemSeasonsTableReferences
                            ._itemIdTable(db),
                        referencedColumn: $$ClothingItemSeasonsTableReferences
                            ._itemIdTable(db)
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
        ),
      );
}

typedef $$ClothingItemSeasonsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClothingItemSeasonsTable,
      ClothingItemSeason,
      $$ClothingItemSeasonsTableFilterComposer,
      $$ClothingItemSeasonsTableOrderingComposer,
      $$ClothingItemSeasonsTableAnnotationComposer,
      $$ClothingItemSeasonsTableCreateCompanionBuilder,
      $$ClothingItemSeasonsTableUpdateCompanionBuilder,
      (ClothingItemSeason, $$ClothingItemSeasonsTableReferences),
      ClothingItemSeason,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$ClothingImagesTableCreateCompanionBuilder =
    ClothingImagesCompanion Function({
      required String id,
      required String itemId,
      required String kind,
      required String relativePath,
      Value<int?> width,
      Value<int?> height,
      Value<int?> byteSize,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$ClothingImagesTableUpdateCompanionBuilder =
    ClothingImagesCompanion Function({
      Value<String> id,
      Value<String> itemId,
      Value<String> kind,
      Value<String> relativePath,
      Value<int?> width,
      Value<int?> height,
      Value<int?> byteSize,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$ClothingImagesTableReferences
    extends BaseReferences<_$AppDatabase, $ClothingImagesTable, ClothingImage> {
  $$ClothingImagesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ClothingItemsTable _itemIdTable(_$AppDatabase db) => db.clothingItems
      .createAlias('clothing_images__item_id__clothing_items__id');

  $$ClothingItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ClothingItemsTableTableManager(
      $_db,
      $_db.clothingItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ClothingImagesTableFilterComposer
    extends Composer<_$AppDatabase, $ClothingImagesTable> {
  $$ClothingImagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
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

  ColumnFilters<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ClothingItemsTableFilterComposer get itemId {
    final $$ClothingItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.clothingItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClothingItemsTableFilterComposer(
            $db: $db,
            $table: $db.clothingItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClothingImagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ClothingImagesTable> {
  $$ClothingImagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
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

  ColumnOrderings<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ClothingItemsTableOrderingComposer get itemId {
    final $$ClothingItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.clothingItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClothingItemsTableOrderingComposer(
            $db: $db,
            $table: $db.clothingItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClothingImagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClothingImagesTable> {
  $$ClothingImagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get byteSize =>
      $composableBuilder(column: $table.byteSize, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ClothingItemsTableAnnotationComposer get itemId {
    final $$ClothingItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.clothingItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClothingItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.clothingItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClothingImagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClothingImagesTable,
          ClothingImage,
          $$ClothingImagesTableFilterComposer,
          $$ClothingImagesTableOrderingComposer,
          $$ClothingImagesTableAnnotationComposer,
          $$ClothingImagesTableCreateCompanionBuilder,
          $$ClothingImagesTableUpdateCompanionBuilder,
          (ClothingImage, $$ClothingImagesTableReferences),
          ClothingImage,
          PrefetchHooks Function({bool itemId})
        > {
  $$ClothingImagesTableTableManager(
    _$AppDatabase db,
    $ClothingImagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClothingImagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClothingImagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClothingImagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> relativePath = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<int?> byteSize = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClothingImagesCompanion(
                id: id,
                itemId: itemId,
                kind: kind,
                relativePath: relativePath,
                width: width,
                height: height,
                byteSize: byteSize,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String itemId,
                required String kind,
                required String relativePath,
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<int?> byteSize = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ClothingImagesCompanion.insert(
                id: id,
                itemId: itemId,
                kind: kind,
                relativePath: relativePath,
                width: width,
                height: height,
                byteSize: byteSize,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ClothingImagesTable, ClothingImage>(table),
                  $$ClothingImagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                    if (itemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.itemId,
                        referencedTable: $$ClothingImagesTableReferences
                            ._itemIdTable(db),
                        referencedColumn: $$ClothingImagesTableReferences
                            ._itemIdTable(db)
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
        ),
      );
}

typedef $$ClothingImagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClothingImagesTable,
      ClothingImage,
      $$ClothingImagesTableFilterComposer,
      $$ClothingImagesTableOrderingComposer,
      $$ClothingImagesTableAnnotationComposer,
      $$ClothingImagesTableCreateCompanionBuilder,
      $$ClothingImagesTableUpdateCompanionBuilder,
      (ClothingImage, $$ClothingImagesTableReferences),
      ClothingImage,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$ClothingAttributesTableCreateCompanionBuilder =
    ClothingAttributesCompanion Function({
      required String id,
      required String itemId,
      required String attribute,
      required String value,
      Value<double?> confidence,
      Value<String?> modelId,
      Value<String?> modelVersion,
      Value<int?> analyzedAt,
      Value<bool> userConfirmed,
      Value<int> rowid,
    });
typedef $$ClothingAttributesTableUpdateCompanionBuilder =
    ClothingAttributesCompanion Function({
      Value<String> id,
      Value<String> itemId,
      Value<String> attribute,
      Value<String> value,
      Value<double?> confidence,
      Value<String?> modelId,
      Value<String?> modelVersion,
      Value<int?> analyzedAt,
      Value<bool> userConfirmed,
      Value<int> rowid,
    });

final class $$ClothingAttributesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ClothingAttributesTable,
          ClothingAttribute
        > {
  $$ClothingAttributesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ClothingItemsTable _itemIdTable(_$AppDatabase db) => db.clothingItems
      .createAlias('clothing_attributes__item_id__clothing_items__id');

  $$ClothingItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ClothingItemsTableTableManager(
      $_db,
      $_db.clothingItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ClothingAttributesTableFilterComposer
    extends Composer<_$AppDatabase, $ClothingAttributesTable> {
  $$ClothingAttributesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attribute => $composableBuilder(
    column: $table.attribute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get analyzedAt => $composableBuilder(
    column: $table.analyzedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get userConfirmed => $composableBuilder(
    column: $table.userConfirmed,
    builder: (column) => ColumnFilters(column),
  );

  $$ClothingItemsTableFilterComposer get itemId {
    final $$ClothingItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.clothingItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClothingItemsTableFilterComposer(
            $db: $db,
            $table: $db.clothingItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClothingAttributesTableOrderingComposer
    extends Composer<_$AppDatabase, $ClothingAttributesTable> {
  $$ClothingAttributesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attribute => $composableBuilder(
    column: $table.attribute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get analyzedAt => $composableBuilder(
    column: $table.analyzedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get userConfirmed => $composableBuilder(
    column: $table.userConfirmed,
    builder: (column) => ColumnOrderings(column),
  );

  $$ClothingItemsTableOrderingComposer get itemId {
    final $$ClothingItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.clothingItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClothingItemsTableOrderingComposer(
            $db: $db,
            $table: $db.clothingItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClothingAttributesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClothingAttributesTable> {
  $$ClothingAttributesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get attribute =>
      $composableBuilder(column: $table.attribute, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => column);

  GeneratedColumn<String> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get analyzedAt => $composableBuilder(
    column: $table.analyzedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get userConfirmed => $composableBuilder(
    column: $table.userConfirmed,
    builder: (column) => column,
  );

  $$ClothingItemsTableAnnotationComposer get itemId {
    final $$ClothingItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.clothingItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClothingItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.clothingItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClothingAttributesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClothingAttributesTable,
          ClothingAttribute,
          $$ClothingAttributesTableFilterComposer,
          $$ClothingAttributesTableOrderingComposer,
          $$ClothingAttributesTableAnnotationComposer,
          $$ClothingAttributesTableCreateCompanionBuilder,
          $$ClothingAttributesTableUpdateCompanionBuilder,
          (ClothingAttribute, $$ClothingAttributesTableReferences),
          ClothingAttribute,
          PrefetchHooks Function({bool itemId})
        > {
  $$ClothingAttributesTableTableManager(
    _$AppDatabase db,
    $ClothingAttributesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClothingAttributesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClothingAttributesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClothingAttributesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> attribute = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<double?> confidence = const Value.absent(),
                Value<String?> modelId = const Value.absent(),
                Value<String?> modelVersion = const Value.absent(),
                Value<int?> analyzedAt = const Value.absent(),
                Value<bool> userConfirmed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClothingAttributesCompanion(
                id: id,
                itemId: itemId,
                attribute: attribute,
                value: value,
                confidence: confidence,
                modelId: modelId,
                modelVersion: modelVersion,
                analyzedAt: analyzedAt,
                userConfirmed: userConfirmed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String itemId,
                required String attribute,
                required String value,
                Value<double?> confidence = const Value.absent(),
                Value<String?> modelId = const Value.absent(),
                Value<String?> modelVersion = const Value.absent(),
                Value<int?> analyzedAt = const Value.absent(),
                Value<bool> userConfirmed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClothingAttributesCompanion.insert(
                id: id,
                itemId: itemId,
                attribute: attribute,
                value: value,
                confidence: confidence,
                modelId: modelId,
                modelVersion: modelVersion,
                analyzedAt: analyzedAt,
                userConfirmed: userConfirmed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ClothingAttributesTable, ClothingAttribute>(
                    table,
                  ),
                  $$ClothingAttributesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                    if (itemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.itemId,
                        referencedTable: $$ClothingAttributesTableReferences
                            ._itemIdTable(db),
                        referencedColumn: $$ClothingAttributesTableReferences
                            ._itemIdTable(db)
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
        ),
      );
}

typedef $$ClothingAttributesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClothingAttributesTable,
      ClothingAttribute,
      $$ClothingAttributesTableFilterComposer,
      $$ClothingAttributesTableOrderingComposer,
      $$ClothingAttributesTableAnnotationComposer,
      $$ClothingAttributesTableCreateCompanionBuilder,
      $$ClothingAttributesTableUpdateCompanionBuilder,
      (ClothingAttribute, $$ClothingAttributesTableReferences),
      ClothingAttribute,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$OutfitsTableCreateCompanionBuilder = OutfitsCompanion Function({
  required String id,
  required String signature,
  required String occasion,
  required String requestJson,
  required double totalScore,
  required String breakdownJson,
  required String reasonsJson,
  required bool weatherConsidered,
  Value<bool> isFavorite,
  required int createdAt,
  Value<int> rowid,
});
typedef $$OutfitsTableUpdateCompanionBuilder = OutfitsCompanion Function({
  Value<String> id,
  Value<String> signature,
  Value<String> occasion,
  Value<String> requestJson,
  Value<double> totalScore,
  Value<String> breakdownJson,
  Value<String> reasonsJson,
  Value<bool> weatherConsidered,
  Value<bool> isFavorite,
  Value<int> createdAt,
  Value<int> rowid,
});

final class $$OutfitsTableReferences
    extends BaseReferences<_$AppDatabase, $OutfitsTable, Outfit> {
  $$OutfitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$OutfitItemsTable, List<OutfitItem>>
  _outfitItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.outfitItems,
    aliasName: 'outfits__id__outfit_items__outfit_id',
  );

  $$OutfitItemsTableProcessedTableManager get outfitItemsRefs {
    final manager = $$OutfitItemsTableTableManager(
      $_db,
      $_db.outfitItems,
    ).filter((f) => f.outfitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_outfitItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$OutfitFeedbackTable, List<OutfitFeedbackData>>
  _outfitFeedbackRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.outfitFeedback,
    aliasName: 'outfits__id__outfit_feedback__outfit_id',
  );

  $$OutfitFeedbackTableProcessedTableManager get outfitFeedbackRefs {
    final manager = $$OutfitFeedbackTableTableManager(
      $_db,
      $_db.outfitFeedback,
    ).filter((f) => f.outfitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_outfitFeedbackRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$OutfitsTableFilterComposer
    extends Composer<_$AppDatabase, $OutfitsTable> {
  $$OutfitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get signature => $composableBuilder(
    column: $table.signature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occasion => $composableBuilder(
    column: $table.occasion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requestJson => $composableBuilder(
    column: $table.requestJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalScore => $composableBuilder(
    column: $table.totalScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get breakdownJson => $composableBuilder(
    column: $table.breakdownJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reasonsJson => $composableBuilder(
    column: $table.reasonsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get weatherConsidered => $composableBuilder(
    column: $table.weatherConsidered,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> outfitItemsRefs(
    Expression<bool> Function($$OutfitItemsTableFilterComposer f) f,
  ) {
    final $$OutfitItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.outfitItems,
      getReferencedColumn: (t) => t.outfitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OutfitItemsTableFilterComposer(
            $db: $db,
            $table: $db.outfitItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> outfitFeedbackRefs(
    Expression<bool> Function($$OutfitFeedbackTableFilterComposer f) f,
  ) {
    final $$OutfitFeedbackTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.outfitFeedback,
      getReferencedColumn: (t) => t.outfitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OutfitFeedbackTableFilterComposer(
            $db: $db,
            $table: $db.outfitFeedback,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$OutfitsTableOrderingComposer
    extends Composer<_$AppDatabase, $OutfitsTable> {
  $$OutfitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get signature => $composableBuilder(
    column: $table.signature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occasion => $composableBuilder(
    column: $table.occasion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requestJson => $composableBuilder(
    column: $table.requestJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalScore => $composableBuilder(
    column: $table.totalScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get breakdownJson => $composableBuilder(
    column: $table.breakdownJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reasonsJson => $composableBuilder(
    column: $table.reasonsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get weatherConsidered => $composableBuilder(
    column: $table.weatherConsidered,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutfitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutfitsTable> {
  $$OutfitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get signature =>
      $composableBuilder(column: $table.signature, builder: (column) => column);

  GeneratedColumn<String> get occasion =>
      $composableBuilder(column: $table.occasion, builder: (column) => column);

  GeneratedColumn<String> get requestJson => $composableBuilder(
    column: $table.requestJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalScore => $composableBuilder(
    column: $table.totalScore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get breakdownJson => $composableBuilder(
    column: $table.breakdownJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reasonsJson => $composableBuilder(
    column: $table.reasonsJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get weatherConsidered => $composableBuilder(
    column: $table.weatherConsidered,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> outfitItemsRefs<T extends Object>(
    Expression<T> Function($$OutfitItemsTableAnnotationComposer a) f,
  ) {
    final $$OutfitItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.outfitItems,
      getReferencedColumn: (t) => t.outfitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OutfitItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.outfitItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> outfitFeedbackRefs<T extends Object>(
    Expression<T> Function($$OutfitFeedbackTableAnnotationComposer a) f,
  ) {
    final $$OutfitFeedbackTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.outfitFeedback,
      getReferencedColumn: (t) => t.outfitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OutfitFeedbackTableAnnotationComposer(
            $db: $db,
            $table: $db.outfitFeedback,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$OutfitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutfitsTable,
          Outfit,
          $$OutfitsTableFilterComposer,
          $$OutfitsTableOrderingComposer,
          $$OutfitsTableAnnotationComposer,
          $$OutfitsTableCreateCompanionBuilder,
          $$OutfitsTableUpdateCompanionBuilder,
          (Outfit, $$OutfitsTableReferences),
          Outfit,
          PrefetchHooks Function({
            bool outfitItemsRefs,
            bool outfitFeedbackRefs,
          })
        > {
  $$OutfitsTableTableManager(_$AppDatabase db, $OutfitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutfitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutfitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutfitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> signature = const Value.absent(),
                Value<String> occasion = const Value.absent(),
                Value<String> requestJson = const Value.absent(),
                Value<double> totalScore = const Value.absent(),
                Value<String> breakdownJson = const Value.absent(),
                Value<String> reasonsJson = const Value.absent(),
                Value<bool> weatherConsidered = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutfitsCompanion(
                id: id,
                signature: signature,
                occasion: occasion,
                requestJson: requestJson,
                totalScore: totalScore,
                breakdownJson: breakdownJson,
                reasonsJson: reasonsJson,
                weatherConsidered: weatherConsidered,
                isFavorite: isFavorite,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String signature,
                required String occasion,
                required String requestJson,
                required double totalScore,
                required String breakdownJson,
                required String reasonsJson,
                required bool weatherConsidered,
                Value<bool> isFavorite = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => OutfitsCompanion.insert(
                id: id,
                signature: signature,
                occasion: occasion,
                requestJson: requestJson,
                totalScore: totalScore,
                breakdownJson: breakdownJson,
                reasonsJson: reasonsJson,
                weatherConsidered: weatherConsidered,
                isFavorite: isFavorite,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutfitsTable, Outfit>(table),
                  $$OutfitsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({outfitItemsRefs = false, outfitFeedbackRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (outfitItemsRefs) db.outfitItems,
                    if (outfitFeedbackRefs) db.outfitFeedback,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (outfitItemsRefs)
                        await $_getPrefetchedDataByColumns<
                          Outfit,
                          $OutfitsTable,
                          OutfitItem,
                          $OutfitItemsTable
                        >(
                          currentTable: table,
                          referencedTable: $$OutfitsTableReferences
                              ._outfitItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$OutfitsTableReferences(
                                db,
                                table,
                                p0,
                              ).outfitItemsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'outfit_id',
                          typedResults: items,
                        ),
                      if (outfitFeedbackRefs)
                        await $_getPrefetchedDataByColumns<
                          Outfit,
                          $OutfitsTable,
                          OutfitFeedbackData,
                          $OutfitFeedbackTable
                        >(
                          currentTable: table,
                          referencedTable: $$OutfitsTableReferences
                              ._outfitFeedbackRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$OutfitsTableReferences(
                                db,
                                table,
                                p0,
                              ).outfitFeedbackRefs,
                          currentColumn: 'id',
                          referencedColumn: 'outfit_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$OutfitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutfitsTable,
      Outfit,
      $$OutfitsTableFilterComposer,
      $$OutfitsTableOrderingComposer,
      $$OutfitsTableAnnotationComposer,
      $$OutfitsTableCreateCompanionBuilder,
      $$OutfitsTableUpdateCompanionBuilder,
      (Outfit, $$OutfitsTableReferences),
      Outfit,
      PrefetchHooks Function({bool outfitItemsRefs, bool outfitFeedbackRefs})
    >;
typedef $$OutfitItemsTableCreateCompanionBuilder =
    OutfitItemsCompanion Function({
      required String outfitId,
      required String itemId,
      required String slot,
      Value<int> rowid,
    });
typedef $$OutfitItemsTableUpdateCompanionBuilder =
    OutfitItemsCompanion Function({
      Value<String> outfitId,
      Value<String> itemId,
      Value<String> slot,
      Value<int> rowid,
    });

final class $$OutfitItemsTableReferences
    extends BaseReferences<_$AppDatabase, $OutfitItemsTable, OutfitItem> {
  $$OutfitItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $OutfitsTable _outfitIdTable(_$AppDatabase db) =>
      db.outfits.createAlias('outfit_items__outfit_id__outfits__id');

  $$OutfitsTableProcessedTableManager get outfitId {
    final $_column = $_itemColumn<String>('outfit_id')!;

    final manager = $$OutfitsTableTableManager(
      $_db,
      $_db.outfits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_outfitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ClothingItemsTable _itemIdTable(_$AppDatabase db) =>
      db.clothingItems.createAlias('outfit_items__item_id__clothing_items__id');

  $$ClothingItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ClothingItemsTableTableManager(
      $_db,
      $_db.clothingItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OutfitItemsTableFilterComposer
    extends Composer<_$AppDatabase, $OutfitItemsTable> {
  $$OutfitItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnFilters(column),
  );

  $$OutfitsTableFilterComposer get outfitId {
    final $$OutfitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.outfitId,
      referencedTable: $db.outfits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OutfitsTableFilterComposer(
            $db: $db,
            $table: $db.outfits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ClothingItemsTableFilterComposer get itemId {
    final $$ClothingItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.clothingItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClothingItemsTableFilterComposer(
            $db: $db,
            $table: $db.clothingItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OutfitItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $OutfitItemsTable> {
  $$OutfitItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnOrderings(column),
  );

  $$OutfitsTableOrderingComposer get outfitId {
    final $$OutfitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.outfitId,
      referencedTable: $db.outfits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OutfitsTableOrderingComposer(
            $db: $db,
            $table: $db.outfits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ClothingItemsTableOrderingComposer get itemId {
    final $$ClothingItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.clothingItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClothingItemsTableOrderingComposer(
            $db: $db,
            $table: $db.clothingItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OutfitItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutfitItemsTable> {
  $$OutfitItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  $$OutfitsTableAnnotationComposer get outfitId {
    final $$OutfitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.outfitId,
      referencedTable: $db.outfits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OutfitsTableAnnotationComposer(
            $db: $db,
            $table: $db.outfits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ClothingItemsTableAnnotationComposer get itemId {
    final $$ClothingItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.clothingItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClothingItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.clothingItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OutfitItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutfitItemsTable,
          OutfitItem,
          $$OutfitItemsTableFilterComposer,
          $$OutfitItemsTableOrderingComposer,
          $$OutfitItemsTableAnnotationComposer,
          $$OutfitItemsTableCreateCompanionBuilder,
          $$OutfitItemsTableUpdateCompanionBuilder,
          (OutfitItem, $$OutfitItemsTableReferences),
          OutfitItem,
          PrefetchHooks Function({bool outfitId, bool itemId})
        > {
  $$OutfitItemsTableTableManager(_$AppDatabase db, $OutfitItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutfitItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutfitItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutfitItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> outfitId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> slot = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutfitItemsCompanion(
                outfitId: outfitId,
                itemId: itemId,
                slot: slot,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String outfitId,
                required String itemId,
                required String slot,
                Value<int> rowid = const Value.absent(),
              }) => OutfitItemsCompanion.insert(
                outfitId: outfitId,
                itemId: itemId,
                slot: slot,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutfitItemsTable, OutfitItem>(table),
                  $$OutfitItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({outfitId = false, itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                    if (outfitId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.outfitId,
                        referencedTable: $$OutfitItemsTableReferences
                            ._outfitIdTable(db),
                        referencedColumn: $$OutfitItemsTableReferences
                            ._outfitIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (itemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.itemId,
                        referencedTable: $$OutfitItemsTableReferences
                            ._itemIdTable(db),
                        referencedColumn: $$OutfitItemsTableReferences
                            ._itemIdTable(db)
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
        ),
      );
}

typedef $$OutfitItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutfitItemsTable,
      OutfitItem,
      $$OutfitItemsTableFilterComposer,
      $$OutfitItemsTableOrderingComposer,
      $$OutfitItemsTableAnnotationComposer,
      $$OutfitItemsTableCreateCompanionBuilder,
      $$OutfitItemsTableUpdateCompanionBuilder,
      (OutfitItem, $$OutfitItemsTableReferences),
      OutfitItem,
      PrefetchHooks Function({bool outfitId, bool itemId})
    >;
typedef $$OutfitFeedbackTableCreateCompanionBuilder =
    OutfitFeedbackCompanion Function({
      required String id,
      required String outfitId,
      required String kind,
      Value<String?> reasonCode,
      Value<String?> reasonText,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$OutfitFeedbackTableUpdateCompanionBuilder =
    OutfitFeedbackCompanion Function({
      Value<String> id,
      Value<String> outfitId,
      Value<String> kind,
      Value<String?> reasonCode,
      Value<String?> reasonText,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$OutfitFeedbackTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $OutfitFeedbackTable,
          OutfitFeedbackData
        > {
  $$OutfitFeedbackTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $OutfitsTable _outfitIdTable(_$AppDatabase db) =>
      db.outfits.createAlias('outfit_feedback__outfit_id__outfits__id');

  $$OutfitsTableProcessedTableManager get outfitId {
    final $_column = $_itemColumn<String>('outfit_id')!;

    final manager = $$OutfitsTableTableManager(
      $_db,
      $_db.outfits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_outfitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OutfitFeedbackTableFilterComposer
    extends Composer<_$AppDatabase, $OutfitFeedbackTable> {
  $$OutfitFeedbackTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reasonCode => $composableBuilder(
    column: $table.reasonCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reasonText => $composableBuilder(
    column: $table.reasonText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$OutfitsTableFilterComposer get outfitId {
    final $$OutfitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.outfitId,
      referencedTable: $db.outfits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OutfitsTableFilterComposer(
            $db: $db,
            $table: $db.outfits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OutfitFeedbackTableOrderingComposer
    extends Composer<_$AppDatabase, $OutfitFeedbackTable> {
  $$OutfitFeedbackTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reasonCode => $composableBuilder(
    column: $table.reasonCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reasonText => $composableBuilder(
    column: $table.reasonText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$OutfitsTableOrderingComposer get outfitId {
    final $$OutfitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.outfitId,
      referencedTable: $db.outfits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OutfitsTableOrderingComposer(
            $db: $db,
            $table: $db.outfits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OutfitFeedbackTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutfitFeedbackTable> {
  $$OutfitFeedbackTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get reasonCode => $composableBuilder(
    column: $table.reasonCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reasonText => $composableBuilder(
    column: $table.reasonText,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$OutfitsTableAnnotationComposer get outfitId {
    final $$OutfitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.outfitId,
      referencedTable: $db.outfits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OutfitsTableAnnotationComposer(
            $db: $db,
            $table: $db.outfits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OutfitFeedbackTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutfitFeedbackTable,
          OutfitFeedbackData,
          $$OutfitFeedbackTableFilterComposer,
          $$OutfitFeedbackTableOrderingComposer,
          $$OutfitFeedbackTableAnnotationComposer,
          $$OutfitFeedbackTableCreateCompanionBuilder,
          $$OutfitFeedbackTableUpdateCompanionBuilder,
          (OutfitFeedbackData, $$OutfitFeedbackTableReferences),
          OutfitFeedbackData,
          PrefetchHooks Function({bool outfitId})
        > {
  $$OutfitFeedbackTableTableManager(
    _$AppDatabase db,
    $OutfitFeedbackTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutfitFeedbackTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutfitFeedbackTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutfitFeedbackTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> outfitId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> reasonCode = const Value.absent(),
                Value<String?> reasonText = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutfitFeedbackCompanion(
                id: id,
                outfitId: outfitId,
                kind: kind,
                reasonCode: reasonCode,
                reasonText: reasonText,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String outfitId,
                required String kind,
                Value<String?> reasonCode = const Value.absent(),
                Value<String?> reasonText = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => OutfitFeedbackCompanion.insert(
                id: id,
                outfitId: outfitId,
                kind: kind,
                reasonCode: reasonCode,
                reasonText: reasonText,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutfitFeedbackTable, OutfitFeedbackData>(table),
                  $$OutfitFeedbackTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({outfitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                    if (outfitId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.outfitId,
                        referencedTable: $$OutfitFeedbackTableReferences
                            ._outfitIdTable(db),
                        referencedColumn: $$OutfitFeedbackTableReferences
                            ._outfitIdTable(db)
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
        ),
      );
}

typedef $$OutfitFeedbackTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutfitFeedbackTable,
      OutfitFeedbackData,
      $$OutfitFeedbackTableFilterComposer,
      $$OutfitFeedbackTableOrderingComposer,
      $$OutfitFeedbackTableAnnotationComposer,
      $$OutfitFeedbackTableCreateCompanionBuilder,
      $$OutfitFeedbackTableUpdateCompanionBuilder,
      (OutfitFeedbackData, $$OutfitFeedbackTableReferences),
      OutfitFeedbackData,
      PrefetchHooks Function({bool outfitId})
    >;
typedef $$LearnedPreferencesTableCreateCompanionBuilder =
    LearnedPreferencesCompanion Function({
      required String key,
      required double weight,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$LearnedPreferencesTableUpdateCompanionBuilder =
    LearnedPreferencesCompanion Function({
      Value<String> key,
      Value<double> weight,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$LearnedPreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $LearnedPreferencesTable> {
  $$LearnedPreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LearnedPreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $LearnedPreferencesTable> {
  $$LearnedPreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LearnedPreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LearnedPreferencesTable> {
  $$LearnedPreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LearnedPreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LearnedPreferencesTable,
          LearnedPreference,
          $$LearnedPreferencesTableFilterComposer,
          $$LearnedPreferencesTableOrderingComposer,
          $$LearnedPreferencesTableAnnotationComposer,
          $$LearnedPreferencesTableCreateCompanionBuilder,
          $$LearnedPreferencesTableUpdateCompanionBuilder,
          (
            LearnedPreference,
            BaseReferences<
              _$AppDatabase,
              $LearnedPreferencesTable,
              LearnedPreference
            >,
          ),
          LearnedPreference,
          PrefetchHooks Function()
        > {
  $$LearnedPreferencesTableTableManager(
    _$AppDatabase db,
    $LearnedPreferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LearnedPreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LearnedPreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LearnedPreferencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<double> weight = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LearnedPreferencesCompanion(
                key: key,
                weight: weight,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required double weight,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LearnedPreferencesCompanion.insert(
                key: key,
                weight: weight,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LearnedPreferencesTable, LearnedPreference>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $LearnedPreferencesTable,
                    LearnedPreference
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LearnedPreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LearnedPreferencesTable,
      LearnedPreference,
      $$LearnedPreferencesTableFilterComposer,
      $$LearnedPreferencesTableOrderingComposer,
      $$LearnedPreferencesTableAnnotationComposer,
      $$LearnedPreferencesTableCreateCompanionBuilder,
      $$LearnedPreferencesTableUpdateCompanionBuilder,
      (
        LearnedPreference,
        BaseReferences<
          _$AppDatabase,
          $LearnedPreferencesTable,
          LearnedPreference
        >,
      ),
      LearnedPreference,
      PrefetchHooks Function()
    >;
typedef $$ModelInstallationsTableCreateCompanionBuilder =
    ModelInstallationsCompanion Function({
      required String modelId,
      required String version,
      required String relativePath,
      required String sha256,
      required int byteSize,
      required String license,
      required String state,
      Value<int?> installedAt,
      Value<int> rowid,
    });
typedef $$ModelInstallationsTableUpdateCompanionBuilder =
    ModelInstallationsCompanion Function({
      Value<String> modelId,
      Value<String> version,
      Value<String> relativePath,
      Value<String> sha256,
      Value<int> byteSize,
      Value<String> license,
      Value<String> state,
      Value<int?> installedAt,
      Value<int> rowid,
    });

class $$ModelInstallationsTableFilterComposer
    extends Composer<_$AppDatabase, $ModelInstallationsTable> {
  $$ModelInstallationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get license => $composableBuilder(
    column: $table.license,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ModelInstallationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ModelInstallationsTable> {
  $$ModelInstallationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get license => $composableBuilder(
    column: $table.license,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ModelInstallationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ModelInstallationsTable> {
  $$ModelInstallationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => column);

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<int> get byteSize =>
      $composableBuilder(column: $table.byteSize, builder: (column) => column);

  GeneratedColumn<String> get license =>
      $composableBuilder(column: $table.license, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => column,
  );
}

class $$ModelInstallationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ModelInstallationsTable,
          ModelInstallation,
          $$ModelInstallationsTableFilterComposer,
          $$ModelInstallationsTableOrderingComposer,
          $$ModelInstallationsTableAnnotationComposer,
          $$ModelInstallationsTableCreateCompanionBuilder,
          $$ModelInstallationsTableUpdateCompanionBuilder,
          (
            ModelInstallation,
            BaseReferences<
              _$AppDatabase,
              $ModelInstallationsTable,
              ModelInstallation
            >,
          ),
          ModelInstallation,
          PrefetchHooks Function()
        > {
  $$ModelInstallationsTableTableManager(
    _$AppDatabase db,
    $ModelInstallationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ModelInstallationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ModelInstallationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ModelInstallationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> modelId = const Value.absent(),
                Value<String> version = const Value.absent(),
                Value<String> relativePath = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<int> byteSize = const Value.absent(),
                Value<String> license = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int?> installedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ModelInstallationsCompanion(
                modelId: modelId,
                version: version,
                relativePath: relativePath,
                sha256: sha256,
                byteSize: byteSize,
                license: license,
                state: state,
                installedAt: installedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String modelId,
                required String version,
                required String relativePath,
                required String sha256,
                required int byteSize,
                required String license,
                required String state,
                Value<int?> installedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ModelInstallationsCompanion.insert(
                modelId: modelId,
                version: version,
                relativePath: relativePath,
                sha256: sha256,
                byteSize: byteSize,
                license: license,
                state: state,
                installedAt: installedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ModelInstallationsTable, ModelInstallation>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $ModelInstallationsTable,
                    ModelInstallation
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ModelInstallationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ModelInstallationsTable,
      ModelInstallation,
      $$ModelInstallationsTableFilterComposer,
      $$ModelInstallationsTableOrderingComposer,
      $$ModelInstallationsTableAnnotationComposer,
      $$ModelInstallationsTableCreateCompanionBuilder,
      $$ModelInstallationsTableUpdateCompanionBuilder,
      (
        ModelInstallation,
        BaseReferences<
          _$AppDatabase,
          $ModelInstallationsTable,
          ModelInstallation
        >,
      ),
      ModelInstallation,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UserProfileTableTableManager get userProfile =>
      $$UserProfileTableTableManager(_db, _db.userProfile);
  $$ClothingItemsTableTableManager get clothingItems =>
      $$ClothingItemsTableTableManager(_db, _db.clothingItems);
  $$ClothingItemColorsTableTableManager get clothingItemColors =>
      $$ClothingItemColorsTableTableManager(_db, _db.clothingItemColors);
  $$ClothingItemSeasonsTableTableManager get clothingItemSeasons =>
      $$ClothingItemSeasonsTableTableManager(_db, _db.clothingItemSeasons);
  $$ClothingImagesTableTableManager get clothingImages =>
      $$ClothingImagesTableTableManager(_db, _db.clothingImages);
  $$ClothingAttributesTableTableManager get clothingAttributes =>
      $$ClothingAttributesTableTableManager(_db, _db.clothingAttributes);
  $$OutfitsTableTableManager get outfits =>
      $$OutfitsTableTableManager(_db, _db.outfits);
  $$OutfitItemsTableTableManager get outfitItems =>
      $$OutfitItemsTableTableManager(_db, _db.outfitItems);
  $$OutfitFeedbackTableTableManager get outfitFeedback =>
      $$OutfitFeedbackTableTableManager(_db, _db.outfitFeedback);
  $$LearnedPreferencesTableTableManager get learnedPreferences =>
      $$LearnedPreferencesTableTableManager(_db, _db.learnedPreferences);
  $$ModelInstallationsTableTableManager get modelInstallations =>
      $$ModelInstallationsTableTableManager(_db, _db.modelInstallations);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
