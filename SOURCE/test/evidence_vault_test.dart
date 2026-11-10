import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wafa/domain/demo_connections.dart';
import 'package:wafa/domain/demo_models.dart';
import 'package:wafa/ui/agreement_detail.dart';
import 'package:wafa/ui/wafa_ui.dart';

import 'demo_test_helpers.dart';

const _emptyEvidence =
    'No evidence yet. Add receipts, photos or bank confirmations so everyone '
    'has the same record.';
const _demoAdded =
    'Demo: file added. In the real app you choose it from your phone.';
const _noType = 'Choose what you are adding first.';
const _atCapacity = 'This agreement has 25 files, the most it can hold.';

final _addEvidence = find.byKey(const ValueKey('add-evidence'));
final _chooseFile = find.byKey(const ValueKey('choose-evidence-file'));
final _removeEvidence = find.byTooltip('Remove evidence');

Finder _meter(int count) => find.text(
  '$count of 25 files on this agreement · up to 10 MB each',
  findRichText: true,
);

Agreement _createDraft(DemoAgreementRepository repository) =>
    repository.createDraft(
      kind: ContractKind.sale,
      counterparty: 'Bilal Ahmed',
      title: 'Laptop sale',
      amountPence: 30000,
      dueDate: DateTime(2026, 12, 15),
    );

