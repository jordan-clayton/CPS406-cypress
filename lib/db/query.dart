import 'package:supabase_flutter/supabase_flutter.dart';

import 'db_client.dart';

/// See the following for postgrest filters (abbreviation, not symbolic)
/// https://docs.postgrest.org/en/v12/references/api/tables_views.html#operators
/// Filters can be applied on read/modify queries
/// in requires value to be a list
class DatabaseFilter {
  String column;
  String operator;
  dynamic value;

  DatabaseFilter({required this.column, required this.operator, this.value});
}

// TODO: counting/aggregation if necessary
class DatabaseQuery {
  final PostgrestQueryBuilder _queryBuilder;
  late PostgrestFilterBuilder _filterBuilder;

  // For limits/ranges/etc -- call these last, according to SQL conventions.
  PostgrestTransformBuilder? _transformBuilder;
  bool _ready = false;
  bool _modifyQuery = false;

  DatabaseQuery({required DatabaseClient cursor, required String table})
      : _queryBuilder = cursor.from(table: table);

  // READING
  DatabaseQuery select({List<String>? columns}) {
    _applySelect();
    _ready = true;
    return this;
  }

  DatabaseQuery filter({required DatabaseFilter filter}) {
    _checkReady();
    _filterBuilder =
        _filterBuilder.filter(filter.column, filter.operator, filter.value);
    return this;
  }

  DatabaseQuery limit({required int count}) {
    _checkReady();
    _checkModifyQuery();
    _transformBuilder = (_transformBuilder ?? _filterBuilder).limit(count);
    return this;
  }

  DatabaseQuery range({required int from, required int to}) {
    _checkReady();
    _checkModifyQuery();
    _transformBuilder = (_transformBuilder ?? _filterBuilder).range(from, to);
    return this;
  }

  DatabaseQuery maybeSingle() {
    _checkReady();
    _checkModifyQuery();
    _transformBuilder = (_transformBuilder ?? _filterBuilder).maybeSingle();
    return this;
  }

  /// referencedTable needs to be set if the sorting criteria is a foreign key
  /// referencedTable = original table
  DatabaseQuery order(
      {required String column,
      bool ascending = false,
      bool nullsFirst = false,
      String? referencedTable}) {
    _checkReady();
    _checkModifyQuery();
    _transformBuilder = (_transformBuilder ?? _filterBuilder).order(column,
        ascending: ascending,
        nullsFirst: nullsFirst,
        referencedTable: referencedTable);
    return this;
  }

  // Modifications
  DatabaseQuery insert({required List<Map<String, dynamic>> entities}) {
    _filterBuilder = _queryBuilder.insert(entities);
    _ready = true;
    _modifyQuery = true;
    return this;
  }

  DatabaseQuery update({required List<Map<String, dynamic>> entities}) {
    _filterBuilder = _queryBuilder.upsert(entities);
    _ready = true;
    _modifyQuery = true;
    return this;
  }

  // This should be called with a filter.
  DatabaseQuery delete({required List<Map<String, dynamic>> entities}) {
    _filterBuilder = _queryBuilder.delete();
    _ready = true;
    _modifyQuery = true;
    return this;
  }

  // This is for retrieving data from the database following a modify query
  DatabaseQuery retrieveOnModify({List<String>? columns}) {
    if (!_modifyQuery) {
      throw Exception("Cannot apply to a read query");
    }
    final c = columns ?? [];
    _transformBuilder = _filterBuilder.select(c.join(', '));
    return this;
  }

  Future<List<Map<String, dynamic>>> execute() async {
    _checkReady();
    return await _transformBuilder ?? _filterBuilder;
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
