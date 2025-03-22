import 'query.dart';

// TODO: finish Interface
abstract interface class DatabaseService {
  void createEntry({required Map<String, dynamic> entry});

  // TODO: order object, copy args to getEntries
  Map<String, dynamic> getEntry(
      {required String table,
      List<DatabaseFilter>? filters,
      List<String>? order,
      int? limit,
      int? range});

  List<Map<String, dynamic>> getEntries({required DatabaseQuery query});

  void updateEntry({required Map<String, dynamic> entry});

  void deleteEntry({required Map<String, dynamic> entry});
}
