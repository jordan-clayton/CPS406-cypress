import 'package:supabase_flutter/supabase_flutter.dart';

import 'db_client.dart';

class SupabaseImpl implements DatabaseClient {
  bool _initialized = false;
  late SupabaseClient _cursor;
  String? _url;
  String? _anonKey;

  SupabaseImpl({required String url, required String anonKey})
      : _url = url,
        _anonKey = anonKey;

  // It is possible to construct another supabase client manually via constructor
  SupabaseImpl.fromInstance({required SupabaseClient client})
      : _cursor = client,
        _initialized = true;

  @override
  PostgrestQueryBuilder from({required String table}) {
    // TODO: proper exceptions
    if (!_initialized) {
      throw Exception("DB client not initialized");
    }
    return _cursor.from(table);
  }

  @override
  Future<void> initialize() async {
    await Supabase.initialize(url: _url!, anonKey: _anonKey!);
    _cursor = Supabase.instance.client;
    _initialized = true;
  }
}
