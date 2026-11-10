import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wafa/main.dart';
import 'package:wafa/domain/demo_connections.dart';
import 'package:wafa/domain/demo_models.dart';
import 'package:wafa/ui/wafa_ui.dart';
import 'package:wafa/ui/agreement_detail.dart';

import 'demo_test_helpers.dart';

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _dashboardTile(AgreementStatus status) =>
    find.byKey(ValueKey<AgreementStatus>(status));

void _inviteAmina(DemoConnectionsRepository connections) {
  connections.signIn(DemoLoginMethod.google, demoOmar.id);
  connections.registerAgreement('incoming-draft');
  connections.createInvite(
    'incoming-draft',
    ParticipantRole.party,
    intendedPersonId: demoAmina.id,
  );
  connections.signIn(DemoLoginMethod.apple, demoAmina.id);
}

void main() {
  testWidgets('app rebuild preserves one demo repository and its mutations', (
    tester,
  ) async {
    final connections = signedInConnections();
    await tester.pumpWidget(WafaApp(connections: connections));
    final repository = tester
        .widget<WafaHome>(find.byType(WafaHome))
        .repository;
    final draft = repository.createDraft(
      kind: ContractKind.sale,
      counterparty: 'Demo User',
      title: 'Survives a rebuild',
      amountPence: 10000,
      dueDate: DateTime(2026, 10, 20),
    );
    repository.recordRepayment('demo-loan-001', amountPence: 1000);
    await tester.pumpWidget(WafaApp(connections: connections));
    await tester.pumpAndSettle();
    final after = tester.widget<WafaHome>(find.byType(WafaHome)).repository;
    expect(identical(after, repository), isTrue);
    expect(after.findById(draft.id)?.title, 'Survives a rebuild');
    expect(after.findById('demo-loan-001')!.paidPence, 17000);
  });

  testWidgets('main tabs support two-times system text on a compact phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(WafaApp(connections: signedInConnections()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'Initial Home layout');
    for (final label in ['Agreements', 'Tracker', 'Profile', 'Home']) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$label layout');
    }
  });

  testWidgets('repayment dialog scrolls with large text and keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = DemoAgreementRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: wafaTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.6),
            viewInsets: const EdgeInsets.only(bottom: 280),
          ),
          child: child!,
        ),
        home: AgreementDetail(
          repository: repository,
          connections: connectionsFor(repository),
          id: 'demo-loan-001',
          onChanged: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('record-repayment')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('add-payment')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('add-payment')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('payment-amount')), '0');
    await tester.tap(find.byKey(const Key('payment-save')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('money parsing is exact and rejects malformed input', () {
    expect(parsePence('19.99'), 1999);
    expect(parsePence('19.9'), 1990);
    expect(parsePence('19.999'), isNull);
    expect(parsePence('-1'), isNull);
    expect(parsePence('1.2.3'), isNull);
    expect(money(120050), '£1,200.50');
  });
  testWidgets('home has explicit preview and working navigation', (
    tester,
  ) async {
    await tester.pumpWidget(WafaApp(connections: signedInConnections()));
    final brand = find.byType(BrandMark);
    final icon = find.descendant(of: brand, matching: find.byType(CustomPaint));
    final wordmark = find.descendant(of: brand, matching: find.text('wafa'));
    expect(tester.getSize(icon), const Size.square(30));
    expect(
      icon,
      paints
        ..rrect(
          rrect: RRect.fromRectAndRadius(
            const Rect.fromLTWH(0, 0, 30, 30),
            const Radius.circular(6.75),
          ),
          color: WafaColors.green,
        )
        ..path(color: Colors.white, strokeWidth: 7, style: PaintingStyle.stroke)
        ..circle(x: 70, y: 24, radius: 4, color: const Color(0xffbddccc)),
    );
    expect(tester.widget<Text>(wordmark).style?.fontSize, 30);
    expect(find.byIcon(Icons.spa_outlined), findsNothing);
    expect(find.text('PREVIEW'), findsOneWidget);
    expect(find.text('A first look at Wafa'), findsNothing);
    expect(wafaTheme.scaffoldBackgroundColor, Colors.white);
    await tester.tap(find.text('Tracker'));
    await tester.pumpAndSettle();
    expect(find.text('A clearer picture'), findsOneWidget);
    await _tapVisible(tester, find.text('Home'));
    await _tapVisible(tester, find.text('A'));
    expect(find.text('A first look at Wafa'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('A first look at Wafa')).dy,
      lessThan(tester.getTopLeft(find.text('Your space')).dy),
    );
    final footer = find.text('Built around keeping your word');
    await tester.scrollUntilVisible(footer, 180);
    expect(footer, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Needs you orders invitation, overdue, signature, then due soon',
    (tester) async {
      final repository = DemoAgreementRepository(
        clock: () => DateTime(2026, 10, 21),
      );
      final connections = signedInConnections();
      _inviteAmina(connections);
      await tester.pumpWidget(
        WafaApp(repository: repository, connections: connections),
      );
      await tester.pumpAndSettle();

      final rowTitles = [
        'Invitation · ${demoOmar.name}',
        'Garden design · Samira Khan',
        'Bicycle sale · Adam Yusuf',
        'Family support · Yusuf Rahman',
      ];
      final positions = rowTitles
          .map((title) => tester.getTopLeft(find.text(title)).dy)
          .toList();
      expect(positions, orderedEquals([...positions]..sort()));
      expect(positions.toSet(), hasLength(4));
      expect(find.text('Needs you'), findsOneWidget);
      expect(find.text('4 things'), findsOneWidget);
      expect(find.text('Asks you to join an agreement'), findsOneWidget);
      expect(find.text('12 days overdue · £120 left'), findsOneWidget);
      expect(find.text('Waiting for your signature'), findsOneWidget);
      expect(find.text('Due in 7 days · £320 left'), findsOneWidget);
      expect(find.text('Van hire · Maryam Saleh'), findsNothing);
      expect(find.text('Next payment'), findsNothing);

      await _tapVisible(tester, find.byKey(const Key('open-invitations')));
      expect(find.text('Invitations'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text(rowTitles[1]));
      expect(find.byType(AgreementDetail), findsOneWidget);
    },
  );

  testWidgets('calm Home shows the earliest active agreement as Next payment', (
    tester,
  ) async {
    final repository = DemoAgreementRepository();
    final connections = signedInConnections();
    connections.registerAgreement('demo-rental-001');
    connections.registerAgreement('demo-loan-001');
    await tester.pumpWidget(
      MaterialApp(
        theme: wafaTheme,
        home: WafaHome(
          repository: repository,
          connections: connections,
          onSignedOut: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nothing needs you today'), findsOneWidget);
    expect(
      find.text("We'll tell you when a payment or signature is due."),
      findsOneWidget,
    );
    expect(find.text('Needs you'), findsNothing);
    final nextPayment = find.text('Next payment');
    if (nextPayment.evaluate().isEmpty) {
      await tester.scrollUntilVisible(nextPayment, 180);
    }
    expect(nextPayment, findsOneWidget);
    expect(
      tester.widget<AgreementTile>(find.byType(AgreementTile)).agreement.id,
      'demo-loan-001',
    );
  });

  testWidgets('Home shows separate counts for all five agreement statuses', (
    tester,
  ) async {
    await tester.pumpWidget(WafaApp(connections: signedInConnections()));
    await tester.pumpAndSettle();

    const expectedTiles = {
      AgreementStatus.active: ('Active', '3'),
      AgreementStatus.draft: ('Drafts', '0'),
      AgreementStatus.awaitingSignatures: ('Awaiting signatures', '1'),
      AgreementStatus.completed: ('Completed', '1'),
      AgreementStatus.overdue: ('Overdue', '1'),
    };
    for (final MapEntry(key: status, value: (label, count))
        in expectedTiles.entries) {
      final tile = _dashboardTile(status);
      if (tile.evaluate().isEmpty) {
        await tester.scrollUntilVisible(tile, 180);
      }
      expect(
        find.descendant(of: tile, matching: find.text(label)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tile, matching: find.text(count)),
        findsOneWidget,
      );
    }
  });

  testWidgets('Overdue opens only overdue agreements in due date order', (
    tester,
  ) async {
    final repository = DemoAgreementRepository(
      clock: () => DateTime(2026, 11, 1),
    );
    await tester.pumpWidget(
      WafaApp(repository: repository, connections: signedInConnections()),
    );
    await tester.pumpAndSettle();

    await _tapVisible(tester, _dashboardTile(AgreementStatus.overdue));
    expect(find.text('Overdue').first, findsOneWidget);
    expect(
      tester
          .widgetList<AgreementTile>(find.byType(AgreementTile))
          .map((tile) => tile.agreement.id),
      ['demo-service-001', 'demo-loan-001', 'demo-rental-001'],
    );
    await _tapVisible(tester, find.byTooltip('Back'));
    expect(find.text('Your agreements'), findsOneWidget);

    await _tapVisible(tester, _dashboardTile(AgreementStatus.overdue));
    await _tapVisible(tester, find.text('Tracker'));
    expect(find.text('A clearer picture'), findsOneWidget);
    await _tapVisible(tester, find.text('Home'));
    expect(find.text('Needs you'), findsOneWidget);
  });

  testWidgets('a section with no agreements explains its empty state', (
    tester,
  ) async {
    await tester.pumpWidget(WafaApp(connections: signedInConnections()));
    await tester.pumpAndSettle();

    await _tapVisible(tester, _dashboardTile(AgreementStatus.draft));
    expect(find.text('Drafts'), findsOneWidget);
    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(
      find.text("No drafts. Agreements you start but don't send wait here."),
      findsOneWidget,
    );
    expect(find.byType(AgreementTile), findsNothing);
  });

  testWidgets(
    'new members see the first-agreement state and only open invites',
    (tester) async {
      final repository = DemoAgreementRepository(seedSamples: false);
      final connections = signedInConnections();
      final app = WafaApp(repository: repository, connections: connections);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      expect(find.text('Welcome, Amina'), findsOneWidget);
      expect(find.text('No agreements yet'), findsOneWidget);
      expect(
        find.text(
          'Write down what you agree with someone, sign it together, and keep '
          'track of every payment.',
        ),
        findsOneWidget,
      );
      final create = find.byKey(const Key('create-agreement'));
      expect(
        find.descendant(
          of: create,
          matching: find.text('Create your first agreement'),
        ),
        findsOneWidget,
      );
      expect(find.text('Your agreements'), findsNothing);
      expect(find.byKey(const Key('open-invitations')), findsNothing);

      _inviteAmina(connections);
      await tester.pumpWidget(
        WafaApp(repository: repository, connections: connections),
      );
      await tester.pumpAndSettle();
      expect(find.text('Invitations · 1 waiting'), findsOneWidget);
      await _tapVisible(tester, find.byKey(const Key('open-invitations')));
      expect(find.text('Invitations'), findsOneWidget);
    },
  );

  testWidgets('Home greeting switches at noon and six in local time', (
    tester,
  ) async {
    final connections = signedInConnections();
    final repository = DemoAgreementRepository();
    for (final (hour, minute, greeting) in [
      (11, 59, 'Good morning'),
      (12, 0, 'Good afternoon'),
      (17, 59, 'Good afternoon'),
      (18, 0, 'Good evening'),
    ]) {
      await tester.pumpWidget(
        WafaApp(
          repository: repository,
          connections: connections,
          clock: () => DateTime(2026, 10, 13, hour, minute),
        ),
      );
      expect(find.text('$greeting, Amina'), findsOneWidget);
    }
  });

  testWidgets('Home spells out the singular and plural running counts', (
    tester,
  ) async {
    final repository = DemoAgreementRepository();
    final connections = signedInConnections();
    connections.registerAgreement('demo-loan-001');
    Widget app() => MaterialApp(
      theme: wafaTheme,
      home: WafaHome(
        repository: repository,
        connections: connections,
        onSignedOut: () {},
        clock: () => DateTime(2026, 10, 13, 10),
      ),
    );

    await tester.pumpWidget(app());
    expect(find.text('13 Oct · 1 agreement running'), findsOneWidget);
    connections.registerAgreement('demo-service-001');
    await tester.pumpWidget(app());
    expect(find.text('13 Oct · 2 agreements running'), findsOneWidget);
  });

  testWidgets(
    'create flow saves a session-local draft and shows it in Drafts',
    (tester) async {
      final repository = DemoAgreementRepository();
      final before = repository.agreements.length;
      await tester.pumpWidget(
        WafaApp(repository: repository, connections: signedInConnections()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Create an agreement'), findsOneWidget);
      await _tapVisible(tester, find.byKey(const Key('create-agreement')));
      await tester.tap(find.byKey(const Key('create-next')));
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.byKey(const Key('draft-choose-person')));
      await _tapVisible(
        tester,
        find.byKey(const Key('participant-method-wafaId')),
      );
      await tester.enterText(
        find.byKey(const Key('participant-wafa-id')),
        demoOmar.wafaId,
      );
      await _tapVisible(tester, find.byKey(const Key('participant-find-id')));
      await _tapVisible(tester, find.byKey(const Key('draft-select-person')));
      await tester.enterText(find.byKey(const Key('amount')), '250.50');
      await tester.enterText(
        find.byKey(const Key('draft-title')),
        'Demo test agreement',
      );
      await _tapVisible(tester, find.byKey(const Key('create-next')));
      await _tapVisible(tester, find.byKey(const Key('create-next')));
      expect(repository.agreements.length, before + 1);
      expect(repository.agreements.first.counterparty, demoOmar.name);
      expect(find.text('Demo test agreement'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final home = tester.widget<WafaHome>(find.byType(WafaHome));
      final connections = home.connections;
      final draft = repository.agreements.first;
      final invitation = connections.invitesForAgreement(draft.id).single;
      connections.signIn(DemoLoginMethod.google, demoOmar.id);
      connections.requestJoin(invitation.code);
      connections.signIn(DemoLoginMethod.apple, demoAmina.id);
      connections.confirmRequest(invitation.id);
      connections.signIn(DemoLoginMethod.google, demoOmar.id);
      await tester.pumpWidget(
        WafaApp(repository: repository, connections: connections),
      );
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('Agreements').last);
      await _tapVisible(tester, find.text('Demo test agreement'));
      expect(find.text('Draft label: ${demoAmina.name}'), findsOneWidget);
    },
  );
  testWidgets('compact phone layout is overflow-free across main tabs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(WafaApp(connections: signedInConnections()));
    for (final label in ['Agreements', 'Tracker', 'Profile', 'Home']) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
