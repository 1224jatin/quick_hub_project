import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { consumer, provider, admin }

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
  
  // New Identity fields
  final String? gender;
  final int? age;
  final String? aadhaarNumber;
  final String? panNumber;
  final String? aadhaarImage;
  final String? panImage;
  final String? preferredLanguage;

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
    this.gender,
    this.age,
    this.aadhaarNumber,
    this.panNumber,
    this.aadhaarImage,
    this.panImage,
    this.preferredLanguage,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    UserRole role;
    switch (json['role']) {
      case 'provider':
        role = UserRole.provider;
        break;
      case 'admin':
        role = UserRole.admin;
        break;
      default:
        role = UserRole.consumer;
    }

    return UserModel(
      uid: json['uid'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: role,
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
      gender: json['gender'] as String?,
      age: json['age'] as int?,
      aadhaarNumber: json['aadhaarNumber'] as String?,
      panNumber: json['panNumber'] as String?,
      aadhaarImage: json['aadhaarImage'] as String?,
      panImage: json['panImage'] as String?,
      preferredLanguage: json['preferredLanguage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    String roleString;
    switch (role) {
      case UserRole.provider:
        roleString = 'provider';
        break;
      case UserRole.admin:
        roleString = 'admin';
        break;
      default:
        roleString = 'consumer';
    }

    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': roleString,
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
      'gender': gender,
      'age': age,
      'aadhaarNumber': aadhaarNumber,
      'panNumber': panNumber,
      'aadhaarImage': aadhaarImage,
      'panImage': panImage,
      'preferredLanguage': preferredLanguage,
    };
  }
}
