import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/entities/category_expense_entity.dart';

class CategoryChartWidget extends StatefulWidget {
  final List<CategoryExpenseEntity> categoryExpenses;
  final double totalSpent;

  const CategoryChartWidget({
    super.key,
    required this.categoryExpenses,
    required this.totalSpent,
  });

  @override
  State<CategoryChartWidget> createState() => _CategoryChartWidgetState();
}

class _CategoryChartWidgetState extends State<CategoryChartWidget> {
  int _touchedIndex = -1;

  static const Map<String, Color> _categoryColors = {
    'Comida': Colors.orange,
    'Transporte': Colors.blue,
    'Servicios': Colors.amber,
    'Entretenimiento': Colors.purple,
    'Salud': Colors.redAccent,
    'Vivienda': Colors.indigo,
    'Compras': Colors.pink,
    'Viajes': Colors.teal,
    'Otros': Colors.grey,
  };

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

  Color _getColor(String category, int index) {
    if (_categoryColors.containsKey(category)) {
      return _categoryColors[category]!;
    }
    final colors = [
      Colors.teal,
      Colors.cyan,
      Colors.deepOrange,
      Colors.lime,
      Colors.brown,
    ];
    return colors[index % colors.length];
  }

  IconData _getIcon(String category) {
    return _categoryIcons[category] ?? Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.categoryExpenses.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(Icons.pie_chart_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'Gastos por Categoría',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No hay gastos registrados en este ciclo.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.pie_chart, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Gastos por Categoría',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Total: ${Formatters.formatCurrency(widget.totalSpent)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pie Chart Container
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 3,
                  centerSpaceRadius: 40,
                  sections: widget.categoryExpenses.asMap().entries.map((entry) {
                    final index = entry.key;
                    final cat = entry.value;
                    final isTouched = index == _touchedIndex;
                    final radius = isTouched ? 55.0 : 45.0;
                    final color = _getColor(cat.category, index);

                    return PieChartSectionData(
                      color: color,
                      value: cat.amount,
                      title: '${cat.percentage.toStringAsFixed(0)}%',
                      radius: radius,
                      titleStyle: TextStyle(
                        fontSize: isTouched ? 14 : 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Desglose por categoría (Leyenda)
            Column(
              children: widget.categoryExpenses.asMap().entries.map((entry) {
                final index = entry.key;
                final cat = entry.value;
                final isSelected = index == _touchedIndex;
                final color = _getColor(cat.category, index);
                final icon = _getIcon(cat.category);

                return InkWell(
                  onTap: () {
                    setState(() {
                      _touchedIndex = _touchedIndex == index ? -1 : index;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 16, color: color),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            cat.category,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '${cat.count} tx',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              Formatters.formatCurrency(cat.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${cat.percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
