import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wafa/domain/demo_connections.dart';
import 'package:wafa/ui/participants_screen.dart';
import 'package:wafa/ui/wafa_ui.dart';

const _agreementId = 'demo-participant-draft';

DemoConnectionsRepository _connections({DateTime Function()? clock}) {
  final connections = DemoConnectionsRepository(clock: clock);
  connections.signIn(DemoLoginMethod.apple, demoAmina.id);
  connections.registerAgreement(_agreementId);
  return connections;
}

Future<void> _mount(
  WidgetTester tester,
  DemoConnectionsRepository connections, {
  double textScale = 1,
  String agreementId = _agreementId,
  VoidCallback? onChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: wafaTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: ParticipantsScreen(
        connections: connections,
        agreementId: agreementId,
        onChanged: onChanged ?? () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  if (finder.evaluate().isEmpty) {
    await _scrollTo(tester, finder);
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.descendant(
      of: find.byKey(const ValueKey('participant-list')),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.pumpAndSettle();
}

void _accept(
  DemoConnectionsRepository connections,
  DemoPerson person,
  ParticipantRole role,
) {
  connections.signIn(DemoLoginMethod.apple, demoAmina.id);
  final invitation = connections.createInvite(
    _agreementId,
    role,
    intendedPersonId: person.id,
  );
  connections.signIn(DemoLoginMethod.google, person.id);
  connections.requestJoin(invitation.code);
  connections.signIn(DemoLoginMethod.apple, demoAmina.id);
  connections.confirmRequest(invitation.id);
}

void main() {
  testWidgets('an active or closed example never offers participant changes', (
    tester,
  ) async {
    final connections = _connections();
    connections.registerAgreement('demo-locked', invitationsAllowed: false);
    await _mount(tester, connections, agreementId: 'demo-locked');
    expect(find.byKey(const ValueKey('participant-add-person')), findsNothing);
    expect(find.text('Invitations'), findsNothing);
    await _scrollTo(tester, find.text('Your place on this agreement'));
    expect(
      find.textContaining('Only the creator can add people to an unsigned'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('exact Wafa ID creates a separate invitation with chosen role', (
    tester,
  ) async {
    final connections = _connections();
    var changes = 0;
    await _mount(tester, connections, onChanged: () => changes++);
    await _tap(tester, 'participant-add-person');
    await _tap(tester, 'participant-method-wafaId');
    await tester.enterText(
      find.byKey(const ValueKey('participant-wafa-id')),
      demoOmar.wafaId,
    );
    await _tap(tester, 'participant-find-id');
    expect(find.text(demoOmar.name), findsOneWidget);
    await _tap(tester, 'participant-role-witness');
    await _tap(tester, 'participant-create-invite');

    final invitation = connections.invitesForAgreement(_agreementId).single;
    expect(invitation.intendedPersonId, demoOmar.id);
    expect(invitation.role, ParticipantRole.witness);
    expect(invitation.status, InviteStatus.pending);
    expect(connections.participantsForAgreement(_agreementId).length, 1);
    expect(find.text(invitation.code), findsOneWidget);
    expect(
      find.text('Demo code — no real QR or invitation is sent.'),
      findsOneWidget,
    );
    expect(changes, 1);
    await _tap(tester, 'participant-preview-done');
    expect(tester.takeException(), isNull);
  });

  testWidgets('unknown and self Wafa IDs cannot create an invitation', (
    tester,
  ) async {
    final connections = _connections();
    await _mount(tester, connections);
    await _tap(tester, 'participant-add-person');
    await _tap(tester, 'participant-method-wafaId');
    for (final id in ['UNKNOWN', demoAmina.wafaId]) {
      await tester.enterText(
        find.byKey(const ValueKey('participant-wafa-id')),
        id,
      );
      await _tap(tester, 'participant-find-id');
      expect(
        find.byKey(const ValueKey('participant-add-error')),
        findsOneWidget,
      );
      await _tap(tester, 'participant-create-invite');
      expect(connections.invitesForAgreement(_agreementId), isEmpty);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('QR is only a labelled local preview and does not grant access', (
    tester,
  ) async {
    final connections = _connections();
    await _mount(tester, connections);
    await _tap(tester, 'participant-add-person');
    await _tap(tester, 'participant-method-qr');
    await _tap(tester, 'participant-create-invite');
    expect(find.byIcon(Icons.qr_code_2), findsOneWidget);
    expect(
      find.text('Demo code — no real QR or invitation is sent.'),
      findsOneWidget,
    );
    expect(connections.participantsForAgreement(_agreementId).length, 1);
    connections.signIn(DemoLoginMethod.google, demoOmar.id);
    expect(connections.canViewAgreement(_agreementId), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('creator reviews stable identity before confirming a requester', (
    tester,
  ) async {
    final connections = _connections();
    final invitation = connections.createInvite(
      _agreementId,
      ParticipantRole.party,
      intendedPersonId: demoOmar.id,
    );
    connections.signIn(DemoLoginMethod.google, demoOmar.id);
    connections.requestJoin(invitation.code);
    expect(connections.canViewAgreement(_agreementId), isFalse);
    connections.signIn(DemoLoginMethod.apple, demoAmina.id);
    var changes = 0;
    await _mount(tester, connections, onChanged: () => changes++);
    await _tap(tester, 'participant-confirm-${invitation.id}');

    expect(find.text('Is this the right person?'), findsOneWidget);
    expect(find.text('Wafa ID: ${demoOmar.wafaId}'), findsOneWidget);
    expect(find.text('Demo pairing code: ${invitation.code}'), findsOneWidget);
    expect(
      find.text('Joining gives access. It does not sign an agreement.'),
      findsOneWidget,
    );
    await _tap(tester, 'participant-confirm-request');
    expect(connections.participantsForAgreement(_agreementId).length, 2);
    expect(
      connections.invitesForAgreement(_agreementId).single.status,
      InviteStatus.accepted,
    );
    expect(changes, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'three people can share an unsigned draft without roster powers',
    (tester) async {
      final connections = _connections();
      _accept(connections, demoOmar, ParticipantRole.party);
      _accept(connections, demoSara, ParticipantRole.witness);
      await _mount(tester, connections);
      expect(connections.participantsForAgreement(_agreementId).length, 3);
      expect(find.text(demoOmar.name), findsOneWidget);
      await _scrollTo(
        tester,
        find.byKey(ValueKey('participant-person-${demoSara.id}')),
      );
      expect(
        find.byKey(ValueKey('participant-person-${demoSara.id}')),
        findsOneWidget,
      );
      connections.signIn(DemoLoginMethod.google, demoSara.id);
      await _mount(tester, connections);
      expect(
        find.byKey(const ValueKey('participant-add-person')),
        findsNothing,
      );
      expect(find.text('Invitations'), findsNothing);
      expect(find.textContaining('Demo code:'), findsNothing);
      expect(find.text('${demoSara.name} · You'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('revoked, declined and expired invitations have no controls', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 13, 12);
    final connections = _connections(clock: () => now);
    final revoked = connections.createInvite(
      _agreementId,
      ParticipantRole.party,
      intendedPersonId: demoOmar.id,
    );
    connections.revokeInvite(revoked.id);
    final declined = connections.createInvite(
      _agreementId,
      ParticipantRole.party,
      intendedPersonId: demoOmar.id,
    );
    connections.signIn(DemoLoginMethod.google, demoOmar.id);
    connections.declineInvite(declined.id);
    connections.signIn(DemoLoginMethod.apple, demoAmina.id);
    final expired = connections.createInvite(
      _agreementId,
      ParticipantRole.witness,
      intendedPersonId: demoSara.id,
    );
    now = now.add(const Duration(days: 8));
    await _mount(tester, connections);
    for (final invitation in [revoked, declined, expired]) {
      expect(
        find.byKey(ValueKey('participant-confirm-${invitation.id}')),
        findsNothing,
      );
      expect(
        find.byKey(ValueKey('participant-revoke-${invitation.id}')),
        findsNothing,
      );
    }
    for (final status in ['Revoked', 'Declined', 'Expired']) {
      await _scrollTo(tester, find.text(status));
      expect(find.text(status), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('a stale confirmation cannot approve a revoked invitation', (
    tester,
  ) async {
    final connections = _connections();
    final invitation = connections.createInvite(
      _agreementId,
      ParticipantRole.party,
      intendedPersonId: demoOmar.id,
    );
    connections.signIn(DemoLoginMethod.google, demoOmar.id);
    connections.requestJoin(invitation.code);
    connections.signIn(DemoLoginMethod.apple, demoAmina.id);
    await _mount(tester, connections);
    await _tap(tester, 'participant-confirm-${invitation.id}');
    connections.revokeInvite(invitation.id);
    await _tap(tester, 'participant-confirm-request');
    expect(connections.participantsForAgreement(_agreementId).length, 1);
    expect(find.textContaining('no longer available'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('creator can cancel revocation or revoke a pending invitation', (
    tester,
  ) async {
    final connections = _connections();
    final invitation = connections.createInvite(
      _agreementId,
      ParticipantRole.party,
      intendedPersonId: demoOmar.id,
    );
    var changes = 0;
    await _mount(tester, connections, onChanged: () => changes++);
    await _tap(tester, 'participant-revoke-${invitation.id}');
    await tester.tap(find.text('Keep invitation'));
    await tester.pumpAndSettle();
    expect(
      connections.invitesForAgreement(_agreementId).single.status,
      InviteStatus.pending,
    );
    expect(changes, 0);
    await _tap(tester, 'participant-revoke-${invitation.id}');
    await _tap(tester, 'participant-revoke-confirm');
    expect(
      connections.invitesForAgreement(_agreementId).single.status,
      InviteStatus.revoked,
    );
    expect(connections.participantsForAgreement(_agreementId).length, 1);
    expect(changes, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'an unaccepted account cannot see people or private invitation codes',
    (tester) async {
      final connections = _connections();
      connections.createInvite(_agreementId, ParticipantRole.party);
      connections.signIn(DemoLoginMethod.google, demoSara.id);
      await _mount(tester, connections);
      expect(find.text('This agreement is private'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('participant-add-person')),
        findsNothing,
      );
      expect(find.text(demoAmina.name), findsNothing);
      expect(find.textContaining('Demo code:'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'accepted Wafa connections appear without importing phone contacts',
    (tester) async {
      final connections = _connections();
      connections.registerAgreement('demo-other-draft');
      final invitation = connections.createInvite(
        'demo-other-draft',
        ParticipantRole.party,
        intendedPersonId: demoOmar.id,
      );
      connections.signIn(DemoLoginMethod.google, demoOmar.id);
      connections.requestJoin(invitation.code);
      connections.signIn(DemoLoginMethod.apple, demoAmina.id);
      connections.confirmRequest(invitation.id);
      await _mount(tester, connections);
      await _tap(tester, 'participant-add-person');
      expect(
        find.byKey(ValueKey('participant-contact-${demoOmar.id}')),
        findsOneWidget,
      );
      expect(
        find.textContaining('phone address book is not accessed'),
        findsOneWidget,
      );
      await _tap(tester, 'participant-contact-${demoOmar.id}');
      await _tap(tester, 'participant-create-invite');
      expect(
        connections.invitesForAgreement(_agreementId).single.intendedPersonId,
        demoOmar.id,
      );
      expect(connections.participantsForAgreement(_agreementId).length, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'people and invitation dialogs support two-times text and keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final connections = _connections();
      await _mount(tester, connections, textScale: 2);
      expect(tester.takeException(), isNull);
      await _tap(tester, 'participant-add-person');
      expect(tester.takeException(), isNull);
      await _tap(tester, 'participant-method-wafaId');
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('participant-wafa-id')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('participant-wafa-id')),
        demoOmar.wafaId,
      );
      await _tap(tester, 'participant-find-id');
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await _tap(tester, 'participant-role-witness');
      await _tap(tester, 'participant-create-invite');
      expect(tester.takeException(), isNull);
      await _tap(tester, 'participant-preview-done');
      expect(tester.takeException(), isNull);
    },
  );
}
