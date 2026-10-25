import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/demo_connections.dart';
import '../domain/demo_models.dart';
import 'wafa_ui.dart';

class AgreementDocumentScreen extends StatelessWidget {
  const AgreementDocumentScreen({
    super.key,
    required this.repository,
    required this.connections,
    required this.agreementId,
  });

  final DemoAgreementRepository repository;
  final DemoConnectionsRepository connections;
  final String agreementId;

  String _documentText(Agreement agreement) {
    final people = connections
        .participantsForAgreement(agreement.id)
        .map((participant) {
          final person = connections.person(participant.personId);
          return '- ${person?.name ?? 'Demo person'} '
              '(${person?.wafaId ?? 'No demo ID'}) — ${participant.role.label}';
        })
        .join('\n');
    return '''WAFA AGREEMENT COPY — DEMO

Agreement ID: ${agreement.id}
Status: ${agreement.status.label}

PEOPLE AND ROLES
$people

RECORDED AGREEMENT
Title: ${agreement.title}
Type: ${kindLabel(agreement.kind)}
Counterparty label: ${agreement.counterparty}

VALUE AND DATE
Value: ${money(agreement.amountPence)}
Due date: ${dateLabel(agreement.dueDate)}
Recorded paid: ${money(agreement.paidPence)}
Recorded remaining: ${money(agreement.remainingPence)}

RECORDED PURPOSE
${kindDescription(agreement.kind)}

SIGNATURE STATE
No signature is collected in this preview. Joining the agreement is not acceptance or signing.

This copy contains only the fields currently held by the Wafa demo. It is not legal advice, scholarly certification, proof of payment or a binding contract.''';
  }

  Future<void> _copy(BuildContext context, Agreement agreement) async {
    await Clipboard.setData(ClipboardData(text: _documentText(agreement)));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demo agreement text copied.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!connections.canViewAgreement(agreementId)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Agreement copy')),
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(22),
            child: SoftNote(
              icon: Icons.lock_outline_rounded,
              title: 'This agreement is private',
              body:
                  'Only confirmed fictional participants can open its document copy.',
            ),
          ),
        ),
      );
    }
    final agreement = repository.findById(agreementId);
    if (agreement == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Agreement copy')),
        body: const Center(child: Text('This demo agreement is unavailable.')),
      );
    }
    final participants = connections.participantsForAgreement(agreement.id);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agreement copy'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 22),
            child: Center(child: DemoBadge()),
          ),
        ],
      ),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
          children: [
            const SoftNote(
              icon: Icons.description_outlined,
              title: 'Generated from recorded details',
              body:
                  'Wafa shows only the information this demo actually holds. '
                  'Missing clauses are not invented. This copy is unsigned and '
                  'has no legal or scholarly approval.',
            ),
            const SizedBox(height: 18),
            Container(
              key: const ValueKey('agreement-document'),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: WafaColors.line),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D123F32),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('WAFA AGREEMENT COPY · DEMO'),
                  const SizedBox(height: 14),
                  Text(
                    agreement.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: WafaColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Agreement ID ${agreement.id}',
                    style: const TextStyle(color: WafaColors.muted),
                  ),
                  const SizedBox(height: 24),
                  _DocumentSection(
                    number: '1',
                    title: 'People and roles',
                    child: Column(
                      children: [
                        for (final participant in participants)
                          DetailRow(
                            connections.person(participant.personId)?.name ??
                                'Demo person',
                            '${connections.person(participant.personId)?.wafaId ?? ''} · ${participant.role.label} · Not signed',
                          ),
                      ],
                    ),
                  ),
                  _DocumentSection(
                    number: '2',
                    title: 'What was recorded',
                    child: Column(
                      children: [
                        DetailRow('Agreement type', kindLabel(agreement.kind)),
                        DetailRow('Counterparty label', agreement.counterparty),
                        DetailRow('Status', agreement.status.label),
                      ],
                    ),
                  ),
                  _DocumentSection(
                    number: '3',
                    title: 'Value and date',
                    child: Column(
                      children: [
                        DetailRow('Value', money(agreement.amountPence)),
                        DetailRow('Due date', dateLabel(agreement.dueDate)),
                        DetailRow('Recorded paid', money(agreement.paidPence)),
                        DetailRow(
                          'Recorded remaining',
                          money(agreement.remainingPence),
                        ),
                      ],
                    ),
                  ),
                  _DocumentSection(
                    number: '4',
                    title: 'Recorded purpose',
                    child: Text(
                      kindDescription(agreement.kind),
                      style: const TextStyle(height: 1.6),
                    ),
                  ),
                  const _DocumentSection(
                    number: '5',
                    title: 'Signature state',
                    child: Text(
                      'No signature is collected in this preview. Joining the '
                      'agreement is not acceptance or signing.',
                      style: TextStyle(height: 1.6),
                    ),
                  ),
                  const Divider(height: 32),
                  const Text(
                    'Unsigned local preview · Not legal advice · Not scholarly certification · Not proof of payment',
                    style: TextStyle(
                      color: WafaColors.muted,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              key: const ValueKey('copy-agreement-text'),
              onPressed: () => _copy(context, agreement),
              icon: const Icon(Icons.copy_all_outlined),
              label: const Text('Copy demo agreement text'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentSection extends StatelessWidget {
  const _DocumentSection({
    required this.number,
    required this.title,
    required this.child,
  });

  final String number;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$number. $title',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: WafaColors.green,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}
