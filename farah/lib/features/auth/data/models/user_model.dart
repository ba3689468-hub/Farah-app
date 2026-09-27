import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/app_user.dart';

class UserModel extends AppUser {
  const UserModel({
    required super.uid,
    required super.fullName,
    required super.email,
    required super.phone,
    required super.role,
    super.photoUrl,
    super.createdAt,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      role: data['role'] ?? 'user',
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
