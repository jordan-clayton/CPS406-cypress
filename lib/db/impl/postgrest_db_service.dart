import '../interface/db_client.dart';
import '../interface/db_service.dart';
import '../interface/query.dart';
import 'postgrest_query.dart';

// NOTE: these can throw PostgrestExceptions (and other Exceptions) from the DB client/query.
// Catch them higher up.
class PostgrestDatabaseService implements DatabaseService {
  PostgrestDatabaseClient _client;
  bool _initialized = false;

  PostgrestDatabaseService({required PostgrestDatabaseClient client})
      : _client = client,
        _initialized = client.initialized;

  // If we swap out at runtime
  void client(newClient) => {_client = newClient};

  @override
  Future<void> initialize() async {
    await _client.initialize();
    _initialized = true;
  }

  @override
  bool get initialized => _initialized;

  @override
  Future<Map<String, dynamic>> createEntry(
      {required String table,
      required Map<String, dynamic> entry,
      bool retrieveNewRecord = false,
      List<String>? retrieveColumns}) async {
    var query = PostgrestDatabaseQuery(cursor: _client, table: table)
        .insert(entities: [entry]);
    if (retrieveNewRecord) {
      query = query.retrieveOnModify(columns: retrieveColumns);
    }
    return (await query.execute()).firstOrNull ?? {};
  }

  @override
  Future<List<Map<String, dynamic>>> createEntries(
      {required String table,
      required List<Map<String, dynamic>> entries,
      bool retrieveNewRecords = false,
      List<String>? retrieveColumns}) async {
    var query = PostgrestDatabaseQuery(cursor: _client, table: table)
        .insert(entities: entries);
    if (retrieveNewRecords) {
      query = query.retrieveOnModify(columns: retrieveColumns);
    }
    return await query.execute();
  }

  // NOTE: the supabase API will automatically perform joins via foreign keys
  // if we handle it in the select clause (ie. a string in the columns list).
  @override
  Future<Map<String, dynamic>> getEntry(
      {required String table,
      List<String>? columns,
      List<DatabaseFilter>? filters,
      List<DatabaseOrdering>? order,
      int? limit,
      DatabaseRange? range}) async {
    var query = PostgrestDatabaseQuery(cursor: _client, table: table)
        .select(columns: columns);

    for (var f in filters ?? []) {
      query = query.filter(filter: f);
    }

    for (var o in order ?? []) {
      query = query.order(ordering: o);
    }

    if (null != limit) {
      query = query.limit(count: limit);
    }

    if (null != range) {
      query = query.range(range: range);
    }

    query = query.maybeSingle();
    return (await query.execute()).first;
  }

  @override
  Future<List<Map<String, dynamic>>> getEntries(
      {required String table,
      List<String>? columns,
      List<DatabaseFilter>? filters,
      List<DatabaseOrdering>? order,
      int? limit,
      DatabaseRange? range}) async {
    var query = PostgrestDatabaseQuery(cursor: _client, table: table)
        .select(columns: columns);

    for (var f in filters ?? []) {
      query = query.filter(filter: f);
    }

    for (var o in order ?? []) {
      query = query.order(ordering: o);
    }

    if (null != limit) {
      query = query.limit(count: limit);
    }

    if (null != range) {
      query = query.range(range: range);
    }

    return await query.execute();
  }

  @override
  Future<Map<String, dynamic>> updateEntry(
      {required String table,
      required Map<String, dynamic> entry,
      List<DatabaseFilter>? filters,
      bool retrieveUpdatedRecord = false,
      List<String>? retrieveColumns}) async {
    var query = PostgrestDatabaseQuery(cursor: _client, table: table)
        .update(entities: [entry]);

    for (var f in filters ?? []) {
      query = query.filter(filter: f);
    }
    if (retrieveUpdatedRecord) {
      query = query.retrieveOnModify(columns: retrieveColumns);
    }
    return (await query.execute()).firstOrNull ?? {};
  }

  @override
  Future<List<Map<String, dynamic>>> updateEntries(
      {required String table,
      required List<Map<String, dynamic>> entries,
      List<DatabaseFilter>? filters,
      bool retrieveUpdatedRecords = false,
      List<String>? retrieveColumns}) async {
    var query = PostgrestDatabaseQuery(cursor: _client, table: table)
        .update(entities: entries);

    for (var f in filters ?? []) {
      query = query.filter(filter: f);
    }
    if (retrieveUpdatedRecords) {
      query = query.retrieveOnModify(columns: retrieveColumns);
    }
    return await query.execute();
  }

  @override
  Future<void> deleteEntries(
      {required String table, List<DatabaseFilter>? deleteFilters}) async {
    var query = PostgrestDatabaseQuery(cursor: _client, table: table).delete();
    for (var f in deleteFilters ?? []) {
      query = query.filter(filter: f);
    }
    await query.execute();
  }
}
