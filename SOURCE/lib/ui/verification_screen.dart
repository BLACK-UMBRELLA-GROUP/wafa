import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/demo_connections.dart';
import 'wafa_ui.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({
    super.key,
    required this.connections,
    required this.onBack,
  });

  final DemoConnectionsRepository connections;
  final VoidCallback onBack;

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  void _confirm(DemoVerificationCheck check) {
    setState(() => widget.connections.confirmDemoVerificationCheck(check));
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            check == DemoVerificationCheck.photoIdAndSelfie
                ? 'Demo: identity checked. In the real app a specialist ID company does this.'
                : 'Demo: confirmed. In the real app you enter a code we send you.',
          ),
        ),
      );
  }

  void _reset() {
    ScaffoldMessenger.of(context).clearSnackBars();
    setState(widget.connections.resetDemoVerification);
  }

  @override
  Widget build(BuildContext context) {
    final person = widget.connections.currentPerson!;
    final level = widget.connections.verificationLevelFor(person.id);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: math.max(0, constraints.maxHeight - 24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Back',
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xfff5f8f6),
                          foregroundColor: WafaColors.ink,
                        ),
                        onPressed: widget.onBack,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Verification',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: WafaColors.mint,
                        foregroundColor: WafaColors.green,
                        child: Text(
                          person.name.characters.first.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            VerificationName(
                              person.name,
                              level,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Others see your badge next to your name on every agreement. Verification is optional.',
                              style: TextStyle(
                                fontSize: 13,
                                color: WafaColors.muted,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _levelBox(
                          'Basic',
                          'Email + phone',
                          reached: level != VerificationLevel.none,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _levelBox(
                          'Verified',
                          '+ photo ID and selfie',
                          reached: level == VerificationLevel.verified,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: WafaColors.line),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        _checkRow(
                          DemoVerificationCheck.email,
                          'Email address',
                          'Confirmed by a code we email you',
                          'Add',
                        ),
                        const Divider(height: 1),
                        _checkRow(
                          DemoVerificationCheck.phone,
                          'Phone number',
                          'Confirmed by a text message code',
                          'Add',
                        ),
                        const Divider(height: 1),
                        _checkRow(
                          DemoVerificationCheck.photoIdAndSelfie,
                          'Photo ID and selfie',
                          'A passport or driving licence, matched to a live selfie',
                          'Verify',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Photo ID is checked by a specialist ID company. Wafa keeps the result, not a copy of your ID.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: WafaColors.muted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: CustomPaint(
                  foregroundPainter: const _ResetOutline(),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xfffbfdfb),
                      foregroundColor: WafaColors.muted,
                      minimumSize: const Size(0, 44),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    onPressed: _reset,
                    child: const Text('Demo: start again as email only'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _levelBox(String title, String subtitle, {required bool reached}) {
    final color = reached ? WafaColors.green : WafaColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: reached ? WafaColors.mint : Colors.white,
        border: Border.all(color: reached ? WafaColors.green : WafaColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(subtitle, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _checkRow(
    DemoVerificationCheck check,
    String title,
    String subtitle,
    String action,
  ) {
    final done = widget.connections.isVerificationCheckDone(check);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: WafaColors.mint,
            foregroundColor: WafaColors.green,
            child: done
                ? const Icon(Icons.check_circle_outline, size: 18)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: WafaColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (done)
            const Text(
              'Done',
              style: TextStyle(
                color: WafaColors.green,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: WafaColors.green,
                minimumSize: const Size(0, 30),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                side: const BorderSide(color: WafaColors.green),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => _confirm(check),
              child: Text(action),
            ),
        ],
      ),
    );
  }
}

class _ResetOutline extends CustomPainter {
  const _ResetOutline();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(.5),
          const Radius.circular(12),
        ),
      );
    final paint = Paint()
      ..color = const Color(0xffb7c7bd)
      ..style = PaintingStyle.stroke;
    final outline = path.computeMetrics().first;
    for (double offset = 0; offset < outline.length; offset += 5) {
      canvas.drawPath(outline.extractPath(offset, offset + 3), paint);
    }
  }

  @override
  bool shouldRepaint(_ResetOutline oldDelegate) => false;
}
