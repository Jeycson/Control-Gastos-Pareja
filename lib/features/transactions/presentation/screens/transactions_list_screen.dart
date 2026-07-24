import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/formatters.dart';
import '../providers/transactions_provider.dart';

class TransactionsListScreen extends ConsumerStatefulWidget {
  final String? groupId;

  const TransactionsListScreen({
    super.key,
    this.groupId,
  });

  @override
  ConsumerState<TransactionsListScreen> createState() =>
      _TransactionsListScreenState();
}

class _TransactionsListScreenState
    extends ConsumerState<TransactionsListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(transactionsNotifierProvider.notifier)
          .loadTransactions(groupId: widget.groupId);
    });
  }

  final Map<String, IconData> _categoryIcons = const {
    'Comida': Icons.restaurant,
    'Transporte': Icons.directions_bus,
    'Servicios': Icons.lightbulb_outline,
    'Entretenimiento': Icons.movie_outlined,
    'Salud': Icons.local_hospital_outlined,
    'Otros': Icons.category_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionsNotifierProvider);
    final notifier = ref.read(transactionsNotifierProvider.notifier);
    final filtered = state.filteredTransactions;

    if (widget.groupId != null && widget.groupId!.isNotEmpty) {
      ref.watch(realtimeGroupTransactionsProvider(widget.groupId!));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transacciones Recientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: 'Nuevo gasto rápido',
            onPressed: () => context.push('/add-transaction'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  avatar: const Icon(Icons.star, size: 16),
                  label: const Text('Solo Extraordinarios'),
                  selected: state.onlyExtraordinary,
                  onSelected: (_) => notifier.toggleOnlyExtraordinary(),
                ),
                const SizedBox(width: 8),
                ..._categoryIcons.keys.map((category) {
                  final isSelected = state.selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      avatar: Icon(_categoryIcons[category], size: 16),
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (_) => notifier.setCategoryFilter(category),
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1),

          // Lista de Transacciones
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => notifier.loadTransactions(groupId: widget.groupId),
              child: state.isLoading && state.transactions.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay transacciones registradas',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final tx = filtered[index];
                            final icon = _categoryIcons[tx.category] ??
                                Icons.category_outlined;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: tx.isExtraordinary
                                    ? Colors.amber.withValues(alpha: 0.2)
                                    : Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                child: Icon(
                                  icon,
                                  color: tx.isExtraordinary
                                      ? Colors.amber.shade900
                                      : Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      tx.description.isNotEmpty
                                          ? tx.description
                                          : tx.category,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '- ${Formatters.formatCurrency(tx.amount)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Row(
                                children: [
                                  Text(
                                    '${tx.createdAt.day}/${tx.createdAt.month} • ${tx.category}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (tx.userName != null &&
                                      tx.userName!.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '• ${tx.userName}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[800],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                  if (tx.isShared) ...[
                                    const SizedBox(width: 6),
                                    const Chip(
                                      visualDensity: VisualDensity.compact,
                                      label: Text(
                                        'Compartido',
                                        style: TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-transaction'),
        icon: const Icon(Icons.flash_on),
        label: const Text('Nuevo Gasto ⚡'),
      ),
    );
  }
}
