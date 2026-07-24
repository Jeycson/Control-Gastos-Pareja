import 'package:finanzas_compartidas/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:finanzas_compartidas/features/dashboard/presentation/widgets/double_progress_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DoubleProgressBarWidget Tests', () {
    testWidgets('renders progress values and normal state when not in warning',
        (WidgetTester tester) async {
      const metrics = DashboardProgressMetrics(
        timeElapsedPercentage: 50.0,
        moneySpentPercentage: 40.0,
        isWarning: false,
        percentageDifference: -10.0,
        totalSpent: 400.0,
        totalBudget: 1000.0,
        thresholdPercentage: 10.0,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DoubleProgressBarWidget(metrics: metrics),
          ),
        ),
      );

      expect(find.text('Ritmo de Gasto'), findsOneWidget);
      expect(find.text('50.0%'), findsOneWidget); // Time %
      expect(find.text('40.0%'), findsOneWidget); // Money %
      expect(find.text('✅ En Orden'), findsOneWidget);
    });

    testWidgets('renders warning alert state when spent exceeds time by threshold',
        (WidgetTester tester) async {
      const metrics = DashboardProgressMetrics(
        timeElapsedPercentage: 30.0,
        moneySpentPercentage: 65.0,
        isWarning: true,
        percentageDifference: 35.0,
        totalSpent: 650.0,
        totalBudget: 1000.0,
        thresholdPercentage: 10.0,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DoubleProgressBarWidget(metrics: metrics),
          ),
        ),
      );

      expect(find.text('⚠️ Alerta'), findsOneWidget);
      expect(find.textContaining('¡Atención! El porcentaje gastado (65.0%)'),
          findsOneWidget);
    });
  });
}
