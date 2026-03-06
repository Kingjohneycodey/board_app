class User {
  final int id;
  final String email;
  final String? name;
  final String? phone;
  final String? photo;
  final DateTime? dateOfBirth;
  final String? language;
  final dynamic addresses; // JSON array of addresses
  final double walletBalance;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.photo,
    this.dateOfBirth,
    this.language,
    this.addresses,
    required this.walletBalance,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      photo: json['photo'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'] as String)
          : null,
      language: json['language'] as String?,
      addresses: json['addresses'],
      walletBalance: double.parse(json['walletBalance']?.toString() ?? '0'),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'photo': photo,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'language': language,
      'addresses': addresses,
      'walletBalance': walletBalance,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
