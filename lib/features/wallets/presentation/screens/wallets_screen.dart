import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/wallets_provider.dart';
import '../widgets/adjust_balance_dialog.dart';
import '../widgets/create_wallet_dialog.dart';
import '../widgets/wallet_card.dart';

class WalletsScreen extends ConsumerStatefulWidget {
  const WalletsScreen({super.key});

  @override
  ConsumerState<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends ConsumerState<WalletsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(walletsNotifierProvider.notifier).loadWallets();
    });
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateWalletDialog(
        onCreate: ({
          required String name,
          required type,
          required double initialBalance,
          required bool isShared,
        }) async {
          final messenger = ScaffoldMessenger.of(context);
          final success =
              await ref.read(walletsNotifierProvider.notifier).createWallet(
                    name: name,
                    type: type,
                    initialBalance: initialBalance,
                    isShared: isShared,
                  );

          if (success) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Billetera creada con éxito.')),
            );
          }
        },
      ),
    );
  }

  void _showAdjustBalanceDialog(String walletId, double currentBalance) {
    showDialog(
      context: context,
      builder: (context) => AdjustBalanceDialog(
        currentBalance: currentBalance,
        onConfirm: (newBalance) async {
          final messenger = ScaffoldMessenger.of(context);
          final success =
              await ref.read(walletsNotifierProvider.notifier).updateBalance(
                    walletId: walletId,
                    newBalance: newBalance,
                  );

          if (success) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Saldo actualizado correctamente.')),
            );
          }
        },
      ),
    );
  }

  void _confirmDeleteWallet(String walletId, String walletName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Billetera'),
        content: Text('¿Estás seguro de que deseas eliminar "$walletName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(context).pop();
              final success = await ref
                  .read(walletsNotifierProvider.notifier)
                  .deleteWallet(walletId);

              if (success) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Billetera eliminada.')),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walletsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Billeteras'),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(walletsNotifierProvider.notifier).loadWallets(),
        child: state.isLoading && state.wallets.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.wallets.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tienes billeteras creadas',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Crea tu primera billetera de efectivo o tarjeta para comenzar a gestionar tus finanzas.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _showCreateDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Crear Billetera'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.wallets.length,
                    itemBuilder: (context, index) {
                      final wallet = state.wallets[index];
                      return WalletCard(
                        wallet: wallet,
                        onAdjustBalance: () => _showAdjustBalanceDialog(
                          wallet.id,
                          wallet.balance,
                        ),
                        onDelete: () => _confirmDeleteWallet(
                          wallet.id,
                          wallet.name,
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Billetera'),
      ),
    );
  }
}
