import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/realtime_transaction_event.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_realtime_data_source.dart';
import '../datasources/transaction_remote_data_source.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource remoteDataSource;
  final TransactionRealtimeDataSource? realtimeDataSource;
  final Connectivity connectivity;
  final SharedPreferences prefs;

  static const String _queueKey = 'offline_transactions_queue';
  final Set<String> _syncedTxIds = {};

  TransactionRepositoryImpl({
    required this.remoteDataSource,
    this.realtimeDataSource,
    required this.connectivity,
    required this.prefs,
  }) {
    connectivity.onConnectivityChanged.listen((results) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        syncOfflineQueue();
      }
    });
  }

  @override
  Future<List<TransactionEntity>> getTransactions({
    required String userId,
    String? groupId,
  }) async {
    try {
      return await remoteDataSource.getTransactions(
        userId: userId,
        groupId: groupId,
      );
    } catch (e) {
      throw ServerException(message: 'Error al obtener transacciones: $e');
    }
  }

  @override
  Future<TransactionEntity> createTransaction(
      TransactionEntity transaction) async {
    final model = TransactionModel.fromEntity(transaction);

    final connectivityResult = await connectivity.checkConnectivity();
    final isOffline =
        connectivityResult.every((r) => r == ConnectivityResult.none);

    if (isOffline) {
      await _enqueueOfflineTransaction(model);
      return model;
    }

    try {
      final createdModel = await remoteDataSource.createTransaction(model);
      _syncedTxIds.add(createdModel.id);
      return createdModel;
    } catch (e) {
      await _enqueueOfflineTransaction(model);
      return model;
    }
  }

  @override
  Future<void> syncOfflineQueue() async {
    final queueJson = prefs.getStringList(_queueKey) ?? [];
    if (queueJson.isEmpty) return;

    final remainingQueue = <String>[];

    for (final rawJson in queueJson) {
      try {
        final jsonMap = json.decode(rawJson) as Map<String, dynamic>;
        final model = TransactionModel.fromJson(jsonMap);

        // Deduplication check: skip if already synced via Realtime or previous batch
        if (_syncedTxIds.contains(model.id)) {
          continue;
        }

        final created = await remoteDataSource.createTransaction(model);
        _syncedTxIds.add(created.id);
        _syncedTxIds.add(model.id);
      } catch (_) {
        remainingQueue.add(rawJson);
      }
    }

    await prefs.setStringList(_queueKey, remainingQueue);
  }

  @override
  Stream<RealtimeTransactionEvent> subscribeToGroupTransactions(
      String groupId) {
    if (realtimeDataSource != null) {
      return realtimeDataSource!.subscribeToGroupTransactions(groupId);
    }
    return const Stream.empty();
  }

  Future<void> _enqueueOfflineTransaction(TransactionModel model) async {
    final queue = prefs.getStringList(_queueKey) ?? [];

    // Deduplication check: check if already in queue by id
    final existsInQueue = queue.any((item) {
      try {
        final map = json.decode(item) as Map<String, dynamic>;
        return map['id'] == model.id;
      } catch (_) {
        return false;
      }
    });

    if (existsInQueue) return;

    final jsonStr = json.encode(model.toJson());
    queue.add(jsonStr);
    await prefs.setStringList(_queueKey, queue);
  }
}
