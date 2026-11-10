/// Local, fictional agreement data for the Wafa phone prototype.
///
/// Actions in this library change only an in-memory demonstration. They do not
/// process payments, collect signatures, assess compliance, or contact a service.
library;

enum ContractKind {
  interestFreeLoan('Interest-free loan'),
  sale('Sale'),
  itemLending('Item lending'),
  itemRental('Item rental'),
  service('Service'),
  familyAgreement('Family agreement'),
  customAgreement('Custom agreement');

  const ContractKind(this.label);

  final String label;
}

enum AgreementRole {
  owesShare('Owes a share'),
  isOwed('Is owed'),
  witness('Witness');

  const AgreementRole(this.label);

  final String label;
}

class AgreementPerson {
  const AgreementPerson({
    required this.id,
    required this.name,
    required this.role,
    required this.sharePence,
  });

  final String id;
  final String name;
  final AgreementRole role;
  final int sharePence;
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

enum EvidenceType {
  photo('Photo', 'Laptop photo', 1.6),
  receipt('Receipt', 'Sample receipt', 0.3),
  bankConfirmation('Bank confirmation', 'Sample bank confirmation', 0.2),
  document('Document', 'Sample document', 0.5),
  voiceNote('Voice note', 'Sample voice note', 0.8);

  const EvidenceType(this.label, this._sampleName, this._sampleSizeMb);

  final String label;
  final String _sampleName;
  final double _sampleSizeMb;
}

class DemoEvidence {
  const DemoEvidence._({
    required this.type,
    required this.name,
    required this.sizeMb,
    required this.addedOn,
    required this.addedByPersonId,
  });

