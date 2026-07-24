import 'package:finanzas_compartidas/features/settlements/domain/entities/member_balance.dart';
import 'package:finanzas_compartidas/features/settlements/domain/services/settlement_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SettlementCalculator.calculateMemberBalances', () {
    test('Calcula correctamente los balances netos individuales de cada miembro', () {
      final members = [
        {'userId': 'u1', 'userName': 'Alice'},
        {'userId': 'u2', 'userName': 'Bob'},
      ];

      final sharedTransactions = [
        {'userId': 'u1', 'amount': 100.0},
        {'userId': 'u2', 'amount': 40.0},
      ];

      // Total = 140. Cuota por persona = 70.
      // Alice: aportó 100 -> net = +30
      // Bob: aportó 40 -> net = -30
      final balances = SettlementCalculator.calculateMemberBalances(
        members: members,
        sharedTransactions: sharedTransactions,
      );

      final alice = balances.firstWhere((b) => b.userId == 'u1');
      final bob = balances.firstWhere((b) => b.userId == 'u2');

      expect(alice.netBalance, equals(30.0));
      expect(bob.netBalance, equals(-30.0));
    });
  });

  group('SettlementCalculator.calculateSettlements', () {
    test('Caso 1: 2 Personas (Pareja) -> Deudor paga exactamente al acreedor', () {
      const balances = [
        MemberBalance(
          userId: 'u1',
          userName: 'Alice',
          totalContributed: 100,
          netBalance: 30.0,
        ),
        MemberBalance(
          userId: 'u2',
          userName: 'Bob',
          totalContributed: 40,
          netBalance: -30.0,
        ),
      ];

      final payments = SettlementCalculator.calculateSettlements(balances);

      expect(payments.length, equals(1));
      expect(payments[0].fromUserId, equals('u2'));
      expect(payments[0].fromUserName, equals('Bob'));
      expect(payments[0].toUserId, equals('u1'));
      expect(payments[0].toUserName, equals('Alice'));
      expect(payments[0].amount, equals(30.0));
    });

    test('Caso 2: 3 Personas (Roomies) -> Minimización greedy de pagos', () {
      // Alice: +60, Bob: -40, Charlie: -20
      const balances = [
        MemberBalance(
          userId: 'u1',
          userName: 'Alice',
          totalContributed: 180,
          netBalance: 60.0,
        ),
        MemberBalance(
          userId: 'u2',
          userName: 'Bob',
          totalContributed: 80,
          netBalance: -40.0,
        ),
        MemberBalance(
          userId: 'u3',
          userName: 'Charlie',
          totalContributed: 100,
          netBalance: -20.0,
        ),
      ];

      final payments = SettlementCalculator.calculateSettlements(balances);

      expect(payments.length, equals(2));

      // Mayor deudor (Bob -40) paga primero al mayor acreedor (Alice +60)
      expect(payments[0].fromUserId, equals('u2'));
      expect(payments[0].toUserId, equals('u1'));
      expect(payments[0].amount, equals(40.0));

      // Segundo deudor (Charlie -20) paga lo restante al acreedor (Alice)
      expect(payments[1].fromUserId, equals('u3'));
      expect(payments[1].toUserId, equals('u1'));
      expect(payments[1].amount, equals(20.0));
    });

    test('Caso 3: Cuentas ya saldadas en 0.0 -> Lista de pagos vacía', () {
      const balances = [
        MemberBalance(
          userId: 'u1',
          userName: 'Alice',
          totalContributed: 100,
          netBalance: 0.0,
        ),
        MemberBalance(
          userId: 'u2',
          userName: 'Bob',
          totalContributed: 100,
          netBalance: 0.0,
        ),
      ];

      final payments = SettlementCalculator.calculateSettlements(balances);

      expect(payments, isEmpty);
    });

    test('Caso 4: Múltiples deudores y múltiples acreedores', () {
      // Alice (+50), Bob (+30), Charlie (-60), Dave (-20)
      const balances = [
        MemberBalance(
          userId: 'u1',
          userName: 'Alice',
          totalContributed: 150,
          netBalance: 50.0,
        ),
        MemberBalance(
          userId: 'u2',
          userName: 'Bob',
          totalContributed: 130,
          netBalance: 30.0,
        ),
        MemberBalance(
          userId: 'u3',
          userName: 'Charlie',
          totalContributed: 40,
          netBalance: -60.0,
        ),
        MemberBalance(
          userId: 'u4',
          userName: 'Dave',
          totalContributed: 80,
          netBalance: -20.0,
        ),
      ];

      final payments = SettlementCalculator.calculateSettlements(balances);

      // Suma total de los pagos debe ser 80.0
      final totalPaid = payments.fold(0.0, (sum, p) => sum + p.amount);
      expect(totalPaid, equals(80.0));
      expect(payments.length, lessThanOrEqualTo(3));
    });
  });
}
