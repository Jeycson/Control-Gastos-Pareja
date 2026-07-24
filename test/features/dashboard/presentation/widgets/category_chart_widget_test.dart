import 'package:finanzas_compartidas/features/dashboard/domain/entities/category_expense_entity.dart';
import 'package:finanzas_compartidas/features/dashboard/presentation/widgets/category_chart_widget.dart';
import 'package:finanzas_compartidas/features/dashboard/presentation/widgets/extraordinary_expenses_widget.dart';
import 'package:finanzas_compartidas/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategoryChartWidget & ExtraordinaryExpensesWidget Tests', () {
    testWidgets('CategoryChartWidget renders categories and total spent',
        (WidgetTester tester) async {
      final categories = [
        const CategoryExpenseEntity(
          category: 'Comida',
          amount: 150.0,
          percentage: 75.0,
          count: 3,
        ),
        const CategoryExpenseEntity(
          category: 'Transporte',
          amount: 50.0,
          percentage: 25.0,
          count: 1,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryChartWidget(
              categoryExpenses: categories,
              totalSpent: 200.0,
            ),
          ),
        ),
      );

      expect(find.text('Gastos por Categoría'), findsOneWidget);
      expect(find.text('Total: \$200.00'), findsOneWidget);
      expect(find.text('Comida'), findsOneWidget);
      expect(find.text('Transporte'), findsOneWidget);
      expect(find.text('\$150.00'), findsOneWidget);
      expect(find.text('\$50.00'), findsOneWidget);
    });

    testWidgets('ExtraordinaryExpensesWidget renders list of extraordinary items',
        (WidgetTester tester) async {
      final transactions = [
        TransactionEntity(
          id: '1',
          walletId: 'w1',
          userId: 'u1',
          userName: 'María',
          amount: 350.0,
          category: 'Salud',
          isShared: true,
          isExtraordinary: true,
          description: 'Consulta Especialista',
          createdAt: DateTime(2026, 7, 20),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExtraordinaryExpensesWidget(
              transactions: transactions,
              totalExtraordinarySpent: 350.0,
            ),
          ),
        ),
      );

      expect(find.text('Gastos Extraordinarios'), findsOneWidget);
      expect(find.text('\$350.00'), findsNWidgets(2)); // Header badge & list item
      expect(find.text('Consulta Especialista'), findsOneWidget);
      expect(find.textContaining('María'), findsOneWidget);
    });
  });
}
