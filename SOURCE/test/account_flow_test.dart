import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wafa/domain/demo_connections.dart';
import 'package:wafa/domain/demo_models.dart';
import 'package:wafa/main.dart';

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _scrollVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _switchPerson(
  WidgetTester tester,
  DemoPerson person,
  String providerKey,
) async {
  await _tapVisible(tester, find.text('Profile').last);
  await _tapVisible(tester, find.text('Switch demo account'));
  await _tapVisible(tester, find.byKey(ValueKey('demo-person-${person.id}')));
  await _tapVisible(tester, find.byKey(ValueKey(providerKey)));
}

void main() {
  testWidgets('fresh launch clearly rehearses provider sign-in', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const WafaApp());
    await tester.pumpAndSettle();

    await _scrollVisible(tester, find.text('Sign-in preview'));
    expect(find.text('Sign-in preview'), findsOneWidget);
    expect(find.textContaining('no password is requested'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await _tapVisible(
      tester,
      find.byKey(ValueKey('demo-person-${demoOmar.id}')),
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('demo-sign-in-google')),
    );

    expect(
      find.text('Good agreements.\nBetter peace of mind.'),
      findsOneWidget,
    );
    await _tapVisible(tester, find.text('Profile').last);
    expect(find.textContaining(demoOmar.wafaId), findsOneWidget);
    expect(find.textContaining('Google · simulated sign-in'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('request stays private until creator confirms the account', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = DemoAgreementRepository();
    final draft = repository.createDraft(
      kind: ContractKind.sale,
      counterparty: 'Omar draft label',
      title: 'Shared bicycle terms',
      amountPence: 9000,
      dueDate: DateTime(2026, 10, 24),
    );
    final connections = DemoConnectionsRepository();
    connections.signIn(DemoLoginMethod.apple, demoAmina.id);
    await tester.pumpWidget(
      WafaApp(repository: repository, connections: connections),
    );
    await tester.pumpAndSettle();

    final invitation = connections.createInvite(
      draft.id,
      ParticipantRole.party,
      intendedPersonId: demoOmar.id,
    );
    await _switchPerson(tester, demoOmar, 'demo-sign-in-google');
    expect(find.text(draft.title), findsNothing);
    await _tapVisible(tester, find.byKey(const ValueKey('open-invitations')));
    await _tapVisible(
      tester,
      find.byKey(ValueKey('request-join-${invitation.id}')),
    );
    expect(
      find.textContaining('private agreement is still hidden'),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(draft.title), findsNothing);

    await _switchPerson(tester, demoAmina, 'demo-sign-in-apple');
    await _tapVisible(tester, find.text(draft.title));
    await _tapVisible(tester, find.byKey(const ValueKey('open-participants')));
    await _tapVisible(
      tester,
      find.byKey(ValueKey('participant-confirm-${invitation.id}')),
    );
    expect(find.text('Is this the right person?'), findsOneWidget);
    expect(find.text('Wafa ID: ${demoOmar.wafaId}'), findsOneWidget);
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('participant-confirm-request')),
    );
    expect(connections.canViewAgreement(draft.id), isTrue);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await _switchPerson(tester, demoOmar, 'demo-sign-in-google');
    expect(connections.canViewAgreement(draft.id), isTrue);
    await _tapVisible(tester, find.text(draft.title));
    expect(find.text(draft.title), findsWidgets);
    expect(connections.contactsForCurrentPerson.single.id, demoAmina.id);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a targeted code hides sender metadata from another account', (
    tester,
  ) async {
    final repository = DemoAgreementRepository();
    final draft = repository.createDraft(
      kind: ContractKind.service,
      counterparty: 'Private label',
      title: 'Private service terms',
      amountPence: 10000,
      dueDate: DateTime(2026, 10, 24),
    );
    final connections = DemoConnectionsRepository();
    connections.signIn(DemoLoginMethod.apple, demoAmina.id);
    await tester.pumpWidget(
      WafaApp(repository: repository, connections: connections),
    );
    await tester.pumpAndSettle();
    final invitation = connections.createInvite(
      draft.id,
      ParticipantRole.party,
      intendedPersonId: demoOmar.id,
    );
    await _switchPerson(tester, demoSara, 'demo-sign-in-google');
    await _tapVisible(tester, find.byKey(const ValueKey('open-invitations')));
    await tester.enterText(
      find.byKey(const ValueKey('invitation-code')),
      invitation.code,
    );
    await _tapVisible(tester, find.byKey(const ValueKey('preview-invitation')));

    expect(find.text('Invitation for a different account'), findsOneWidget);
    expect(find.text(demoAmina.name), findsNothing);
    expect(find.text(demoAmina.wafaId), findsNothing);
    expect(find.text(draft.title), findsNothing);
    expect(find.byKey(ValueKey('request-join-${invitation.id}')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
