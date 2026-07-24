import 'package:finanzas_compartidas/features/settlements/domain/entities/member_balance.dart';
import 'package:finanzas_compartidas/features/settlements/domain/entities/settlement_payment.dart';
import 'package:finanzas_compartidas/features/settlements/domain/usecases/get_settlements_summary_usecase.dart';
import 'package:finanzas_compartidas/features/settlements/domain/usecases/mark_settlement_paid_usecase.dart';
import 'package:finanzas_compartidas/features/settlements/presentation/providers/settlements_provider.dart';
import 'package:finanzas_compartidas/features/settlements/presentation/screens/settlements_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetSettlementsSummaryUseCase extends Mock
    implements GetSettlementsSummaryUseCase {}
class MockMarkSettlementPaidUseCase extends Mock
    implements MarkSettlementPaidUseCase {}

class TestSettlementsNotifier extends SettlementsNotifier {
  TestSettlementsNotifier(SettlementsState initialState)
      : super(
          getSettlementsSummaryUseCase: MockGetSettlementsSummaryUseCase(),
          markSettlementPaidUseCase: MockMarkSettlementPaidUseCase(),
        ) {
    state = initialState;
  }

  @override
  Future<void> loadSettlements(String groupId) async {}
}

void main() {
  const memberBalances = [
    MemberBalance(
      userId: 'u1',
      userName: 'Carlos',
      totalContributed: 300.0,
      netBalance: 100.0,
    ),
    MemberBalance(
      userId: 'u2',
      userName: 'Ana',
      totalContributed: 100.0,
      netBalance: -100.0,
    ),
  ];

  const payments = [
    SettlementPayment(
      fromUserId: 'u2',
      fromUserName: 'Ana',
      toUserId: 'u1',
      toUserName: 'Carlos',
      amount: 100.0,
    ),
  ];

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        settlementsNotifierProvider.overrideWith((ref) => TestSettlementsNotifier(
              const SettlementsState(
                isLoading: false,
                memberBalances: memberBalances,
                payments: payments,
              ),
            )),
      ],
      child: const MaterialApp(
        home: SettlementsScreen(groupId: 'g1'),
      ),
    );
  }

  group('SettlementsScreen Widget Tests', () {
    testWidgets('renders contributions summary and suggested minimum payment cards',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Cuentas Claras 🤝'), findsOneWidget);
      expect(find.text('Resumen de Aportes'), findsOneWidget);
      expect(find.text('Carlos'), findsOneWidget);
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Pagos Mínimos para Saldar Cuentas'), findsOneWidget);
      expect(find.text('Marcar como Pagado'), findsOneWidget);
    });
  });
}
