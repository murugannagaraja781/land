class UserProfile {
  final String name;
  final String phone;
  final String email;
  final String city;
  final String avatarKey;
  final bool isVerified;
  final String memberSince;
  final double completionPercentage;

  const UserProfile({
    required this.name,
    required this.phone,
    required this.email,
    required this.city,
    this.avatarKey = 'avatar_user',
    this.isVerified = true,
    this.memberSince = 'March 2024',
    this.completionPercentage = 0.85,
  });

  UserProfile copyWith({
    String? name,
    String? phone,
    String? email,
    String? city,
    String? avatarKey,
    bool? isVerified,
    String? memberSince,
    double? completionPercentage,
  }) {
    return UserProfile(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      city: city ?? this.city,
      avatarKey: avatarKey ?? this.avatarKey,
      isVerified: isVerified ?? this.isVerified,
      memberSince: memberSince ?? this.memberSince,
      completionPercentage: completionPercentage ?? this.completionPercentage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'city': city,
      'avatarKey': avatarKey,
      'isVerified': isVerified,
      'memberSince': memberSince,
      'completionPercentage': completionPercentage,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] ?? 'Murugan Nagarajan',
      phone: map['phone'] ?? '+91 98401 98765',
      email: map['email'] ?? 'murugan.properties@gmail.com',
      city: map['city'] ?? 'Porur, Chennai',
      avatarKey: map['avatarKey'] ?? 'avatar_user',
      isVerified: map['isVerified'] ?? true,
      memberSince: map['memberSince'] ?? 'March 2024',
      completionPercentage: (map['completionPercentage'] as num?)?.toDouble() ?? 0.85,
    );
  }
}
