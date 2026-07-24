import 'package:finanzas_compartidas/features/transactions/data/datasources/transaction_realtime_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockRealtimeChannel extends Mock implements RealtimeChannel {}

void main() {
  late MockSupabaseClient mockSupabaseClient;

  setUpAll(() {
    registerFallbackValue(PostgresChangeEvent.all);
    registerFallbackValue(
      const PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'group_id',
        value: 'dummy',
      ),
    );
  });

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
  });

  test('TransactionRealtimeDataSourceImpl initializes broadcast stream', () async {
    final mockChannel = MockRealtimeChannel();
    when(() => mockSupabaseClient.channel(any())).thenReturn(mockChannel);
    when(() => mockChannel.onPostgresChanges(
          event: any(named: 'event'),
          schema: any(named: 'schema'),
          table: any(named: 'table'),
          filter: any(named: 'filter'),
          callback: any(named: 'callback'),
        )).thenReturn(mockChannel);
    when(() => mockChannel.subscribe(any())).thenReturn(mockChannel);
    when(() => mockSupabaseClient.removeChannel(mockChannel))
        .thenAnswer((_) async => 'ok');

    final dataSource = TransactionRealtimeDataSourceImpl(mockSupabaseClient);
    final stream = dataSource.subscribeToGroupTransactions('group123');

    expect(stream, isA<Stream>());
  });
}
