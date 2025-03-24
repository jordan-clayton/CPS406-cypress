import 'package:supabase_flutter/supabase_flutter.dart';

import 'db_client.dart';

class SupabaseImpl implements PostgrestDatabaseClient {
  bool _initialized;
  late SupabaseClient _cursor;
  String? _url;
  String? _anonKey;

  SupabaseImpl(
      {required String url, required String anonKey, bool initialized = false})
      : _url = url,
        _anonKey = anonKey,
        _initialized = false;

  // It is possible to construct another supabase client manually via constructor
  // It is also the case that successful client construction implies initialization
  SupabaseImpl.withClient({required SupabaseClient client})
      : _cursor = client,
        _initialized = true;

  // We can also swap at runtime.
  // It would be in our interest to make sure the authentication and database
  // are the same client.
  void cursor(newCursor) => {_cursor = newCursor};

  @override
  PostgrestQueryBuilder from({required String table}) {
    // TODO: proper exceptions
    if (!_initialized) {
      throw Exception("Supabase client not initialized");
    }
    return _cursor.from(table);
  }

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    await Supabase.initialize(url: _url!, anonKey: _anonKey!);
    _cursor = Supabase.instance.client;
    _initialized = true;
  }
}
