import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/budget_week_entity.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/entities/group_member_entity.dart';
import '../../domain/repositories/group_repository.dart';
import '../datasources/group_remote_data_source.dart';

class GroupRepositoryImpl implements GroupRepository {
  final GroupRemoteDataSource remoteDataSource;

  GroupRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<GroupEntity>> getUserGroups(String userId) async {
    try {
      return await remoteDataSource.getUserGroups(userId);
    } catch (e) {
      throw ServerException(message: 'Error al cargar grupos: $e');
    }
  }

  @override
  Future<GroupEntity?> getGroupById(String groupId) async {
    try {
      return await remoteDataSource.getGroupById(groupId);
    } catch (e) {
      throw ServerException(message: 'Error al obtener el grupo: $e');
    }
  }

  @override
  Future<GroupEntity> createGroup({
    required String name,
    required double budgetTotal,
    required DateTime startDate,
    required int weeksCount,
    required String createdBy,
  }) async {
    try {
      return await remoteDataSource.createGroup(
        name: name,
        budgetTotal: budgetTotal,
        startDate: startDate,
        weeksCount: weeksCount,
        createdBy: createdBy,
      );
    } catch (e) {
      throw ServerException(message: 'Error al crear el grupo: $e');
    }
  }

  @override
  Future<GroupEntity> joinGroupWithInviteCode({
    required String inviteCode,
    required String userId,
  }) async {
    try {
      return await remoteDataSource.joinGroupWithInviteCode(
        inviteCode: inviteCode,
        userId: userId,
      );
    } catch (e) {
      throw ServerException(message: e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<List<GroupMemberEntity>> getGroupMembers(String groupId) async {
    try {
      return await remoteDataSource.getGroupMembers(groupId);
    } catch (e) {
      throw ServerException(message: 'Error al obtener miembros del grupo: $e');
    }
  }

  @override
  Future<List<BudgetWeekEntity>> getGroupBudgetWeeks(String groupId) async {
    try {
      return await remoteDataSource.getGroupBudgetWeeks(groupId);
    } catch (e) {
      throw ServerException(message: 'Error al obtener semanas del presupuesto: $e');
    }
  }

  @override
  Future<double> getGroupTotalSpent(String groupId) async {
    try {
      return await remoteDataSource.getGroupTotalSpent(groupId);
    } catch (e) {
      throw ServerException(message: 'Error al calcular total gastado: $e');
    }
  }

  @override
  Future<void> updateBudgetWeeks(List<BudgetWeekEntity> weeks) async {
    try {
      await remoteDataSource.updateBudgetWeeks(weeks);
    } catch (e) {
      throw ServerException(message: 'Error al actualizar semanas de presupuesto: $e');
    }
  }
}
