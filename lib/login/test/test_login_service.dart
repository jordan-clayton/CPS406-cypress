import 'package:uuid/uuid.dart';

import '../interface/login_service.dart';

class MockLoginService implements LoginService {
  String? _fakeEmail;
  String? _fakePassword;
  late bool _loggedIn;

  String? _fakeUserID;
  final Map<String, String> _validUserIDs;

  MockLoginService()
      : _loggedIn = false,
        _validUserIDs = {};

  MockLoginService.withMockedCredentials(
      {required fakeClientEmail,
      required fakeClientPassword,
      required fakeUserID})
      : _fakeEmail = fakeClientEmail,
        _fakePassword = fakeClientPassword,
        _loggedIn = false,
        _fakeUserID = fakeUserID,
        _validUserIDs = {fakeClientEmail: fakeUserID};

  String? _generateUserID() {
    const uuid = Uuid();
    return uuid.v4();
  }

  @override
  bool get hasSession => _loggedIn;

  // Just a nop
  @override
  Future<void> initialize() async {}

  @override
  Future<bool> logIn({required String email, required String password}) async {
    if (_loggedIn) {
      throw Exception('Already logged in, this should not be called.');
    }
    if (email != _fakeEmail) {
      return false;
    }

    if (password != _fakePassword) {
      return false;
    }

    _loggedIn = true;
    _fakeUserID = _validUserIDs[_fakeEmail];
    if (null == _fakeUserID) {
      throw Exception('Mocked userID doesn\'t exist for $_fakeEmail');
    }
    return true;
  }

  @override
  Future<void> signOut() async {
    _loggedIn = false;
  }

  @override
  Future<String?> signUp(
      {required String email, required String password}) async {
    _fakeEmail = email;
    _fakePassword = password;
    _fakeUserID = _generateUserID();

    // Simulate making an entry in the authenticated users database.
    _validUserIDs[_fakeEmail!] = _fakeUserID!;

    return _fakeUserID;
  }

  @override
  String? get userID => _fakeUserID;
}
