import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/group_remote_data_source.dart';
import '../../data/repositories/group_repository_impl.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/repositories/group_repository.dart';
import '../../domain/usecases/create_group_usecase.dart';
import '../../domain/usecases/get_group_summary_usecase.dart';
import '../../domain/usecases/get_user_groups_usecase.dart';
import '../../domain/usecases/join_group_usecase.dart';

final groupRemoteDataSourceProvider = Provider<GroupRemoteDataSource>((ref) {
  return GroupRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepositoryImpl(ref.watch(groupRemoteDataSourceProvider));
});

final getUserGroupsUseCaseProvider = Provider<GetUserGroupsUseCase>((ref) {
  return GetUserGroupsUseCase(ref.watch(groupRepositoryProvider));
});

final createGroupUseCaseProvider = Provider<CreateGroupUseCase>((ref) {
  return CreateGroupUseCase(ref.watch(groupRepositoryProvider));
});

final joinGroupUseCaseProvider = Provider<JoinGroupUseCase>((ref) {
  return JoinGroupUseCase(ref.watch(groupRepositoryProvider));
});

final getGroupSummaryUseCaseProvider = Provider<GetGroupSummaryUseCase>((ref) {
  return GetGroupSummaryUseCase(ref.watch(groupRepositoryProvider));
});

class GroupsState {
  final bool isLoading;
  final List<GroupEntity> groups;
  final GroupSummary? selectedGroupSummary;
  final String? errorMessage;

  const GroupsState({
    required this.isLoading,
    required this.groups,
    this.selectedGroupSummary,
    this.errorMessage,
  });

  factory GroupsState.initial() => const GroupsState(
        isLoading: false,
        groups: [],
      );

  GroupsState copyWith({
    bool? isLoading,
    List<GroupEntity>? groups,
    GroupSummary? selectedGroupSummary,
    String? errorMessage,
  }) {
    return GroupsState(
      isLoading: isLoading ?? this.isLoading,
      groups: groups ?? this.groups,
      selectedGroupSummary: selectedGroupSummary ?? this.selectedGroupSummary,
      errorMessage: errorMessage,
    );
  }
}

class GroupsNotifier extends StateNotifier<GroupsState> {
  final GetUserGroupsUseCase getUserGroupsUseCase;
  final CreateGroupUseCase createGroupUseCase;
  final JoinGroupUseCase joinGroupUseCase;
  final GetGroupSummaryUseCase getGroupSummaryUseCase;
  final Ref ref;

  GroupsNotifier({
    required this.getUserGroupsUseCase,
    required this.createGroupUseCase,
    required this.joinGroupUseCase,
    required this.getGroupSummaryUseCase,
    required this.ref,
  }) : super(GroupsState.initial());

  Future<void> loadUserGroups() async {
    final authState = ref.read(authNotifierProvider);
    final user = authState.user;
    if (user == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final groups = await getUserGroupsUseCase(user.id);
      state = state.copyWith(isLoading: false, groups: groups);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<GroupEntity?> createGroup({
    required String name,
    required double budgetTotal,
    required DateTime startDate,
    required int weeksCount,
  }) async {
    final authState = ref.read(authNotifierProvider);
    final user = authState.user;
    if (user == null) return null;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final group = await createGroupUseCase(
        CreateGroupParams(
          name: name,
          budgetTotal: budgetTotal,
          startDate: startDate,
          weeksCount: weeksCount,
          createdBy: user.id,
        ),
      );
      await loadUserGroups();
      return group;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<GroupEntity?> joinGroup(String inviteCode) async {
    final authState = ref.read(authNotifierProvider);
    final user = authState.user;
    if (user == null) return null;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final group = await joinGroupUseCase(
        JoinGroupParams(inviteCode: inviteCode, userId: user.id),
      );
      await loadUserGroups();
      return group;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<void> loadGroupSummary(String groupId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final summary = await getGroupSummaryUseCase(groupId);
      state = state.copyWith(isLoading: false, selectedGroupSummary: summary);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final groupsNotifierProvider =
    StateNotifierProvider<GroupsNotifier, GroupsState>((ref) {
  return GroupsNotifier(
    getUserGroupsUseCase: ref.watch(getUserGroupsUseCaseProvider),
    createGroupUseCase: ref.watch(createGroupUseCaseProvider),
    joinGroupUseCase: ref.watch(joinGroupUseCaseProvider),
    getGroupSummaryUseCase: ref.watch(getGroupSummaryUseCaseProvider),
    ref: ref,
  );
});
