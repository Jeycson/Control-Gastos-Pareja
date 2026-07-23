import 'package:flutter/material.dart';
import '../../domain/entities/wallet_entity.dart';

class CreateWalletDialog extends StatefulWidget {
  final Function({
    required String name,
    required WalletType type,
    required double initialBalance,
    required bool isShared,
  }) onCreate;

  const CreateWalletDialog({
    super.key,
    required this.onCreate,
  });

  @override
  State<CreateWalletDialog> createState() => _CreateWalletDialogState();
}

class _CreateWalletDialogState extends State<CreateWalletDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0.00');
  WalletType _selectedType = WalletType.card;
  bool _isShared = false;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final balance = double.tryParse(_balanceController.text.trim()) ?? 0.0;
      widget.onCreate(
        name: _nameController.text.trim(),
        type: _selectedType,
        initialBalance: balance,
        isShared: _isShared,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva Billetera'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la billetera',
                  hintText: 'Ej. Tarjeta Débito, Efectivo diario',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa un nombre para la billetera.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<WalletType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de billetera',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: WalletType.card,
                    child: Row(
                      children: [
                        Icon(Icons.credit_card),
                        SizedBox(width: 8),
                        Text('Tarjeta'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: WalletType.cash,
                    child: Row(
                      children: [
                        Icon(Icons.payments_outlined),
                        SizedBox(width: 8),
                        Text('Efectivo'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Balance inicial',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el balance inicial.';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Ingresa un número válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('¿Billetera compartida?'),
                subtitle: const Text('Visible para miembros de tu grupo'),
                value: _isShared,
                onChanged: (val) {
                  setState(() {
                    _isShared = val;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Crear'),
        ),
      ],
    );
  }
}
