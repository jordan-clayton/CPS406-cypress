import 'package:supabase_flutter/supabase_flutter.dart';

import '../interface/db_client.dart';
import '../interface/query.dart';

class PostgrestDatabaseQuery implements DatabaseQuery {
  final PostgrestQueryBuilder _queryBuilder;
  late PostgrestFilterBuilder _filterBuilder;

  // For limits/ranges/etc -- call these last, according to SQL conventions.
  PostgrestTransformBuilder? _transformBuilder;
  bool _ready = false;
  bool _modifyQuery = false;

  PostgrestDatabaseQuery(
      {required PostgrestDatabaseClient cursor, required String table})
      : _queryBuilder = cursor.from(table: table);

  // READING
  @override
  PostgrestDatabaseQuery select({List<String>? columns}) {
    _applySelect();
    _ready = true;
    return this;
  }

  @override
  PostgrestDatabaseQuery filter({required DatabaseFilter filter}) {
    _checkReady();
    _filterBuilder =
        _filterBuilder.filter(filter.column, filter.operator, filter.value);
    return this;
  }

  @override
  PostgrestDatabaseQuery limit({required int count}) {
    _checkReady();
    _checkModifyQuery();
    _transformBuilder = (_transformBuilder ?? _filterBuilder).limit(count);
    return this;
  }

  @override
  PostgrestDatabaseQuery range({required DatabaseRange range}) {
    _checkReady();
    _checkModifyQuery();
    _transformBuilder =
        (_transformBuilder ?? _filterBuilder).range(range.from, range.to);
    return this;
  }

  @override
  PostgrestDatabaseQuery maybeSingle() {
    _checkReady();
    _checkModifyQuery();
    _transformBuilder = (_transformBuilder ?? _filterBuilder).maybeSingle();
    return this;
  }

  /// referencedTable needs to be set if the sorting criteria is a foreign key
  /// referencedTable = original table
  // NOTE: when ordering by the output of a server function (eg. distance),
  // compute the value as a named table column in the select query & refer to
  // it in the ordering
  @override
  PostgrestDatabaseQuery order({required DatabaseOrdering ordering}) {
    _checkReady();
    _checkModifyQuery();
    _transformBuilder = (_transformBuilder ?? _filterBuilder).order(
        ordering.column,
        ascending: ordering.ascending,
        nullsFirst: ordering.nullsFirst,
        referencedTable: ordering.referencedTable);
    return this;
  }

  // Modifications
  @override
  PostgrestDatabaseQuery insert(
      {required List<Map<String, dynamic>> entities}) {
    _filterBuilder = _queryBuilder.insert(entities);
    _ready = true;
    _modifyQuery = true;
    return this;
  }

  @override
  PostgrestDatabaseQuery update(
      {required List<Map<String, dynamic>> entities}) {
    _filterBuilder = _queryBuilder.upsert(entities);
    _ready = true;
    _modifyQuery = true;
    return this;
  }

  // This should be called with a filter.
  // NOTE: if we want to retrieve the deleted records, we can; I'm not sure
  // if that's particularly helpful.
  @override
  PostgrestDatabaseQuery delete() {
    _filterBuilder = _queryBuilder.delete();
    _ready = true;
    _modifyQuery = true;
    return this;
  }

  // This is for retrieving data from the database following a modify query
  @override
  PostgrestDatabaseQuery retrieveOnModify({List<String>? columns}) {
    if (!_modifyQuery) {
      throw Exception("Cannot apply to a read query");
    }
    final c = columns ?? [];
    _transformBuilder = _filterBuilder.select(c.join(', '));
    return this;
  }

  @override
  Future<List<Map<String, dynamic>>> execute() async {
    _checkReady();
    final response = await (_transformBuilder ?? _filterBuilder);
    if (null == response) {
      return [];
    }
    return [...response];
  }

  // TODO: decide whether or not to silently apply or throw an exception.
  void _applySelect({List<String>? columns}) {
    final c = columns ?? [];
    _filterBuilder = _queryBuilder.select(c.join(', '));
  }

  void _checkReady() {
    if (!_ready) {
      // TODO: exceptions
      throw Exception("Select/Create/Update/Delete has not been called");
    }
  }

  void _checkModifyQuery() {
    if (_modifyQuery) {
      // TODO: exceptions
      throw Exception("Cannot apply to a modify query");
    }
  }
}
