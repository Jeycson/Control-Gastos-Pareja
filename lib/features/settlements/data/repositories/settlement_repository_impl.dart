import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/member_balance.dart';
import '../../domain/entities/settlement_payment.dart';
import '../../domain/repositories/settlement_repository.dart';
import '../datasources/settlement_remote_data_source.dart';

class SettlementRepositoryImpl implements SettlementRepository {
  final SettlementRemoteDataSource remoteDataSource;

  SettlementRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<MemberBalance>> getGroupMemberBalances(String groupId) async {
    try {
      return await remoteDataSource.getGroupMemberBalances(groupId);
    } catch (e) {
      throw ServerException(message: 'Error al obtener balances de miembros: $e');
    }
  }

  @override
  Future<List<SettlementPayment>> getGroupSettlementPayments(
    String groupId,
  ) async {
    try {
      return await remoteDataSource.getGroupSettlementPayments(groupId);
    } catch (e) {
      throw ServerException(message: 'Error al calcular transferencias: $e');
    }
  }

  @override
  Future<void> markAsPaid({
    required String groupId,
    required SettlementPayment payment,
  }) async {
    try {
      await remoteDataSource.markAsPaid(groupId: groupId, payment: payment);
    } catch (e) {
      throw ServerException(message: 'Error al marcar liquidación como pagada: $e');
    }
  }
}
