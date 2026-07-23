import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_remote_data_source.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource remoteDataSource;
  final Connectivity connectivity;
  final SharedPreferences prefs;

  static const String _queueKey = 'offline_transactions_queue';

  TransactionRepositoryImpl({
    required this.remoteDataSource,
    required this.connectivity,
    required this.prefs,
  }) {
    // Listen for connectivity changes to sync offline queue
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
      return createdModel;
    } catch (e) {
      // If remote creation failed due to network error, queue offline
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
        await remoteDataSource.createTransaction(model);
      } catch (_) {
        remainingQueue.add(rawJson);
      }
    }

    await prefs.setStringList(_queueKey, remainingQueue);
  }

  Future<void> _enqueueOfflineTransaction(TransactionModel model) async {
    final queue = prefs.getStringList(_queueKey) ?? [];
    final jsonStr = json.encode(model.toJson());
    queue.add(jsonStr);
    await prefs.setStringList(_queueKey, queue);
  }
}
