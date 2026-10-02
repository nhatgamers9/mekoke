// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $HabitsTable extends Habits with TableInfo<$HabitsTable, Habit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitsTable(this.attachedDatabase, [this._alias]);
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
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate, String> cleanSince =
      GeneratedColumn<String>(
        'clean_since',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocalDate>($HabitsTable.$convertercleanSince);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, cleanSince, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habits';
  @override
  VerificationContext validateIntegrity(
    Insertable<Habit> instance, {
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
  Habit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Habit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      cleanSince: $HabitsTable.$convertercleanSince.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}clean_since'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $HabitsTable createAlias(String alias) {
    return $HabitsTable(attachedDatabase, alias);
  }

  static TypeConverter<LocalDate, String> $convertercleanSince =
      const LocalDateConverter();
}

class Habit extends DataClass implements Insertable<Habit> {
  final int id;
  final String name;
  final LocalDate cleanSince;
  final DateTime createdAt;
  const Habit({
    required this.id,
    required this.name,
    required this.cleanSince,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['clean_since'] = Variable<String>(
        $HabitsTable.$convertercleanSince.toSql(cleanSince),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  HabitsCompanion toCompanion(bool nullToAbsent) {
    return HabitsCompanion(
      id: Value(id),
      name: Value(name),
      cleanSince: Value(cleanSince),
      createdAt: Value(createdAt),
    );
  }

  factory Habit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Habit(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      cleanSince: serializer.fromJson<LocalDate>(json['cleanSince']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'cleanSince': serializer.toJson<LocalDate>(cleanSince),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Habit copyWith({
    int? id,
    String? name,
    LocalDate? cleanSince,
    DateTime? createdAt,
  }) => Habit(
    id: id ?? this.id,
    name: name ?? this.name,
    cleanSince: cleanSince ?? this.cleanSince,
    createdAt: createdAt ?? this.createdAt,
  );
  Habit copyWithCompanion(HabitsCompanion data) {
    return Habit(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      cleanSince: data.cleanSince.present
          ? data.cleanSince.value
          : this.cleanSince,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Habit(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('cleanSince: $cleanSince, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, cleanSince, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Habit &&
          other.id == this.id &&
          other.name == this.name &&
          other.cleanSince == this.cleanSince &&
          other.createdAt == this.createdAt);
}

class HabitsCompanion extends UpdateCompanion<Habit> {
  final Value<int> id;
  final Value<String> name;
  final Value<LocalDate> cleanSince;
  final Value<DateTime> createdAt;
  const HabitsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.cleanSince = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  HabitsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required LocalDate cleanSince,
    required DateTime createdAt,
  }) : name = Value(name),
       cleanSince = Value(cleanSince),
       createdAt = Value(createdAt);
  static Insertable<Habit> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? cleanSince,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (cleanSince != null) 'clean_since': cleanSince,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  HabitsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<LocalDate>? cleanSince,
    Value<DateTime>? createdAt,
  }) {
    return HabitsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      cleanSince: cleanSince ?? this.cleanSince,
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
    if (cleanSince.present) {
      map['clean_since'] = Variable<String>(
        $HabitsTable.$convertercleanSince.toSql(cleanSince.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('cleanSince: $cleanSince, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CheckInsTable extends CheckIns with TableInfo<$CheckInsTable, CheckIn> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CheckInsTable(this.attachedDatabase, [this._alias]);
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
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate, String> date =
      GeneratedColumn<String>(
        'date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      ).withConverter<LocalDate>($CheckInsTable.$converterdate);
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<int> mood = GeneratedColumn<int>(
    'mood',
    aliasedName,
    false,
    check: () => ComparableExpr(mood).isBetweenValues(1, 5),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, date, mood, note, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'check_ins';
  @override
  VerificationContext validateIntegrity(
    Insertable<CheckIn> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('mood')) {
      context.handle(
        _moodMeta,
        mood.isAcceptableOrUnknown(data['mood']!, _moodMeta),
      );
    } else if (isInserting) {
      context.missing(_moodMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
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
  CheckIn map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CheckIn(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: $CheckInsTable.$converterdate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}date'],
        )!,
      ),
      mood: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mood'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CheckInsTable createAlias(String alias) {
    return $CheckInsTable(attachedDatabase, alias);
  }

  static TypeConverter<LocalDate, String> $converterdate =
      const LocalDateConverter();
}

class CheckIn extends DataClass implements Insertable<CheckIn> {
  final int id;
  final LocalDate date;
  final int mood;
  final String? note;
  final DateTime updatedAt;
  const CheckIn({
    required this.id,
    required this.date,
    required this.mood,
    this.note,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['date'] = Variable<String>($CheckInsTable.$converterdate.toSql(date));
    }
    map['mood'] = Variable<int>(mood);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CheckInsCompanion toCompanion(bool nullToAbsent) {
    return CheckInsCompanion(
      id: Value(id),
      date: Value(date),
      mood: Value(mood),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      updatedAt: Value(updatedAt),
    );
  }

  factory CheckIn.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CheckIn(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<LocalDate>(json['date']),
      mood: serializer.fromJson<int>(json['mood']),
      note: serializer.fromJson<String?>(json['note']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<LocalDate>(date),
      'mood': serializer.toJson<int>(mood),
      'note': serializer.toJson<String?>(note),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CheckIn copyWith({
    int? id,
    LocalDate? date,
    int? mood,
    Value<String?> note = const Value.absent(),
    DateTime? updatedAt,
  }) => CheckIn(
    id: id ?? this.id,
    date: date ?? this.date,
    mood: mood ?? this.mood,
    note: note.present ? note.value : this.note,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CheckIn copyWithCompanion(CheckInsCompanion data) {
    return CheckIn(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      mood: data.mood.present ? data.mood.value : this.mood,
      note: data.note.present ? data.note.value : this.note,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CheckIn(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('mood: $mood, ')
          ..write('note: $note, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, mood, note, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CheckIn &&
          other.id == this.id &&
          other.date == this.date &&
          other.mood == this.mood &&
          other.note == this.note &&
          other.updatedAt == this.updatedAt);
}

class CheckInsCompanion extends UpdateCompanion<CheckIn> {
  final Value<int> id;
  final Value<LocalDate> date;
  final Value<int> mood;
  final Value<String?> note;
  final Value<DateTime> updatedAt;
  const CheckInsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.mood = const Value.absent(),
    this.note = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CheckInsCompanion.insert({
    this.id = const Value.absent(),
    required LocalDate date,
    required int mood,
    this.note = const Value.absent(),
    required DateTime updatedAt,
  }) : date = Value(date),
       mood = Value(mood),
       updatedAt = Value(updatedAt);
  static Insertable<CheckIn> custom({
    Expression<int>? id,
    Expression<String>? date,
    Expression<int>? mood,
    Expression<String>? note,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (mood != null) 'mood': mood,
      if (note != null) 'note': note,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CheckInsCompanion copyWith({
    Value<int>? id,
    Value<LocalDate>? date,
    Value<int>? mood,
    Value<String?>? note,
    Value<DateTime>? updatedAt,
  }) {
    return CheckInsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(
        $CheckInsTable.$converterdate.toSql(date.value),
      );
    }
    if (mood.present) {
      map['mood'] = Variable<int>(mood.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CheckInsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('mood: $mood, ')
          ..write('note: $note, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $FastsTable extends Fasts with TableInfo<$FastsTable, Fast> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FastsTable(this.attachedDatabase, [this._alias]);
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
  @override
  late final GeneratedColumnWithTypeConverter<FastingPlan, String> plan =
      GeneratedColumn<String>(
        'plan',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<FastingPlan>($FastsTable.$converterplan);
  static const VerificationMeta _goalMinutesMeta = const VerificationMeta(
    'goalMinutes',
  );
  @override
  late final GeneratedColumn<int> goalMinutes = GeneratedColumn<int>(
    'goal_minutes',
    aliasedName,
    false,
    check: () => ComparableExpr(goalMinutes).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    plan,
    goalMinutes,
    startedAt,
    endedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fasts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Fast> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('goal_minutes')) {
      context.handle(
        _goalMinutesMeta,
        goalMinutes.isAcceptableOrUnknown(
          data['goal_minutes']!,
          _goalMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_goalMinutesMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Fast map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Fast(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      plan: $FastsTable.$converterplan.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}plan'],
        )!,
      ),
      goalMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}goal_minutes'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
    );
  }

  @override
  $FastsTable createAlias(String alias) {
    return $FastsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FastingPlan, String, String> $converterplan =
      const EnumNameConverter<FastingPlan>(FastingPlan.values);
}

class Fast extends DataClass implements Insertable<Fast> {
  final int id;
  final FastingPlan plan;
  final int goalMinutes;
  final DateTime startedAt;
  final DateTime? endedAt;
  const Fast({
    required this.id,
    required this.plan,
    required this.goalMinutes,
    required this.startedAt,
    this.endedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['plan'] = Variable<String>($FastsTable.$converterplan.toSql(plan));
    }
    map['goal_minutes'] = Variable<int>(goalMinutes);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    return map;
  }

  FastsCompanion toCompanion(bool nullToAbsent) {
    return FastsCompanion(
      id: Value(id),
      plan: Value(plan),
      goalMinutes: Value(goalMinutes),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
    );
  }

  factory Fast.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Fast(
      id: serializer.fromJson<int>(json['id']),
      plan: $FastsTable.$converterplan.fromJson(
        serializer.fromJson<String>(json['plan']),
      ),
      goalMinutes: serializer.fromJson<int>(json['goalMinutes']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'plan': serializer.toJson<String>(
        $FastsTable.$converterplan.toJson(plan),
      ),
      'goalMinutes': serializer.toJson<int>(goalMinutes),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
    };
  }

  Fast copyWith({
    int? id,
    FastingPlan? plan,
    int? goalMinutes,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
  }) => Fast(
    id: id ?? this.id,
    plan: plan ?? this.plan,
    goalMinutes: goalMinutes ?? this.goalMinutes,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
  );
  Fast copyWithCompanion(FastsCompanion data) {
    return Fast(
      id: data.id.present ? data.id.value : this.id,
      plan: data.plan.present ? data.plan.value : this.plan,
      goalMinutes: data.goalMinutes.present
          ? data.goalMinutes.value
          : this.goalMinutes,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Fast(')
          ..write('id: $id, ')
          ..write('plan: $plan, ')
          ..write('goalMinutes: $goalMinutes, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, plan, goalMinutes, startedAt, endedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Fast &&
          other.id == this.id &&
          other.plan == this.plan &&
          other.goalMinutes == this.goalMinutes &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt);
}

class FastsCompanion extends UpdateCompanion<Fast> {
  final Value<int> id;
  final Value<FastingPlan> plan;
  final Value<int> goalMinutes;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  const FastsCompanion({
    this.id = const Value.absent(),
    this.plan = const Value.absent(),
    this.goalMinutes = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
  });
  FastsCompanion.insert({
    this.id = const Value.absent(),
    required FastingPlan plan,
    required int goalMinutes,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
  }) : plan = Value(plan),
       goalMinutes = Value(goalMinutes),
       startedAt = Value(startedAt);
  static Insertable<Fast> custom({
    Expression<int>? id,
    Expression<String>? plan,
    Expression<int>? goalMinutes,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plan != null) 'plan': plan,
      if (goalMinutes != null) 'goal_minutes': goalMinutes,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
    });
  }

  FastsCompanion copyWith({
    Value<int>? id,
    Value<FastingPlan>? plan,
    Value<int>? goalMinutes,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
  }) {
    return FastsCompanion(
      id: id ?? this.id,
      plan: plan ?? this.plan,
      goalMinutes: goalMinutes ?? this.goalMinutes,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (plan.present) {
      map['plan'] = Variable<String>(
        $FastsTable.$converterplan.toSql(plan.value),
      );
    }
    if (goalMinutes.present) {
      map['goal_minutes'] = Variable<int>(goalMinutes.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FastsCompanion(')
          ..write('id: $id, ')
          ..write('plan: $plan, ')
          ..write('goalMinutes: $goalMinutes, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt')
          ..write(')'))
        .toString();
  }
}

class $PrefsTable extends Prefs with TableInfo<$PrefsTable, PrefEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrefsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
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
  List<GeneratedColumn> get $columns => [name, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prefs';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrefEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
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
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  PrefEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrefEntry(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $PrefsTable createAlias(String alias) {
    return $PrefsTable(attachedDatabase, alias);
  }
}

class PrefEntry extends DataClass implements Insertable<PrefEntry> {
  final String name;
  final String value;
  const PrefEntry({required this.name, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['value'] = Variable<String>(value);
    return map;
  }

  PrefsCompanion toCompanion(bool nullToAbsent) {
    return PrefsCompanion(name: Value(name), value: Value(value));
  }

  factory PrefEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrefEntry(
      name: serializer.fromJson<String>(json['name']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'value': serializer.toJson<String>(value),
    };
  }

  PrefEntry copyWith({String? name, String? value}) =>
      PrefEntry(name: name ?? this.name, value: value ?? this.value);
  PrefEntry copyWithCompanion(PrefsCompanion data) {
    return PrefEntry(
      name: data.name.present ? data.name.value : this.name,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrefEntry(')
          ..write('name: $name, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrefEntry &&
          other.name == this.name &&
          other.value == this.value);
}

class PrefsCompanion extends UpdateCompanion<PrefEntry> {
  final Value<String> name;
  final Value<String> value;
  final Value<int> rowid;
  const PrefsCompanion({
    this.name = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrefsCompanion.insert({
    required String name,
    required String value,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       value = Value(value);
  static Insertable<PrefEntry> custom({
    Expression<String>? name,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrefsCompanion copyWith({
    Value<String>? name,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return PrefsCompanion(
      name: name ?? this.name,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
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
    return (StringBuffer('PrefsCompanion(')
          ..write('name: $name, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HabitsTable habits = $HabitsTable(this);
  late final $CheckInsTable checkIns = $CheckInsTable(this);
  late final $FastsTable fasts = $FastsTable(this);
  late final $PrefsTable prefs = $PrefsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    habits,
    checkIns,
    fasts,
    prefs,
  ];
}

typedef $$HabitsTableCreateCompanionBuilder = HabitsCompanion Function({
  Value<int> id,
  required String name,
  required LocalDate cleanSince,
  required DateTime createdAt,
});
typedef $$HabitsTableUpdateCompanionBuilder = HabitsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<LocalDate> cleanSince,
  Value<DateTime> createdAt,
});

class $$HabitsTableFilterComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<LocalDate, LocalDate, String> get cleanSince =>
      $composableBuilder(
        column: $table.cleanSince,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HabitsTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableOrderingComposer({
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

  ColumnOrderings<String> get cleanSince => $composableBuilder(
    column: $table.cleanSince,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HabitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableAnnotationComposer({
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

  GeneratedColumnWithTypeConverter<LocalDate, String> get cleanSince =>
      $composableBuilder(
        column: $table.cleanSince,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$HabitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitsTable,
          Habit,
          $$HabitsTableFilterComposer,
          $$HabitsTableOrderingComposer,
          $$HabitsTableAnnotationComposer,
          $$HabitsTableCreateCompanionBuilder,
          $$HabitsTableUpdateCompanionBuilder,
          (Habit, BaseReferences<_$AppDatabase, $HabitsTable, Habit>),
          Habit,
          PrefetchHooks Function()
        > {
  $$HabitsTableTableManager(_$AppDatabase db, $HabitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<LocalDate> cleanSince = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => HabitsCompanion(
                id: id,
                name: name,
                cleanSince: cleanSince,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required LocalDate cleanSince,
                required DateTime createdAt,
              }) => HabitsCompanion.insert(
                id: id,
                name: name,
                cleanSince: cleanSince,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HabitsTable, Habit>(table),
                  BaseReferences<_$AppDatabase, $HabitsTable, Habit>(
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

typedef $$HabitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitsTable,
      Habit,
      $$HabitsTableFilterComposer,
      $$HabitsTableOrderingComposer,
      $$HabitsTableAnnotationComposer,
      $$HabitsTableCreateCompanionBuilder,
      $$HabitsTableUpdateCompanionBuilder,
      (Habit, BaseReferences<_$AppDatabase, $HabitsTable, Habit>),
      Habit,
      PrefetchHooks Function()
    >;
typedef $$CheckInsTableCreateCompanionBuilder = CheckInsCompanion Function({
  Value<int> id,
  required LocalDate date,
  required int mood,
  Value<String?> note,
  required DateTime updatedAt,
});
typedef $$CheckInsTableUpdateCompanionBuilder = CheckInsCompanion Function({
  Value<int> id,
  Value<LocalDate> date,
  Value<int> mood,
  Value<String?> note,
  Value<DateTime> updatedAt,
});

class $$CheckInsTableFilterComposer
    extends Composer<_$AppDatabase, $CheckInsTable> {
  $$CheckInsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<LocalDate, LocalDate, String> get date =>
      $composableBuilder(
        column: $table.date,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CheckInsTableOrderingComposer
    extends Composer<_$AppDatabase, $CheckInsTable> {
  $$CheckInsTableOrderingComposer({
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

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CheckInsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CheckInsTable> {
  $$CheckInsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LocalDate, String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CheckInsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CheckInsTable,
          CheckIn,
          $$CheckInsTableFilterComposer,
          $$CheckInsTableOrderingComposer,
          $$CheckInsTableAnnotationComposer,
          $$CheckInsTableCreateCompanionBuilder,
          $$CheckInsTableUpdateCompanionBuilder,
          (CheckIn, BaseReferences<_$AppDatabase, $CheckInsTable, CheckIn>),
          CheckIn,
          PrefetchHooks Function()
        > {
  $$CheckInsTableTableManager(_$AppDatabase db, $CheckInsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CheckInsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CheckInsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CheckInsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<LocalDate> date = const Value.absent(),
                Value<int> mood = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CheckInsCompanion(
                id: id,
                date: date,
                mood: mood,
                note: note,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required LocalDate date,
                required int mood,
                Value<String?> note = const Value.absent(),
                required DateTime updatedAt,
              }) => CheckInsCompanion.insert(
                id: id,
                date: date,
                mood: mood,
                note: note,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CheckInsTable, CheckIn>(table),
                  BaseReferences<_$AppDatabase, $CheckInsTable, CheckIn>(
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

typedef $$CheckInsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CheckInsTable,
      CheckIn,
      $$CheckInsTableFilterComposer,
      $$CheckInsTableOrderingComposer,
      $$CheckInsTableAnnotationComposer,
      $$CheckInsTableCreateCompanionBuilder,
      $$CheckInsTableUpdateCompanionBuilder,
      (CheckIn, BaseReferences<_$AppDatabase, $CheckInsTable, CheckIn>),
      CheckIn,
      PrefetchHooks Function()
    >;
typedef $$FastsTableCreateCompanionBuilder = FastsCompanion Function({
  Value<int> id,
  required FastingPlan plan,
  required int goalMinutes,
  required DateTime startedAt,
  Value<DateTime?> endedAt,
});
typedef $$FastsTableUpdateCompanionBuilder = FastsCompanion Function({
  Value<int> id,
  Value<FastingPlan> plan,
  Value<int> goalMinutes,
  Value<DateTime> startedAt,
  Value<DateTime?> endedAt,
});

class $$FastsTableFilterComposer extends Composer<_$AppDatabase, $FastsTable> {
  $$FastsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<FastingPlan, FastingPlan, String> get plan =>
      $composableBuilder(
        column: $table.plan,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get goalMinutes => $composableBuilder(
    column: $table.goalMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FastsTableOrderingComposer
    extends Composer<_$AppDatabase, $FastsTable> {
  $$FastsTableOrderingComposer({
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

  ColumnOrderings<String> get plan => $composableBuilder(
    column: $table.plan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get goalMinutes => $composableBuilder(
    column: $table.goalMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FastsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FastsTable> {
  $$FastsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FastingPlan, String> get plan =>
      $composableBuilder(column: $table.plan, builder: (column) => column);

  GeneratedColumn<int> get goalMinutes => $composableBuilder(
    column: $table.goalMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);
}

class $$FastsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FastsTable,
          Fast,
          $$FastsTableFilterComposer,
          $$FastsTableOrderingComposer,
          $$FastsTableAnnotationComposer,
          $$FastsTableCreateCompanionBuilder,
          $$FastsTableUpdateCompanionBuilder,
          (Fast, BaseReferences<_$AppDatabase, $FastsTable, Fast>),
          Fast,
          PrefetchHooks Function()
        > {
  $$FastsTableTableManager(_$AppDatabase db, $FastsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FastsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FastsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FastsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<FastingPlan> plan = const Value.absent(),
                Value<int> goalMinutes = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
              }) => FastsCompanion(
                id: id,
                plan: plan,
                goalMinutes: goalMinutes,
                startedAt: startedAt,
                endedAt: endedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required FastingPlan plan,
                required int goalMinutes,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
              }) => FastsCompanion.insert(
                id: id,
                plan: plan,
                goalMinutes: goalMinutes,
                startedAt: startedAt,
                endedAt: endedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FastsTable, Fast>(table),
                  BaseReferences<_$AppDatabase, $FastsTable, Fast>(
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

typedef $$FastsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FastsTable,
      Fast,
      $$FastsTableFilterComposer,
      $$FastsTableOrderingComposer,
      $$FastsTableAnnotationComposer,
      $$FastsTableCreateCompanionBuilder,
      $$FastsTableUpdateCompanionBuilder,
      (Fast, BaseReferences<_$AppDatabase, $FastsTable, Fast>),
      Fast,
      PrefetchHooks Function()
    >;
typedef $$PrefsTableCreateCompanionBuilder = PrefsCompanion Function({
  required String name,
  required String value,
  Value<int> rowid,
});
typedef $$PrefsTableUpdateCompanionBuilder = PrefsCompanion Function({
  Value<String> name,
  Value<String> value,
  Value<int> rowid,
});

class $$PrefsTableFilterComposer extends Composer<_$AppDatabase, $PrefsTable> {
  $$PrefsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrefsTableOrderingComposer
    extends Composer<_$AppDatabase, $PrefsTable> {
  $$PrefsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrefsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrefsTable> {
  $$PrefsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$PrefsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrefsTable,
          PrefEntry,
          $$PrefsTableFilterComposer,
          $$PrefsTableOrderingComposer,
          $$PrefsTableAnnotationComposer,
          $$PrefsTableCreateCompanionBuilder,
          $$PrefsTableUpdateCompanionBuilder,
          (PrefEntry, BaseReferences<_$AppDatabase, $PrefsTable, PrefEntry>),
          PrefEntry,
          PrefetchHooks Function()
        > {
  $$PrefsTableTableManager(_$AppDatabase db, $PrefsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> name = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => PrefsCompanion(name: name, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String name,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => PrefsCompanion.insert(name: name, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PrefsTable, PrefEntry>(table),
                  BaseReferences<_$AppDatabase, $PrefsTable, PrefEntry>(
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

typedef $$PrefsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrefsTable,
      PrefEntry,
      $$PrefsTableFilterComposer,
      $$PrefsTableOrderingComposer,
      $$PrefsTableAnnotationComposer,
      $$PrefsTableCreateCompanionBuilder,
      $$PrefsTableUpdateCompanionBuilder,
      (PrefEntry, BaseReferences<_$AppDatabase, $PrefsTable, PrefEntry>),
      PrefEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HabitsTableTableManager get habits =>
      $$HabitsTableTableManager(_db, _db.habits);
  $$CheckInsTableTableManager get checkIns =>
      $$CheckInsTableTableManager(_db, _db.checkIns);
  $$FastsTableTableManager get fasts =>
      $$FastsTableTableManager(_db, _db.fasts);
  $$PrefsTableTableManager get prefs =>
      $$PrefsTableTableManager(_db, _db.prefs);
}
