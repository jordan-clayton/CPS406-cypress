import 'package:equatable/equatable.dart';

// Equatable requires final fields (hashcode + equality);
// The hashcode should stay stable over time if we happen to use this object in the app
class User extends Equatable implements Comparable<User> {
  // This will be a uuid and thus be reasonably unique enough to be used for equality.
  final String id;

  // TODO: mark as final if at all appropriate => client side signup is not yet implemented.
  String username;
  String? fcmToken;
  String? email;
  String? phone;

  User(
      {required this.id,
      this.username = 'cypress user',
      this.fcmToken,
      this.email,
      this.phone});

  factory User.fromEntity(Map<String, dynamic> entity) => User(
      id: entity['id'],
      username: entity['username'],
      fcmToken: entity['fcm_token'],
      email: entity['email'],
      phone: entity['phone']);

  Map<String, dynamic> toEntity() => {
        'id': id,
        'username': username,
        'fcm_token': fcmToken ?? '',
        'email': email ?? '',
        'phone': phone ?? '',
      };

  User copyWith(
          {String? id,
          String? username,
          String? fcmToken,
          String? email,
          String? phone}) =>
      User(
        id: id ?? this.id,
        username: username ?? this.username,
        fcmToken: fcmToken ?? this.fcmToken,
        email: email ?? this.email,
        phone: phone ?? this.phone,
      );

  UserView toView() => UserView(this);

  // Equatable requires final fields (hashcode + equality);
  // The hashcode should stay stable over time if we happen to use this object in the app
  @override
  List<Object> get props => [id];

  @override
  int compareTo(User other) => id.compareTo(other.id);
}

// Immutable wrapper class for constant references
class UserView {
  final User _user;

  UserView(this._user);
  String get username => _user.username;
  String? get fcmToken => _user.fcmToken;
  String? get email => _user.email;
  String? get phone => _user.phone;
}
