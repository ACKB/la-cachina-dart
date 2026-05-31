import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.email,
    super.name,
    super.imageUrl,
    super.whatsappNumber,
    required super.createdAt,
  });

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      id:             map['id'].toString(),
      email:          map['email']          as String? ?? '',
      name:           map['name']           as String?,
      imageUrl:       map['image']          as String?,
      whatsappNumber: map['whatsapp_number'] as String?,
      createdAt:      DateTime.parse(map['created_at'].toString()),
    );
  }
}
