/// Local, fictional agreement data for the Wafa phone prototype.
///
/// Actions in this library change only an in-memory demonstration. They do not
/// process payments, collect signatures, assess compliance, or contact a service.
library;

enum ContractKind {
  interestFreeLoan('Interest-free loan'),
  sale('Sale'),
  rental('Rental'),
  service('Service');

  const ContractKind(this.label);

  final String label;
}

enum AgreementStatus {
  draft('Draft'),
  awaitingSignatures('Awaiting signatures'),
  active('Active'),
  completed('Completed'),
  overdue('Overdue');

  const AgreementStatus(this.label);

  final String label;
}

enum PaymentMethod {
  bankTransfer('Bank transfer'),
  cash('Cash'),
  card('Card'),
  other('Other');

  const PaymentMethod(this.label);

  final String label;
}

class DemoPayment {
  const DemoPayment({
    required this.id,
    required this.agreementId,
    required this.amountPence,
    required this.paidOn,
    required this.method,
    required this.recordedByPersonId,
    required this.note,
    required this.reference,
  });

  final String id;
  final String agreementId;
  final int amountPence;
  final DateTime paidOn;
  final PaymentMethod method;
  final String recordedByPersonId;
  final String note;
  final String reference;
}

/// An immutable snapshot. Repository methods validate changes to stored data.
class Agreement {
  const Agreement({
    required this.id,
    required this.counterparty,
    required this.title,
    required this.amountPence,
    required this.dueDate,
    required this.paidPence,
    required this.kind,
    required this.status,
  });

  final String id;
  final String counterparty;
  final String title;
  final int amountPence;
  final DateTime dueDate;
  final int paidPence;
  final ContractKind kind;
  final AgreementStatus status;

  int get remainingPence {
    final remaining = amountPence - paidPence;
    return remaining < 0 ? 0 : remaining;
  }

  /// A safe 0–1 fraction even when displaying an imperfect external snapshot.
  double get progress {
    if (amountPence <= 0) return 0;
    return (paidPence / amountPence).clamp(0.0, 1.0).toDouble();
  }

  bool get isLoan => kind == ContractKind.interestFreeLoan;

  bool get canRecordRepayment => isLoan && _isOpen && remainingPence > 0;

  bool get canRecordPayment => _isOpen && remainingPence > 0;

  bool get canCompleteObligation => !isLoan && _isOpen && remainingPence > 0;

  bool get _isOpen =>
      status == AgreementStatus.active || status == AgreementStatus.overdue;

  Agreement _copyWith({int? paidPence, AgreementStatus? status}) => Agreement(
    id: id,
    counterparty: counterparty,
    title: title,
    amountPence: amountPence,
    dueDate: dueDate,
    paidPence: paidPence ?? this.paidPence,
    kind: kind,
    status: status ?? this.status,
  );
}

typedef DemoClock = DateTime Function();

/// Each instance starts a fresh demo session; there is no persistence.
class DemoAgreementRepository {
  DemoAgreementRepository({DemoClock? clock, bool seedSamples = true})
    : _clock = clock ?? _defaultDemoClock {
    if (seedSamples) {
      _agreements.addAll(_sampleAgreements());
      _payments.addAll(_samplePayments());
    }
    _refreshOpenStatuses();
  }

  final DemoClock _clock;
  final List<Agreement> _agreements = [];
  final List<DemoPayment> _payments = [];
  int _nextDraftNumber = 1;
  int _nextPaymentNumber = 1;

  /// The fixed default keeps the October 2026 example dates reproducible.
  static DateTime _defaultDemoClock() => DateTime(2026, 10, 13);

  DateTime get today => _dateOnly(_clock());

  List<Agreement> get agreements {
    _refreshOpenStatuses();
    return List<Agreement>.unmodifiable(_agreements);
  }

  Agreement? findById(String agreementId) {
    _refreshOpenStatuses();
    final index = _agreements.indexWhere((item) => item.id == agreementId);
    return index < 0 ? null : _agreements[index];
  }

  List<DemoPayment> paymentsFor(String agreementId) {
    _requiredIndex(agreementId);
    final records =
        _payments
            .where((payment) => payment.agreementId == agreementId)
            .toList(growable: false)
          ..sort((a, b) => b.paidOn.compareTo(a.paidOn));
    return List<DemoPayment>.unmodifiable(records);
  }

