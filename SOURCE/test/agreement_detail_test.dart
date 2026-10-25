import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wafa/domain/demo_connections.dart';
import 'package:wafa/domain/demo_models.dart';
import 'package:wafa/ui/agreement_detail.dart';
import 'package:wafa/ui/wafa_ui.dart';

import 'demo_test_helpers.dart';

void main() {
  Future<void> mountDetail(
    WidgetTester tester,
    DemoAgreementRepository repository, {
    String id = 'demo-loan-001',
    VoidCallback? onChanged,
    DemoConnectionsRepository? connections,
  }) async {
    final demoConnections = connections ?? connectionsFor(repository);
    await tester.pumpWidget(
      MaterialApp(
        theme: wafaTheme,
        home: AgreementDetail(
          repository: repository,
          connections: demoConnections,
          id: id,
          onChanged: onChanged ?? () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openRepayment(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('record-repayment')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('add-payment')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('add-payment')));
    await tester.pumpAndSettle();
  }

  testWidgets('invalid repayments leave the local loan unchanged', (
    tester,
  ) async {
    final repository = DemoAgreementRepository();
    var changes = 0;
    await mountDetail(tester, repository, onChanged: () => changes++);
    await openRepayment(tester);

    for (final input in ['0', '-10', '320.01', '1.001', 'abc']) {
      await tester.enterText(
        find.byKey(const ValueKey('payment-amount')),
        input,
      );
      await tester.tap(find.byKey(const ValueKey('payment-save')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(repository.findById('demo-loan-001')!.paidPence, 16000);
      expect(changes, 0);
      expect(tester.takeException(), isNull);
    }

    expect(
      find.text('Enter a positive amount with at most two decimal places.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a partial repayment uses exact pence and refreshes details', (
    tester,
  ) async {
    final repository = DemoAgreementRepository();
    var changes = 0;
    await mountDetail(tester, repository, onChanged: () => changes++);
    await openRepayment(tester);
    await tester.enterText(
      find.byKey(const ValueKey('payment-amount')),
      '75.25',
    );
    await tester.tap(find.byKey(const ValueKey('payment-save')));
    await tester.pumpAndSettle();

    final updated = repository.findById('demo-loan-001')!;
    expect(updated.paidPence, 23525);
    expect(updated.remainingPence, 24475);
    expect(updated.status, AgreementStatus.active);
    expect(changes, 1);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('£244.75'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-payment')));
    await tester.pumpAndSettle();
    expect(find.text('Up to £244.75'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('an open non-loan obligation can be completed locally', (
    tester,
  ) async {
    final repository = DemoAgreementRepository();
    var changes = 0;
    await mountDetail(
      tester,
      repository,
      id: 'demo-rental-001',
      onChanged: () => changes++,
    );

    expect(find.byKey(const ValueKey('record-repayment')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('complete-obligation')));
    await tester.pumpAndSettle();

    final updated = repository.findById('demo-rental-001')!;
    expect(updated.status, AgreementStatus.completed);
    expect(updated.remainingPence, 0);
    expect(changes, 1);
    expect(find.byKey(const ValueKey('complete-obligation')), findsNothing);
    expect(find.text('Demo obligation marked complete.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('draft, awaiting and completed records offer no live action', (
    tester,
  ) async {
    final repository = DemoAgreementRepository();
    final connections = connectionsFor(repository);
    final draft = repository.createDraft(
      kind: ContractKind.service,
      counterparty: 'Fictional person',
      title: 'Draft example',
      amountPence: 10000,
      dueDate: DateTime(2026, 10, 20),
    );
    connections.registerAgreement(draft.id);

    for (final id in [draft.id, 'demo-sale-001', 'demo-loan-002']) {
      await mountDetail(tester, repository, id: id, connections: connections);
      expect(find.byKey(const ValueKey('record-repayment')), findsNothing);
      expect(find.byKey(const ValueKey('complete-obligation')), findsNothing);
      expect(find.byKey(const ValueKey('record-payment')), findsNothing);
      expect(find.text('PREVIEW'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('an unconfirmed invite cannot reveal agreement details', (
    tester,
  ) async {
    final repository = DemoAgreementRepository();
    final connections = connectionsFor(repository);
    final draft = repository.createDraft(
      kind: ContractKind.service,
      counterparty: 'Private draft label',
      title: 'Private garden plan',
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

    await mountDetail(
      tester,
      repository,
      id: draft.id,
      connections: connections,
    );

    expect(find.text('This agreement is private'), findsOneWidget);
    expect(find.text('Private garden plan'), findsNothing);
    expect(find.textContaining('£'), findsNothing);
    expect(find.byKey(const ValueKey('open-participants')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirmed people see the shared draft and role roster', (
    tester,
  ) async {
    final repository = DemoAgreementRepository();
    final connections = connectionsFor(repository);
    final draft = repository.createDraft(
      kind: ContractKind.service,
      counterparty: 'Shared draft label',
      title: 'Shared garden plan',
      amountPence: 12000,
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

    await mountDetail(
      tester,
      repository,
      id: draft.id,
      connections: connections,
    );

    expect(find.text('Shared garden plan'), findsWidgets);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('agreement-participants')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('WAFA-SARA'), findsOneWidget);
    expect(find.text('View people'), findsOneWidget);
    expect(find.byKey(const ValueKey('record-repayment')), findsNothing);
    expect(find.byKey(const ValueKey('complete-obligation')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail and repayment dialog fit a phone viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await mountDetail(tester, DemoAgreementRepository());
    expect(tester.takeException(), isNull);
    await openRepayment(tester);
    await tester.enterText(find.byKey(const ValueKey('payment-amount')), '0');
    await tester.tap(find.byKey(const ValueKey('payment-save')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
