import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wafa/domain/demo_connections.dart';
import 'package:wafa/domain/demo_models.dart';
import 'package:wafa/main.dart';

import 'demo_test_helpers.dart';

void main() {
  testWidgets('a shared record opens read-only from agreement detail', (
    tester,
  ) async {
    await _mount(tester);
    expect(find.text('Your track record'), findsNothing);
    expect(find.text('Record ›'), findsNothing);
    await _openFamily(tester);

    expect(find.text('Record ›'), findsOneWidget);
    await _tap(tester, find.text('No shared record'));
    expect(find.text("Sara hasn't shared a track record."), findsOneWidget);
    expect(find.text('Agreements completed'), findsNothing);

    await _tap(tester, find.text('Record ›'));
    expect(find.text('Omar Farooq'), findsOneWidget);
    expect(
      find.text('Shared by Omar. Facts only, never a score.'),
      findsOneWidget,
    );
    expect(find.text('14 of 14 (100%)'), findsOneWidget);
    expect(find.text('Jan 2025'), findsOneWidget);
    expect(find.textContaining('£'), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
    await _tap(tester, find.byTooltip('Back'));
    expect(find.text("Mum's care costs"), findsOneWidget);
    expect(find.text('Agreements completed'), findsNothing);

    await _tap(tester, find.text('Record ›'));
    await _tap(tester, find.text('Tracker'));
    expect(find.text("Who's in it"), findsNothing);
    expect(find.text('Track record'), findsNothing);
    expect(find.text('Record ›'), findsNothing);
    expect(find.text('No shared record'), findsNothing);
  });

  testWidgets('Sara can share and revoke her record across account switches', (
    tester,
  ) async {
    await _mount(tester);
    await _switchTo(tester, demoSara);
    await _tap(tester, find.text('Profile'));
    expect(find.text('Only you can see it'), findsOneWidget);
    await _tap(tester, find.text('Your track record'));
    expect(find.text('1 of 2 (50%)'), findsOneWidget);
    await _tap(tester, find.text('Share my record on my agreements'));
    expect(
      find.text('People on your agreements can now see your track record.'),
      findsOneWidget,
    );
    await _tap(tester, find.byTooltip('Back'));
    expect(find.text('Shared on your agreements'), findsOneWidget);

    await _switchTo(tester, demoAmina);
    await _openFamily(tester);
    expect(find.text('Record ›'), findsNWidgets(2));
    await _tap(tester, find.text('Record ›').last);
    expect(
      find.text('Shared by Sara. Facts only, never a score.'),
      findsOneWidget,
    );
    await _tap(tester, find.text('Profile'));
    expect(find.text('Shared on your agreements'), findsOneWidget);

    await _switchTo(tester, demoSara);
    await _tap(tester, find.text('Profile'));
    await _tap(tester, find.text('Your track record'));
    await _tap(tester, find.text('Stop sharing my record'));
    expect(find.text('Your track record is private again.'), findsOneWidget);
    await _tap(tester, find.byTooltip('Back'));
    expect(find.text('Only you can see it'), findsOneWidget);

    await _switchTo(tester, demoAmina);
    await _openFamily(tester);
    expect(find.text('Record ›'), findsOneWidget);
    await _tap(tester, find.text('No shared record'));
    expect(find.text("Sara hasn't shared a track record."), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('private defaults, stable IDs and confirmed agreement access', () {
    final repository = DemoAgreementRepository();
    final connections = connectionsFor(repository);
    final family = repository.findById('demo-family-001')!;
    expect(connections.ownTrackRecord?.paidOnTimeLabel, '5 of 6 (83%)');
    expect(connections.sharedTrackRecordFor(family, demoAmina.id), isNull);
    expect(connections.canRequestTrackRecord(family, demoSara.id), isTrue);
    expect(connections.sharedTrackRecordFor(family, demoSara.id), isNull);
    expect(connections.canRequestTrackRecord(family, demoOmar.name), isFalse);

    final draft = connections.createAgreementDraft(
      repository,
      kind: ContractKind.familyAgreement,
      title: 'New example',
      dueDate: DateTime(2026, 12, 1),
      people: const [
        AgreementPerson(
          id: 'demo-amina',
          name: 'Amina Noor',
          role: AgreementRole.owesShare,
          sharePence: 1500,
        ),
        AgreementPerson(
          id: 'demo-omar',
          name: 'Omar Farooq',
          role: AgreementRole.isOwed,
          sharePence: 0,
        ),
        AgreementPerson(
          id: 'demo-sara',
          name: 'Sara Malik',
          role: AgreementRole.witness,
          sharePence: 0,
        ),
      ],
    );
    final invite = connections.invitesForAgreement(draft.id).first;
    expect(connections.sharedTrackRecordFor(draft, demoOmar.id), isNull);
    connections.signIn(DemoLoginMethod.apple, demoOmar.id);
    connections.requestJoin(invite.code);
    expect(connections.sharedTrackRecordFor(draft, demoAmina.id), isNull);
    expect(connections.sharedTrackRecordFor(family, demoAmina.id), isNull);
    connections.signIn(DemoLoginMethod.apple, demoAmina.id);
    connections.confirmRequest(invite.id);
    expect(connections.sharedTrackRecordFor(draft, demoOmar.id), isNotNull);
    connections.signOut();
    expect(connections.sharedTrackRecordFor(draft, demoOmar.id), isNull);
  });

  test(
    'fixture-only people retain defaults and zero completions format as a dash',
    () {
      final connections = signedInConnections();
      connections.registerAgreement('fictional-test');
      final agreement = Agreement(
        id: 'fictional-test',
        title: 'Fictional example',
        counterparty: 'Maryam Saleh',
        amountPence: 0,
        dueDate: DateTime(2026, 12, 1),
        paidPence: 0,
        kind: ContractKind.familyAgreement,
        status: AgreementStatus.active,
        people: const [
          AgreementPerson(
            id: 'demo-amina',
            name: 'Amina Noor',
            role: AgreementRole.isOwed,
            sharePence: 0,
          ),
          AgreementPerson(
            id: 'demo-yusuf',
            name: 'Yusuf Rahman',
            role: AgreementRole.owesShare,
            sharePence: 0,
          ),
          AgreementPerson(
            id: 'demo-maryam',
            name: 'Maryam Saleh',
            role: AgreementRole.owesShare,
            sharePence: 0,
          ),
        ],
      );
      expect(
        connections.canRequestTrackRecord(agreement, 'demo-yusuf'),
        isTrue,
      );
      expect(connections.sharedTrackRecordFor(agreement, 'demo-yusuf'), isNull);
      expect(
        connections
            .sharedTrackRecordFor(agreement, 'demo-maryam')
            ?.paidOnTimeLabel,
        '8 of 9 (89%)',
      );
      expect(connections.persons, [demoAmina, demoOmar, demoSara]);
      const empty = DemoTrackRecord(
        completed: 0,
        onTime: 0,
        extensions: 0,
        open: 1,
        since: 'Oct 2026',
      );
      expect(empty.paidOnTimeLabel, '—');
    },
  );
}

Future<void> _mount(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(WafaApp(connections: signedInConnections()));
  await tester.pumpAndSettle();
}

Future<void> _openFamily(WidgetTester tester) async {
  await _tap(tester, find.text('Agreements').last);
  expect(find.text('Record ›'), findsNothing);
  expect(find.text('No shared record'), findsNothing);
  await _tap(tester, find.text("Mum's care costs"));
}

Future<void> _switchTo(WidgetTester tester, DemoPerson person) async {
  await _tap(tester, find.text('Profile').last);
  await _tap(tester, find.text('Switch demo account'));
  await _tap(tester, find.byKey(ValueKey('demo-person-${person.id}')));
  await _tap(tester, find.byKey(const ValueKey('demo-sign-in-apple')));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      150,
      scrollable: find.byType(Scrollable).last,
    );
  }
  if (finder.hitTestable().evaluate().isEmpty) {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
