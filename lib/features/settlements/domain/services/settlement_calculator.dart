import '../entities/member_balance.dart';
import '../entities/settlement_payment.dart';

/*
 * ============================================================================
 * MOTOR DE LIQUIDACIÓN Y MINIMIZACIÓN DE PAGOS (PURE DOMAIN MODULE)
 * ============================================================================
 * 
 * ALGORITMO GREEDY:
 * 1. Calcula aportes por miembro y balance neto = aportado - (total_compartido / num_miembros).
 * 2. Separa a los miembros en dos grupos:
 *    - Deudores (balance neto < 0)
 *    - Acreedores (balance neto > 0)
 * 3. Ordena deudores descendentemente por su deuda y acreedores por su crédito.
 * 4. Mientras existan deudores y acreedores pendientes:
 *    - Toma el mayor deudor y el mayor acreedor.
 *    - Monto a transferir = min(deuda_deudor, credito_acreedor).
 *    - Genera SettlementPayment(from: deudor, to: acreedor, amount: monto).
 *    - Descuenta monto a ambos. Quien llegue a saldo 0 es retirado de la cola.
 * ============================================================================
 */

abstract class SettlementCalculator {
  static List<MemberBalance> calculateMemberBalances({
    required List<Map<String, dynamic>> members,
    required List<Map<String, dynamic>> sharedTransactions,
  }) {
    if (members.isEmpty) return [];

    final Map<String, double> contributions = {};
    final Map<String, String> userNames = {};

    for (final m in members) {
      final uid = m['userId'] as String;
      contributions[uid] = 0.0;
      userNames[uid] = m['userName'] as String? ?? 'Usuario';
    }

    double totalSharedAmount = 0.0;
    for (final tx in sharedTransactions) {
      final uid = tx['userId'] as String;
      final amount = (tx['amount'] as num).toDouble();
      totalSharedAmount += amount;
      contributions[uid] = (contributions[uid] ?? 0.0) + amount;
    }

    final fairShare = totalSharedAmount / members.length;

    return members.map((m) {
      final uid = m['userId'] as String;
      final name = userNames[uid] ?? 'Usuario';
      final contributed = contributions[uid] ?? 0.0;
      final net = contributed - fairShare;
      return MemberBalance(
        userId: uid,
        userName: name,
        totalContributed: contributed,
        netBalance: net,
      );
    }).toList();
  }

  static List<SettlementPayment> calculateSettlements(
    List<MemberBalance> memberBalances,
  ) {
    if (memberBalances.isEmpty) return [];

    final debtors = <_TempBalance>[];
    final creditors = <_TempBalance>[];

    for (final mb in memberBalances) {
      final roundedNet = double.parse(mb.netBalance.toStringAsFixed(2));
      if (roundedNet < -0.01) {
        debtors.add(_TempBalance(mb.userId, mb.userName, roundedNet.abs()));
      } else if (roundedNet > 0.01) {
        creditors.add(_TempBalance(mb.userId, mb.userName, roundedNet));
      }
    }

    debtors.sort((a, b) => b.amount.compareTo(a.amount));
    creditors.sort((a, b) => b.amount.compareTo(a.amount));

    final payments = <SettlementPayment>[];
    int dIndex = 0;
    int cIndex = 0;

    while (dIndex < debtors.length && cIndex < creditors.length) {
      final debtor = debtors[dIndex];
      final creditor = creditors[cIndex];

      final minAmount =
          debtor.amount < creditor.amount ? debtor.amount : creditor.amount;
      final roundedPayment = double.parse(minAmount.toStringAsFixed(2));

      if (roundedPayment > 0) {
        payments.add(SettlementPayment(
          fromUserId: debtor.userId,
          fromUserName: debtor.userName,
          toUserId: creditor.userId,
          toUserName: creditor.userName,
          amount: roundedPayment,
        ));
      }

      debtor.amount -= roundedPayment;
      creditor.amount -= roundedPayment;

      if (debtor.amount <= 0.01) dIndex++;
      if (creditor.amount <= 0.01) cIndex++;
    }

    return payments;
  }
}

class _TempBalance {
  final String userId;
  final String userName;
  double amount;

  _TempBalance(this.userId, this.userName, this.amount);
}
