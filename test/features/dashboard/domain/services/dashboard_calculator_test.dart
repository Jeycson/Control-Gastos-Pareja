import 'package:finanzas_compartidas/features/dashboard/domain/services/dashboard_calculator.dart';
import 'package:finanzas_compartidas/features/groups/domain/entities/budget_week_entity.dart';
import 'package:finanzas_compartidas/features/groups/domain/entities/group_entity.dart';
import 'package:finanzas_compartidas/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardCalculator Unit Tests', () {
    final startDate = DateTime(2026, 7, 1);
    final endDate = DateTime(2026, 7, 31);

    test('calculateTimeProgress return correct percentage when halfway', () {
      final now = DateTime(2026, 7, 16); // 15 days out of 30 days
      final progress =
          DashboardCalculator.calculateTimeProgress(startDate, endDate, now);

      expect(progress, closeTo(50.0, 1.0));
    });

    test('calculateTimeProgress return 0 before start and 100 after end', () {
      final before = DateTime(2026, 6, 25);
      final after = DateTime(2026, 8, 5);

      expect(
        DashboardCalculator.calculateTimeProgress(
            startDate, endDate, before),
        0.0,
      );
      expect(
        DashboardCalculator.calculateTimeProgress(startDate, endDate, after),
        100.0,
      );
    });

    test('calculateMoneyProgress returns correct percentage', () {
      expect(DashboardCalculator.calculateMoneyProgress(500, 1000), 50.0);
      expect(DashboardCalculator.calculateMoneyProgress(1200, 1000), 1200.0 / 10.0);
      expect(DashboardCalculator.calculateMoneyProgress(100, 0), 0.0);
    });

    test('checkIsWarning detects warning when money exceeds time by threshold', () {
      // Money spent % = 70%, Time elapsed % = 50% => diff = 20% > 10% threshold -> warning
      expect(
        DashboardCalculator.checkIsWarning(70.0, 50.0, threshold: 10.0),
        isTrue,
      );

      // Money spent % = 55%, Time elapsed % = 50% => diff = 5% <= 10% threshold -> no warning
      expect(
        DashboardCalculator.checkIsWarning(55.0, 50.0, threshold: 10.0),
        isFalse,
      );
    });

    test('calculateCategoryExpenses groups and calculates percentages correctly', () {
      final transactions = [
        TransactionEntity(
          id: '1',
          walletId: 'w1',
          userId: 'u1',
          amount: 60.0,
          category: 'Comida',
          isShared: true,
          isExtraordinary: false,
          description: 'Cena',
          createdAt: DateTime.now(),
        ),
        TransactionEntity(
          id: '2',
          walletId: 'w1',
          userId: 'u1',
          amount: 40.0,
          category: 'Transporte',
          isShared: true,
          isExtraordinary: false,
          description: 'Gasolina',
          createdAt: DateTime.now(),
        ),
        TransactionEntity(
          id: '3',
          walletId: 'w1',
          userId: 'u1',
          amount: 100.0,
          category: 'Comida',
          isShared: true,
          isExtraordinary: true,
          description: 'Supermercado',
          createdAt: DateTime.now(),
        ),
      ];

      final categories =
          DashboardCalculator.calculateCategoryExpenses(transactions);

      expect(categories.length, 2);
      expect(categories.first.category, 'Comida');
      expect(categories.first.amount, 160.0);
      expect(categories.first.percentage, 80.0);
      expect(categories.first.count, 2);

      expect(categories.last.category, 'Transporte');
      expect(categories.last.amount, 40.0);
      expect(categories.last.percentage, 20.0);
      expect(categories.last.count, 1);
    });

    test('filterExtraordinaryTransactions filters only extraordinary transactions', () {
      final transactions = [
        TransactionEntity(
          id: '1',
          walletId: 'w1',
          userId: 'u1',
          amount: 50.0,
          category: 'Comida',
          isShared: true,
          isExtraordinary: false,
          description: 'Normal',
          createdAt: DateTime(2026, 7, 10),
        ),
        TransactionEntity(
          id: '2',
          walletId: 'w1',
          userId: 'u1',
          amount: 300.0,
          category: 'Salud',
          isShared: true,
          isExtraordinary: true,
          description: 'Doctor de emergencia',
          createdAt: DateTime(2026, 7, 12),
        ),
      ];

      final extraordinary =
          DashboardCalculator.filterExtraordinaryTransactions(transactions);

      expect(extraordinary.length, 1);
      expect(extraordinary.first.id, '2');
      expect(extraordinary.first.amount, 300.0);
    });

    test('buildMetrics returns complete DashboardMetricsEntity with warning state', () {
      final group = GroupEntity(
        id: 'g1',
        name: 'Pareja',
        inviteCode: 'ABCDEF',
        budgetTotal: 1000.0,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
        weeksCount: 4,
        createdBy: 'u1',
      );

      final budgetWeeks = [
        BudgetWeekEntity(
          id: 'w1',
          groupId: 'g1',
          weekNumber: 1,
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 7),
          plannedAmount: 250.0,
          spentAmount: 200.0,
          adjustedAmount: 250.0,
        ),
        BudgetWeekEntity(
          id: 'w2',
          groupId: 'g1',
          weekNumber: 2,
          startDate: DateTime(2026, 7, 8),
          endDate: DateTime(2026, 7, 14),
          plannedAmount: 250.0,
          spentAmount: 300.0,
          adjustedAmount: 250.0,
        ),
      ];

      final transactions = [
        TransactionEntity(
          id: 't1',
          walletId: 'w1',
          userId: 'u1',
          amount: 700.0, // 70% of 1000 spent!
          category: 'Comida',
          isShared: true,
          isExtraordinary: true,
          description: 'Compra Grande',
          createdAt: DateTime(2026, 7, 10),
        ),
      ];

      // Current date: July 10 (day 10 out of 30 days -> ~30% time elapsed)
      final metrics = DashboardCalculator.buildMetrics(
        group: group,
        budgetWeeks: budgetWeeks,
        transactions: transactions,
        now: DateTime(2026, 7, 10),
        threshold: 10.0,
      );

      expect(metrics.totalBudget, 1000.0);
      expect(metrics.totalSpent, 700.0);
      expect(metrics.moneySpentPercentage, 70.0);
      expect(metrics.timeElapsedPercentage, closeTo(30.0, 2.0));
      expect(metrics.isWarning, isTrue); // 70% - 30% = 40% > 10%
      expect(metrics.totalExtraordinarySpent, 700.0);
    });
  });
}
