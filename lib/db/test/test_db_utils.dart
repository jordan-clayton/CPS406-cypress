import 'package:cypress/models/flagged.dart';
import 'package:uuid/uuid.dart';

import '../../models/duplicates.dart';
import '../../models/employee.dart';
import '../../models/report.dart';
import '../../models/subscription.dart';
import '../../models/user.dart';

// Collection of seed functions to make testing easier
// If seeding a mock database with multiple data, pass the previous database reference in.
// The reference will be returned when the function completes.

Map<String, List<Map<String, dynamic>>> seedEmptyDatabase() {
  return {
    'profiles': List.empty(growable: true),
    'employees': List.empty(growable: true),
    'reports': List.empty(growable: true),
    'subscriptions': List.empty(growable: true),
    'duplicates': List.empty(growable: true),
    'flagged': List.empty(growable: true),
  };
}

Map<String, List<Map<String, dynamic>>> seedDatabaseWithProfiles(
    {List<User>? userProfiles,
    Map<String, List<Map<String, dynamic>>>? startingDatabase}) {
  const uuid = Uuid();
  final db = startingDatabase ?? seedEmptyDatabase();
  final userEntities = userProfiles?.map((u) {
        final entity = u.toEntity();
        entity['id'] = uuid.v4();
        return entity;
      }) ??
      [];
  db['profiles']!.addAll(userEntities);
  return db;
}

Map<String, List<Map<String, dynamic>>> seedDatabaseWithEmployees(
    {List<Employee>? employeeProfiles,
    Map<String, List<Map<String, dynamic>>>? startingDatabase}) {
  final db = startingDatabase ?? seedEmptyDatabase();
  final userEntities = employeeProfiles?.map((e) => e.toEntity()) ?? [];
  db['employees']!.addAll(userEntities);
  return db;
}

Map<String, List<Map<String, dynamic>>> seedDatabaseWithReports(
    {List<Report>? reports,
    Map<String, List<Map<String, dynamic>>>? startingDatabase}) {
  int acc = 0;
  final db = startingDatabase ?? seedEmptyDatabase();
  final reportEntities = reports?.map((r) {
        final entity = r.toEntity();
        entity['id'] = acc++;
        return entity;
      }).toList() ??
      [];
  db['reports']!.addAll(reportEntities);
  return db;
}

Map<String, List<Map<String, dynamic>>> seedDatabaseWithSubscriptions(
    {List<Subscription>? subscriptions,
    Map<String, List<Map<String, dynamic>>>? startingDatabase}) {
  final db = startingDatabase ?? seedEmptyDatabase();
  final userEntities = subscriptions?.map((e) => e.toEntity()) ?? [];
  db['subscriptions']!.addAll(userEntities);
  return db;
}

Map<String, List<Map<String, dynamic>>> seedDatabaseWithDuplicates(
    {List<DuplicateReport>? duplicateReports,
    Map<String, List<Map<String, dynamic>>>? startingDatabase}) {
  final db = startingDatabase ?? seedEmptyDatabase();
  final userEntities = duplicateReports?.map((d) => d.toEntity()) ?? [];
  db['duplicates']!.addAll(userEntities);
  return db;
}

Map<String, List<Map<String, dynamic>>> seedDatabaseWithFlagged(
    {List<Flagged>? flaggedReports,
    Map<String, List<Map<String, dynamic>>>? startingDatabase}) {
  final db = startingDatabase ?? seedEmptyDatabase();
  final userEntities = flaggedReports?.map((d) => d.toEntity()) ?? [];
  db['flagged']!.addAll(userEntities);
  return db;
}
