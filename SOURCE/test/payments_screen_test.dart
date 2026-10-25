import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wafa/domain/demo_connections.dart';
import 'package:wafa/domain/demo_models.dart';
import 'package:wafa/ui/payments_screen.dart';
import 'package:wafa/ui/wafa_ui.dart';

import 'demo_test_helpers.dart';

void main() {
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> mountPayments(
    WidgetTester tester,
    DemoAgreementRepository repository,
    DemoConnectionsRepository connections, {
    String id = 'demo-loan-001',
    VoidCallback? onChanged,
    double textScale = 1,
    EdgeInsets viewInsets = EdgeInsets.zero,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: wafaTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            viewInsets: viewInsets,
          ),
          child: child!,
        ),
        home: PaymentsScreen(
          repository: repository,
          connections: connections,
          agreementId: id,
          onChanged: onChanged ?? () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('party records method, date, note and reference', (tester) async {
    final repository = DemoAgreementRepository();
    var changes = 0;
    await mountPayments(
      tester,
      repository,
      connectionsFor(repository),
      onChanged: () => changes++,
    );

    await scrollTo(tester, find.byKey(const ValueKey('add-payment')));
    await tester.tap(find.byKey(const ValueKey('add-payment')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('payment-amount')),
      '25.50',
    );
    await tester.tap(find.byKey(const ValueKey('payment-method')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cash').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('payment-reference')),
      'RECEIPT-25',
    );
    await tester.enterText(
      find.byKey(const ValueKey('payment-note')),
      'Paid in person.',
    );
    await tester.tap(find.byKey(const ValueKey('payment-save')));
    await tester.pumpAndSettle();

    final payment = repository.paymentsFor('demo-loan-001').first;
    expect(payment.amountPence, 2550);
    expect(payment.paidOn, DateTime(2026, 10, 13));
    expect(payment.method, PaymentMethod.cash);
    expect(payment.reference, 'RECEIPT-25');
    expect(payment.note, 'Paid in person.');
    expect(payment.recordedByPersonId, demoAmina.id);
    expect(changes, 1);
    await scrollTo(
      tester,
      find.byKey(const ValueKey('payment-demo-payment-001')),
    );
    expect(find.text('Cash · Recorded by Amina Noor'), findsOneWidget);
    expect(find.text('Unverified demo entry'), findsWidgets);
  });

  testWidgets('witness can view but cannot add payment records', (
    tester,
  ) async {
    final repository = DemoAgreementRepository();
    final connections = connectionsFor(repository);
    final draft = repository.createDraft(
      kind: ContractKind.service,
      counterparty: 'Fictional customer',
      title: 'Witness example',
      amountPence: 10000,
      dueDate: DateTime(2026, 10, 24),
    );
    connections.registerAgreement(draft.id);
    final invitation = connections.createInvite(
      draft.id,
      ParticipantRole.witness,
      intendedPersonId: demoSara.id,
    );
    connections.signIn(DemoLoginMethod.google, demoSara.id);
    connections.requestJoin(invitation.code);
    connections.signIn(DemoLoginMethod.apple, demoAmina.id);
    connections.confirmRequest(invitation.id);
    connections.signIn(DemoLoginMethod.google, demoSara.id);

    await mountPayments(tester, repository, connections, id: draft.id);

    expect(find.text('View-only role'), findsOneWidget);
    expect(find.byKey(const ValueKey('add-payment')), findsNothing);
    await scrollTo(
      tester,
      find.text(
        'No itemised payments have been recorded for this demo agreement.',
      ),
    );
    expect(
      find.text(
        'No itemised payments have been recorded for this demo agreement.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('unconfirmed invite cannot reveal the payment timeline', (
    tester,
  ) async {
    final repository = DemoAgreementRepository();
    final connections = connectionsFor(repository);
    final draft = repository.createDraft(
      kind: ContractKind.service,
      counterparty: 'Private draft label',
      title: 'Private payments',
      amountPence: 12000,
      dueDate: DateTime(2026, 10, 24),
    );
    connections.registerAgreement(draft.id);
    final invitation = connections.createInvite(
      draft.id,
      ParticipantRole.party,
      intendedPersonId: demoOmar.id,
    );
    connections.signIn(DemoLoginMethod.google, demoOmar.id);
    connections.requestJoin(invitation.code);

    await mountPayments(tester, repository, connections, id: draft.id);

    expect(find.text('Payment records are private'), findsOneWidget);
    expect(find.text('Private payments'), findsNothing);
    expect(find.textContaining('£'), findsNothing);
    expect(find.byKey(const ValueKey('payments-list')), findsNothing);
  });

  testWidgets('payment dialog handles large text and a keyboard inset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = DemoAgreementRepository();
    await mountPayments(
      tester,
      repository,
      connectionsFor(repository),
      textScale: 1.6,
      viewInsets: const EdgeInsets.only(bottom: 280),
    );

    await scrollTo(tester, find.byKey(const ValueKey('add-payment')));
    await tester.tap(find.byKey(const ValueKey('add-payment')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('payment-amount')), '0');
    await tester.tap(find.byKey(const ValueKey('payment-save')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
