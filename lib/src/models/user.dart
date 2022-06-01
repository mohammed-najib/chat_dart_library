class User {
  // String get id => _id;
  // String userName;
  // String photoUrl;
  // String _id;
  // bool active;
  // DateTime lastSeen;
  String? _id;
  String? userName;
  String? photoUrl;
  bool? active;
  DateTime? lastSeen;

  String? get id => _id;

  User({
    // required String userName,
    // required String photoUrl,
    // required bool active,
    // required DateTime lastSeen,
    required this.userName,
    required this.photoUrl,
    required this.active,
    required this.lastSeen,
  });

  toJson() => {
        'user_name': userName,
        'photo_url': photoUrl,
        'active': active,
        'last_seen': lastSeen,
      };

  factory User.fromJson(Map<String, dynamic> json) {
    final user = User(
      userName: json['user_name'],
      photoUrl: json['photo_url'],
      active: json['active'],
      lastSeen: json['last_seen'],
    );
    user._id = json['id'];

    return user;
  }
}