Future<void> _showDetail(
  WidgetTester tester,
  DemoAgreementRepository repository,
  String agreementId, {
  DemoConnectionsRepository? connections,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: wafaTheme,
      home: AgreementDetail(
        key: ValueKey(agreementId),
        repository: repository,
        connections: connections ?? connectionsFor(repository),
        id: agreementId,
        onChanged: () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _openAdd(WidgetTester tester) async {
  await _reveal(tester, _addEvidence);
  await tester.tap(_addEvidence);
  await tester.pumpAndSettle();
  expect(find.text('Add evidence'), findsOneWidget);
}

Future<void> _choosePhoto(WidgetTester tester) async {
  final photo = find.text('Photo');
  await tester.ensureVisible(photo);
  await tester.pumpAndSettle();
  await tester.tap(photo);
  await tester.tap(_chooseFile);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows Evidence on each seeded agreement and a new Draft', (
    tester,
  ) async {
    final repository = DemoAgreementRepository();
    _createDraft(repository);

    for (final agreement in repository.agreements) {
      await _showDetail(tester, repository, agreement.id);
      await _reveal(tester, _addEvidence);
      expect(find.text('Evidence'), findsOneWidget);
      expect(find.text('+ Add'), findsOneWidget);
    }
  });

  testWidgets('shows the locked sample evidence on the two named agreements', (
    tester,
  ) async {
    final repository = DemoAgreementRepository();
    await _showDetail(tester, repository, 'demo-service-001');
    await _reveal(tester, _meter(2));
    expect(find.text('Garden before the work'), findsOneWidget);
    expect(find.text('Photo · 2.4 MB · added 2 Oct'), findsOneWidget);
    expect(find.text('Plants receipt'), findsOneWidget);
    expect(find.text('Receipt · 0.3 MB · added 5 Oct'), findsOneWidget);
    expect(_removeEvidence, findsNothing);

    await _showDetail(tester, repository, 'demo-family-001');
    await _reveal(tester, _meter(1));
    expect(find.text('Transfer to Sara · £100'), findsOneWidget);
    expect(
      find.text('Bank confirmation · 0.2 MB · added 1 Nov'),
      findsOneWidget,
    );
    expect(_removeEvidence, findsNothing);

    for (final agreement in repository.agreements) {
      if (agreement.id == 'demo-service-001' ||
          agreement.id == 'demo-family-001') {
        continue;
      }
      expect(repository.evidenceFor(agreement.id), isEmpty);
    }
  });

  testWidgets('shows empty copy and requires a type before choosing a file', (
    tester,
  ) async {
    final repository = DemoAgreementRepository();
    const id = 'demo-loan-001';
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _showDetail(tester, repository, id);
    await _reveal(tester, _meter(0));
    expect(find.text(_emptyEvidence), findsOneWidget);
    await _openAdd(tester);
    expect(find.text('Family support · what are you adding?'), findsOneWidget);
    for (final type in [
      'Photo',
      'Receipt',
      'Bank confirmation',
      'Document',
      'Voice note',
    ]) {
      expect(find.text(type), findsOneWidget);
    }
    expect(_meter(0), findsOneWidget);
    await tester.tap(_chooseFile);
    await tester.pumpAndSettle();
    expect(find.text(_noType), findsOneWidget);
    expect(repository.evidenceFor(id), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('updates the meter at 25 and refuses another demo file', (
    tester,
  ) async {
    final repository = DemoAgreementRepository();
    const id = 'demo-loan-001';
    for (var count = 0; count < 24; count++) {
      repository.addEvidence(
        id,
        type: EvidenceType.receipt,
        addedByPersonId: demoAmina.id,
      );
    }

    await _showDetail(tester, repository, id);
    await _openAdd(tester);
    await _reveal(tester, _meter(24));
    expect(_meter(24), findsOneWidget);

    await _choosePhoto(tester);
    await _reveal(tester, _meter(25));
    expect(_meter(25), findsOneWidget);
    expect(repository.evidenceFor(id), hasLength(25));
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    await tester.tap(_chooseFile);
    await tester.pumpAndSettle();
    expect(find.text(_atCapacity), findsOneWidget);
    expect(repository.evidenceFor(id), hasLength(25));
    expect(repository.evidenceFor('demo-rental-001'), isEmpty);
  });

  testWidgets('adds a fictional photo and lets its adder remove it in Draft', (
    tester,
  ) async {
    final repository = DemoAgreementRepository(
      clock: () => DateTime(2026, 11, 10),
    );
    final draft = _createDraft(repository);
    await _showDetail(tester, repository, draft.id);
    await _openAdd(tester);
    await _choosePhoto(tester);
    expect(find.text(_demoAdded), findsOneWidget);
    await _reveal(tester, _meter(1));
    expect(_meter(1), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await _reveal(tester, _removeEvidence);
    expect(find.text('Laptop photo'), findsOneWidget);
    expect(find.text('Photo · 1.6 MB · added 10 Nov'), findsOneWidget);
    expect(find.text('×'), findsOneWidget);
    await tester.tap(_removeEvidence);
    await tester.pumpAndSettle();
    await _reveal(tester, _meter(0));
    expect(_removeEvidence, findsNothing);
    expect(find.text(_emptyEvidence), findsOneWidget);
    expect(repository.evidenceFor(draft.id), isEmpty);
  });

  testWidgets(
    'keeps evidence and hides removal when a Draft becomes awaiting',
    (tester) async {
      final repository = _DraftStatusFixture();
      final draft = _createDraft(repository);
      final connections = connectionsFor(repository);
      final evidence = repository.addEvidence(
        draft.id,
        type: EvidenceType.photo,
        addedByPersonId: demoAmina.id,
      );
      await _showDetail(tester, repository, draft.id, connections: connections);
      await _reveal(tester, _removeEvidence);
      expect(_removeEvidence, findsOneWidget);

      repository.awaitingId = draft.id;
      await _showDetail(tester, repository, draft.id, connections: connections);
      await _reveal(tester, find.text(evidence.name));
      expect(find.text(evidence.name), findsOneWidget);
      expect(find.text('×'), findsNothing);
      expect(_removeEvidence, findsNothing);
      expect(repository.evidenceFor(draft.id), contains(evidence));

      const awaiting = 'demo-sale-001';
      final awaitingEvidence = repository.addEvidence(
        awaiting,
        type: EvidenceType.photo,
        addedByPersonId: demoAmina.id,
      );
      expect(
        repository.removeEvidence(
          awaiting,
          awaitingEvidence,
          personId: demoAmina.id,
        ),
        isFalse,
      );
    },
  );

  testWidgets('a confirmed participant can only remove their own evidence', (
    tester,
  ) async {
    final repository = DemoAgreementRepository();
    final draft = _createDraft(repository);
    final connections = connectionsFor(repository);
    final invite = connections.createInvite(
      draft.id,
      ParticipantRole.witness,
      intendedPersonId: demoSara.id,
    );
    connections.signIn(DemoLoginMethod.google, demoSara.id);
    connections.requestJoin(invite.code);
    connections.signIn(DemoLoginMethod.apple, demoAmina.id);
    connections.confirmRequest(invite.id);
    connections.signIn(DemoLoginMethod.google, demoSara.id);

    final ownerEvidence = repository.addEvidence(
      draft.id,
      type: EvidenceType.photo,
      addedByPersonId: demoAmina.id,
    );
    await _showDetail(tester, repository, draft.id, connections: connections);
    await _reveal(tester, find.text(ownerEvidence.name));
    expect(find.text(ownerEvidence.name), findsOneWidget);
    expect(_removeEvidence, findsNothing);
    expect(
      repository.removeEvidence(draft.id, ownerEvidence, personId: demoSara.id),
      isFalse,
    );

    final witnessEvidence = repository.addEvidence(
      draft.id,
      type: EvidenceType.receipt,
      addedByPersonId: demoSara.id,
    );
    expect(
      repository.removeEvidence(
        draft.id,
        witnessEvidence,
        personId: demoAmina.id,
      ),
      isFalse,
    );
    await _showDetail(tester, repository, draft.id, connections: connections);
    await _reveal(tester, _removeEvidence);
    expect(_removeEvidence, findsOneWidget);
    await tester.tap(_removeEvidence);
    await tester.pumpAndSettle();
    expect(repository.evidenceFor(draft.id), [ownerEvidence]);
  });
}

// Sending signatures is outside LOCK 5. Simulate the changed status reported
// for an existing agreement, retaining the repository's local evidence.
class _DraftStatusFixture extends DemoAgreementRepository {
  String? awaitingId;

  @override
  Agreement? findById(String agreementId) {
    final agreement = super.findById(agreementId);
    if (agreement == null || awaitingId != agreementId) return agreement;
    return Agreement(
      id: agreement.id,
      counterparty: agreement.counterparty,
      title: agreement.title,
      amountPence: agreement.amountPence,
      dueDate: agreement.dueDate,
      paidPence: agreement.paidPence,
      kind: agreement.kind,
      status: AgreementStatus.awaitingSignatures,
      people: agreement.people,
    );
  }
}
