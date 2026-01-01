class UserModel {
  final int id;
  final String email;
  final String? fullName;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: json['fullName'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