  final EvidenceType type;
  final String name;
  final double sizeMb;
  final DateTime addedOn;
  final String addedByPersonId;
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
    this.payerId,
  });

  final String id;
  final String agreementId;
  final int amountPence;
  final DateTime paidOn;
  final PaymentMethod method;
  final String recordedByPersonId;
  final String note;
  final String reference;
  final String? payerId;
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
    this.people = const [],
    this._paidByPerson = const {},
  });

  final String id;
  final String counterparty;
  final String title;
  final int amountPence;
  final DateTime dueDate;
  final int paidPence;
  final ContractKind kind;
  final AgreementStatus status;
  final List<AgreementPerson> people;
  final Map<String, int> _paidByPerson;

  int paidPenceFor(String personId) => _paidByPerson[personId] ?? 0;

  /// Keeps existing counterparty displays relative to the viewer in a pair.
  Agreement forViewer(String? viewerId) {
    if (people.length != 2 || !people.any((person) => person.id == viewerId)) {
      return this;
    }
    final other = people.firstWhere((person) => person.id != viewerId).name;
    return other == counterparty ? this : _copyWith(counterparty: other);
  }

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

  Agreement _copyWith({
    String? counterparty,
    int? paidPence,
    AgreementStatus? status,
    Map<String, int>? paidByPerson,
  }) => Agreement(
    id: id,
    counterparty: counterparty ?? this.counterparty,
    title: title,
    amountPence: amountPence,
    dueDate: dueDate,
    paidPence: paidPence ?? this.paidPence,
    kind: kind,
    status: status ?? this.status,
    people: people,
    paidByPerson: paidByPerson ?? _paidByPerson,
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
      _evidence.addAll(_sampleEvidence());
    }
    _refreshOpenStatuses();
  }

  final DemoClock _clock;
  final List<Agreement> _agreements = [];
  final List<DemoPayment> _payments = [];
  final Map<String, List<DemoEvidence>> _evidence = {};
  int _nextDraftNumber = 1;
  int _nextPaymentNumber = 1;

  static const evidenceFileLimit = 25;
  static const evidenceSizeLimitMb = 10;

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

  List<DemoEvidence> evidenceFor(String agreementId) {
    _requiredIndex(agreementId);
    return List<DemoEvidence>.unmodifiable(_evidence[agreementId] ?? const []);
  }

  DemoEvidence addEvidence(
    String agreementId, {
    required EvidenceType type,
    required String addedByPersonId,
  }) {
    _requiredIndex(agreementId);
    final records = _evidence.putIfAbsent(agreementId, () => []);
    if (records.length >= evidenceFileLimit) {
      throw StateError(
        'This agreement already holds $evidenceFileLimit files.',
      );
    }
    // A choice creates a bounded fictional record. No file is read.
    final record = DemoEvidence._(
      type: type,
      name: type._sampleName,
      sizeMb: type._sampleSizeMb,
      addedOn: today,
      addedByPersonId: addedByPersonId,
    );
    records.add(record);
    return record;
  }

  bool removeEvidence(
    String agreementId,
    DemoEvidence file, {
    required String personId,
  }) {
    if (findById(agreementId)?.status != AgreementStatus.draft ||
        file.addedByPersonId != personId) {
      return false;
    }
    return _evidence[agreementId]?.remove(file) ?? false;
  }

  /// Creates an unsigned, local draft from the prototype form.
  Agreement createDraft({
    required ContractKind kind,
    required String counterparty,
    required String title,
    required int amountPence,
    required DateTime dueDate,
    List<AgreementPerson> people = const [],
    void Function(Agreement draft)? prepareInvitations,
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

    if (people.isNotEmpty) {
      final owing = people.where(
        (person) => person.role == AgreementRole.owesShare,
      );
      final validShares =
          owing.isNotEmpty &&
          people.any((person) => person.role == AgreementRole.isOwed) &&
          people.every(
            (person) => person.role == AgreementRole.owesShare
                ? person.sharePence > 0
                : person.sharePence == 0,
          ) &&
          owing.fold(0, (sum, person) => sum + person.sharePence) ==
              amountPence;
      if (!validShares ||
          people.map((person) => person.id).toSet().length != people.length) {
        throw ArgumentError('The people and shares do not match the draft.');
      }
    }

    final number = _nextDraftNumber.toString().padLeft(3, '0');
    final draft = Agreement(
      id: 'demo-draft-$number',
      counterparty: cleanCounterparty,
      title: cleanTitle,
      amountPence: amountPence,
      dueDate: cleanDueDate,
      paidPence: 0,
      kind: kind,
      status: AgreementStatus.draft,
      people: List<AgreementPerson>.unmodifiable(people),
    );
    prepareInvitations?.call(draft);
    _nextDraftNumber++;
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
    String? payerId,
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
    var paidByPerson = agreement._paidByPerson;
    if (agreement.people.isNotEmpty) {
      final owing = agreement.people.where(
        (person) => person.role == AgreementRole.owesShare,
      );
      final payer = payerId == null
          ? owing.length == 1
                ? owing.single
                : null
          : owing.where((person) => person.id == payerId).firstOrNull;
      if (payer == null) {
        throw ArgumentError('Choose someone who owes a share.');
      }
      final paid = agreement.paidPenceFor(payer.id) + amountPence;
      if (paid > payer.sharePence) {
        throw ArgumentError('The payment cannot exceed the remaining share.');
      }
      payerId = payer.id;
      paidByPerson = Map.unmodifiable({...paidByPerson, payer.id: paid});
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
      paidByPerson: paidByPerson,
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
        payerId: payerId,
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
      paidByPerson: Map.unmodifiable({
        for (final person in agreement.people)
          if (person.role == AgreementRole.owesShare)
            person.id: person.sharePence,
      }),
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
      title: 'Van hire',
      amountPence: 85000,
      dueDate: DateTime(2026, 10, 31),
      paidPence: 0,
      kind: ContractKind.itemRental,
      status: AgreementStatus.active,
    ),
    Agreement(
      id: 'demo-family-001',
      counterparty: 'Sara Malik',
      title: "Mum's care costs",
      amountPence: 30000,
      dueDate: DateTime(2026, 11, 30),
      paidPence: 10000,
      kind: ContractKind.familyAgreement,
      status: AgreementStatus.active,
      people: const [
        AgreementPerson(
          id: 'demo-amina',
          name: 'Amina Noor',
          role: AgreementRole.owesShare,
          sharePence: 15000,
        ),
        AgreementPerson(
          id: 'demo-omar',
          name: 'Omar Farooq',
          role: AgreementRole.owesShare,
          sharePence: 15000,
        ),
        AgreementPerson(
          id: 'demo-sara',
          name: 'Sara Malik',
          role: AgreementRole.isOwed,
          sharePence: 0,
        ),
      ],
      paidByPerson: const {'demo-amina': 10000},
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

  static Map<String, List<DemoEvidence>> _sampleEvidence() => {
    'demo-service-001': [
      DemoEvidence._(
        type: EvidenceType.photo,
        name: 'Garden before the work',
        sizeMb: 2.4,
        addedOn: DateTime(2026, 10, 2),
        addedByPersonId: 'demo-amina',
      ),
      DemoEvidence._(
        type: EvidenceType.receipt,
        name: 'Plants receipt',
        sizeMb: 0.3,
        addedOn: DateTime(2026, 10, 5),
        addedByPersonId: 'demo-amina',
      ),
    ],
    'demo-family-001': [
      DemoEvidence._(
        type: EvidenceType.bankConfirmation,
        name: 'Transfer to Sara · £100',
        sizeMb: 0.2,
        addedOn: DateTime(2026, 11, 1),
        addedByPersonId: 'demo-amina',
      ),
    ],
  };

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
      id: 'demo-payment-seed-003',
      agreementId: 'demo-family-001',
      amountPence: 10000,
      paidOn: DateTime(2026, 10, 13),
      method: PaymentMethod.bankTransfer,
      recordedByPersonId: 'demo-amina',
      payerId: 'demo-amina',
      note: '',
      reference: '',
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
