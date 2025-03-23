import 'package:equatable/equatable.dart';

// Equatable requires final fields (hashcode + equality);
// The hashcode should stay stable over time if we happen to use this object in the app
class User extends Equatable implements Comparable<User> {
  // This will be a uuid and thus be reasonably unique enough to be used for equality.
  final String userID;

  // TODO: mark as final if at all appropriate => client side signup is not yet implemented.
  String username;
  String? fcmToken;
  String? email;
  String? phone;

  User(
      {required this.userID,
      this.username = 'cypress user',
      this.fcmToken,
      this.email,
      this.phone});

  User.fromEntity(Map<String, dynamic> entity)
      : userID = entity['id'],
        username = entity['username'],
        fcmToken = entity['fcm_token'],
        email = entity['email'],
        phone = entity['phone'];

  Map<String, dynamic> toEntity() => {
        'username': username,
        'fcmToken': fcmToken ?? '',
        'email': email ?? '',
        'phone': phone ?? '',
      };

  // Equatable requires final fields (hashcode + equality);
  // The hashcode should stay stable over time if we happen to use this object in the app
  @override
  List<Object> get props => [userID];

  @override
  int compareTo(User other) => userID.compareTo(other.userID);
}
