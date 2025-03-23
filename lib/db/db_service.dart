import 'query.dart';

abstract interface class DatabaseService {
  String? get clientID;
  bool get validSession;
  bool get initialized;

  Future<void> initialize();
  Future<Map<String, dynamic>> createEntry(
      {required String table,
      required Map<String, dynamic> entry,
      bool retrieveNewRecord,
      // For specific columns instead of whole record
      List<String>? retrieveColumns});

  Future<List<Map<String, dynamic>>> createEntries(
      {required String table,
      required List<Map<String, dynamic>> entries,
      bool retrieveNewRecords,
      // For specific columns instead of whole record
      List<String>? retrieveColumns});

  Future<Map<String, dynamic>> getEntry(
      {required String table,
      List<String>? columns,
      List<DatabaseFilter>? filters,
      List<DatabaseOrdering>? order,
      int? limit,
      DatabaseRange? range});

  Future<List<Map<String, dynamic>>> getEntries(
      {required String table,
      List<String>? columns,
      List<DatabaseFilter>? filters,
      List<DatabaseOrdering>? order,
      int? limit,
      DatabaseRange? range});

  Future<Map<String, dynamic>> updateEntry(
      {required String table,
      required Map<String, dynamic> entry,
      List<DatabaseFilter>? filters,
      bool retrieveUpdatedRecord,
      // For specific columns instead of whole record
      List<String>? retrieveColumns});

  Future<List<Map<String, dynamic>>> updateEntries(
      {required String table,
      required List<Map<String, dynamic>> entries,
      List<DatabaseFilter>? filters,
      bool retrieveUpdatedRecords,
      List<String>? retrieveColumns});

  Future<void> deleteEntries(
      {required String table, List<DatabaseFilter>? deleteFilters});
}
