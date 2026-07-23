import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:finanzas_compartidas/core/errors/exceptions.dart';
import 'package:finanzas_compartidas/features/transactions/data/datasources/transaction_remote_data_source.dart';
import 'package:finanzas_compartidas/features/transactions/data/models/transaction_model.dart';
import 'package:finanzas_compartidas/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockTransactionRemoteDataSource extends Mock
    implements TransactionRemoteDataSource {}

class MockConnectivity extends Mock implements Connectivity {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late TransactionRepositoryImpl repository;
  late MockTransactionRemoteDataSource mockRemoteDataSource;
  late MockConnectivity mockConnectivity;
  late MockSharedPreferences mockPrefs;

  const tUserId = 'user-123';
  final tDate = DateTime(2026, 7, 22);
  final tTransactionModel = TransactionModel(
    id: 'tx-1',
    walletId: 'w-1',
    userId: tUserId,
    amount: 25.50,
    category: 'Comida',
    isShared: false,
    isExtraordinary: false,
    description: 'Almuerzo',
    createdAt: tDate,
  );

  setUpAll(() {
    registerFallbackValue(tTransactionModel);
  });

  setUp(() {
    mockRemoteDataSource = MockTransactionRemoteDataSource();
    mockConnectivity = MockConnectivity();
    mockPrefs = MockSharedPreferences();

    when(() => mockConnectivity.onConnectivityChanged)
        .thenAnswer((_) => Stream.value([ConnectivityResult.wifi]));

    repository = TransactionRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      connectivity: mockConnectivity,
      prefs: mockPrefs,
    );
  });

  group('getTransactions', () {
    test('should return list of TransactionModel when remote call is successful',
        () async {
      when(() => mockRemoteDataSource.getTransactions(
            userId: tUserId,
            groupId: null,
          )).thenAnswer((_) async => [tTransactionModel]);

      final result = await repository.getTransactions(userId: tUserId);

      expect(result, equals([tTransactionModel]));
      verify(() => mockRemoteDataSource.getTransactions(
            userId: tUserId,
            groupId: null,
          )).called(1);
    });

    test('should throw ServerException when remote call fails', () async {
      when(() => mockRemoteDataSource.getTransactions(
            userId: tUserId,
            groupId: null,
          )).thenThrow(Exception('Remote Error'));

      expect(
        () => repository.getTransactions(userId: tUserId),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('createTransaction online', () {
    test('should return created model when online and remote call succeeds',
        () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(() => mockRemoteDataSource.createTransaction(any()))
          .thenAnswer((_) async => tTransactionModel);

      final result = await repository.createTransaction(tTransactionModel);

      expect(result, equals(tTransactionModel));
      verify(() => mockRemoteDataSource.createTransaction(any())).called(1);
    });
  });
}
