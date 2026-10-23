// KANAWA - Modelo User (App Motorista)

class User {
  final String id;
  final String phone;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? profilePhoto;
  final int userType;
  final String userTypeDisplay;
  final bool isVerified;

  User({
    required this.id,
    required this.phone,
    this.email,
    this.firstName,
    this.lastName,
    this.profilePhoto,
    required this.userType,
    required this.userTypeDisplay,
    required this.isVerified,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      profilePhoto: json['profile_photo'],
      userType: json['user_type'] ?? 0,
      userTypeDisplay: json['user_type_display'] ?? '',
      isVerified: json['is_verified'] ?? false,
    );
  }

  String get fullName {
    final f = firstName ?? '';
    final l = lastName ?? '';
    final full = '$f $l'.trim();
    return full.isNotEmpty ? full : phone;
  }

  bool get isDriver => userType == 10;
  bool get isPassenger => userType == 20;
}