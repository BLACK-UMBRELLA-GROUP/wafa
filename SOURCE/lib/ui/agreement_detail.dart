import 'package:flutter/material.dart';

import '../domain/demo_connections.dart';
import '../domain/demo_models.dart';
import 'agreement_document.dart';
import 'participants_screen.dart';
import 'payments_screen.dart';
import 'wafa_ui.dart';

class AgreementDetail extends StatefulWidget {
  const AgreementDetail({
    super.key,
    required this.repository,
    required this.connections,
    required this.id,
    required this.onChanged,
  });

  final DemoAgreementRepository repository;
  final DemoConnectionsRepository connections;
  final String id;
  final VoidCallback onChanged;

  @override
  State<AgreementDetail> createState() => _AgreementDetailState();
}

class _AgreementDetailState extends State<AgreementDetail> {
  void _completeObligation() {
    if (!_currentPersonCanAct()) {
      _showChangedRecordMessage();
      return;
    }
    try {
      widget.repository.completeObligation(widget.id);
      setState(() {});
      widget.onChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demo obligation marked complete.')),
      );
    } on ArgumentError {
      _showChangedRecordMessage();
    } on StateError {
      _showChangedRecordMessage();
    }
  }

  bool _currentPersonCanAct() {
    final currentId = widget.connections.currentPerson?.id;
    if (currentId == null || !widget.connections.canViewAgreement(widget.id)) {
      return false;
    }
    return widget.connections
        .participantsForAgreement(widget.id)
        .any(
          (participant) =>
              participant.personId == currentId &&
              participant.role == ParticipantRole.party,
        );
  }

  Future<void> _openPeople() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ParticipantsScreen(
          connections: widget.connections,
          agreementId: widget.id,
          onChanged: () {
            if (mounted) setState(() {});
            widget.onChanged();
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openDocument() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AgreementDocumentScreen(
          repository: widget.repository,
          connections: widget.connections,
          agreementId: widget.id,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openPayments() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PaymentsScreen(
          repository: widget.repository,
          connections: widget.connections,
          agreementId: widget.id,
          onChanged: () {
            if (mounted) setState(() {});
            widget.onChanged();
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void _showChangedRecordMessage() {
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'This demo record has changed. Check its latest details.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.connections.canViewAgreement(widget.id)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Agreement')),
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(22),
            child: SoftNote(
              icon: Icons.lock_outline_rounded,
              title: 'This agreement is private',
              body:
                  'An invitation request does not reveal the agreement. The '
                  'creator must confirm your fictional Wafa account first.',
            ),
          ),
        ),
      );
    }
    final agreement = widget.repository.findById(widget.id);
    if (agreement == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Agreement')),
        body: const Center(child: Text('This demo agreement is unavailable.')),
      );
    }

    final theme = Theme.of(context);
    final participants = widget.connections.participantsForAgreement(widget.id);
    final canManagePeople = widget.connections.canManageParticipants(widget.id);
    final canAct = _currentPersonCanAct();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agreement'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 22),
            child: Center(child: DemoBadge()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
        children: [
          Row(
            children: [
              KindMark(agreement.kind),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  kindLabel(agreement.kind),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: WafaColors.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              StatusBadge(agreement.status),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            agreement.title,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: WafaColors.ink,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            agreement.status == AgreementStatus.draft
                ? 'Draft label: ${agreement.counterparty}'
                : 'With ${agreement.counterparty}',
            style: theme.textTheme.bodyLarge?.copyWith(color: WafaColors.muted),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: WafaColors.green,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AGREEMENT VALUE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  money(agreement.amountPence),
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Due ${dateLabel(agreement.dueDate)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                if (agreement.isLoan) ...[
                  const SizedBox(height: 22),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: agreement.progress,
                      minHeight: 5,
                      color: WafaColors.mint,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${money(agreement.paidPence)} recorded',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        '${money(agreement.remainingPence)} left',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          const SectionTitle('Agreement record'),
          const SizedBox(height: 12),
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Open the document-style copy or review payment dates, methods and notes.',
                  style: TextStyle(color: WafaColors.muted, height: 1.5),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const ValueKey('open-agreement-document'),
                    onPressed: _openDocument,
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('View agreement copy'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const ValueKey('open-payments'),
                    onPressed: _openPayments,
                    icon: const Icon(Icons.payments_outlined),
                    label: Text(
                      'Payments & dates · '
                      '${widget.repository.paymentsFor(agreement.id).length}',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              const Expanded(child: SectionTitle('People on this agreement')),
              Text(
                '${participants.length}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: WafaColors.green,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Surface(
            key: const ValueKey('agreement-participants'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final participant in participants) ...[
                  Builder(
                    builder: (_) {
                      final person = widget.connections.person(
                        participant.personId,
                      );
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: WafaColors.mint,
                          foregroundColor: WafaColors.green,
                          child: Icon(Icons.person_outline_rounded),
                        ),
                        title: Text(person?.name ?? 'Demo person'),
                        subtitle: Text(
                          '${person?.wafaId ?? ''} · ${participant.role.label} · Not signed',
                        ),
                      );
                    },
                  ),
                  if (participant != participants.last) const Divider(),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const ValueKey('open-participants'),
                    onPressed: _openPeople,
                    icon: Icon(
                      canManagePeople
                          ? Icons.person_add_alt_1_outlined
                          : Icons.people_outline_rounded,
                    ),
                    label: Text(
                      canManagePeople ? 'Add or manage people' : 'View people',
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (agreement.status == AgreementStatus.draft) ...[
            const SizedBox(height: 12),
            const SoftNote(
              icon: Icons.link_off_outlined,
              title: 'Draft name is not a linked person',
              body:
                  'The name typed while creating this draft is only a label. '
                  'Use People to invite a fictional Wafa account. Joining '
                  'still does not accept terms or sign the agreement.',
            ),
          ],
          const SizedBox(height: 28),
          const SectionTitle('The details'),
          const SizedBox(height: 12),
          Surface(
            child: Column(
              children: [
                DetailRow('Agreement type', kindLabel(agreement.kind)),
                DetailRow(
                  agreement.status == AgreementStatus.draft
                      ? 'Draft label'
                      : 'With',
                  agreement.counterparty,
                ),
                DetailRow('Due date', dateLabel(agreement.dueDate)),
                DetailRow('Value', money(agreement.amountPence)),
                DetailRow('Recorded paid', money(agreement.paidPence)),
                DetailRow('Remaining', money(agreement.remainingPence)),
                DetailRow('Status', agreement.status.label),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const SectionTitle('Agreement preview'),
          const SizedBox(height: 12),
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('FICTIONAL EXAMPLE · PREVIEW ONLY'),
                const SizedBox(height: 14),
                Text(
                  agreement.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'An example ${kindLabel(agreement.kind).toLowerCase()} with '
                  '${agreement.counterparty}, valued at ${money(agreement.amountPence)} '
                  'and due ${dateLabel(agreement.dueDate)}.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
                const SizedBox(height: 12),
                Text(
                  kindDescription(agreement.kind),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: WafaColors.muted,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  _statusNote(agreement),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: WafaColors.muted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SoftNote(
            icon: Icons.info_outline_rounded,
            title: 'A local demo',
            body:
                'These are fictional records. Demo actions do not send money '
                'or collect signatures. This preview has no legal or scholarly approval.',
          ),
        ],
      ),
      bottomNavigationBar:
          canAct &&
              (agreement.canRecordPayment || agreement.canCompleteObligation)
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(22, 12, 22, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (agreement.canRecordPayment)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: ValueKey(
                          agreement.isLoan
                              ? 'record-repayment'
                              : 'record-payment',
                        ),
                        onPressed: _openPayments,
                        icon: const Icon(Icons.add_card_outlined),
                        label: const Text('Open payment record'),
                      ),
                    ),
                  if (agreement.canCompleteObligation) ...[
                    const SizedBox(height: 6),
                    TextButton.icon(
                      key: const ValueKey('complete-obligation'),
                      onPressed: _completeObligation,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Mark demo obligation complete'),
                    ),
                  ],
                ],
              ),
            )
          : null,
    );
  }

  String _statusNote(Agreement agreement) => switch (agreement.status) {
    AgreementStatus.draft => 'A demo draft. No signature has been requested.',
    AgreementStatus.awaitingSignatures =>
      'Awaiting signatures in this example. Signing is unavailable in this preview.',
    AgreementStatus.completed => 'This demo record is complete.',
    AgreementStatus.active ||
    AgreementStatus.overdue => 'Demo changes affect this example only.',
  };
}
