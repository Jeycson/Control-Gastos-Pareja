import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/budget_week_entity.dart';
import '../models/budget_week_model.dart';
import '../models/group_member_model.dart';
import '../models/group_model.dart';

abstract class GroupRemoteDataSource {
  Future<List<GroupModel>> getUserGroups(String userId);
  Future<GroupModel?> getGroupById(String groupId);
  Future<GroupModel> createGroup({
    required String name,
    required double budgetTotal,
    required DateTime startDate,
    required int weeksCount,
    required String createdBy,
  });
  Future<GroupModel> joinGroupWithInviteCode({
    required String inviteCode,
    required String userId,
  });
  Future<List<GroupMemberModel>> getGroupMembers(String groupId);
  Future<List<BudgetWeekModel>> getGroupBudgetWeeks(String groupId);
  Future<double> getGroupTotalSpent(String groupId);
  Future<void> updateBudgetWeeks(List<BudgetWeekEntity> weeks);
}

class GroupRemoteDataSourceImpl implements GroupRemoteDataSource {
  final SupabaseClient supabaseClient;

  GroupRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<List<GroupModel>> getUserGroups(String userId) async {
    final response = await supabaseClient
        .from('group_members')
        .select('groups!inner(*)')
        .eq('user_id', userId);

    return (response as List<dynamic>)
        .map((item) => GroupModel.fromJson(item['groups'] as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<GroupModel?> getGroupById(String groupId) async {
    final response = await supabaseClient
        .from('groups')
        .select()
        .eq('id', groupId)
        .maybeSingle();

    if (response == null) return null;
    return GroupModel.fromJson(response);
  }

  @override
  Future<GroupModel> createGroup({
    required String name,
    required double budgetTotal,
    required DateTime startDate,
    required int weeksCount,
    required String createdBy,
  }) async {
    final endDate = startDate.add(Duration(days: (weeksCount * 7) - 1));

    final groupPayload = {
      'name': name,
      'budget_total': budgetTotal,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate.toIso8601String().split('T').first,
      'weeks_count': weeksCount,
      'created_by': createdBy,
    };

    final groupResponse = await supabaseClient
        .from('groups')
        .insert(groupPayload)
        .select()
        .single();

    final group = GroupModel.fromJson(groupResponse);

    // 1. Insert Creator into group_members
    await supabaseClient.from('group_members').insert({
      'group_id': group.id,
      'user_id': createdBy,
      'role': 'admin',
    });

    // 2. Automatically generate N budget_weeks dividing budgetTotal equally
    final weeklyPlanned = budgetTotal / weeksCount;
    final List<Map<String, dynamic>> budgetWeeksPayload = [];

    for (int i = 1; i <= weeksCount; i++) {
      final weekStart = startDate.add(Duration(days: (i - 1) * 7));
      final weekEnd = weekStart.add(const Duration(days: 6));

      budgetWeeksPayload.add({
        'group_id': group.id,
        'week_number': i,
        'start_date': weekStart.toIso8601String().split('T').first,
        'end_date': weekEnd.toIso8601String().split('T').first,
        'planned_amount': weeklyPlanned,
        'spent_amount': 0.00,
        'adjusted_amount': weeklyPlanned,
      });
    }

    await supabaseClient.from('budget_weeks').insert(budgetWeeksPayload);

    return group;
  }

  @override
  Future<GroupModel> joinGroupWithInviteCode({
    required String inviteCode,
    required String userId,
  }) async {
    final cleanCode = inviteCode.trim().toUpperCase();

    final groupResponse = await supabaseClient
        .from('groups')
        .select()
        .eq('invite_code', cleanCode)
        .maybeSingle();

    if (groupResponse == null) {
      throw Exception('Código de invitación no válido o el grupo no existe.');
    }

    final group = GroupModel.fromJson(groupResponse);

    await supabaseClient.from('group_members').upsert({
      'group_id': group.id,
      'user_id': userId,
      'role': 'member',
    });

    return group;
  }

  @override
  Future<List<GroupMemberModel>> getGroupMembers(String groupId) async {
    final response = await supabaseClient
        .from('group_members')
        .select('group_id, user_id, role, joined_at, profiles(full_name, avatar_url)')
        .eq('group_id', groupId);

    return (response as List<dynamic>)
        .map((json) => GroupMemberModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<BudgetWeekModel>> getGroupBudgetWeeks(String groupId) async {
    final response = await supabaseClient
        .from('budget_weeks')
        .select()
        .eq('group_id', groupId)
        .order('week_number', ascending: true);

    return (response as List<dynamic>)
        .map((json) => BudgetWeekModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<double> getGroupTotalSpent(String groupId) async {
    final response = await supabaseClient
        .from('transactions')
        .select('amount')
        .eq('group_id', groupId)
        .eq('is_shared', true);

    double total = 0.0;
    for (final item in (response as List<dynamic>)) {
      total += (item['amount'] as num).toDouble();
    }
    return total;
  }

  @override
  Future<void> updateBudgetWeeks(List<BudgetWeekEntity> weeks) async {
    for (final week in weeks) {
      await supabaseClient.from('budget_weeks').update({
        'adjusted_amount': week.adjustedAmount,
        'spent_amount': week.spentAmount,
      }).eq('id', week.id);
    }
  }
}
