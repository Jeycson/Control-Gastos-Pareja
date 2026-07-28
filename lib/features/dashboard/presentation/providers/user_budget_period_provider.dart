import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/shared_preferences_provider.dart';

class UserBudgetPeriodState {
  final DateTime startDate;
  final DateTime endDate;
  final int weeksCount;

  const UserBudgetPeriodState({
    required this.startDate,
    required this.endDate,
    required this.weeksCount,
  });

  factory UserBudgetPeriodState.initial() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    return UserBudgetPeriodState(
      startDate: start,
      endDate: end,
      weeksCount: 4,
    );
  }

  UserBudgetPeriodState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    int? weeksCount,
  }) {
    return UserBudgetPeriodState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      weeksCount: weeksCount ?? this.weeksCount,
    );
  }
}

class UserBudgetPeriodNotifier extends StateNotifier<UserBudgetPeriodState> {
  final SharedPreferences prefs;

  static const String _startDateKey = 'user_budget_start_date';
  static const String _endDateKey = 'user_budget_end_date';
  static const String _weeksKey = 'user_budget_weeks_count';

  UserBudgetPeriodNotifier(this.prefs) : super(UserBudgetPeriodState.initial()) {
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    final startStr = prefs.getString(_startDateKey);
    final endStr = prefs.getString(_endDateKey);
    final weeks = prefs.getInt(_weeksKey);

    final start = startStr != null ? DateTime.tryParse(startStr) : null;
    final end = endStr != null ? DateTime.tryParse(endStr) : null;

    if (start != null && end != null && weeks != null) {
      state = UserBudgetPeriodState(
        startDate: start,
        endDate: end,
        weeksCount: weeks,
      );
    }
  }

  Future<void> updatePeriod({
    required DateTime startDate,
    required DateTime endDate,
    required int weeksCount,
  }) async {
    state = UserBudgetPeriodState(
      startDate: startDate,
      endDate: endDate,
      weeksCount: weeksCount,
    );

    await prefs.setString(_startDateKey, startDate.toIso8601String());
    await prefs.setString(_endDateKey, endDate.toIso8601String());
    await prefs.setInt(_weeksKey, weeksCount);
  }
}

final userBudgetPeriodProvider =
    StateNotifierProvider<UserBudgetPeriodNotifier, UserBudgetPeriodState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UserBudgetPeriodNotifier(prefs);
});
