import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wafa/domain/demo_connections.dart';
import 'package:wafa/domain/demo_models.dart';
import 'package:wafa/ui/agreement_document.dart';
import 'package:wafa/ui/wafa_ui.dart';

import 'demo_test_helpers.dart';

void main() {
  Future<void> mountDocument(
    WidgetTester tester,
    DemoAgreementRepository repository,
    DemoConnectionsRepository connections, {
    String id = 'demo-loan-001',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: wafaTheme,
        home: AgreementDocumentScreen(
          repository: repository,
          connections: connections,
          agreementId: id,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows only the recorded agreement fields and safeguards', (
    tester,
  ) async {
    final repository = DemoAgreementRepository();
    await mountDocument(tester, repository, connectionsFor(repository));

    expect(find.byKey(const ValueKey('agreement-document')), findsOneWidget);
    expect(find.text('Family support'), findsOneWidget);
    expect(find.text('£480'), findsOneWidget);
    expect(find.text('Amina Noor'), findsOneWidget);
    expect(find.textContaining('No signature is collected'), findsOneWidget);
    expect(find.textContaining('Not legal advice'), findsOneWidget);
    expect(find.textContaining('interest rate'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('copies a labelled unsigned demo record', (tester) async {
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    final repository = DemoAgreementRepository();
    await mountDocument(tester, repository, connectionsFor(repository));

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('copy-agreement-text')),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('copy-agreement-text')));
    await tester.pumpAndSettle();

    expect(copiedText, contains('WAFA AGREEMENT COPY — DEMO'));
    expect(copiedText, contains('Agreement ID: demo-loan-001'));
    expect(copiedText, contains('No signature is collected'));
  });

  testWidgets('does not reveal a document before participant confirmation', (
    tester,
  ) async {
    final repository = DemoAgreementRepository();
    final connections = connectionsFor(repository);
    final draft = repository.createDraft(
      kind: ContractKind.service,
      counterparty: 'Private draft label',
      title: 'Private document',
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

    await mountDocument(tester, repository, connections, id: draft.id);

    expect(find.text('This agreement is private'), findsOneWidget);
    expect(find.text('Private document'), findsNothing);
    expect(find.textContaining('£'), findsNothing);
    expect(find.byKey(const ValueKey('agreement-document')), findsNothing);
  });

  testWidgets('document remains overflow-free with large text', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final repository = DemoAgreementRepository();

    await mountDocument(tester, repository, connectionsFor(repository));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
