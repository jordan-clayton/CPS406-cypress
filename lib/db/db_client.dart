import 'package:supabase/supabase.dart';

// TODO: implement a supabase delegate cls
abstract interface class DatabaseClient {
  Future<void> initialize();
  PostgrestQueryBuilder from({required String table});
}
