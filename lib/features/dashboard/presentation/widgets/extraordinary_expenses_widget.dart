import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';

class ExtraordinaryExpensesWidget extends StatelessWidget {
  final List<TransactionEntity> transactions;
  final double totalExtraordinarySpent;

  const ExtraordinaryExpensesWidget({
    super.key,
    required this.transactions,
    required this.totalExtraordinarySpent,
  });

  static const Map<String, IconData> _categoryIcons = {
    'Comida': Icons.restaurant,
    'Transporte': Icons.directions_bus,
    'Servicios': Icons.lightbulb_outline,
    'Entretenimiento': Icons.movie_outlined,
    'Salud': Icons.local_hospital_outlined,
    'Vivienda': Icons.home_outlined,
    'Compras': Icons.shopping_bag_outlined,
    'Viajes': Icons.flight_takeoff,
    'Otros': Icons.category_outlined,
  };

  IconData _getIcon(String category) {
    return _categoryIcons[category] ?? Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title & Total Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bolt, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      'Gastos Extraordinarios',
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
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    Formatters.formatCurrency(totalExtraordinarySpent),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[900],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (transactions.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 36, color: Colors.green[400]),
                      const SizedBox(height: 8),
                      Text(
                        '¡Genial! No hay gastos extraordinarios en este período.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  final icon = _getIcon(tx.category);

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber.withValues(alpha: 0.15),
                      child: Icon(icon, color: Colors.amber[800], size: 20),
                    ),
                    title: Text(
                      tx.description.isNotEmpty
                          ? tx.description
                          : tx.category,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      '${tx.userName ?? 'Usuario'} • ${_formatDate(tx.createdAt)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Formatters.formatCurrency(tx.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.deepOrange,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Extraordinario',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}
