import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/formatters.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/presentation/providers/groups_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../../wallets/presentation/providers/wallets_provider.dart';
import '../../../wallets/presentation/widgets/configure_budget_period_dialog.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/category_chart_widget.dart';
import '../widgets/double_progress_bar_widget.dart';
import '../widgets/extraordinary_expenses_widget.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(groupsNotifierProvider.notifier).loadUserGroups();
      try {
        await ref.read(walletsNotifierProvider.notifier).loadWallets();
      } catch (_) {}
      final groups = ref.read(groupsNotifierProvider).groups;
      if (mounted) {
        setState(() {
          _selectedGroupId = groups.isNotEmpty ? groups.first.id : null;
        });
      }
      if (mounted) {
        await ref
            .read(dashboardNotifierProvider(_selectedGroupId).notifier)
            .loadDashboard(isRefresh: true);
      }
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(groupsNotifierProvider.notifier).loadUserGroups();
    try {
      await ref.read(walletsNotifierProvider.notifier).loadWallets();
    } catch (_) {}
    await ref
        .read(dashboardNotifierProvider(_selectedGroupId).notifier)
        .loadDashboard(isRefresh: true);
  }

  Widget _buildBottomAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: theme.colorScheme.primary),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekStatColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authNotifierProvider).user;
    final groupsState = ref.watch(groupsNotifierProvider);
    final asyncDashboard =
        ref.watch(dashboardNotifierProvider(_selectedGroupId));

    final progressMetrics =
        ref.watch(dashboardProgressProvider(_selectedGroupId));
    final categoryExpenses =
        ref.watch(dashboardCategoryExpensesProvider(_selectedGroupId));
    final extraordinaryExpenses =
        ref.watch(dashboardExtraordinaryExpensesProvider(_selectedGroupId));

    if (_selectedGroupId != null && _selectedGroupId!.isNotEmpty) {
      ref.watch(realtimeGroupTransactionsProvider(_selectedGroupId!));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard Financiero 📊',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _onRefresh,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomAction(
                context,
                icon: Icons.account_balance_wallet_outlined,
                label: 'Billeteras',
                onTap: () => context.push('/wallets'),
              ),
              _buildBottomAction(
                context,
                icon: Icons.groups_outlined,
                label: 'Grupos',
                onTap: () => context.push('/groups'),
              ),
              Tooltip(
                message: 'Nuevo Gasto ⚡',
                child: ElevatedButton(
                  onPressed: () => context.push('/add-transaction'),
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(14),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 3,
                  ),
                  child: const Icon(Icons.flash_on, size: 26),
                ),
              ),
              _buildBottomAction(
                context,
                icon: Icons.receipt_long_outlined,
                label: 'Historial',
                onTap: () => context.push('/transactions'),
              ),
              if (_selectedGroupId != null)
                _buildBottomAction(
                  context,
                  icon: Icons.handshake_outlined,
                  label: 'Cuentas',
                  onTap: () =>
                      context.push('/settlements/${_selectedGroupId!}'),
                ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Saludo y selector de Grupo
              Card(
                elevation: 1,
                color: theme.colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Hola, ${user?.fullName.isNotEmpty == true ? user!.fullName : 'Usuario'}! 👋',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Resumen general de tu ciclo presupuestario',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      if (groupsState.groups.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.groups, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Grupo:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String?>(
                                    isExpanded: true,
                                    value: _selectedGroupId,
                                    items: [
                                      const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text('Todos mis gastos'),
                                      ),
                                      ...groupsState.groups.map((g) {
                                        return DropdownMenuItem<String?>(
                                          value: g.id,
                                          child: Text(g.name),
                                        );
                                      }),
                                    ],
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedGroupId = val;
                                      });
                                      ref
                                          .read(dashboardNotifierProvider(val)
                                              .notifier)
                                          .loadDashboard();
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Contenido principal según asyncDashboard state
              asyncDashboard.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Error al cargar dashboard: $err',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (metrics) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tarjetas de Resumen de Cifras Clave
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Presupuesto Total',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    Formatters.formatCurrency(
                                        metrics.totalBudget),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Card(
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Gastado',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    Formatters.formatCurrency(
                                        metrics.totalSpent),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: metrics.isWarning
                                          ? Colors.deepOrange
                                          : theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (metrics.currentWeekNumber != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Card(
                              elevation: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Semana Actual',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Semana ${metrics.currentWeekNumber}${metrics.totalWeeks != null ? '/${metrics.totalWeeks}' : ''}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 1. Barra de Progreso Doble
                    if (progressMetrics != null)
                      DoubleProgressBarWidget(metrics: progressMetrics),

                    // 2. Desglose Semanal del Período (Modo Personal)
                    if (_selectedGroupId == null &&
                        metrics.budgetWeeks != null &&
                        metrics.budgetWeeks!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Desglose Semanal Personal 📅',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.edit_calendar_outlined,
                                        size: 20),
                                    tooltip: 'Configurar Período',
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (context) =>
                                          const ConfigureBudgetPeriodDialog(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: metrics.budgetWeeks!.length,
                                itemBuilder: (context, index) {
                                  final week = metrics.budgetWeeks![index];
                                  final isCurrent =
                                      metrics.currentWeekNumber ==
                                          week.weekNumber;
                                  final startStr =
                                      '${week.startDate.day}/${week.startDate.month}';
                                  final endStr =
                                      '${week.endDate.day}/${week.endDate.month}';

                                  return Card(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    color: isCurrent
                                        ? theme.colorScheme.primaryContainer
                                            .withValues(alpha: 0.3)
                                        : null,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: isCurrent
                                          ? BorderSide(
                                              color: theme.colorScheme.primary)
                                          : BorderSide.none,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                'Semana ${week.weekNumber} ($startStr - $endStr)',
                                                style: TextStyle(
                                                  fontWeight: isCurrent
                                                      ? FontWeight.bold
                                                      : FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              if (isCurrent) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        theme.colorScheme.primary,
                                                    borderRadius:
                                                        BorderRadius.circular(6),
                                                  ),
                                                  child: const Text(
                                                    'Actual 📍',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              _buildWeekStatColumn(
                                                'Previsto',
                                                Formatters.formatCurrency(
                                                    week.adjustedAmount),
                                                Colors.grey[700]!,
                                              ),
                                              _buildWeekStatColumn(
                                                'Gastado',
                                                Formatters.formatCurrency(
                                                    week.spentAmount),
                                                week.spentAmount >
                                                        week.adjustedAmount
                                                    ? Colors.red
                                                    : Colors.orange[800]!,
                                              ),
                                              _buildWeekStatColumn(
                                                'Restante',
                                                Formatters.formatCurrency(
                                                    week.adjustedAmount -
                                                        week.spentAmount),
                                                (week.adjustedAmount -
                                                            week.spentAmount) >=
                                                        0
                                                    ? Colors.green[700]!
                                                    : Colors.red[700]!,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // 3. Gráfica de Gastos por Categoría
                    CategoryChartWidget(
                      categoryExpenses: categoryExpenses,
                      totalSpent: metrics.totalSpent,
                    ),

                    const SizedBox(height: 16),

                    // 4. Gastos Extraordinarios Filtrados
                    ExtraordinaryExpensesWidget(
                      transactions: extraordinaryExpenses,
                      totalExtraordinarySpent: metrics.totalExtraordinarySpent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
