import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:cypress/db/interface/query.dart';
import 'package:uuid/uuid.dart';

import '../interface/db_service.dart';

// Use this mock class in testing, seed appropriately with the required data to satisfy test conditions.
class MockDatabaseService implements DatabaseService {
  // Simulate a database using a map.
  // The keys are table columns, the values are lists? of HashMap entries.
  // The queries will not be as efficient as a database retrieval, so keep that in mind.
  late final Map<String, List<Map<String, dynamic>>> _mockDatabase;

  // For generating primary keys.
  late final Uuid _uuid;
  late int reportIDAccumulator;

  /// When seeding data, make sure that all lists are growable, otherwise this mock class will fail.
  MockDatabaseService(
      {required Map<String, List<Map<String, dynamic>>> seedData})
      : _mockDatabase = seedData,
        _uuid = const Uuid(),
        reportIDAccumulator = 0;

  void _addIDToEntry(
      {required String table, required Map<String, dynamic> entry}) {
    if ('reports' == table) {
      entry['id'] = reportIDAccumulator++;
    }
    if ('employees' == table || 'profiles' == table) {
      entry['id'] = _uuid.v4();
    }
  }

  Map<String, dynamic> _returnNewRecord(
      {required Map<String, dynamic> entry, List<String>? retrieveColumns}) {
    // If the retrieveColumns are specified, filter data
    final Map<String, dynamic> returned = {};
    // TODO: extract to function.
    if (null != retrieveColumns) {
      for (var col in retrieveColumns) {
        returned[col] = entry[col];
      }
      // Otherwise, duplicate the entry record to simulate returning the inserted record.
    } else {
      returned.addAll(entry);
    }
    return returned;
  }

  List<String> _primaryKey({required String table}) {
    return switch (table) {
      'profiles' => ['id'],
      'employees' => ['id', 'employee_id'],
      'reports' => ['id'],
      'subscriptions' => ['user_id', 'report_id', 'method'],
      'duplicates' => ['report_id', 'match_id'],
      'flagged' => ['report_id', 'reason'],
      _ => throw Exception(
          'Table is not in the database, cannot retrieve primary key'),
    };
  }

  // These will throw on invalid table access.
  // Ensure the seeded data is coherent.
  @override
  Future<Map<String, dynamic>> createEntry(
      {required String table,
      required Map<String, dynamic> entry,
      bool retrieveNewRecord = false,
      List<String>? retrieveColumns}) async {
    final returned = await createEntries(
        table: table,
        entries: [entry],
        retrieveColumns: retrieveColumns,
        retrieveNewRecords: retrieveNewRecord);
    if (!retrieveNewRecord) {
      return {};
    }
    return returned.first;
  }

  // This throws on an invalid table entry.
  @override
  Future<List<Map<String, dynamic>>> createEntries(
      {required String table,
      required List<Map<String, dynamic>> entries,
      bool retrieveNewRecords = false,
      List<String>? retrieveColumns}) async {
    final dbTable = _mockDatabase[table]!;
    // Add the ids to the entries
    for (var entry in entries) {
      _addIDToEntry(table: table, entry: entry);
    }
    dbTable.addAll(entries);
    // If not retrieving fields from the insert, return the empty list.
    if (!retrieveNewRecords) {
      return [];
    }
    // Otherwise, generate a list of entries.
    return List.generate(
        entries.length,
        (i) => _returnNewRecord(
            entry: entries[i], retrieveColumns: retrieveColumns));
  }

