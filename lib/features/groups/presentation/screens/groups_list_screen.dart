import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/formatters.dart';
import '../providers/groups_provider.dart';
import '../widgets/join_group_dialog.dart';

class GroupsListScreen extends ConsumerStatefulWidget {
  const GroupsListScreen({super.key});

  @override
  ConsumerState<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends ConsumerState<GroupsListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(groupsNotifierProvider.notifier).loadUserGroups();
    });
  }

  void _showJoinDialog() {
    showDialog(
      context: context,
      builder: (context) => JoinGroupDialog(
        onJoin: (code) async {
          final messenger = ScaffoldMessenger.of(context);
          final group =
              await ref.read(groupsNotifierProvider.notifier).joinGroup(code);

          if (group != null) {
            messenger.showSnackBar(
              SnackBar(content: Text('Te has unido al grupo "${group.name}".')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Grupos de Gastos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Unirse con código',
            onPressed: _showJoinDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(groupsNotifierProvider.notifier).loadUserGroups(),
        child: state.isLoading && state.groups.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.groups.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No perteneces a ningún grupo',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Crea un grupo para compartir presupuestos con tu pareja o roomies, o únete usando un código.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => context.push('/create-group'),
                                icon: const Icon(Icons.add),
                                label: const Text('Crear Grupo'),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: _showJoinDialog,
                                icon: const Icon(Icons.group_add_outlined),
                                label: const Text('Unirse'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.groups.length,
                    itemBuilder: (context, index) {
                      final group = state.groups[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            child: const Icon(Icons.group),
                          ),
                          title: Text(
                            group.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Presupuesto: ${Formatters.formatCurrency(group.budgetTotal)} (${group.weeksCount} semanas)',
                              ),
                              Text(
                                'Código: ${group.inviteCode}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/group-summary/${group.id}'),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-group'),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Grupo'),
      ),
    );
  }
}
