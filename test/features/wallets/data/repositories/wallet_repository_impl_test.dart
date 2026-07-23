import 'package:finanzas_compartidas/core/errors/exceptions.dart';
import 'package:finanzas_compartidas/features/wallets/data/datasources/wallet_remote_data_source.dart';
import 'package:finanzas_compartidas/features/wallets/data/models/wallet_model.dart';
import 'package:finanzas_compartidas/features/wallets/data/repositories/wallet_repository_impl.dart';
import 'package:finanzas_compartidas/features/wallets/domain/entities/wallet_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWalletRemoteDataSource extends Mock
    implements WalletRemoteDataSource {}

void main() {
  late WalletRepositoryImpl repository;
  late MockWalletRemoteDataSource mockRemoteDataSource;

  const tUserId = 'user-123';
  const tWalletId = 'wallet-123';
  const tWalletModel = WalletModel(
    id: tWalletId,
    userId: tUserId,
    name: 'Tarjeta Débito',
    type: WalletType.card,
    balance: 500.0,
    isShared: false,
  );

  setUpAll(() {
    registerFallbackValue(tWalletModel);
  });

  setUp(() {
    mockRemoteDataSource = MockWalletRemoteDataSource();
    repository = WalletRepositoryImpl(mockRemoteDataSource);
  });

  group('getWallets', () {
    test('should return list of WalletEntity when remote call is successful',
        () async {
      when(() => mockRemoteDataSource.getWallets(tUserId))
          .thenAnswer((_) async => [tWalletModel]);

      final result = await repository.getWallets(tUserId);

      expect(result, equals([tWalletModel]));
      verify(() => mockRemoteDataSource.getWallets(tUserId)).called(1);
    });

    test('should throw ServerException when remote call fails', () async {
      when(() => mockRemoteDataSource.getWallets(tUserId))
          .thenThrow(Exception('DB Error'));

      expect(
        () => repository.getWallets(tUserId),
        throwsA(isA<ServerException>()),
      );
      verify(() => mockRemoteDataSource.getWallets(tUserId)).called(1);
    });
  });

  group('createWallet', () {
    test('should return created WalletEntity when remote call is successful',
        () async {
      when(() => mockRemoteDataSource.createWallet(any()))
          .thenAnswer((_) async => tWalletModel);

      final result = await repository.createWallet(tWalletModel);

      expect(result, equals(tWalletModel));
      verify(() => mockRemoteDataSource.createWallet(any())).called(1);
    });

    test('should throw ServerException when createWallet fails', () async {
      when(() => mockRemoteDataSource.createWallet(any()))
          .thenThrow(Exception('Insert Error'));

      expect(
        () => repository.createWallet(tWalletModel),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('updateBalance', () {
    test('should complete successfully when remote update completes', () async {
      when(() => mockRemoteDataSource.updateBalance(
            walletId: tWalletId,
            newBalance: 1000.0,
          )).thenAnswer((_) async {});

      await repository.updateBalance(
        walletId: tWalletId,
        newBalance: 1000.0,
      );

      verify(() => mockRemoteDataSource.updateBalance(
            walletId: tWalletId,
            newBalance: 1000.0,
          )).called(1);
    });

    test('should throw ServerException when update fails', () async {
      when(() => mockRemoteDataSource.updateBalance(
            walletId: tWalletId,
            newBalance: 1000.0,
          )).thenThrow(Exception('Update Error'));

      expect(
        () =>
            repository.updateBalance(walletId: tWalletId, newBalance: 1000.0),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('deleteWallet', () {
    test('should complete successfully when remote delete completes', () async {
      when(() => mockRemoteDataSource.deleteWallet(tWalletId))
          .thenAnswer((_) async {});

      await repository.deleteWallet(tWalletId);

      verify(() => mockRemoteDataSource.deleteWallet(tWalletId)).called(1);
    });

    test('should throw ServerException when delete fails', () async {
      when(() => mockRemoteDataSource.deleteWallet(tWalletId))
          .thenThrow(Exception('Delete Error'));

      expect(
        () => repository.deleteWallet(tWalletId),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
