import 'package:flutter_test/flutter_test.dart';
import 'package:wafa/domain/demo_models.dart';

void main() {
  DemoAgreementRepository emptyRepository() => DemoAgreementRepository(
    clock: () => DateTime(2026, 10, 13, 16),
    seedSamples: false,
  );

  Agreement createDraft(
    DemoAgreementRepository repository, {
    String counterparty = '  Amina Noor  ',
    String title = '  Household support  ',
    int amountPence = 50000,
    DateTime? dueDate,
  }) => repository.createDraft(
    kind: ContractKind.interestFreeLoan,
    counterparty: counterparty,
    title: title,
    amountPence: amountPence,
    dueDate: dueDate ?? DateTime(2026, 10, 20, 12),
  );

  group('local draft creation', () {
    test('validates and stores a trimmed unsigned draft', () {
      final repository = emptyRepository();
      final draft = createDraft(repository);

      expect(draft.id, 'demo-draft-001');
      expect(draft.counterparty, 'Amina Noor');
      expect(draft.title, 'Household support');
      expect(draft.amountPence, 50000);
      expect(draft.paidPence, 0);
      expect(draft.remainingPence, 50000);
      expect(draft.dueDate, DateTime(2026, 10, 20));
      expect(draft.status, AgreementStatus.draft);
      expect(draft.canRecordRepayment, isFalse);
      expect(repository.findById(draft.id), same(draft));
    });

    test('accepts a due date on today and assigns distinct draft IDs', () {
      final repository = emptyRepository();
      final first = createDraft(repository, dueDate: DateTime(2026, 10, 13));
      final second = createDraft(repository);

      expect(first.id, isNot(second.id));
      expect(repository.agreements, [second, first]);
    });

    test('rejects blank fields, nonpositive amounts, and past dates', () {
      final repository = emptyRepository();

      expect(
        () => createDraft(repository, counterparty: ' '),
        throwsArgumentError,
      );
      expect(() => createDraft(repository, title: ' '), throwsArgumentError);
      expect(
        () => createDraft(repository, amountPence: 0),
        throwsArgumentError,
      );
      expect(
        () => createDraft(repository, amountPence: -1),
        throwsArgumentError,
      );
      expect(
        () => createDraft(repository, dueDate: DateTime(2026, 10, 12)),
        throwsArgumentError,
      );
      expect(repository.agreements, isEmpty);
      expect(createDraft(repository).id, 'demo-draft-001');
    });
  });

  group('simulated repayment', () {
    test(
      'updates paid and remaining amounts without mutating old snapshots',
      () {
        final repository = DemoAgreementRepository();
        final original = repository.findById('demo-loan-001')!;
        final updated = repository.recordRepayment(
          original.id,
          amountPence: 10000,
        );

        expect(original.paidPence, 16000);
        expect(updated.paidPence, 26000);
        expect(updated.remainingPence, 22000);
        expect(updated.progress, closeTo(26000 / 48000, 0.000001));
        expect(updated.status, AgreementStatus.active);
        expect(repository.findById(original.id), same(updated));
      },
    );

    test('an exact final repayment completes the demo loan', () {
      final repository = DemoAgreementRepository();
      final original = repository.findById('demo-loan-001')!;
      final updated = repository.recordRepayment(
        original.id,
        amountPence: original.remainingPence,
      );

      expect(updated.remainingPence, 0);
      expect(updated.progress, 1);
      expect(updated.status, AgreementStatus.completed);
      expect(updated.canRecordRepayment, isFalse);
    });

    test(
      'rejects overpayments, zero, and negative repayments without changes',
      () {
        final repository = DemoAgreementRepository();
        final original = repository.findById('demo-loan-001')!;

        for (final amount in [-1, 0, original.remainingPence + 1]) {
          expect(
            () => repository.recordRepayment(original.id, amountPence: amount),
            throwsArgumentError,
          );
        }
        expect(repository.findById(original.id), same(original));
      },
    );

    test('rejects draft, completed, non-loan, and unknown agreements', () {
      final repository = DemoAgreementRepository();
      final draft = createDraft(repository);

      for (final id in [draft.id, 'demo-loan-002', 'demo-rental-001']) {
        expect(
          () => repository.recordRepayment(id, amountPence: 1),
          throwsStateError,
        );
      }
      expect(
        () => repository.recordRepayment('unknown', amountPence: 1),
        throwsArgumentError,
      );
    });

    test('a partial repayment keeps a past-due loan overdue', () {
      final repository = DemoAgreementRepository(
        clock: () => DateTime(2026, 10, 29),
      );
      final updated = repository.recordRepayment(
        'demo-loan-001',
        amountPence: 100,
      );

      expect(updated.status, AgreementStatus.overdue);
      expect(updated.remainingPence, 31900);
    });
  });

  group('itemised payment records', () {
    test('seed records reconcile with the seeded paid balances', () {
      final repository = DemoAgreementRepository();

      for (final id in ['demo-loan-001', 'demo-loan-002']) {
        final total = repository
            .paymentsFor(id)
            .fold<int>(0, (sum, payment) => sum + payment.amountPence);
        expect(total, repository.findById(id)!.paidPence);
      }
    });

    test('stores date, method, recorder, note and reference exactly', () {
      final repository = DemoAgreementRepository();
      final updated = repository.recordPayment(
        'demo-loan-001',
        amountPence: 7525,
        paidOn: DateTime(2026, 10, 12, 18),
        method: PaymentMethod.cash,
        recordedByPersonId: ' demo-amina ',
        note: '  Paid after the family meeting.  ',
        reference: '  RECEIPT-7  ',
      );

      final payment = repository.paymentsFor('demo-loan-001').first;
      expect(updated.paidPence, 23525);
      expect(payment.amountPence, 7525);
      expect(payment.paidOn, DateTime(2026, 10, 12));
      expect(payment.method, PaymentMethod.cash);
      expect(payment.recordedByPersonId, 'demo-amina');
      expect(payment.note, 'Paid after the family meeting.');
      expect(payment.reference, 'RECEIPT-7');
    });

    test('supports an itemised payment for an open non-loan agreement', () {
      final repository = DemoAgreementRepository();
      final updated = repository.recordPayment(
        'demo-rental-001',
        amountPence: 25000,
        paidOn: DateTime(2026, 10, 10),
        method: PaymentMethod.bankTransfer,
        recordedByPersonId: 'demo-amina',
      );

      expect(updated.paidPence, 25000);
      expect(updated.remainingPence, 60000);
      expect(repository.paymentsFor(updated.id), hasLength(1));
    });

    test('rejects invalid details without changing the record', () {
      final repository = DemoAgreementRepository();
      final original = repository.findById('demo-loan-001')!;
      final before = repository.paymentsFor(original.id).length;

      for (final callback in <void Function()>[
        () => repository.recordPayment(
          original.id,
          amountPence: 0,
          paidOn: repository.today,
          method: PaymentMethod.other,
          recordedByPersonId: 'demo-amina',
        ),
        () => repository.recordPayment(
          original.id,
          amountPence: original.remainingPence + 1,
          paidOn: repository.today,
          method: PaymentMethod.other,
          recordedByPersonId: 'demo-amina',
        ),
        () => repository.recordPayment(
          original.id,
          amountPence: 1,
          paidOn: DateTime(2026, 10, 14),
          method: PaymentMethod.other,
          recordedByPersonId: 'demo-amina',
        ),
        () => repository.recordPayment(
          original.id,
          amountPence: 1,
          paidOn: repository.today,
          method: PaymentMethod.other,
          recordedByPersonId: ' ',
        ),
        () => repository.recordPayment(
          original.id,
          amountPence: 1,
          paidOn: repository.today,
          method: PaymentMethod.other,
          recordedByPersonId: 'demo-amina',
          note: List.filled(241, 'x').join(),
        ),
        () => repository.recordPayment(
          original.id,
          amountPence: 1,
          paidOn: repository.today,
          method: PaymentMethod.other,
          recordedByPersonId: 'demo-amina',
          reference: List.filled(81, 'x').join(),
        ),
      ]) {
        expect(callback, throwsArgumentError);
      }

      expect(repository.findById(original.id), same(original));
      expect(repository.paymentsFor(original.id), hasLength(before));
    });

    test('returns newest-first immutable payment lists', () {
      final repository = DemoAgreementRepository();
      repository.recordPayment(
        'demo-loan-001',
        amountPence: 100,
        paidOn: DateTime(2026, 9, 30),
        method: PaymentMethod.card,
        recordedByPersonId: 'demo-amina',
      );
      repository.recordPayment(
        'demo-loan-001',
        amountPence: 200,
        paidOn: DateTime(2026, 10, 12),
        method: PaymentMethod.cash,
        recordedByPersonId: 'demo-amina',
      );

      final payments = repository.paymentsFor('demo-loan-001');
      expect(payments.first.amountPence, 200);
      expect(() => payments.clear(), throwsUnsupportedError);
    });
  });

  group('simulated non-loan completion', () {
    test('completes both active and overdue obligations', () {
      final repository = DemoAgreementRepository();

      for (final id in ['demo-rental-001', 'demo-service-001']) {
        final updated = repository.completeObligation(id);
        expect(updated.status, AgreementStatus.completed);
        expect(updated.paidPence, updated.amountPence);
        expect(updated.remainingPence, 0);
        expect(updated.progress, 1);
        expect(updated.canCompleteObligation, isFalse);
      }
    });

    test('does not complete a loan or an unsigned sale', () {
      final repository = DemoAgreementRepository();
      expect(
        () => repository.completeObligation('demo-loan-001'),
        throwsStateError,
      );
      expect(
        () => repository.completeObligation('demo-sale-001'),
        throwsStateError,
      );
    });
  });

  group('derived amounts', () {
    Agreement snapshot({required int paidPence, int amountPence = 10000}) =>
        Agreement(
          id: 'snapshot',
          counterparty: 'Fictional person',
          title: 'Example',
          amountPence: amountPence,
          dueDate: DateTime(2026, 10, 20),
          paidPence: paidPence,
          kind: ContractKind.interestFreeLoan,
          status: AgreementStatus.active,
        );

    test('uses integer pence and bounds remaining and progress', () {
      expect(snapshot(paidPence: 2500).remainingPence, 7500);
      expect(snapshot(paidPence: 2500).progress, 0.25);
      expect(snapshot(paidPence: 12000).remainingPence, 0);
      expect(snapshot(paidPence: 12000).progress, 1);
      expect(snapshot(paidPence: -1).progress, 0);
      expect(snapshot(paidPence: 0, amountPence: 0).progress, 0);
    });
  });

  group('demo session isolation and clock', () {
    test(
      'a new repository has fresh sample records and fresh draft numbering',
      () {
        final first = DemoAgreementRepository();
        final second = DemoAgreementRepository();
        first.recordRepayment('demo-loan-001', amountPence: 10000);
        first.completeObligation('demo-rental-001');
        createDraft(first);

        expect(second.findById('demo-loan-001')!.paidPence, 16000);
        expect(
          second.findById('demo-rental-001')!.status,
          AgreementStatus.active,
        );
        expect(second.findById('demo-draft-001'), isNull);
        expect(createDraft(second).id, 'demo-draft-001');
      },
    );

    test('the returned list cannot add or remove repository records', () {
      final repository = DemoAgreementRepository();
      expect(() => repository.agreements.clear(), throwsUnsupportedError);
      expect(repository.agreements, hasLength(5));
    });

    test(
      'due today stays active; advancing the injected day marks it overdue',
      () {
        var date = DateTime(2026, 10, 28, 23, 59);
        final repository = DemoAgreementRepository(clock: () => date);
        expect(
          repository.findById('demo-loan-001')!.status,
          AgreementStatus.active,
        );

        date = DateTime(2026, 10, 29);
        expect(
          repository.findById('demo-loan-001')!.status,
          AgreementStatus.overdue,
        );
        expect(
          repository.findById('demo-loan-002')!.status,
          AgreementStatus.completed,
        );
        expect(
          repository.findById('demo-sale-001')!.status,
          AgreementStatus.awaitingSignatures,
        );
      },
    );
  });
}
