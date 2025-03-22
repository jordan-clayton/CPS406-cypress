// TODO: define equality; implement comparable
class User {
  String userID;
  String username;
  String? fcmToken;
  String? email;
  String? phone;
  User(
      {required this.userID,
      required this.username,
      this.fcmToken,
      this.email,
      this.phone});
  User.fromEntity(Map<String, dynamic> entity)
      : userID = entity['user_id'],
        username = entity['username'],
        fcmToken = entity['fcm_token'],
        email = entity['email'],
        phone = entity['phone'];
}
