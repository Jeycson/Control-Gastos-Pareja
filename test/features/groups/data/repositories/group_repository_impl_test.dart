import 'package:finanzas_compartidas/core/errors/exceptions.dart';
import 'package:finanzas_compartidas/features/groups/data/datasources/group_remote_data_source.dart';
import 'package:finanzas_compartidas/features/groups/data/models/budget_week_model.dart';
import 'package:finanzas_compartidas/features/groups/data/models/group_member_model.dart';
import 'package:finanzas_compartidas/features/groups/data/models/group_model.dart';
import 'package:finanzas_compartidas/features/groups/data/repositories/group_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRemoteDataSource extends Mock implements GroupRemoteDataSource {}

void main() {
  late GroupRepositoryImpl repository;
  late MockGroupRemoteDataSource mockRemoteDataSource;

  const tUserId = 'user-123';
  const tGroupId = 'group-123';

  final tGroupModel = GroupModel(
    id: tGroupId,
    name: 'Pareja Gastos',
    inviteCode: 'A1B2C3',
    budgetTotal: 1000.0,
    startDate: DateTime(2026, 7, 1),
    endDate: DateTime(2026, 7, 28),
    weeksCount: 4,
    createdBy: tUserId,
  );

  const tGroupMemberModel = GroupMemberModel(
    groupId: tGroupId,
    userId: tUserId,
    role: 'admin',
    fullName: 'Jeycson',
  );

  final tBudgetWeekModel = BudgetWeekModel(
    id: 'week-1',
    groupId: tGroupId,
    weekNumber: 1,
    startDate: DateTime(2026, 7, 1),
    endDate: DateTime(2026, 7, 7),
    plannedAmount: 250.0,
    spentAmount: 50.0,
    adjustedAmount: 0.0,
  );

  setUp(() {
    mockRemoteDataSource = MockGroupRemoteDataSource();
    repository = GroupRepositoryImpl(mockRemoteDataSource);
  });

  group('getUserGroups', () {
    test('should return list of GroupModel when remote call is successful', () async {
      when(() => mockRemoteDataSource.getUserGroups(tUserId))
          .thenAnswer((_) async => [tGroupModel]);

      final result = await repository.getUserGroups(tUserId);

      expect(result, equals([tGroupModel]));
      verify(() => mockRemoteDataSource.getUserGroups(tUserId)).called(1);
    });

    test('should throw ServerException when remote call fails', () async {
      when(() => mockRemoteDataSource.getUserGroups(tUserId))
          .thenThrow(Exception('DB Error'));

      expect(
        () => repository.getUserGroups(tUserId),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('createGroup', () {
    test('should return created GroupModel when remote call is successful', () async {
      when(() => mockRemoteDataSource.createGroup(
            name: 'Pareja Gastos',
            budgetTotal: 1000.0,
            startDate: any(named: 'startDate'),
            weeksCount: 4,
            createdBy: tUserId,
          )).thenAnswer((_) async => tGroupModel);

      final result = await repository.createGroup(
        name: 'Pareja Gastos',
        budgetTotal: 1000.0,
        startDate: DateTime(2026, 7, 1),
        weeksCount: 4,
        createdBy: tUserId,
      );

      expect(result, equals(tGroupModel));
    });
  });

  group('joinGroupWithInviteCode', () {
    test('should return joined GroupModel when inviteCode is valid', () async {
      when(() => mockRemoteDataSource.joinGroupWithInviteCode(
            inviteCode: 'A1B2C3',
            userId: tUserId,
          )).thenAnswer((_) async => tGroupModel);

      final result = await repository.joinGroupWithInviteCode(
        inviteCode: 'A1B2C3',
        userId: tUserId,
      );

      expect(result, equals(tGroupModel));
    });
  });

  group('getGroupMembers', () {
    test('should return list of members for a group', () async {
      when(() => mockRemoteDataSource.getGroupMembers(tGroupId))
          .thenAnswer((_) async => [tGroupMemberModel]);

      final result = await repository.getGroupMembers(tGroupId);

      expect(result, equals([tGroupMemberModel]));
    });
  });

  group('getGroupBudgetWeeks', () {
    test('should return list of budget weeks for a group', () async {
      when(() => mockRemoteDataSource.getGroupBudgetWeeks(tGroupId))
          .thenAnswer((_) async => [tBudgetWeekModel]);

      final result = await repository.getGroupBudgetWeeks(tGroupId);

      expect(result, equals([tBudgetWeekModel]));
    });
  });
}
