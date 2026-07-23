import 'package:finanzas_compartidas/features/groups/domain/entities/budget_week_entity.dart';
import 'package:finanzas_compartidas/features/groups/domain/services/budget_recalculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BudgetWeekEntity createWeek({
    required int weekNumber,
    required double planned,
    required double spent,
    required double adjusted,
  }) {
    return BudgetWeekEntity(
      id: 'w-$weekNumber',
      groupId: 'g-1',
      weekNumber: weekNumber,
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 7, 7),
      plannedAmount: planned,
      spentAmount: spent,
      adjustedAmount: adjusted,
    );
  }

  group('BudgetRecalculator.closeWeekAndRedistribute', () {
    test('1. Sobregiro Normal: Excedente se resta equitativamente entre semanas futuras', () {
      final initialWeeks = [
        createWeek(weekNumber: 1, planned: 250, spent: 310, adjusted: 250), // -60 sobregiro
        createWeek(weekNumber: 2, planned: 250, spent: 0, adjusted: 250),
        createWeek(weekNumber: 3, planned: 250, spent: 0, adjusted: 250),
        createWeek(weekNumber: 4, planned: 250, spent: 0, adjusted: 250),
      ];

      final result = BudgetRecalculator.closeWeekAndRedistribute(initialWeeks, 0);

      expect(result[0].adjustedAmount, equals(250.0));
      expect(result[1].adjustedAmount, equals(230.0));
      expect(result[2].adjustedAmount, equals(230.0));
      expect(result[3].adjustedAmount, equals(230.0));
    });

    test('2. Ahorro Normal: Remanente se suma equitativamente entre semanas futuras', () {
      final initialWeeks = [
        createWeek(weekNumber: 1, planned: 250, spent: 190, adjusted: 250), // +60 ahorro
        createWeek(weekNumber: 2, planned: 250, spent: 0, adjusted: 250),
        createWeek(weekNumber: 3, planned: 250, spent: 0, adjusted: 250),
        createWeek(weekNumber: 4, planned: 250, spent: 0, adjusted: 250),
      ];

      final result = BudgetRecalculator.closeWeekAndRedistribute(initialWeeks, 0);

      expect(result[0].adjustedAmount, equals(250.0));
      expect(result[1].adjustedAmount, equals(270.0));
      expect(result[2].adjustedAmount, equals(270.0));
      expect(result[3].adjustedAmount, equals(270.0));
    });

    test('3. Sobregiro en Penúltima Semana: Afecta únicamente a la última semana restante', () {
      final initialWeeks = [
        createWeek(weekNumber: 1, planned: 200, spent: 200, adjusted: 200),
        createWeek(weekNumber: 2, planned: 200, spent: 200, adjusted: 200),
        createWeek(weekNumber: 3, planned: 200, spent: 300, adjusted: 200), // -100 sobregiro
        createWeek(weekNumber: 4, planned: 200, spent: 0, adjusted: 200),
      ];

      final result = BudgetRecalculator.closeWeekAndRedistribute(initialWeeks, 2);

      expect(result[0].adjustedAmount, equals(200.0));
      expect(result[1].adjustedAmount, equals(200.0));
      expect(result[2].adjustedAmount, equals(200.0));
      expect(result[3].adjustedAmount, equals(100.0));
    });

    test('4. Cierre de Última Semana: No redistribuye ya que no quedan semanas futuras', () {
      final initialWeeks = [
        createWeek(weekNumber: 1, planned: 250, spent: 250, adjusted: 250),
        createWeek(weekNumber: 2, planned: 250, spent: 250, adjusted: 250),
        createWeek(weekNumber: 3, planned: 250, spent: 400, adjusted: 250), // sobregiro última semana
      ];

      final result = BudgetRecalculator.closeWeekAndRedistribute(initialWeeks, 2);

      expect(result[0].adjustedAmount, equals(250.0));
      expect(result[1].adjustedAmount, equals(250.0));
      expect(result[2].adjustedAmount, equals(250.0));
    });

    test('5. Sobregiro Mayor al Total Restante (Caso Límite): Ajusta el balance a 0.0 sin números negativos', () {
      final initialWeeks = [
        createWeek(weekNumber: 1, planned: 100, spent: 400, adjusted: 100), // -300 sobregiro
        createWeek(weekNumber: 2, planned: 100, spent: 0, adjusted: 100),
        createWeek(weekNumber: 3, planned: 100, spent: 0, adjusted: 100),
      ];

      final result = BudgetRecalculator.closeWeekAndRedistribute(initialWeeks, 0);

      // Deducción por semana = 300 / 2 = 150. 100 - 150 = -50 -> clamp a 0.0
      expect(result[1].adjustedAmount, equals(0.0));
      expect(result[2].adjustedAmount, equals(0.0));
    });

    test('6. Ahorro Exacto a Cero: La diferencia es cero y el presupuesto no se modifica', () {
      final initialWeeks = [
        createWeek(weekNumber: 1, planned: 250, spent: 250, adjusted: 250),
        createWeek(weekNumber: 2, planned: 250, spent: 0, adjusted: 250),
        createWeek(weekNumber: 3, planned: 250, spent: 0, adjusted: 250),
      ];

      final result = BudgetRecalculator.closeWeekAndRedistribute(initialWeeks, 0);

      expect(result[1].adjustedAmount, equals(250.0));
      expect(result[2].adjustedAmount, equals(250.0));
    });

    test('7. Múltiples Cierres Consecutivos: Progreso encadenado de cierres', () {
      final initialWeeks = [
        createWeek(weekNumber: 1, planned: 200, spent: 140, adjusted: 200), // +60 ahorro -> +20 a semanas 2,3,4
        createWeek(weekNumber: 2, planned: 200, spent: 260, adjusted: 200), // +20 pasa a 220, gasta 260 -> -40 sobregiro
        createWeek(weekNumber: 3, planned: 200, spent: 0, adjusted: 200),
        createWeek(weekNumber: 4, planned: 200, spent: 0, adjusted: 200),
      ];

      // Cierre Semana 1
      final step1 = BudgetRecalculator.closeWeekAndRedistribute(initialWeeks, 0);
      expect(step1[1].adjustedAmount, equals(220.0));
      expect(step1[2].adjustedAmount, equals(220.0));
      expect(step1[3].adjustedAmount, equals(220.0));

      // Cierre Semana 2 (Semana 2 tenía adjusted 220 y spent 260 -> -40 sobregiro. Quedan 2 semanas -> -20 cada una)
      final step2 = BudgetRecalculator.closeWeekAndRedistribute(step1, 1);
      expect(step2[2].adjustedAmount, equals(200.0));
      expect(step2[3].adjustedAmount, equals(200.0));
    });

    test('8. Ciclo de 1 Sola Semana: Retorna la lista inalterada', () {
      final singleWeek = [
        createWeek(weekNumber: 1, planned: 500, spent: 700, adjusted: 500),
      ];

      final result = BudgetRecalculator.closeWeekAndRedistribute(singleWeek, 0);

      expect(result.length, equals(1));
      expect(result[0].adjustedAmount, equals(500.0));
    });

    test('9. Inmutabilidad y Protección contra índices inválidos', () {
      final initialWeeks = [
        createWeek(weekNumber: 1, planned: 100, spent: 100, adjusted: 100),
        createWeek(weekNumber: 2, planned: 100, spent: 100, adjusted: 100),
      ];

      final resultInvalid = BudgetRecalculator.closeWeekAndRedistribute(initialWeeks, -1);
      expect(resultInvalid, equals(initialWeeks));

      final resultOut = BudgetRecalculator.closeWeekAndRedistribute(initialWeeks, 5);
      expect(resultOut, equals(initialWeeks));
    });
  });
}
