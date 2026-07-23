import '../../../../core/usecases/usecase.dart';
import '../entities/budget_week_entity.dart';
import '../repositories/group_repository.dart';
import '../services/budget_recalculator.dart';

class CloseWeekParams {
  final String groupId;
  final int closingWeekIndex;

  const CloseWeekParams({
    required this.groupId,
    required this.closingWeekIndex,
  });
}

class CloseWeekUseCase implements UseCase<List<BudgetWeekEntity>, CloseWeekParams> {
  final GroupRepository repository;

  CloseWeekUseCase(this.repository);

  @override
  Future<List<BudgetWeekEntity>> call(CloseWeekParams params) async {
    // 1. Read current budget weeks from repository
    final currentWeeks = await repository.getGroupBudgetWeeks(params.groupId);

    // 2. Apply pure domain recalculation logic
    final updatedWeeks = BudgetRecalculator.closeWeekAndRedistribute(
      currentWeeks,
      params.closingWeekIndex,
    );

    // 3. Write updated adjusted_amount values back to repository
    await repository.updateBudgetWeeks(updatedWeeks);

    return updatedWeeks;
  }
}
