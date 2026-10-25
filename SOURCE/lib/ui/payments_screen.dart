import 'package:flutter/material.dart';

import '../domain/demo_connections.dart';
import '../domain/demo_models.dart';
import 'wafa_ui.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({
    super.key,
    required this.repository,
    required this.connections,
    required this.agreementId,
    required this.onChanged,
  });

  final DemoAgreementRepository repository;
  final DemoConnectionsRepository connections;
  final String agreementId;
  final VoidCallback onChanged;

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  bool get _currentPersonIsParty {
    final currentId = widget.connections.currentPerson?.id;
    return currentId != null &&
        widget.connections
            .participantsForAgreement(widget.agreementId)
            .any(
              (participant) =>
                  participant.personId == currentId &&
                  participant.role == ParticipantRole.party,
            );
  }

  Future<void> _addPayment(Agreement agreement) async {
    final actingPersonId = widget.connections.currentPerson?.id;
    if (actingPersonId == null || !_currentPersonIsParty) return;
    final draft = await showDialog<_PaymentDraft>(
      context: context,
      builder: (_) => _PaymentDialog(
        today: widget.repository.today,
        remainingPence: agreement.remainingPence,
      ),
    );
    if (!mounted || draft == null) return;
    if (widget.connections.currentPerson?.id != actingPersonId ||
        !_currentPersonIsParty ||
        !widget.connections.canViewAgreement(widget.agreementId)) {
      _showUnavailable();
      return;
    }
    try {
      widget.repository.recordPayment(
        widget.agreementId,
        amountPence: draft.amountPence,
        paidOn: draft.paidOn,
        method: draft.method,
        recordedByPersonId: actingPersonId,
        note: draft.note,
        reference: draft.reference,
      );
      setState(() {});
      widget.onChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${money(draft.amountPence)} demo payment recorded.'),
        ),
      );
    } on ArgumentError {
      _showUnavailable();
    } on StateError {
      _showUnavailable();
    }
  }

  void _showUnavailable() {
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'This demo payment could not be recorded. Check the latest balance and access.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.connections.canViewAgreement(widget.agreementId)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payments')),
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(22),
            child: SoftNote(
              icon: Icons.lock_outline_rounded,
              title: 'Payment records are private',
              body:
                  'Only confirmed fictional participants can view this timeline.',
            ),
          ),
        ),
      );
    }
    final agreement = widget.repository.findById(widget.agreementId);
    if (agreement == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payments')),
        body: const Center(child: Text('This demo agreement is unavailable.')),
      );
    }
    final payments = widget.repository.paymentsFor(agreement.id);
    final canAdd = _currentPersonIsParty && agreement.canRecordPayment;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 22),
            child: Center(child: DemoBadge()),
          ),
        ],
      ),
      body: ListView(
        key: const ValueKey('payments-list'),
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
        children: [
          const PageHeading(
            'A clear payment record.',
            subtitle: 'Dates, methods and notes in one shared timeline.',
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: WafaColors.green,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agreement.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                _LightRow('Agreement value', money(agreement.amountPence)),
                _LightRow('Recorded paid', money(agreement.paidPence)),
                _LightRow('Remaining', money(agreement.remainingPence)),
                _LightRow('Agreement due', dateLabel(agreement.dueDate)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SoftNote(
            icon: Icons.verified_user_outlined,
            title: 'Record, not verification',
            body:
                'Wafa does not connect to a bank or prove money moved. Both '
                'parties should check the real payment. Never put account '
                'numbers, card details or sensitive banking data in notes.',
          ),
          const SizedBox(height: 24),
          if (canAdd) ...[
            FilledButton.icon(
              key: const ValueKey('add-payment'),
              onPressed: () => _addPayment(agreement),
              icon: const Icon(Icons.add_card_outlined),
              label: const Text('Record a demo payment'),
            ),
            const SizedBox(height: 24),
          ] else if (!_currentPersonIsParty) ...[
            const SoftNote(
              icon: Icons.visibility_outlined,
              title: 'View-only role',
              body:
                  'Witnesses can view this fictional timeline but cannot add payment records.',
            ),
            const SizedBox(height: 24),
          ] else if (!agreement.canRecordPayment) ...[
            SoftNote(
              icon: Icons.lock_clock_outlined,
              title: 'Payment entry unavailable',
              body:
                  'This ${agreement.status.label.toLowerCase()} demo agreement '
                  'is not open for new payment records.',
            ),
            const SizedBox(height: 24),
          ],
          const SectionTitle('Payment timeline'),
          const SizedBox(height: 12),
          if (payments.isEmpty)
            Surface(
              child: Text(
                agreement.paidPence > 0
                    ? 'A balance is recorded, but no itemised payments are available for this demo agreement.'
                    : 'No itemised payments have been recorded for this demo agreement.',
                style: const TextStyle(color: WafaColors.muted, height: 1.5),
              ),
            ),
          for (final payment in payments)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PaymentCard(
                payment: payment,
                recorder: widget.connections.person(payment.recordedByPersonId),
              ),
            ),
          const SizedBox(height: 18),
          const SectionTitle('Payment schedule'),
          const SizedBox(height: 12),
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DetailRow('Current due date', dateLabel(agreement.dueDate)),
                DetailRow('Amount remaining', money(agreement.remainingPence)),
                const SizedBox(height: 8),
                const Text(
                  'This first preview supports one overall due date. Agreed '
                  'instalment schedules, reminders and receipt evidence will '
                  'need a later, separately designed flow.',
                  style: TextStyle(color: WafaColors.muted, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LightRow extends StatelessWidget {
  const _LightRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment, required this.recorder});
  final DemoPayment payment;
  final DemoPerson? recorder;

  @override
  Widget build(BuildContext context) => Surface(
    key: ValueKey('payment-${payment.id}'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                money(payment.amountPence),
                style: const TextStyle(
                  color: WafaColors.green,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              dateLabel(payment.paidOn),
              style: const TextStyle(color: WafaColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '${payment.method.label} · Recorded by ${recorder?.name ?? 'Demo record'}',
        ),
        if (payment.reference.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Reference: ${payment.reference}'),
        ],
        if (payment.note.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            payment.note,
            style: const TextStyle(color: WafaColors.muted, height: 1.5),
          ),
        ],
        const SizedBox(height: 10),
        const Text(
          'Unverified demo entry',
          style: TextStyle(
            color: WafaColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _PaymentDraft {
  const _PaymentDraft({
    required this.amountPence,
    required this.paidOn,
    required this.method,
    required this.note,
    required this.reference,
  });

  final int amountPence;
  final DateTime paidOn;
  final PaymentMethod method;
  final String note;
  final String reference;
}

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({required this.today, required this.remainingPence});
  final DateTime today;
  final int remainingPence;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _reference = TextEditingController();
  late DateTime _paidOn;
  PaymentMethod _method = PaymentMethod.bankTransfer;

  @override
  void initState() {
    super.initState();
    _paidOn = widget.today;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _reference.dispose();
    super.dispose();
  }

  String? _validateAmount(String? value) {
    final pence = parsePence(value ?? '');
    if (pence == null || pence <= 0) {
      return 'Enter a positive amount with at most two decimal places.';
    }
    if (pence > widget.remainingPence) {
      return 'Enter no more than ${money(widget.remainingPence)}.';
    }
    return null;
  }

  Future<void> _chooseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidOn,
      firstDate: DateTime(widget.today.year - 5),
      lastDate: widget.today,
      currentDate: widget.today,
      helpText: 'When was this paid?',
    );
    if (!mounted || picked == null) return;
    setState(() => _paidOn = picked);
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.pop(
      context,
      _PaymentDraft(
        amountPence: parsePence(_amount.text)!,
        paidOn: _paidOn,
        method: _method,
        note: _note.text.trim(),
        reference: _reference.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Record a demo payment'),
    content: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'This creates an unverified local record. It does not move money.',
          ),
          const SizedBox(height: 18),
          TextFormField(
            key: const ValueKey('payment-amount'),
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: '£ ',
              helperText: 'Up to ${money(widget.remainingPence)}',
              errorMaxLines: 3,
            ),
            validator: _validateAmount,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<PaymentMethod>(
            key: const ValueKey('payment-method'),
            initialValue: _method,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Payment method'),
            items: PaymentMethod.values
                .map(
                  (method) => DropdownMenuItem(
                    value: method,
                    child: Text(method.label),
                  ),
                )
                .toList(growable: false),
            onChanged: (method) {
              if (method != null) setState(() => _method = method);
            },
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            key: const ValueKey('payment-date'),
            onPressed: _chooseDate,
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text('Paid on ${dateLabel(_paidOn)}'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const ValueKey('payment-reference'),
            controller: _reference,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Reference (optional)',
              hintText: 'Example: receipt number',
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: const ValueKey('payment-note'),
            controller: _note,
            maxLength: 240,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'What this payment was for',
            ),
          ),
          const Text(
            'Do not enter bank account numbers or card details.',
            style: TextStyle(color: WafaColors.muted, fontSize: 12),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const ValueKey('payment-save'),
        onPressed: _submit,
        child: const Text('Save demo record'),
      ),
    ],
  );
}
