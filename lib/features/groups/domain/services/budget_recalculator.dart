import '../entities/budget_week_entity.dart';

/*
 * ============================================================================
 * MOTOR DE RECÁLCULO PRESUPUESTARIO (PURE DOMAIN MODULE)
 * ============================================================================
 * 
 * PSEUDOCÓDIGO DEL ALGORITMO:
 * 
 * ALGORITMO: Recálculo y Redistribución Presupuestaria de Semanas (closeWeekAndRedistribute)
 * 
 * ENTRADAS:
 *   - weeks: Lista inmutable de BudgetWeekEntity (ordenadas por weekNumber)
 *   - closingWeekIndex: Índice de la semana que se está cerrando (0 <= index < weeks.length)
 * 
 * SALIDA:
 *   - List<BudgetWeekEntity>: Nueva lista inmutable con los valores adjustedAmount recalculados
 * 
 * PASOS:
 *   1. Validar que closingWeekIndex esté en el rango válido [0, weeks.length - 1].
 *      Si es inválido, retornar una copia inalterada de `weeks`.
 *   2. Obtener la semana a cerrar: closingWeek = weeks[closingWeekIndex].
 *   3. Calcular la diferencia neta de la semana que cierra:
 *        diferencia = closingWeek.adjustedAmount - closingWeek.spentAmount
 *   4. Contar semanas futuras restantes:
 *        remainingWeeksCount = (weeks.length - 1) - closingWeekIndex
 *   5. Caso A: Si no quedan semanas futuras (remainingWeeksCount == 0) O la diferencia es 0 (diferencia == 0):
 *        - No hay semanas futuras entre las cuales redistribuir.
 *        - Retornar una nueva lista con las mismas semanas inalteradas.
 *   6. Caso B: Si quedan semanas futuras (remainingWeeksCount > 0):
 *        - Si diferencia > 0 (Ahorro):
 *            remanentePorSemana = diferencia / remainingWeeksCount
 *            Para cada semana futura (index > closingWeekIndex):
 *              semanaFutura.adjustedAmount = semanaFutura.adjustedAmount + remanentePorSemana
 *        - Si diferencia < 0 (Sobregiro):
 *            excedente = abs(diferencia)
 *            deduccionPorSemana = excedente / remainingWeeksCount
 *            Para cada semana futura (index > closingWeekIndex):
 *              semanaFutura.adjustedAmount = max(0.0, semanaFutura.adjustedAmount - deduccionPorSemana)
 *   7. Construir y retornar la nueva lista de semanas sin mutar ninguna instancia original.
 * ============================================================================
 */

abstract class BudgetRecalculator {
  static List<BudgetWeekEntity> closeWeekAndRedistribute(
    List<BudgetWeekEntity> weeks,
    int closingWeekIndex,
  ) {
    if (weeks.isEmpty || closingWeekIndex < 0 || closingWeekIndex >= weeks.length) {
      return List<BudgetWeekEntity>.from(weeks);
    }

    final closingWeek = weeks[closingWeekIndex];
    final difference = closingWeek.adjustedAmount - closingWeek.spentAmount;
    final remainingWeeksCount = (weeks.length - 1) - closingWeekIndex;

    // Si es la última semana o no hay diferencia, no hay semanas futuras entre las cuales redistribuir
    if (remainingWeeksCount == 0 || difference == 0) {
      return List<BudgetWeekEntity>.from(weeks);
    }

    final adjustmentPerWeek = difference / remainingWeeksCount;
    final updatedWeeks = <BudgetWeekEntity>[];

    for (int i = 0; i < weeks.length; i++) {
      if (i <= closingWeekIndex) {
        // Semanas pasadas o la semana que cierra mantienen sus datos inalterados
        updatedWeeks.add(weeks[i]);
      } else {
        // Semanas futuras reciben el ajuste proporcional (sumando si es ahorro, restando si es sobregiro)
        final currentAdjusted = weeks[i].adjustedAmount;
        final newAdjusted = (currentAdjusted + adjustmentPerWeek).clamp(0.0, double.infinity);

        updatedWeeks.add(weeks[i].copyWith(
          adjustedAmount: newAdjusted,
        ));
      }
    }

    return updatedWeeks;
  }
}
