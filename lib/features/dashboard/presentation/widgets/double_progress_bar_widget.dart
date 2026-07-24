import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/dashboard_provider.dart';

class DoubleProgressBarWidget extends StatelessWidget {
  final DashboardProgressMetrics metrics;

  const DoubleProgressBarWidget({
    super.key,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final timeRatio = (metrics.timeElapsedPercentage / 100.0).clamp(0.0, 1.0);
    final moneyRatio = (metrics.moneySpentPercentage / 100.0).clamp(0.0, 1.0);

    final spentColor = metrics.isWarning
        ? Colors.deepOrange
        : theme.colorScheme.primary;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title and Status Chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      metrics.isWarning
                          ? Icons.warning_amber_rounded
                          : Icons.speed,
                      color: metrics.isWarning
                          ? Colors.deepOrange
                          : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ritmo de Gasto',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: metrics.isWarning
                        ? Colors.deepOrange.withValues(alpha: 0.15)
                        : Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    metrics.isWarning ? '⚠️ Alerta' : '✅ En Orden',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: metrics.isWarning
                          ? Colors.deepOrange
                          : Colors.green[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bar 1: Tiempo Transcurrido
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.schedule, size: 16, color: Colors.blueGrey),
                        SizedBox(width: 6),
                        Text(
                          'Tiempo transcurrido',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${metrics.timeElapsedPercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: timeRatio,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.blueAccent,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Bar 2: Dinero Gastado
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.attach_money, size: 16, color: spentColor),
                        const SizedBox(width: 4),
                        Text(
                          'Dinero gastado (${Formatters.formatCurrency(metrics.totalSpent)} / ${Formatters.formatCurrency(metrics.totalBudget)})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${metrics.moneySpentPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: spentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: moneyRatio,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(spentColor),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Banner explicativo según estado de advertencia
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: metrics.isWarning
                    ? Colors.deepOrange.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: metrics.isWarning
                      ? Colors.deepOrange.withValues(alpha: 0.3)
                      : Colors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                metrics.isWarning
                    ? '⚠️ ¡Atención! El porcentaje gastado (${metrics.moneySpentPercentage.toStringAsFixed(1)}%) supera al tiempo transcurrido (${metrics.timeElapsedPercentage.toStringAsFixed(1)}%) por ${metrics.percentageDifference.toStringAsFixed(1)} puntos porcentuales (umbral: ${metrics.thresholdPercentage.toStringAsFixed(0)}%). Recomendamos moderar los gastos.'
                    : '✅ ¡Buen trabajo! Tu ritmo de gasto está alineado con el tiempo del ciclo presupuestario.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: metrics.isWarning
                      ? Colors.deepOrange[900]
                      : Colors.green[900],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
