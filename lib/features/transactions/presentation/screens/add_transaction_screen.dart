import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/presentation/providers/groups_provider.dart';
import '../../../wallets/domain/entities/wallet_entity.dart';
import '../../../wallets/presentation/providers/wallets_provider.dart';
import '../../domain/entities/transaction_entity.dart';
import '../providers/transactions_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState
    extends ConsumerState<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'Comida';
  bool _isShared = false;
  bool _isExtraordinary = false;
  WalletEntity? _selectedWallet;
  String? _selectedGroupId;

  final Map<String, IconData> _categories = const {
    'Comida': Icons.restaurant,
    'Transporte': Icons.directions_bus,
    'Servicios': Icons.lightbulb_outline,
    'Entretenimiento': Icons.movie_outlined,
    'Salud': Icons.local_hospital_outlined,
    'Otros': Icons.category_outlined,
  };

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(walletsNotifierProvider.notifier).loadWallets();
      await ref.read(groupsNotifierProvider.notifier).loadUserGroups();
      final wallets = ref.read(walletsNotifierProvider).wallets;
      if (wallets.isNotEmpty && mounted) {
        setState(() {
          _selectedWallet = wallets.first;
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onKeypadTap(String value) {
    if (value == 'DEL') {
      if (_amountController.text.isNotEmpty) {
        _amountController.text =
            _amountController.text.substring(0, _amountController.text.length - 1);
      }
    } else if (value == '.') {
      if (!_amountController.text.contains('.')) {
        _amountController.text = '${_amountController.text}.';
      }
    } else {
      _amountController.text = '${_amountController.text}$value';
    }
    setState(() {});
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto válido mayor a 0.')),
      );
      return;
    }

    if (_selectedWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una billetera de origen.')),
      );
      return;
    }

    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final newTx = TransactionEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      walletId: _selectedWallet!.id,
      userId: user.id,
      groupId: _isShared ? _selectedGroupId : null,
      amount: amount,
      category: _selectedCategory,
      isShared: _isShared,
      isExtraordinary: _isExtraordinary,
      description: _descriptionController.text.trim(),
      createdAt: DateTime.now(),
      userName: user.fullName.isNotEmpty ? user.fullName : user.email,
    );

    // Optimistic Save
    final success = await ref
        .read(transactionsNotifierProvider.notifier)
        .addTransaction(newTx);

    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Transacción registrada al instante! ⚡')),
      );
      router.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletsState = ref.watch(walletsNotifierProvider);
    final groupsState = ref.watch(groupsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro Rápido de Gasto ⚡'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Display de Monto Grande
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'Monto del Gasto',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$ ${_amountController.text.isEmpty ? '0' : _amountController.text}',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Selector de Billetera (Chips)
              Text(
                'Selecciona Billetera',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (walletsState.wallets.isEmpty)
                const Text('No tienes billeteras registradas.')
              else
                Wrap(
                  spacing: 8,
                  children: walletsState.wallets.map((wallet) {
                    final isSelected = _selectedWallet?.id == wallet.id;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            wallet.type == WalletType.card
                                ? Icons.credit_card
                                : Icons.payments_outlined,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(wallet.name),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedWallet = wallet;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),

              // Selector de Categoría (Chips con Iconos)
              Text(
                'Categoría',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _categories.entries.map((entry) {
                  final isSelected = _selectedCategory == entry.key;
                  return ChoiceChip(
                    avatar: Icon(entry.value, size: 16),
                    label: Text(entry.key),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = entry.key;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Toggles: ¿Es Compartido? y Extraordinario
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('¿Es gasto compartido?'),
                        subtitle: const Text('Se incluirá en el presupuesto del grupo'),
                        value: _isShared,
                        onChanged: (val) {
                          setState(() {
                            _isShared = val;
                            if (_isShared &&
                                _selectedGroupId == null &&
                                groupsState.groups.isNotEmpty) {
                              _selectedGroupId = groupsState.groups.first.id;
                            }
                          });
                        },
                      ),
                      if (_isShared && groupsState.groups.isNotEmpty) ...[
                        const Divider(height: 1),
                        ListTile(
                          title: const Text('Seleccionar Grupo'),
                          trailing: DropdownButton<String>(
                            value: _selectedGroupId,
                            items: groupsState.groups.map((group) {
                              return DropdownMenuItem(
                                value: group.id,
                                child: Text(group.name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedGroupId = val;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Gasto Extraordinario'),
                        subtitle: const Text('Marcar como no recurrente'),
                        value: _isExtraordinary,
                        onChanged: (val) {
                          setState(() {
                            _isExtraordinary = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Descripción opcional
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción rápida (Opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit_note),
                ),
              ),
              const SizedBox(height: 16),

              // Teclado numérico táctil rápido
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    for (var row in [
                      ['1', '2', '3'],
                      ['4', '5', '6'],
                      ['7', '8', '9'],
                      ['.', '0', 'DEL'],
                    ])
                      Row(
                        children: row.map((key) {
                          return Expanded(
                            child: InkWell(
                              onTap: () => _onKeypadTap(key),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                height: 52,
                                alignment: Alignment.center,
                                child: key == 'DEL'
                                    ? const Icon(Icons.backspace_outlined)
                                    : Text(
                                        key,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Botón Guardar
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: const Text(
                  'Guardar Transacción Instantánea',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
