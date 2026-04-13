import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { consumer, provider }

class UserModel {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? profileImage;
  final String? pushToken;
  final DateTime createdAt;

  // Provider specific fields
  final String? serviceType;
  final String? bio;
  final double? hourlyRate;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final bool isActive;
  final GeoPoint? location;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.profileImage,
    this.pushToken,
    required this.createdAt,
    this.serviceType,
    this.bio,
    this.hourlyRate,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isVerified = false,
    this.isActive = false,
    this.location,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] == 'provider' ? UserRole.provider : UserRole.consumer,
      profileImage: json['profileImage'] as String?,
      pushToken: json['pushToken'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      serviceType: json['serviceType'] as String?,
      bio: json['bio'] as String?,
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      isVerified: json['isVerified'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? false,
      location: json['location'] as GeoPoint?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role == UserRole.provider ? 'provider' : 'consumer',
      'profileImage': profileImage,
      'pushToken': pushToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'serviceType': serviceType,
      'bio': bio,
      'hourlyRate': hourlyRate,
      'rating': rating,
      'reviewCount': reviewCount,
      'isVerified': isVerified,
      'isActive': isActive,
      'location': location,
    };
  }
}