  /// Creates an unsigned, local draft from the prototype form.
  Agreement createDraft({
    required ContractKind kind,
    required String counterparty,
    required String title,
    required int amountPence,
    required DateTime dueDate,
  }) {
    final cleanCounterparty = counterparty.trim();
    final cleanTitle = title.trim();
    final cleanDueDate = _dateOnly(dueDate);

    if (cleanCounterparty.isEmpty) {
      throw ArgumentError.value(counterparty, 'counterparty', 'Enter a name.');
    }
    if (cleanTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Enter an agreement title.');
    }
    if (amountPence <= 0) {
      throw ArgumentError.value(
        amountPence,
        'amountPence',
        'The amount must be greater than zero.',
      );
    }
    if (cleanDueDate.isBefore(today)) {
      throw ArgumentError.value(
        dueDate,
        'dueDate',
        'Choose today or a later date.',
      );
    }

    final number = (_nextDraftNumber++).toString().padLeft(3, '0');
    final draft = Agreement(
      id: 'demo-draft-$number',
      counterparty: cleanCounterparty,
      title: cleanTitle,
      amountPence: amountPence,
      dueDate: cleanDueDate,
      paidPence: 0,
      kind: kind,
      status: AgreementStatus.draft,
    );
    _agreements.insert(0, draft);
    return draft;
  }

  /// Records a simulated repayment against an open interest-free loan.
  Agreement recordRepayment(String agreementId, {required int amountPence}) {
    final agreement = findById(agreementId);
    if (agreement == null) {
      throw ArgumentError.value(
        agreementId,
        'agreementId',
        'The demo agreement was not found.',
      );
    }
    if (!agreement.canRecordRepayment) {
      throw StateError('Only an open demo loan can record a repayment.');
    }
    return recordPayment(
      agreementId,
      amountPence: amountPence,
      paidOn: today,
      method: PaymentMethod.bankTransfer,
      recordedByPersonId: 'demo-system',
      note: 'Recorded from the agreement action.',
    );
  }

  /// Adds an itemised fictional payment to an open agreement.
  Agreement recordPayment(
    String agreementId, {
    required int amountPence,
    required DateTime paidOn,
    required PaymentMethod method,
    required String recordedByPersonId,
    String note = '',
    String reference = '',
  }) {
    if (amountPence <= 0) {
      throw ArgumentError.value(
        amountPence,
        'amountPence',
        'The repayment must be greater than zero.',
      );
    }
    final index = _requiredIndex(agreementId);
    final agreement = _agreements[index];
    if (!agreement.canRecordPayment) {
      throw StateError('Only an open demo agreement can record a payment.');
    }
    if (amountPence > agreement.remainingPence) {
      throw ArgumentError.value(
        amountPence,
        'amountPence',
        'The repayment cannot exceed the remaining amount.',
      );
    }

    final cleanDate = _dateOnly(paidOn);
    if (cleanDate.isAfter(today)) {
      throw ArgumentError.value(
        paidOn,
        'paidOn',
        'A recorded payment date cannot be in the future.',
      );
    }
    final cleanRecorder = recordedByPersonId.trim();
    if (cleanRecorder.isEmpty) {
      throw ArgumentError.value(
        recordedByPersonId,
        'recordedByPersonId',
        'A fictional recorder is required.',
      );
    }
    final cleanNote = note.trim();
    final cleanReference = reference.trim();
    if (cleanNote.length > 240) {
      throw ArgumentError.value(note, 'note', 'Keep notes to 240 characters.');
    }
    if (cleanReference.length > 80) {
      throw ArgumentError.value(
        reference,
        'reference',
        'Keep references to 80 characters.',
      );
    }

    final paidPence = agreement.paidPence + amountPence;
    final updated = agreement._copyWith(
      paidPence: paidPence,
      status: paidPence == agreement.amountPence
          ? AgreementStatus.completed
          : _openStatus(agreement.dueDate),
    );
    _agreements[index] = updated;
    final number = (_nextPaymentNumber++).toString().padLeft(3, '0');
    _payments.add(
      DemoPayment(
        id: 'demo-payment-$number',
        agreementId: agreement.id,
        amountPence: amountPence,
        paidOn: cleanDate,
        method: method,
        recordedByPersonId: cleanRecorder,
        note: cleanNote,
        reference: cleanReference,
      ),
    );
    return updated;
  }

