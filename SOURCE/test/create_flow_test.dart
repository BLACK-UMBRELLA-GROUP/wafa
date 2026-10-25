import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wafa/domain/demo_models.dart';
import 'package:wafa/ui/create_agreement.dart';
import 'package:wafa/ui/wafa_ui.dart';

void main() {
  DemoAgreementRepository repository() => DemoAgreementRepository(
    clock: () => DateTime(2026, 10, 13),
    seedSamples: false,
  );

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
        home: CreateAgreement(repository: demoRepository),
      ),
    );
  }

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('create-next')));
    await tester.pumpAndSettle();
  }

  Future<void> fill(
    WidgetTester tester, {
    String name = 'Amina Noor',
    String amount = '125.40',
    String title = '',
  }) async {
    await tester.enterText(find.byKey(const Key('counterparty')), name);
    await tester.enterText(find.byKey(const Key('draft-title')), title);
    await tester.enterText(find.byKey(const Key('amount')), amount);
  }

  testWidgets('all four kinds are available with stable selection keys', (
    tester,
  ) async {
    await mount(tester, repository());
    for (final kind in ContractKind.values) {
      expect(find.byKey(Key('kind-${kind.name}')), findsOneWidget);
    }
    await tester.ensureVisible(find.byKey(const Key('kind-service')));
    await tester.tap(find.byKey(const Key('kind-service')));
    await next(tester);
    expect(find.text('Agreement amount'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a missing name and malformed amounts keep the details step open',
    (tester) async {
      final demoRepository = repository();
      await mount(tester, demoRepository);
      await next(tester);
      await fill(tester, name: ' ', amount: '12.345');
      await next(tester);

      expect(find.text('Enter a fictional counterparty name.'), findsOneWidget);
      expect(
        find.text('Enter an amount above £0 with up to 2 decimal places.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('counterparty')), findsOneWidget);
      expect(demoRepository.agreements, isEmpty);

      for (final value in ['1e3', '-10', '12.3.4', '0']) {
        await fill(tester, amount: value);
        await next(tester);
        expect(find.byKey(const Key('amount')), findsOneWidget);
        expect(demoRepository.agreements, isEmpty);
      }
    },
  );

  testWidgets('valid details advance to review using exact integer pence', (
    tester,
  ) async {
    final demoRepository = repository();
    await mount(tester, demoRepository);
    await next(tester);
    await fill(tester, title: 'Family support');
    await next(tester);

    expect(find.text('A promise, put into words.'), findsOneWidget);
    expect(find.text('Family support'), findsOneWidget);
    expect(find.text(money(12540)), findsOneWidget);
    expect(find.text(dateLabel(DateTime(2026, 10, 27))), findsOneWidget);
    expect(find.text('Demo draft only'), findsOneWidget);
    expect(find.textContaining('binding agreement'), findsOneWidget);
    expect(demoRepository.agreements, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back navigation preserves fields and selected kind', (
    tester,
  ) async {
    await mount(tester, repository());
    await tester.tap(find.byKey(const Key('kind-sale')));
    await next(tester);
    await fill(tester, title: 'Bicycle sale');
    await next(tester);
    await tester.tap(find.byKey(const Key('create-back')));
    await tester.pumpAndSettle();

    TextFormField field(String key) =>
        tester.widget<TextFormField>(find.byKey(Key(key)));
    expect(field('counterparty').controller!.text, 'Amina Noor');
    expect(field('amount').controller!.text, '125.40');
    expect(field('draft-title').controller!.text, 'Bicycle sale');
    await tester.tap(find.byKey(const Key('create-back')));
    await tester.pumpAndSettle();
    await next(tester);
    expect(find.text('Agreement amount'), findsOneWidget);
    expect(field('amount').controller!.text, '125.40');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'saving returns the draft and gives an optional title a fallback',
    (tester) async {
      final demoRepository = repository();
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
                      builder: (_) =>
                          CreateAgreement(repository: demoRepository),
                    ),
                  );
                },
                child: const Text('Create'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open-create')));
      await tester.pumpAndSettle();
      await next(tester);
      await fill(tester, amount: '0.01');
      await next(tester);
      await next(tester);

      expect(result, isNotNull);
      expect(result!.amountPence, 1);
      expect(result!.counterparty, 'Amina Noor');
      expect(
        result!.title,
        '${kindLabel(ContractKind.interestFreeLoan)} with Amina Noor',
      );
      expect(result!.status, AgreementStatus.draft);
      expect(result!.paidPence, 0);
      expect(demoRepository.agreements.single, same(result));
      expect(find.byKey(const Key('open-create')), findsOneWidget);
    },
  );

  testWidgets(
    'phone layout stays scrollable with large text and keyboard inset',
    (tester) async {
      await mount(tester, repository(), textScale: 1.6);
      expect(tester.takeException(), isNull);
      await next(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('amount')));
      await fill(tester, title: 'A clear promise');
      await next(tester);
      expect(find.text('Demo draft only'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
