import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/groups_provider.dart';

class GroupSummaryScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupSummaryScreen({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<GroupSummaryScreen> createState() => _GroupSummaryScreenState();
}

class _GroupSummaryScreenState extends ConsumerState<GroupSummaryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(groupsNotifierProvider.notifier).loadGroupSummary(widget.groupId);
    });
  }

  void _copyInviteCode(String code) {
    final messenger = ScaffoldMessenger.of(context);
    Clipboard.setData(ClipboardData(text: code));
    messenger.showSnackBar(
      SnackBar(content: Text('Código de invitación "$code" copiado al portapapeles.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupsNotifierProvider);
    final summary = state.selectedGroupSummary;

    return Scaffold(
      appBar: AppBar(
        title: Text(summary?.group.name ?? 'Resumen del Grupo'),
      ),
      body: state.isLoading && summary == null
          ? const Center(child: CircularProgressIndicator())
          : summary == null
              ? const Center(child: Text('No se pudo cargar la información del grupo.'))
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(groupsNotifierProvider.notifier)
                      .loadGroupSummary(widget.groupId),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        summary.group.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () =>
                                          _copyInviteCode(summary.group.inviteCode),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Código: ${summary.group.inviteCode}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Icon(Icons.copy, size: 16),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatItem(
                                      context,
                                      'Presupuesto Total',
                                      Formatters.formatCurrency(
                                          summary.group.budgetTotal),
                                      Colors.blue,
                                    ),
                                    _buildStatItem(
                                      context,
                                      'Gastado a Hoy',
                                      Formatters.formatCurrency(
                                          summary.totalSpent),
                                      Colors.orange,
                                    ),
                                    _buildStatItem(
                                      context,
                                      'Disponible',
                                      Formatters.formatCurrency(
                                        summary.group.budgetTotal -
                                            summary.totalSpent,
                                      ),
                                      (summary.group.budgetTotal - summary.totalSpent) >= 0
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                LinearProgressIndicator(
                                  value: summary.group.budgetTotal > 0
                                      ? (summary.totalSpent /
                                              summary.group.budgetTotal)
                                          .clamp(0.0, 1.0)
                                      : 0.0,
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.hub_outlined, color: Colors.blue),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Modelo de Fondo Compartido: Calculado dinámicamente sobre las transacciones compartidas (is_shared = true) de los miembros, evitando duplicación en billeteras.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Miembros (${summary.members.length})',
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
                            itemCount: summary.members.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final member = summary.members[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text(
                                    member.fullName.isNotEmpty
                                        ? member.fullName[0].toUpperCase()
                                        : 'U',
                                  ),
                                ),
                                title: Text(member.fullName),
                                trailing: Chip(
                                  label: Text(
                                    member.role == 'admin'
                                        ? 'Administrador'
                                        : 'Miembro',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Semanas de Presupuesto (${summary.budgetWeeks.length})',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: summary.budgetWeeks.length,
                          itemBuilder: (context, index) {
                            final week = summary.budgetWeeks[index];
                            final startStr =
                                '${week.startDate.day}/${week.startDate.month}';
                            final endStr =
                                '${week.endDate.day}/${week.endDate.month}';

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text('Semana ${week.weekNumber} ($startStr - $endStr)'),
                                subtitle: Text(
                                  'Planificado: ${Formatters.formatCurrency(week.plannedAmount)}',
                                ),
                                trailing: Text(
                                  Formatters.formatCurrency(week.spentAmount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
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

  Widget _buildStatItem(
      BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
