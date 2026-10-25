import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wafa/main.dart';
import 'package:wafa/domain/demo_models.dart';
import 'package:wafa/ui/wafa_ui.dart';
import 'package:wafa/ui/agreement_detail.dart';

import 'demo_test_helpers.dart';

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
    expect(find.text('wafa'), findsOneWidget);
    expect(find.text('PREVIEW'), findsOneWidget);
    expect(find.text('Create an agreement'), findsOneWidget);
    expect(wafaTheme.scaffoldBackgroundColor, Colors.white);
    await tester.tap(find.text('Tracker'));
    await tester.pumpAndSettle();
    expect(find.text('A clearer picture'), findsOneWidget);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Demo profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'create flow saves a session-local draft and shows it in Drafts',
    (tester) async {
      final repository = DemoAgreementRepository();
      final before = repository.agreements.length;
      await tester.pumpWidget(
        WafaApp(repository: repository, connections: signedInConnections()),
      );
      await tester.drag(find.byType(ListView).first, const Offset(0, -220));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('create-agreement')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('create-next')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('counterparty')),
        'Demo Person',
      );
      await tester.enterText(find.byKey(const Key('amount')), '250.50');
      await tester.enterText(
        find.byKey(const Key('draft-title')),
        'Demo test agreement',
      );
      await tester.tap(find.byKey(const Key('create-next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('create-next')));
      await tester.pumpAndSettle();
      expect(repository.agreements.length, before + 1);
      expect(find.text('Demo test agreement'), findsOneWidget);
      expect(tester.takeException(), isNull);
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
