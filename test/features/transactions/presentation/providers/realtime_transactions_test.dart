import 'package:finanzas_compartidas/features/transactions/domain/entities/transaction_entity.dart';
import 'package:finanzas_compartidas/features/transactions/domain/usecases/create_transaction_usecase.dart';
import 'package:finanzas_compartidas/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:finanzas_compartidas/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetTransactionsUseCase extends Mock implements GetTransactionsUseCase {}
class MockCreateTransactionUseCase extends Mock
    implements CreateTransactionUseCase {}

void main() {
  late MockGetTransactionsUseCase mockGetTxUseCase;
  late MockCreateTransactionUseCase mockCreateTxUseCase;

  setUp(() {
    mockGetTxUseCase = MockGetTransactionsUseCase();
    mockCreateTxUseCase = MockCreateTransactionUseCase();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        getTransactionsUseCaseProvider.overrideWithValue(mockGetTxUseCase),
        createTransactionUseCaseProvider.overrideWithValue(mockCreateTxUseCase),
      ],
    );
  }

  group('TransactionsNotifier Incremental Upsert & Deduplication Tests', () {
    test('upsertTransaction updates existing item in-place without duplicate entries', () {
      final container = makeContainer();
      final notifier = container.read(transactionsNotifierProvider.notifier);

      final tx1 = TransactionEntity(
        id: 'tx-100',
        walletId: 'w1',
        userId: 'u1',
        groupId: 'g1',
        amount: 50.0,
        category: 'Comida',
        isShared: true,
        isExtraordinary: false,
        description: 'Original',
        createdAt: DateTime(2026, 7, 20),
      );

      // 1. Add initial transaction
      notifier.upsertTransaction(tx1);
      var state = container.read(transactionsNotifierProvider);
      expect(state.transactions.length, 1);
      expect(state.transactions.first.description, 'Original');

      // 2. Receive UPDATE event for same transaction id
      final tx1Updated = tx1.copyWith(
        amount: 75.0,
        description: 'Actualizado vía Realtime',
      );
      notifier.upsertTransaction(tx1Updated);

      state = container.read(transactionsNotifierProvider);
      expect(state.transactions.length, 1); // No duplicate entry created!
      expect(state.transactions.first.amount, 75.0);
      expect(state.transactions.first.description, 'Actualizado vía Realtime');
    });

    test('upsertTransaction prepends new incoming Realtime transaction and sorts by date', () {
      final container = makeContainer();
      final notifier = container.read(transactionsNotifierProvider.notifier);

      final oldTx = TransactionEntity(
        id: 'tx-1',
        walletId: 'w1',
        userId: 'u1',
        amount: 20.0,
        category: 'Comida',
        isShared: true,
        isExtraordinary: false,
        description: 'Viejo',
        createdAt: DateTime(2026, 7, 1),
      );

      final newTx = TransactionEntity(
        id: 'tx-2',
        walletId: 'w1',
        userId: 'u2',
        amount: 100.0,
        category: 'Transporte',
        isShared: true,
        isExtraordinary: true,
        description: 'Nuevo desde otro usuario',
        createdAt: DateTime(2026, 7, 22),
      );

      notifier.upsertTransaction(oldTx);
      notifier.upsertTransaction(newTx);

      final state = container.read(transactionsNotifierProvider);
      expect(state.transactions.length, 2);
      expect(state.transactions.first.id, 'tx-2'); // Sorted newer first
    });

    test('removeTransaction deletes specified transaction from Riverpod state', () {
      final container = makeContainer();
      final notifier = container.read(transactionsNotifierProvider.notifier);

      final tx = TransactionEntity(
        id: 'tx-999',
        walletId: 'w1',
        userId: 'u1',
        amount: 40.0,
        category: 'Salud',
        isShared: true,
        isExtraordinary: false,
        description: 'Eliminado',
        createdAt: DateTime.now(),
      );

      notifier.upsertTransaction(tx);
      expect(container.read(transactionsNotifierProvider).transactions.length, 1);

      notifier.removeTransaction('tx-999');
      expect(container.read(transactionsNotifierProvider).transactions.length, 0);
    });
  });
}
