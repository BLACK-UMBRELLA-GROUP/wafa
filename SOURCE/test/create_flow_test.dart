import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wafa/domain/demo_connections.dart';
import 'package:wafa/domain/demo_models.dart';
import 'package:wafa/ui/create_agreement.dart';
import 'package:wafa/ui/wafa_ui.dart';

void main() {
  DemoAgreementRepository repository() => DemoAgreementRepository(
    clock: () => DateTime(2026, 10, 13),
    seedSamples: false,
  );

  DemoConnectionsRepository signedIn() =>
      DemoConnectionsRepository()..signIn(DemoLoginMethod.apple, demoAmina.id);

  Future<void> mount(
    WidgetTester tester,
    DemoAgreementRepository demoRepository, {
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: wafaTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: CreateAgreement(
          repository: demoRepository,
          connections: signedIn(),
        ),
      ),
    );
  }

  Finder byKey(String value) => find.byKey(Key(value));

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> next(WidgetTester tester) => tap(tester, byKey('create-next'));

  Future<void> enter(WidgetTester tester, String key, String value) async {
    final field = byKey(key);
    await tester.ensureVisible(field);
    await tester.enterText(field, value);
    await tester.pumpAndSettle();
  }

  Future<void> findPerson(WidgetTester tester, DemoPerson person) async {
    await tap(tester, byKey('draft-add-person'));
    await tap(tester, byKey('participant-method-wafaId'));
    await enter(tester, 'participant-wafa-id', person.wafaId);
    await tap(tester, byKey('participant-find-id'));
    await tap(tester, byKey('draft-select-person'));
  }

  Future<void> cycle(WidgetTester tester, DemoPerson person) =>
      tap(tester, byKey('draft-role-${person.id}'));

  testWidgets('the seven launch types render in the locked order', (
    tester,
  ) async {
    await mount(tester, repository());
    const orderedLabels = [
      'Interest-free loan',
      'Sale',
      'Item lending',
      'Item rental',
      'Service',
      'Family agreement',
      'Custom agreement',
    ];
    expect(ContractKind.values.length, orderedLabels.length);
    for (final (index, label) in orderedLabels.indexed) {
      final tile = byKey('kind-${ContractKind.values[index].name}');
      expect(
        find.descendant(of: tile, matching: find.text(label)),
        findsOneWidget,
      );
      if (index > 0) {
        final previous = byKey('kind-${ContractKind.values[index - 1].name}');
        expect(
          tester.getTopLeft(tile).dy,
          greaterThan(tester.getTopLeft(previous).dy),
        );
      }
    }
    expect(
      find.text(
        'Later, after review: business partnership, charity pledge, employment.',
      ),
      findsOneWidget,
    );
    await tap(tester, byKey('kind-service'));
    await next(tester);
    expect(
      find.text('Service · add everyone who is part of it.'),
      findsOneWidget,
    );
    expect(find.text('Total amount'), findsOneWidget);
  });

  testWidgets('details errors appear singly in the specified order', (
    tester,
  ) async {
    final demoRepository = repository();
    await mount(tester, demoRepository);
    await next(tester);
    await findPerson(tester, demoOmar);
    await cycle(tester, demoAmina);
    await next(tester);

    const errors = [
      'Someone needs to owe a share.',
      'Someone needs to be owed.',
      'Enter an amount above £0.',
      'Give everyone who owes a share an amount above £0.',
    ];

    void expectOnlyError(int index) {
      for (final (position, error) in errors.indexed) {
        expect(
          find.text(error),
          position == index ? findsOneWidget : findsNothing,
        );
      }
    }

    expectOnlyError(0);
    await cycle(tester, demoAmina);
    expectOnlyError(-1);
    await cycle(tester, demoAmina);
    await cycle(tester, demoOmar);
    await next(tester);
    expectOnlyError(1);

    await cycle(tester, demoOmar);
    await cycle(tester, demoOmar);
    await findPerson(tester, demoSara);
    for (final value in ['12.345', '1e3', '-10', '0']) {
      await enter(tester, 'amount', value);
      await next(tester);
      expectOnlyError(2);
    }

    await enter(tester, 'amount', '0.01');
    await next(tester);
    expectOnlyError(3);
    await enter(tester, 'amount', '0.02');
    expectOnlyError(-1);
    await next(tester);
    expect(find.text('Save draft'), findsOneWidget);
    expect(demoRepository.agreements, isEmpty);
  });

  testWidgets('equal split awards the odd penny to the first debtor', (
    tester,
  ) async {
    await mount(tester, repository());
    await next(tester);
    await findPerson(tester, demoOmar);
    await findPerson(tester, demoSara);
    await enter(tester, 'draft-title', 'Family support');
    await enter(tester, 'amount', '125.41');
    expect(find.text('2 people owe £62.70 each'), findsOneWidget);
    await next(tester);
    expect(find.text('Family support'), findsOneWidget);
    expect(find.text('£125.41'), findsOneWidget);
    expect(find.text('£62.71'), findsOneWidget);
    expect(find.text('£62.70'), findsOneWidget);
    expect(find.text('British pound (GBP)'), findsOneWidget);
    expect(
      find.text(
        'Each person gets an invitation and signs the same agreement. '
        'It becomes active when everyone has signed, witnesses too.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('set amounts total updates and values survive back navigation', (
    tester,
  ) async {
    await mount(tester, repository());
    await tap(tester, byKey('kind-sale'));
    await next(tester);
    await findPerson(tester, demoOmar);
    await findPerson(tester, demoSara);
    await tap(tester, find.text('Set each amount'));
    await enter(tester, 'draft-title', 'Bicycle sale');
    await enter(tester, 'draft-share-${demoAmina.id}', '14.35');
    expect(find.text('Total: £14.35'), findsOneWidget);
    await next(tester);
    expect(
      find.text('Give everyone who owes a share an amount above £0.'),
      findsOneWidget,
    );
    await enter(tester, 'draft-share-${demoSara.id}', '37.17');
    expect(find.text('Total: £51.52'), findsOneWidget);
    await next(tester);
    expect(find.text('£51.52'), findsOneWidget);
    await tap(tester, byKey('create-back'));

    String fieldValue(String key) => tester
        .widget<EditableText>(
          find.descendant(of: byKey(key), matching: find.byType(EditableText)),
        )
        .controller
        .text;
    expect(fieldValue('draft-title'), 'Bicycle sale');
    expect(fieldValue('draft-share-${demoSara.id}'), '37.17');
    await tap(tester, byKey('create-back'));
    await next(tester);
    expect(find.text('Sale · add everyone who is part of it.'), findsOneWidget);
    expect(find.text('Total: £51.52'), findsOneWidget);
    expect(fieldValue('draft-share-${demoAmina.id}'), '14.35');
    expect(find.text('Omar Farooq'), findsOneWidget);
  });

  testWidgets('the custom warning appears only for Custom agreement', (
    tester,
  ) async {
    await mount(tester, repository());
    const warning =
        'Your own terms must not include interest or anything prohibited. '
        'If you are unsure, ask a scholar before you sign.';
    await next(tester);
    expect(find.text(warning), findsNothing);
    await tap(tester, byKey('create-back'));
    await tap(tester, byKey('kind-customAgreement'));
    await next(tester);
    expect(find.text(warning), findsOneWidget);
  });

  testWidgets(
    'saving returns the draft and prepares separate invitations for selected people',
    (tester) async {
      final demoRepository = repository();
      final connections = signedIn();
      Agreement? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: wafaTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                key: const Key('open-create'),
                onPressed: () async {
                  result = await Navigator.of(context).push<Agreement>(
                    MaterialPageRoute(
                      builder: (_) => CreateAgreement(
                        repository: demoRepository,
                        connections: connections,
                      ),
                    ),
                  );
                },
                child: const Text('Create'),
              ),
            ),
          ),
        ),
      );
      await tap(tester, byKey('open-create'));
      await next(tester);
      await enter(tester, 'amount', '0.01');
      await next(tester);
      expect(find.text('Someone needs to be owed.'), findsOneWidget);
      expect(connections.incomingInvites, isEmpty);
      expect(demoRepository.agreements, isEmpty);

      await findPerson(tester, demoOmar);
      await findPerson(tester, demoSara);
      await cycle(tester, demoSara);
      await cycle(tester, demoSara);
      await next(tester);
      await next(tester);

      final draft = result!;
      expect(draft.amountPence, 1);
      expect(draft.title, 'Interest-free loan');
      expect(draft.status, AgreementStatus.draft);
      expect(draft.people.map((person) => person.id), [
        demoAmina.id,
        demoOmar.id,
        demoSara.id,
      ]);
      expect(draft.people.map((person) => person.role), [
        AgreementRole.owesShare,
        AgreementRole.isOwed,
        AgreementRole.witness,
      ]);
      expect(draft.people.map((person) => person.sharePence), [1, 0, 0]);
      expect(demoRepository.agreements.single, same(draft));
      final invites = connections.invitesForAgreement(draft.id);
      expect(invites.map((invite) => invite.intendedPersonId), [
        demoOmar.id,
        demoSara.id,
      ]);
      expect(invites.map((invite) => invite.role), [
        ParticipantRole.party,
        ParticipantRole.witness,
      ]);
      expect(invites.map((invite) => invite.code).toSet(), hasLength(2));
      expect(
        invites.every((invite) => invite.status == InviteStatus.pending),
        isTrue,
      );
      expect(find.byKey(const Key('open-create')), findsOneWidget);
    },
  );

  testWidgets(
    'phone layout stays scrollable with large text and keyboard inset',
    (tester) async {
      await mount(tester, repository(), textScale: 1.6);
      expect(tester.takeException(), isNull);
      await next(tester);
      await findPerson(tester, demoOmar);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await enter(tester, 'draft-title', 'A clear promise');
      await enter(tester, 'amount', '10');
      await next(tester);
      expect(find.text('A clear promise'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
