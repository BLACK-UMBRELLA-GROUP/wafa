import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wafa/main.dart';
import 'package:wafa/ui/wafa_ui.dart';

import 'demo_test_helpers.dart';

void main() {
  testWidgets('Profile reflects each simulated verification level', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(WafaApp(connections: signedInConnections()));
    await tester.pumpAndSettle();

    Future<void> tap(Finder finder) async {
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    final verification = find.text('Verification');
    final back = find.byTooltip('Back');
    final badge = find.byType(VerificationBadge);
    await tap(find.text('Profile'));
    expect(find.text('Not verified yet'), findsOneWidget);
    expect(badge, findsNothing);
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

    await tap(verification);
    await tap(find.text('Demo: start again as email only'));
    expect(find.text('Done'), findsOneWidget);
    expect(badge, findsNothing);
    await tap(back);
    expect(find.text('Not verified yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
