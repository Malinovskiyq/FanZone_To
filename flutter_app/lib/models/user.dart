import '../config/app_config.dart';

enum UserRole {
  user,
  bookingManager,
  admin;

  static UserRole fromString(String? role) {
    switch (role?.toUpperCase()) {
      case 'ADMIN':
        return UserRole.admin;
      case 'BOOKING_MANAGER':
        return UserRole.bookingManager;
      default:
        return UserRole.user;
    }
  }

  String toServerString() {
    switch (this) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.bookingManager:
        return 'BOOKING_MANAGER';
      case UserRole.user:
        return 'USER';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.user:
        return 'Болельщик';
      case UserRole.bookingManager:
        return 'Ответственный';
      case UserRole.admin:
        return 'Администратор';
    }
  }
}

class UserProfile {
  final String? id;
  final String? userId;
  final String firstName;
  final String lastName;
  final String? city;
  final String? avatarUrl;
  final String? bio;

  UserProfile({
    this.id,
    this.userId,
    required this.firstName,
    required this.lastName,
    this.city,
    this.avatarUrl,
    this.bio,
  });

  String get fullName => '$firstName $lastName';
  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      userId: json['userId'] ?? json['user_id'],
      firstName: json['firstName'] ?? json['first_name'] ?? '',
      lastName: json['lastName'] ?? json['last_name'] ?? '',
      city: json['city'],
      avatarUrl: json['avatarUrl'] ?? json['avatar_url'],
      bio: json['bio'],
    );
  }

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'city': city,
        'bio': bio,
      };
}

class SocialLink {
  final String id;
  final String platform;
  final String url;
  final String? label;

  SocialLink({
    required this.id,
    required this.platform,
    required this.url,
    this.label,
  });

  factory SocialLink.fromJson(Map<String, dynamic> json) {
    return SocialLink(
      id: json['id'] ?? '',
      platform: json['platform'] ?? 'OTHER',
      url: json['url'] ?? '',
      label: json['label'],
    );
  }
}

class User {
  final String id;
  final String? email;
  final String? phone;
  final String username;
  final UserRole role;
  final bool isActive;
  final String? fcmToken;
  final DateTime? createdAt;
  final UserProfile? profile;
  final List<SocialLink>? socialLinks;

  User({
    required this.id,
    this.email,
    this.phone,
    required this.username,
    required this.role,
    this.isActive = true,
    this.fcmToken,
    this.createdAt,
    this.profile,
    this.socialLinks,
  });

  String get displayName => profile?.fullName ?? '@$username';

  String? get avatarFullUrl {
    final path = profile?.avatarUrl;
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '${AppConfig.uploadsBaseUrl}/$path';
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'],
      phone: json['phone'],
      username: json['username'] ?? '',
      role: UserRole.fromString(json['role']),
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      fcmToken: json['fcmToken'] ?? json['fcm_token'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      profile: json['profile'] != null ? UserProfile.fromJson(json['profile']) : null,
      socialLinks: (json['socialLinks'] as List?)
          ?.map((e) => SocialLink.fromJson(e))
          .toList(),
    );
  }
}

class AuthResponse {
  final String accessToken;
  final String? refreshToken;
  final User? user;

  AuthResponse({
    required this.accessToken,
    this.refreshToken,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] ?? json['access_token'] ?? '',
      refreshToken: json['refreshToken'] ?? json['refresh_token'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}
