import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgrestQueryBuilder;

abstract interface class DatabaseClient {
  Future<void> initialize();
}

abstract interface class PostgrestDatabaseClient implements DatabaseClient {
  String? get userID;
  bool get hasSession;
  PostgrestQueryBuilder from({required String table});
}
