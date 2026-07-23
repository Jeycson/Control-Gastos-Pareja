class GroupMemberEntity {
  final String groupId;
  final String userId;
  final String role;
  final String fullName;
  final String? avatarUrl;
  final DateTime? joinedAt;

  const GroupMemberEntity({
    required this.groupId,
    required this.userId,
    required this.role,
    required this.fullName,
    this.avatarUrl,
    this.joinedAt,
  });
}
