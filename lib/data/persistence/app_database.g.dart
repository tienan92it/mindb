// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ConnectionProfilesTable extends ConnectionProfiles
    with TableInfo<$ConnectionProfilesTable, ConnectionProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConnectionProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _hostMeta = const VerificationMeta('host');
  @override
  late final GeneratedColumn<String> host = GeneratedColumn<String>(
      'host', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _portMeta = const VerificationMeta('port');
  @override
  late final GeneratedColumn<int> port = GeneratedColumn<int>(
      'port', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _databaseNameMeta =
      const VerificationMeta('databaseName');
  @override
  late final GeneratedColumn<String> databaseName = GeneratedColumn<String>(
      'database_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _usernameMeta =
      const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
      'username', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _useSslMeta = const VerificationMeta('useSsl');
  @override
  late final GeneratedColumn<bool> useSsl = GeneratedColumn<bool>(
      'use_ssl', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("use_ssl" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastUsedAtMeta =
      const VerificationMeta('lastUsedAt');
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
      'last_used_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        host,
        port,
        databaseName,
        username,
        useSsl,
        lastUsedAt,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'connection_profiles';
  @override
  VerificationContext validateIntegrity(
      Insertable<ConnectionProfileRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('host')) {
      context.handle(
          _hostMeta, host.isAcceptableOrUnknown(data['host']!, _hostMeta));
    } else if (isInserting) {
      context.missing(_hostMeta);
    }
    if (data.containsKey('port')) {
      context.handle(
          _portMeta, port.isAcceptableOrUnknown(data['port']!, _portMeta));
    } else if (isInserting) {
      context.missing(_portMeta);
    }
    if (data.containsKey('database_name')) {
      context.handle(
          _databaseNameMeta,
          databaseName.isAcceptableOrUnknown(
              data['database_name']!, _databaseNameMeta));
    } else if (isInserting) {
      context.missing(_databaseNameMeta);
    }
    if (data.containsKey('username')) {
      context.handle(_usernameMeta,
          username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('use_ssl')) {
      context.handle(_useSslMeta,
          useSsl.isAcceptableOrUnknown(data['use_ssl']!, _useSslMeta));
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
          _lastUsedAtMeta,
          lastUsedAt.isAcceptableOrUnknown(
              data['last_used_at']!, _lastUsedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConnectionProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConnectionProfileRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      host: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}host'])!,
      port: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}port'])!,
      databaseName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}database_name'])!,
      username: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}username'])!,
      useSsl: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}use_ssl'])!,
      lastUsedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_used_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ConnectionProfilesTable createAlias(String alias) {
    return $ConnectionProfilesTable(attachedDatabase, alias);
  }
}

class ConnectionProfileRow extends DataClass
    implements Insertable<ConnectionProfileRow> {
  final String id;
  final String name;
  final String host;
  final int port;
  final String databaseName;
  final String username;
  final bool useSsl;
  final DateTime? lastUsedAt;
  final DateTime createdAt;
  const ConnectionProfileRow(
      {required this.id,
      required this.name,
      required this.host,
      required this.port,
      required this.databaseName,
      required this.username,
      required this.useSsl,
      this.lastUsedAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['host'] = Variable<String>(host);
    map['port'] = Variable<int>(port);
    map['database_name'] = Variable<String>(databaseName);
    map['username'] = Variable<String>(username);
    map['use_ssl'] = Variable<bool>(useSsl);
    if (!nullToAbsent || lastUsedAt != null) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ConnectionProfilesCompanion toCompanion(bool nullToAbsent) {
    return ConnectionProfilesCompanion(
      id: Value(id),
      name: Value(name),
      host: Value(host),
      port: Value(port),
      databaseName: Value(databaseName),
      username: Value(username),
      useSsl: Value(useSsl),
      lastUsedAt: lastUsedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUsedAt),
      createdAt: Value(createdAt),
    );
  }

  factory ConnectionProfileRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConnectionProfileRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      host: serializer.fromJson<String>(json['host']),
      port: serializer.fromJson<int>(json['port']),
      databaseName: serializer.fromJson<String>(json['databaseName']),
      username: serializer.fromJson<String>(json['username']),
      useSsl: serializer.fromJson<bool>(json['useSsl']),
      lastUsedAt: serializer.fromJson<DateTime?>(json['lastUsedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'host': serializer.toJson<String>(host),
      'port': serializer.toJson<int>(port),
      'databaseName': serializer.toJson<String>(databaseName),
      'username': serializer.toJson<String>(username),
      'useSsl': serializer.toJson<bool>(useSsl),
      'lastUsedAt': serializer.toJson<DateTime?>(lastUsedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ConnectionProfileRow copyWith(
          {String? id,
          String? name,
          String? host,
          int? port,
          String? databaseName,
          String? username,
          bool? useSsl,
          Value<DateTime?> lastUsedAt = const Value.absent(),
          DateTime? createdAt}) =>
      ConnectionProfileRow(
        id: id ?? this.id,
        name: name ?? this.name,
        host: host ?? this.host,
        port: port ?? this.port,
        databaseName: databaseName ?? this.databaseName,
        username: username ?? this.username,
        useSsl: useSsl ?? this.useSsl,
        lastUsedAt: lastUsedAt.present ? lastUsedAt.value : this.lastUsedAt,
        createdAt: createdAt ?? this.createdAt,
      );
  ConnectionProfileRow copyWithCompanion(ConnectionProfilesCompanion data) {
    return ConnectionProfileRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      host: data.host.present ? data.host.value : this.host,
      port: data.port.present ? data.port.value : this.port,
      databaseName: data.databaseName.present
          ? data.databaseName.value
          : this.databaseName,
      username: data.username.present ? data.username.value : this.username,
      useSsl: data.useSsl.present ? data.useSsl.value : this.useSsl,
      lastUsedAt:
          data.lastUsedAt.present ? data.lastUsedAt.value : this.lastUsedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConnectionProfileRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('host: $host, ')
          ..write('port: $port, ')
          ..write('databaseName: $databaseName, ')
          ..write('username: $username, ')
          ..write('useSsl: $useSsl, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, host, port, databaseName, username,
      useSsl, lastUsedAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConnectionProfileRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.host == this.host &&
          other.port == this.port &&
          other.databaseName == this.databaseName &&
          other.username == this.username &&
          other.useSsl == this.useSsl &&
          other.lastUsedAt == this.lastUsedAt &&
          other.createdAt == this.createdAt);
}

class ConnectionProfilesCompanion
    extends UpdateCompanion<ConnectionProfileRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> host;
  final Value<int> port;
  final Value<String> databaseName;
  final Value<String> username;
  final Value<bool> useSsl;
  final Value<DateTime?> lastUsedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ConnectionProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.host = const Value.absent(),
    this.port = const Value.absent(),
    this.databaseName = const Value.absent(),
    this.username = const Value.absent(),
    this.useSsl = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConnectionProfilesCompanion.insert({
    required String id,
    required String name,
    required String host,
    required int port,
    required String databaseName,
    required String username,
    this.useSsl = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        host = Value(host),
        port = Value(port),
        databaseName = Value(databaseName),
        username = Value(username),
        createdAt = Value(createdAt);
  static Insertable<ConnectionProfileRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? host,
    Expression<int>? port,
    Expression<String>? databaseName,
    Expression<String>? username,
    Expression<bool>? useSsl,
    Expression<DateTime>? lastUsedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (host != null) 'host': host,
      if (port != null) 'port': port,
      if (databaseName != null) 'database_name': databaseName,
      if (username != null) 'username': username,
      if (useSsl != null) 'use_ssl': useSsl,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConnectionProfilesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? host,
      Value<int>? port,
      Value<String>? databaseName,
      Value<String>? username,
      Value<bool>? useSsl,
      Value<DateTime?>? lastUsedAt,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return ConnectionProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      databaseName: databaseName ?? this.databaseName,
      username: username ?? this.username,
      useSsl: useSsl ?? this.useSsl,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (host.present) {
      map['host'] = Variable<String>(host.value);
    }
    if (port.present) {
      map['port'] = Variable<int>(port.value);
    }
    if (databaseName.present) {
      map['database_name'] = Variable<String>(databaseName.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (useSsl.present) {
      map['use_ssl'] = Variable<bool>(useSsl.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConnectionProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('host: $host, ')
          ..write('port: $port, ')
          ..write('databaseName: $databaseName, ')
          ..write('username: $username, ')
          ..write('useSsl: $useSsl, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionHistoriesTable extends SessionHistories
    with TableInfo<$SessionHistoriesTable, SessionHistory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionHistoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _connectionIdMeta =
      const VerificationMeta('connectionId');
  @override
  late final GeneratedColumn<String> connectionId = GeneratedColumn<String>(
      'connection_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _summaryMeta =
      const VerificationMeta('summary');
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
      'summary', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _turnsJsonMeta =
      const VerificationMeta('turnsJson');
  @override
  late final GeneratedColumn<String> turnsJson = GeneratedColumn<String>(
      'turns_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [connectionId, summary, turnsJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_histories';
  @override
  VerificationContext validateIntegrity(Insertable<SessionHistory> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('connection_id')) {
      context.handle(
          _connectionIdMeta,
          connectionId.isAcceptableOrUnknown(
              data['connection_id']!, _connectionIdMeta));
    } else if (isInserting) {
      context.missing(_connectionIdMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(_summaryMeta,
          summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta));
    }
    if (data.containsKey('turns_json')) {
      context.handle(_turnsJsonMeta,
          turnsJson.isAcceptableOrUnknown(data['turns_json']!, _turnsJsonMeta));
    } else if (isInserting) {
      context.missing(_turnsJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {connectionId};
  @override
  SessionHistory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionHistory(
      connectionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}connection_id'])!,
      summary: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}summary']),
      turnsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}turns_json'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SessionHistoriesTable createAlias(String alias) {
    return $SessionHistoriesTable(attachedDatabase, alias);
  }
}

class SessionHistory extends DataClass implements Insertable<SessionHistory> {
  final String connectionId;
  final String? summary;
  final String turnsJson;
  final DateTime updatedAt;
  const SessionHistory(
      {required this.connectionId,
      this.summary,
      required this.turnsJson,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['connection_id'] = Variable<String>(connectionId);
    if (!nullToAbsent || summary != null) {
      map['summary'] = Variable<String>(summary);
    }
    map['turns_json'] = Variable<String>(turnsJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SessionHistoriesCompanion toCompanion(bool nullToAbsent) {
    return SessionHistoriesCompanion(
      connectionId: Value(connectionId),
      summary: summary == null && nullToAbsent
          ? const Value.absent()
          : Value(summary),
      turnsJson: Value(turnsJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory SessionHistory.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionHistory(
      connectionId: serializer.fromJson<String>(json['connectionId']),
      summary: serializer.fromJson<String?>(json['summary']),
      turnsJson: serializer.fromJson<String>(json['turnsJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'connectionId': serializer.toJson<String>(connectionId),
      'summary': serializer.toJson<String?>(summary),
      'turnsJson': serializer.toJson<String>(turnsJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SessionHistory copyWith(
          {String? connectionId,
          Value<String?> summary = const Value.absent(),
          String? turnsJson,
          DateTime? updatedAt}) =>
      SessionHistory(
        connectionId: connectionId ?? this.connectionId,
        summary: summary.present ? summary.value : this.summary,
        turnsJson: turnsJson ?? this.turnsJson,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SessionHistory copyWithCompanion(SessionHistoriesCompanion data) {
    return SessionHistory(
      connectionId: data.connectionId.present
          ? data.connectionId.value
          : this.connectionId,
      summary: data.summary.present ? data.summary.value : this.summary,
      turnsJson: data.turnsJson.present ? data.turnsJson.value : this.turnsJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionHistory(')
          ..write('connectionId: $connectionId, ')
          ..write('summary: $summary, ')
          ..write('turnsJson: $turnsJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(connectionId, summary, turnsJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionHistory &&
          other.connectionId == this.connectionId &&
          other.summary == this.summary &&
          other.turnsJson == this.turnsJson &&
          other.updatedAt == this.updatedAt);
}

class SessionHistoriesCompanion extends UpdateCompanion<SessionHistory> {
  final Value<String> connectionId;
  final Value<String?> summary;
  final Value<String> turnsJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SessionHistoriesCompanion({
    this.connectionId = const Value.absent(),
    this.summary = const Value.absent(),
    this.turnsJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionHistoriesCompanion.insert({
    required String connectionId,
    this.summary = const Value.absent(),
    required String turnsJson,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : connectionId = Value(connectionId),
        turnsJson = Value(turnsJson),
        updatedAt = Value(updatedAt);
  static Insertable<SessionHistory> custom({
    Expression<String>? connectionId,
    Expression<String>? summary,
    Expression<String>? turnsJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (connectionId != null) 'connection_id': connectionId,
      if (summary != null) 'summary': summary,
      if (turnsJson != null) 'turns_json': turnsJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionHistoriesCompanion copyWith(
      {Value<String>? connectionId,
      Value<String?>? summary,
      Value<String>? turnsJson,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return SessionHistoriesCompanion(
      connectionId: connectionId ?? this.connectionId,
      summary: summary ?? this.summary,
      turnsJson: turnsJson ?? this.turnsJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (connectionId.present) {
      map['connection_id'] = Variable<String>(connectionId.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (turnsJson.present) {
      map['turns_json'] = Variable<String>(turnsJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionHistoriesCompanion(')
          ..write('connectionId: $connectionId, ')
          ..write('summary: $summary, ')
          ..write('turnsJson: $turnsJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ConnectionProfilesTable connectionProfiles =
      $ConnectionProfilesTable(this);
  late final $SessionHistoriesTable sessionHistories =
      $SessionHistoriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [connectionProfiles, sessionHistories];
}

typedef $$ConnectionProfilesTableCreateCompanionBuilder
    = ConnectionProfilesCompanion Function({
  required String id,
  required String name,
  required String host,
  required int port,
  required String databaseName,
  required String username,
  Value<bool> useSsl,
  Value<DateTime?> lastUsedAt,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$ConnectionProfilesTableUpdateCompanionBuilder
    = ConnectionProfilesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> host,
  Value<int> port,
  Value<String> databaseName,
  Value<String> username,
  Value<bool> useSsl,
  Value<DateTime?> lastUsedAt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$ConnectionProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ConnectionProfilesTable> {
  $$ConnectionProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get host => $composableBuilder(
      column: $table.host, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get port => $composableBuilder(
      column: $table.port, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get databaseName => $composableBuilder(
      column: $table.databaseName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get useSsl => $composableBuilder(
      column: $table.useSsl, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$ConnectionProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ConnectionProfilesTable> {
  $$ConnectionProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get host => $composableBuilder(
      column: $table.host, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get port => $composableBuilder(
      column: $table.port, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get databaseName => $composableBuilder(
      column: $table.databaseName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get useSsl => $composableBuilder(
      column: $table.useSsl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ConnectionProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConnectionProfilesTable> {
  $$ConnectionProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get host =>
      $composableBuilder(column: $table.host, builder: (column) => column);

  GeneratedColumn<int> get port =>
      $composableBuilder(column: $table.port, builder: (column) => column);

  GeneratedColumn<String> get databaseName => $composableBuilder(
      column: $table.databaseName, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<bool> get useSsl =>
      $composableBuilder(column: $table.useSsl, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ConnectionProfilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ConnectionProfilesTable,
    ConnectionProfileRow,
    $$ConnectionProfilesTableFilterComposer,
    $$ConnectionProfilesTableOrderingComposer,
    $$ConnectionProfilesTableAnnotationComposer,
    $$ConnectionProfilesTableCreateCompanionBuilder,
    $$ConnectionProfilesTableUpdateCompanionBuilder,
    (
      ConnectionProfileRow,
      BaseReferences<_$AppDatabase, $ConnectionProfilesTable,
          ConnectionProfileRow>
    ),
    ConnectionProfileRow,
    PrefetchHooks Function()> {
  $$ConnectionProfilesTableTableManager(
      _$AppDatabase db, $ConnectionProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConnectionProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConnectionProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConnectionProfilesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> host = const Value.absent(),
            Value<int> port = const Value.absent(),
            Value<String> databaseName = const Value.absent(),
            Value<String> username = const Value.absent(),
            Value<bool> useSsl = const Value.absent(),
            Value<DateTime?> lastUsedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConnectionProfilesCompanion(
            id: id,
            name: name,
            host: host,
            port: port,
            databaseName: databaseName,
            username: username,
            useSsl: useSsl,
            lastUsedAt: lastUsedAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String host,
            required int port,
            required String databaseName,
            required String username,
            Value<bool> useSsl = const Value.absent(),
            Value<DateTime?> lastUsedAt = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ConnectionProfilesCompanion.insert(
            id: id,
            name: name,
            host: host,
            port: port,
            databaseName: databaseName,
            username: username,
            useSsl: useSsl,
            lastUsedAt: lastUsedAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ConnectionProfilesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ConnectionProfilesTable,
    ConnectionProfileRow,
    $$ConnectionProfilesTableFilterComposer,
    $$ConnectionProfilesTableOrderingComposer,
    $$ConnectionProfilesTableAnnotationComposer,
    $$ConnectionProfilesTableCreateCompanionBuilder,
    $$ConnectionProfilesTableUpdateCompanionBuilder,
    (
      ConnectionProfileRow,
      BaseReferences<_$AppDatabase, $ConnectionProfilesTable,
          ConnectionProfileRow>
    ),
    ConnectionProfileRow,
    PrefetchHooks Function()>;
typedef $$SessionHistoriesTableCreateCompanionBuilder
    = SessionHistoriesCompanion Function({
  required String connectionId,
  Value<String?> summary,
  required String turnsJson,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$SessionHistoriesTableUpdateCompanionBuilder
    = SessionHistoriesCompanion Function({
  Value<String> connectionId,
  Value<String?> summary,
  Value<String> turnsJson,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$SessionHistoriesTableFilterComposer
    extends Composer<_$AppDatabase, $SessionHistoriesTable> {
  $$SessionHistoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get connectionId => $composableBuilder(
      column: $table.connectionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get turnsJson => $composableBuilder(
      column: $table.turnsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SessionHistoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionHistoriesTable> {
  $$SessionHistoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get connectionId => $composableBuilder(
      column: $table.connectionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get turnsJson => $composableBuilder(
      column: $table.turnsJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SessionHistoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionHistoriesTable> {
  $$SessionHistoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get connectionId => $composableBuilder(
      column: $table.connectionId, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get turnsJson =>
      $composableBuilder(column: $table.turnsJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SessionHistoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SessionHistoriesTable,
    SessionHistory,
    $$SessionHistoriesTableFilterComposer,
    $$SessionHistoriesTableOrderingComposer,
    $$SessionHistoriesTableAnnotationComposer,
    $$SessionHistoriesTableCreateCompanionBuilder,
    $$SessionHistoriesTableUpdateCompanionBuilder,
    (
      SessionHistory,
      BaseReferences<_$AppDatabase, $SessionHistoriesTable, SessionHistory>
    ),
    SessionHistory,
    PrefetchHooks Function()> {
  $$SessionHistoriesTableTableManager(
      _$AppDatabase db, $SessionHistoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionHistoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionHistoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionHistoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> connectionId = const Value.absent(),
            Value<String?> summary = const Value.absent(),
            Value<String> turnsJson = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SessionHistoriesCompanion(
            connectionId: connectionId,
            summary: summary,
            turnsJson: turnsJson,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String connectionId,
            Value<String?> summary = const Value.absent(),
            required String turnsJson,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SessionHistoriesCompanion.insert(
            connectionId: connectionId,
            summary: summary,
            turnsJson: turnsJson,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SessionHistoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SessionHistoriesTable,
    SessionHistory,
    $$SessionHistoriesTableFilterComposer,
    $$SessionHistoriesTableOrderingComposer,
    $$SessionHistoriesTableAnnotationComposer,
    $$SessionHistoriesTableCreateCompanionBuilder,
    $$SessionHistoriesTableUpdateCompanionBuilder,
    (
      SessionHistory,
      BaseReferences<_$AppDatabase, $SessionHistoriesTable, SessionHistory>
    ),
    SessionHistory,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ConnectionProfilesTableTableManager get connectionProfiles =>
      $$ConnectionProfilesTableTableManager(_db, _db.connectionProfiles);
  $$SessionHistoriesTableTableManager get sessionHistories =>
      $$SessionHistoriesTableTableManager(_db, _db.sessionHistories);
}
