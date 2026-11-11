import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wafa/domain/demo_connections.dart';
import 'package:wafa/main.dart';
import 'package:wafa/ui/wafa_ui.dart';

import 'demo_test_helpers.dart';

void main() {
  testWidgets('Profile and the payer chooser reflect each verification level', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(WafaApp(connections: signedInConnections()));
    await tester.pumpAndSettle();

    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    final verification = find.text('Verification');
    final back = find.byTooltip('Back');
    final badge = find.byType(VerificationBadge);
    final profile = find.text('Profile');

    Future<void> expectPayerBadge(String? label) async {
      await tap(find.text('Agreements'));
      final agreement = find.text("Mum's care costs");
      await tester.scrollUntilVisible(
        agreement,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tap(agreement);
      await tap(find.byKey(const ValueKey('record-payment')));
      expect(find.text('Who paid?'), findsOneWidget);

      final payer = find.byKey(ValueKey('payer-${demoAmina.id}'));
      final payerBadge = find.descendant(of: payer, matching: badge);
      expect(payer, findsOneWidget);
      expect(payerBadge, label == null ? findsNothing : findsOneWidget);
      if (label != null) {
        expect(
          find.descendant(of: payerBadge, matching: find.text(label)),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(
          of: find.byKey(ValueKey('payer-${demoOmar.id}')),
          matching: find.text('✓ Verified'),
        ),
        findsOneWidget,
      );

      await tap(back);
      await tap(back);
      await tap(profile);
    }

    await tap(profile);
    expect(find.text('Not verified yet'), findsOneWidget);
    expect(badge, findsNothing);
    await expectPayerBadge(null);
    await tap(verification);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(badge, findsNothing);

    await tap(find.widgetWithText(OutlinedButton, 'Add'));
    expect(find.text('Done'), findsNWidgets(2));
    expect(
      find.descendant(of: badge, matching: find.text('Basic')),
      findsOneWidget,
    );
    expect(
      find.text(
        'Demo: confirmed. In the real app you enter a code we send you.',
      ),
      findsOneWidget,
    );
    await tap(back);
    expect(find.text('Basic · add photo ID to be Verified'), findsOneWidget);
    expect(
      find.descendant(of: badge, matching: find.text('Basic')),
      findsOneWidget,
    );

    await expectPayerBadge('Basic');
    await tap(verification);
    await tap(find.widgetWithText(OutlinedButton, 'Verify'));
    expect(find.text('Done'), findsNWidgets(3));
    expect(
      find.text(
        'Demo: identity checked. In the real app a specialist ID company does this.',
      ),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Verified'), findsOneWidget);
    expect(
      find.descendant(of: badge, matching: find.text('✓ Verified')),
      findsOneWidget,
    );

    await expectPayerBadge('✓ Verified');
    await tap(verification);
    await tap(find.text('Demo: start again as email only'));
    expect(find.text('Done'), findsOneWidget);
    expect(badge, findsNothing);
    await tap(back);
    expect(find.text('Not verified yet'), findsOneWidget);
    await expectPayerBadge(null);
    expect(tester.takeException(), isNull);
  });
}
