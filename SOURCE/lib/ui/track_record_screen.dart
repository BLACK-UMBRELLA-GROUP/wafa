import 'package:flutter/material.dart';

import '../domain/demo_connections.dart';
import 'wafa_ui.dart';

class TrackRecordScreen extends StatelessWidget {
  const TrackRecordScreen({
    super.key,
    required this.record,
    required this.onBack,
    this.personName,
    this.isShared = false,
    this.onSharingChanged,
  });

  final DemoTrackRecord record;
  final VoidCallback onBack;
  final String? personName;
  final bool isShared;
  final ValueChanged<bool>? onSharingChanged;

  @override
  Widget build(BuildContext context) {
    final name = personName;
    final firstName = name?.split(' ').first;
    final changeSharing = onSharingChanged;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      children: [
        Row(
          children: [
            IconButton.filledTonal(
              tooltip: 'Back',
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xfff5f8f6),
                foregroundColor: WafaColors.ink,
              ),
              onPressed: onBack,
              icon: const Icon(Icons.chevron_left),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name ?? 'Your track record',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: WafaColors.mint,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: name == null ? 14 : 22,
                color: WafaColors.green,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name == null ? 'Your track record' : 'Track record',
                      style: const TextStyle(
                        color: WafaColors.green,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      name == null
                          ? 'Only facts, never a score. You choose whether '
                                'people on your agreements can see it.'
                          : 'Shared by $firstName. Facts only, never a score.',
                      style: const TextStyle(
                        color: WafaColors.muted,
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Surface(
          child: Column(
            spacing: 9,
            children: [
              _fact('Agreements completed', '${record.completed}'),
              _fact('Paid on time', record.paidOnTimeLabel),
              _fact('Extensions agreed', '${record.extensions}'),
              _fact('Open now', '${record.open}'),
              _fact('On Wafa since', record.since),
            ],
          ),
        ),
        const SizedBox(height: 26),
        const Text(
          'An extension both sides agreed is never counted as late. '
          'Wealth, amounts and income are never used.',
          style: TextStyle(
            color: WafaColors.muted,
            fontSize: 12.5,
            height: 1.5,
          ),
        ),
        if (changeSharing != null) ...[
          const SizedBox(height: 16),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: WafaColors.ink,
              side: const BorderSide(color: WafaColors.line),
              minimumSize: const Size(48, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => changeSharing(!isShared),
            child: Text(
              isShared
                  ? 'Stop sharing my record'
                  : 'Share my record on my agreements',
            ),
          ),
        ],
      ],
    );
  }

  Widget _fact(String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: WafaColors.muted, fontSize: 15),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}
