import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgrestQueryBuilder;

abstract interface class DatabaseClient {
  Future<void> initialize();
  bool get initialized;
}

abstract interface class PostgrestDatabaseClient implements DatabaseClient {
  PostgrestQueryBuilder from({required String table});
}
