import 'dart:async';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/realtime_transaction_event.dart';
import '../models/transaction_model.dart';

abstract class TransactionRealtimeDataSource {
  Stream<RealtimeTransactionEvent> subscribeToGroupTransactions(String groupId);
}

class TransactionRealtimeDataSourceImpl implements TransactionRealtimeDataSource {
  final SupabaseClient supabaseClient;

  TransactionRealtimeDataSourceImpl(this.supabaseClient);

  @override
  Stream<RealtimeTransactionEvent> subscribeToGroupTransactions(String groupId) {
    late StreamController<RealtimeTransactionEvent> controller;
    RealtimeChannel? channel;
    Timer? retryTimer;
    int attempt = 0;
    bool isClosed = false;

    void cleanup() {
      retryTimer?.cancel();
      retryTimer = null;
      if (channel != null) {
        supabaseClient.removeChannel(channel!);
        channel = null;
      }
    }

    void subscribe() {
      if (isClosed) return;
      cleanup();

      final channelName = 'public:transactions:group_id=eq.$groupId';

      channel = supabaseClient.channel(channelName);

      channel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'transactions',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'group_id',
              value: groupId,
            ),
            callback: (payload) {
              try {
                final eventType = payload.eventType;
                final newRecord = payload.newRecord;
                final oldRecord = payload.oldRecord;

                if (eventType == PostgresChangeEvent.insert && newRecord.isNotEmpty) {
                  final model = TransactionModel.fromJson(newRecord);
                  if (!controller.isClosed) {
                    controller.add(RealtimeTransactionEvent(
                      type: RealtimeEventType.insert,
                      transaction: model,
                    ));
                  }
                } else if (eventType == PostgresChangeEvent.update && newRecord.isNotEmpty) {
                  final model = TransactionModel.fromJson(newRecord);
                  if (!controller.isClosed) {
                    controller.add(RealtimeTransactionEvent(
                      type: RealtimeEventType.update,
                      transaction: model,
                    ));
                  }
                } else if (eventType == PostgresChangeEvent.delete && oldRecord.isNotEmpty) {
                  final model = TransactionModel.fromJson(oldRecord);
                  if (!controller.isClosed) {
                    controller.add(RealtimeTransactionEvent(
                      type: RealtimeEventType.delete,
                      transaction: model,
                    ));
                  }
                }
              } catch (_) {
                // Ignore parse errors on partial frames
              }
            },
          )
          .subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          attempt = 0;
        } else if (status == RealtimeSubscribeStatus.closed ||
            status == RealtimeSubscribeStatus.channelError ||
            status == RealtimeSubscribeStatus.timedOut) {
          if (isClosed) return;
          // Exponential backoff retry: 1s, 2s, 4s, 8s, 16s, max 32s
          attempt++;
          final seconds = min(pow(2, attempt - 1).toInt(), 32);
          final jitterMs = Random().nextInt(500);
          final delay = Duration(seconds: seconds, milliseconds: jitterMs);

          retryTimer?.cancel();
          retryTimer = Timer(delay, () {
            if (!isClosed) {
              subscribe();
            }
          });
        }
      });
    }

    controller = StreamController<RealtimeTransactionEvent>.broadcast(
      onListen: () {
        subscribe();
      },
      onCancel: () {
        isClosed = true;
        cleanup();
        controller.close();
      },
    );

    return controller.stream;
  }
}
