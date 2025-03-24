abstract interface class LoginService {
  String? get userID;
  bool get hasSession;

  // This should return the newly created user ID if there is one
  Future<String?> signUp({required String email, required String password});

  Future<bool> logIn({required String email, required String password});
  Future<void> initialize();
}