  @override
  Future<void> deleteEntries(
      {required String table, List<DatabaseFilter>? deleteFilters}) async {
    final dbTable = _mockDatabase[table]!;
    dbTable.removeWhere((entry) {
      if (null == deleteFilters) {
        return true;
      }
      return deleteFilters.fold(true,
          (acc, dbFilter) => acc && (dbFilter.value == entry[dbFilter.column]));
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getEntries(
      {required String table,
      List<String>? columns,
      List<DatabaseFilter>? filters,
      List<DatabaseOrdering>? order,
      int? limit,
      DatabaseRange? range}) async {
    final dbTable = _mockDatabase[table];
    if (null == dbTable) {
      log('Invalid table: $table');
      log('Tables in mock db: ${_mockDatabase.keys}');
      throw Exception('Invalid table');
    }

    // Filter based on columns.
    var filtered = dbTable.where((entry) {
      if (null == filters) {
        return true;
      }
      return filters.fold(
          true,
          (acc, filter) =>
              acc &&
              // Most tests we need only use equality.
              // If this becomes a problem, create an appropriate function table.
              ((filter.operator == 'eq')
                  ? filter.value == entry[filter.column]
                  : filter.value != entry[filter.column]));
    });

    for (var o in (order ?? [])) {
      filtered = filtered.sorted((p, c) {
        if (p[o.column] < c[o.column]) {
          return -1;
        }
        if (p[o.column] > c[o.column]) {
          return 1;
        }
        return 0;
      });
    }

    if (null != range) {
      return filtered
          .whereIndexed((i, entry) => i >= range.to && i <= range.from)
          .toList();
    }
    if (null != limit) {
      return filtered.take(limit).toList();
    }

    return filtered.toList();
  }

  //  This throws when a query fails to find the record in the db.
  @override
  Future<Map<String, dynamic>> getEntry(
      {required String table,
      List<String>? columns,
      List<DatabaseFilter>? filters,
      List<DatabaseOrdering>? order,
      int? limit,
      DatabaseRange? range}) async {
    final entries = await getEntries(
        table: table,
        columns: columns,
        filters: filters,
        order: order,
        limit: limit,
        range: range);

    return entries.first;
  }

  // The mock db is always initialized.
  @override
  Future<void> initialize() async {
    return;
  }

  @override
  bool get initialized => true;

  @override
  Future<List<Map<String, dynamic>>> updateEntries(
      {required String table,
      required List<Map<String, dynamic>> entries,
      List<DatabaseFilter>? filters,
      bool retrieveUpdatedRecords = false,
      List<String>? retrieveColumns}) async {
    final dbTable = _mockDatabase[table]!;

    // Filter closure
    filterFunction(existingEntry, newEntry) {
      if (null == filters || filters.isEmpty) {
        // filter by primary key
        final primaryKey = _primaryKey(table: table);
        return primaryKey.fold(
            true, (acc, key) => newEntry[key] == existingEntry[key]);
      }
      return filters.fold(true,
          (acc, filter) => acc && filter.value == existingEntry[filter.column]);
    }

    final List<Map<String, dynamic>> modifiedEntries =
        List.empty(growable: true);
    // For each update-able entry, 'update it'
    for (var entry in entries) {
      for (var existingEntry in dbTable) {
        if (!filterFunction(existingEntry, entry)) {
          continue;
        }
        // Matches the filter, so update accordingly.

        // This will overwrite the data.
        existingEntry.addAll(entry);
        // Copy it to the modified entries record.
        modifiedEntries.add(existingEntry);
      }
    }

    if (!retrieveUpdatedRecords) {
      return [];
    }

    // If there are no columns, return the modifiedEntries.
    if (null == retrieveColumns) {
      return modifiedEntries.toList();
    }

    // Otherwise filter out the unwanted data accordingly.
    return modifiedEntries.map((e) {
      final Map<String, dynamic> filtered = {};
      for (var column in retrieveColumns) {
        filtered[column] = e[column];
      }
      return filtered;
    }).toList();
  }

  @override
  Future<Map<String, dynamic>> updateEntry(
      {required String table,
      required Map<String, dynamic> entry,
      List<DatabaseFilter>? filters,
      bool retrieveUpdatedRecord = false,
      List<String>? retrieveColumns}) async {
    final updatedRecords = await updateEntries(
        table: table,
        entries: [entry],
        filters: filters,
        retrieveUpdatedRecords: retrieveUpdatedRecord,
        retrieveColumns: retrieveColumns);

    if (!retrieveUpdatedRecord) {
      return {};
    }
    return updatedRecords.first;
  }
}
