import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../dashboard/presentation/providers/user_budget_period_provider.dart';

import '../providers/wallets_provider.dart';

class ConfigureBudgetPeriodDialog extends ConsumerStatefulWidget {
  final double? totalWalletBalance;

  const ConfigureBudgetPeriodDialog({
    super.key,
    this.totalWalletBalance,
  });

  @override
  ConsumerState<ConfigureBudgetPeriodDialog> createState() =>
      _ConfigureBudgetPeriodDialogState();
}

class _ConfigureBudgetPeriodDialogState
    extends ConsumerState<ConfigureBudgetPeriodDialog> {
  late DateTime _startDate;
  late DateTime _endDate;
  late int _weeksCount;

  @override
  void initState() {
    super.initState();
    final current = ref.read(userBudgetPeriodProvider);
    _startDate = current.startDate;
    _endDate = current.endDate;
    _weeksCount = current.weeksCount;
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _endDate = _startDate.add(Duration(days: (_weeksCount * 7) - 1));
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: _startDate.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        final days = _endDate.difference(_startDate).inDays + 1;
        _weeksCount = (days / 7).ceil().clamp(1, 12);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletsState = ref.watch(walletsNotifierProvider);
    final effectiveTotalBalance = widget.totalWalletBalance ??
        walletsState.wallets.fold<double>(0.0, (sum, w) => sum + w.balance);
    final weeklyAmount =
        _weeksCount > 0 ? effectiveTotalBalance / _weeksCount : 0.0;

    return AlertDialog(
      title: const Text('Período Presupuestal Individual 📅'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Presupuesto Total (Suma de Billeteras)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.formatCurrency(effectiveTotalBalance),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fecha de Inicio'),
              subtitle: Text(
                '${_startDate.day}/${_startDate.month}/${_startDate.year}',
              ),
              trailing: const Icon(Icons.calendar_month),
              onTap: _selectStartDate,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fecha de Fin'),
              subtitle: Text(
                '${_endDate.day}/${_endDate.month}/${_endDate.year}',
              ),
              trailing: const Icon(Icons.calendar_month),
              onTap: _selectEndDate,
            ),
            const SizedBox(height: 8),
            Text(
              'Número de semanas: $_weeksCount',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _weeksCount.toDouble(),
              min: 1,
              max: 12,
              divisions: 11,
              label: '$_weeksCount semanas',
              onChanged: (val) {
                setState(() {
                  _weeksCount = val.toInt();
                  _endDate = _startDate.add(Duration(days: (_weeksCount * 7) - 1));
                });
              },
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Presupuesto Semanal Asignado:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${Formatters.formatCurrency(weeklyAmount)} por semana durante $_weeksCount semanas.',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            ref.read(userBudgetPeriodProvider.notifier).updatePeriod(
                  startDate: _startDate,
                  endDate: _endDate,
                  weeksCount: _weeksCount,
                );
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Período presupuestal actualizado exitosamente.'),
              ),
            );
          },
          child: const Text('Guardar Período'),
        ),
      ],
    );
  }
}
