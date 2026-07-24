import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../providers/settlements_provider.dart';

class SettlementsScreen extends ConsumerStatefulWidget {
  final String groupId;

  const SettlementsScreen({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<SettlementsScreen> createState() => _SettlementsScreenState();
}

class _SettlementsScreenState extends ConsumerState<SettlementsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(settlementsNotifierProvider.notifier)
          .loadSettlements(widget.groupId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settlementsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuentas Claras 🤝'),
      ),
      body: state.isLoading && state.memberBalances.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref
                  .read(settlementsNotifierProvider.notifier)
                  .loadSettlements(widget.groupId),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resumen de Aportes
                    Text(
                      'Resumen de Aportes',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.memberBalances.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final mb = state.memberBalances[index];
                          final isPositive = mb.netBalance >= 0;

                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                mb.userName.isNotEmpty
                                    ? mb.userName[0].toUpperCase()
                                    : 'U',
                              ),
                            ),
                            title: Text(mb.userName),
                            subtitle: Text(
                              'Aportó: ${Formatters.formatCurrency(mb.totalContributed)}',
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  isPositive ? 'A favor' : 'En contra',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '${isPositive ? '+' : ''}${Formatters.formatCurrency(mb.netBalance)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isPositive ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Transferencias Mínimas Sugeridas
                    Text(
                      'Pagos Mínimos para Saldar Cuentas',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    state.payments.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.check_circle_outline,
                                    color: Colors.green, size: 48),
                                SizedBox(height: 8),
                                Text(
                                  '¡Las cuentas están al día!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.green,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Todos los miembros han aportado en partes iguales.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.payments.length,
                            itemBuilder: (context, index) {
                              final payment = state.payments[index];

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.swap_horiz,
                                            color: Colors.blue,
                                            size: 28,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: RichText(
                                              text: TextSpan(
                                                style: DefaultTextStyle.of(context)
                                                    .style
                                                    .copyWith(fontSize: 15),
                                                children: [
                                                  TextSpan(
                                                    text: payment.fromUserName,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  const TextSpan(
                                                      text: ' debe transferir '),
                                                  TextSpan(
                                                    text: Formatters.formatCurrency(
                                                        payment.amount),
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.blue,
                                                    ),
                                                  ),
                                                  const TextSpan(text: ' a '),
                                                  TextSpan(
                                                    text: payment.toUserName,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            final messenger =
                                                ScaffoldMessenger.of(context);
                                            final success = await ref
                                                .read(settlementsNotifierProvider
                                                    .notifier)
                                                .markAsPaid(
                                                  groupId: widget.groupId,
                                                  payment: payment,
                                                );
                                            if (success) {
                                              messenger.showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Transferencia marcada como pagada. ¡Cuentas actualizadas! 🤝',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          icon: const Icon(Icons.check, size: 18),
                                          label: const Text('Marcar como Pagado'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                          ),
                                        ),
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
    );
  }
}
