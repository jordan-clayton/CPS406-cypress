import 'package:supabase_flutter/supabase_flutter.dart';

import '../interface/login_service.dart';

class SupabaseLoginService implements LoginService {
  bool _initialized;
  late SupabaseClient _cursor;
  String? _url;
  String? _anonKey;

  SupabaseLoginService(
      {required String url, required String anonKey, bool initialized = false})
      : _url = url,
        _anonKey = anonKey,
        _initialized = false;

  // It is possible to construct another supabase client manually via constructor.
  // It is also the case that successful client construction implies initialization.
  // I would recommend for sanity's sake that we supply the same instance client
  // to a (login, database) pair when we're using Supabase.
  SupabaseLoginService.withClient({required SupabaseClient client})
      : _cursor = client,
        _initialized = true;

  @override
  String? get userID {
    if (!_initialized) {
      throw Exception("Supabase client not initialized");
    }
    return _cursor.auth.currentUser?.id;
  }

  @override
  bool get hasSession {
    if (!_initialized) {
      throw Exception("Supabase client not initialized");
    }
    return null != _cursor.auth.currentSession;
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

  @override
  Future<bool> logIn({required String email, required String password}) async {
    final response =
        await _cursor.auth.signInWithPassword(password: password, email: email);
    return null != response.session;
  }

  // On a valid sign up, if we set ``confirm email address'' then only the user
  // information is returned.
  @override
  Future<String?> signUp(
      {required String email, required String password}) async {
    final response =
        await _cursor.auth.signUp(password: password, email: email);
    return response.user?.id;
  }

  @override
  Future<void> signOut() async {
    return await _cursor.auth.signOut();
  }
}
