/// Query Data transfer objects
/// See the following for postgrest filters (abbreviation, not symbolic)
/// https://docs.postgrest.org/en/v12/references/api/tables_views.html#operators
/// Filters can be applied on read/modify queries
/// in requires value to be a list
class DatabaseFilter {
  String column;
  String operator;
  dynamic value;

  DatabaseFilter(
      {required this.column, required this.operator, required this.value});
}

class DatabaseOrdering {
  String column;
  bool ascending;
  bool nullsFirst;

  /// referencedTable needs to be set if the sorting criteria is a foreign key
  /// referencedTable = original table
  String? referencedTable;

  DatabaseOrdering(
      {required this.column,
      this.ascending = false,
      this.nullsFirst = false,
      this.referencedTable});
}

// I miss named tuples and structs :(
class DatabaseRange {
  int to;
  int from;

  DatabaseRange({required this.to, required this.from});
}

// TODO: counting/aggregation if necessary
abstract interface class DatabaseQuery {
  // READING
  DatabaseQuery select({List<String>? columns});

  DatabaseQuery filter({required DatabaseFilter filter});

  DatabaseQuery limit({required int count});

  DatabaseQuery range({required DatabaseRange range});

  DatabaseQuery maybeSingle();

  DatabaseQuery order({required DatabaseOrdering ordering});

  // Modifications
  DatabaseQuery insert({required List<Map<String, dynamic>> entities});

  DatabaseQuery update({required List<Map<String, dynamic>> entities});

  // This should be called with a filter.
  DatabaseQuery delete();

  // This is for retrieving data from the database following a modify query
  DatabaseQuery retrieveOnModify({List<String>? columns});

  Future<List<Map<String, dynamic>>> execute();
}
