import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/formatters.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/presentation/providers/groups_provider.dart';
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
      final groups = ref.read(groupsNotifierProvider).groups;
      if (groups.isNotEmpty && mounted) {
        setState(() {
          _selectedGroupId = groups.first.id;
        });
      }
      unawaited(ref
          .read(dashboardNotifierProvider(_selectedGroupId).notifier)
          .loadDashboard());
    });
  }

  Future<void> _onRefresh() async {
    await ref
        .read(dashboardNotifierProvider(_selectedGroupId).notifier)
        .loadDashboard(isRefresh: true);
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

                    const SizedBox(height: 16),

                    // 2. Gráfica de Gastos por Categoría
                    CategoryChartWidget(
                      categoryExpenses: categoryExpenses,
                      totalSpent: metrics.totalSpent,
                    ),

                    const SizedBox(height: 16),

                    // 3. Gastos Extraordinarios Filtrados
                    ExtraordinaryExpensesWidget(
                      transactions: extraordinaryExpenses,
                      totalExtraordinarySpent: metrics.totalExtraordinarySpent,
                    ),

                    const SizedBox(height: 24),

                    // Accesos Rápidos
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => context.push('/add-transaction'),
                          icon: const Icon(Icons.flash_on),
                          label: const Text('Nuevo Gasto ⚡'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                theme.colorScheme.primaryContainer,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                        if (_selectedGroupId != null)
                          ElevatedButton.icon(
                            onPressed: () => context.push(
                                '/settlements/${_selectedGroupId!}'),
                            icon: const Icon(Icons.handshake_outlined),
                            label: const Text('Cuentas Claras 🤝'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/transactions'),
                          icon: const Icon(Icons.receipt_long_outlined),
                          label: const Text('Transacciones'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/groups'),
                          icon: const Icon(Icons.groups_outlined),
                          label: const Text('Grupos'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/wallets'),
                          icon:
                              const Icon(Icons.account_balance_wallet_outlined),
                          label: const Text('Billeteras'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
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
