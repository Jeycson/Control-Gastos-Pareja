import '../../domain/entities/group_member_entity.dart';

class GroupMemberModel extends GroupMemberEntity {
  const GroupMemberModel({
    required super.groupId,
    required super.userId,
    required super.role,
    required super.fullName,
    super.avatarUrl,
    super.joinedAt,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>? ?? {};
    return GroupMemberModel(
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String? ?? 'member',
      fullName: profile['full_name'] as String? ?? 'Usuario',
      avatarUrl: profile['avatar_url'] as String?,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : null,
    );
  }
}