  /// Marks a simulated sale, rental, or service obligation fulfilled.
  Agreement completeObligation(String agreementId) {
    final index = _requiredIndex(agreementId);
    final agreement = _agreements[index];
    if (!agreement.canCompleteObligation) {
      throw StateError(
        'Only an open non-loan demo obligation can be completed.',
      );
    }
    final updated = agreement._copyWith(
      paidPence: agreement.amountPence,
      status: AgreementStatus.completed,
    );
    _agreements[index] = updated;
    return updated;
  }

  int _requiredIndex(String agreementId) {
    _refreshOpenStatuses();
    final index = _agreements.indexWhere((item) => item.id == agreementId);
    if (index < 0) {
      throw ArgumentError.value(
        agreementId,
        'agreementId',
        'The demo agreement was not found.',
      );
    }
    return index;
  }

  AgreementStatus _openStatus(DateTime dueDate) =>
      _dateOnly(dueDate).isBefore(today)
      ? AgreementStatus.overdue
      : AgreementStatus.active;

  void _refreshOpenStatuses() {
    for (var index = 0; index < _agreements.length; index++) {
      final agreement = _agreements[index];
      if (!agreement._isOpen) continue;
      final status = _openStatus(agreement.dueDate);
      if (agreement.status != status) {
        _agreements[index] = agreement._copyWith(status: status);
      }
    }
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static List<Agreement> _sampleAgreements() => [
    Agreement(
      id: 'demo-loan-001',
      counterparty: 'Yusuf Rahman',
      title: 'Family support',
      amountPence: 48000,
      dueDate: DateTime(2026, 10, 28),
      paidPence: 16000,
      kind: ContractKind.interestFreeLoan,
      status: AgreementStatus.active,
    ),
    Agreement(
      id: 'demo-rental-001',
      counterparty: 'Maryam Saleh',
      title: 'Studio rental',
      amountPence: 85000,
      dueDate: DateTime(2026, 10, 31),
      paidPence: 0,
      kind: ContractKind.rental,
      status: AgreementStatus.active,
    ),
    Agreement(
      id: 'demo-sale-001',
      counterparty: 'Adam Yusuf',
      title: 'Bicycle sale',
      amountPence: 7500,
      dueDate: DateTime(2026, 10, 24),
      paidPence: 0,
      kind: ContractKind.sale,
      status: AgreementStatus.awaitingSignatures,
    ),
    Agreement(
      id: 'demo-service-001',
      counterparty: 'Samira Khan',
      title: 'Garden design',
      amountPence: 12000,
      dueDate: DateTime(2026, 10, 9),
      paidPence: 0,
      kind: ContractKind.service,
      status: AgreementStatus.overdue,
    ),
    Agreement(
      id: 'demo-loan-002',
      counterparty: 'Zain Idris',
      title: 'Travel support',
      amountPence: 15000,
      dueDate: DateTime(2026, 10, 10),
      paidPence: 15000,
      kind: ContractKind.interestFreeLoan,
      status: AgreementStatus.completed,
    ),
  ];

  static List<DemoPayment> _samplePayments() => [
    DemoPayment(
      id: 'demo-payment-seed-001',
      agreementId: 'demo-loan-001',
      amountPence: 16000,
      paidOn: DateTime(2026, 10, 1),
      method: PaymentMethod.bankTransfer,
      recordedByPersonId: 'demo-amina',
      note: 'Example family-support repayment.',
      reference: 'DEMO-001',
    ),
    DemoPayment(
      id: 'demo-payment-seed-002',
      agreementId: 'demo-loan-002',
      amountPence: 15000,
      paidOn: DateTime(2026, 10, 8),
      method: PaymentMethod.cash,
      recordedByPersonId: 'demo-amina',
      note: 'Example final cash repayment.',
      reference: '',
    ),
  ];
}
