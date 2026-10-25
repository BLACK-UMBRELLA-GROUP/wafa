import 'package:flutter_test/flutter_test.dart';
import 'package:wafa/domain/demo_connections.dart';

void main() {
  const agreement = 'demo-agreement-001';
  const otherAgreement = 'demo-agreement-002';

  DemoConnectionsRepository ownedRepository({DateTime Function()? clock}) {
    final repository = DemoConnectionsRepository(clock: clock);
    repository.signIn(DemoLoginMethod.apple, demoAmina.id);
    repository.registerAgreement(agreement);
    repository.registerAgreement(otherAgreement);
    return repository;
  }

  group('fictional identity and ownership', () {
    test(
      'starts signed out with immutable fixed people and exact ID lookup',
      () {
        final repository = DemoConnectionsRepository();
        expect(repository.currentPerson, isNull);
        expect(repository.loginMethod, isNull);
        expect(repository.persons, [demoAmina, demoOmar, demoSara]);
        expect(() => repository.persons.clear(), throwsUnsupportedError);
        expect(repository.person(demoOmar.id), same(demoOmar));
        expect(repository.person('unknown'), isNull);
        expect(repository.findPersonByWafaId('wafa-omar'), same(demoOmar));
        expect(repository.findPersonByWafaId(' WAFA-SARA '), same(demoSara));
        expect(repository.findPersonByWafaId('WAFA-OM'), isNull);
        expect(repository.findPersonByWafaId('Omar Farooq'), isNull);
        expect(repository.canViewAgreement(agreement), isFalse);
      },
    );

    test(
      'sign-in rejects unknown identities without changing the current one',
      () {
        final repository = ownedRepository();
        expect(
          () => repository.signIn(DemoLoginMethod.google, 'unknown'),
          throwsArgumentError,
        );
        expect(repository.currentPerson, same(demoAmina));
        expect(repository.loginMethod, DemoLoginMethod.apple);
      },
    );

    test('registered owner and their party role cannot be reassigned', () {
      final repository = ownedRepository();
      repository.registerAgreement(agreement);
      final owner = repository.participantsForAgreement(agreement).single;
      expect(owner.personId, demoAmina.id);
      expect(owner.role, ParticipantRole.party);
      expect(repository.canManageParticipants(agreement), isTrue);
      expect(
        () => repository.registerAgreement(agreement, ownerId: demoOmar.id),
        throwsStateError,
      );
      repository.signIn(DemoLoginMethod.google, demoOmar.id);
      expect(() => repository.registerAgreement(agreement), throwsStateError);
      expect(repository.canViewAgreement(agreement), isFalse);
      expect(repository.canManageParticipants(agreement), isFalse);
      expect(repository.participantsForAgreement(agreement), isEmpty);
    });

    test(
      'explicit seed ownership is immutable and is not granted to the caller',
      () {
        final repository = DemoConnectionsRepository();
        repository.signIn(DemoLoginMethod.google, demoOmar.id);
        repository.registerAgreement(agreement, ownerId: demoAmina.id);
        expect(repository.canViewAgreement(agreement), isFalse);
        expect(
          () => repository.createInvite(agreement, ParticipantRole.party),
          throwsStateError,
        );
        repository.signIn(DemoLoginMethod.apple, demoAmina.id);
        expect(repository.canViewAgreement(agreement), isTrue);
      },
    );

    test(
      'locked registration keeps the owner roster but denies invitation changes',
      () {
        final repository = DemoConnectionsRepository();
        repository.signIn(DemoLoginMethod.apple, demoAmina.id);
        repository.registerAgreement(agreement, invitationsAllowed: false);
        expect(repository.canViewAgreement(agreement), isTrue);
        expect(repository.canManageParticipants(agreement), isFalse);
        expect(
          repository.participantsForAgreement(agreement).single.personId,
          demoAmina.id,
        );
        expect(
          () => repository.createInvite(agreement, ParticipantRole.party),
          throwsStateError,
        );
        expect(
          () => repository.createInvite(
            agreement,
            ParticipantRole.witness,
            intendedPersonId: demoOmar.id,
          ),
          throwsStateError,
        );
        expect(() => repository.registerAgreement(agreement), throwsStateError);
        expect(
          () => repository.registerAgreement(
            agreement,
            ownerId: demoOmar.id,
            invitationsAllowed: false,
          ),
          throwsStateError,
        );
        repository.registerAgreement(agreement, invitationsAllowed: false);
        expect(repository.participantsForAgreement(agreement), hasLength(1));
        expect(repository.invitesForAgreement(agreement), isEmpty);
        expect(repository.canManageParticipants(agreement), isFalse);
      },
    );

    test(
      'an unlocked agreement cannot be silently registered with new capability',
      () {
        final repository = ownedRepository();
        expect(
          () => repository.registerAgreement(
            agreement,
            invitationsAllowed: false,
          ),
          throwsStateError,
        );
        expect(repository.canManageParticipants(agreement), isTrue);
      },
    );

    test('signed-out identity cannot mutate agreement or invitation data', () {
      final repository = ownedRepository();
      final invite = repository.createInvite(agreement, ParticipantRole.party);
      repository.signOut();

      expect(() => repository.registerAgreement('new'), throwsStateError);
      expect(
        () => repository.createInvite(agreement, ParticipantRole.witness),
        throwsStateError,
      );
      expect(() => repository.requestJoin(invite.code), throwsStateError);
      expect(() => repository.confirmRequest(invite.id), throwsStateError);
      expect(() => repository.declineInvite(invite.id), throwsStateError);
      expect(() => repository.revokeInvite(invite.id), throwsStateError);
      expect(repository.contactsForCurrentPerson, isEmpty);
      expect(repository.participantsForAgreement(agreement), isEmpty);
      expect(repository.invitesForAgreement(agreement), isEmpty);
    });
  });

  group('request and owner confirmation', () {
    test('a code grants only a request; confirmation grants one agreement', () {
      final repository = ownedRepository();
      final invite = repository.createInvite(
        agreement,
        ParticipantRole.witness,
      );
      expect(invite.status, InviteStatus.pending);
      expect(invite.createdAt, DateTime(2026, 10, 13, 12));
      expect(invite.expiresAt, DateTime(2026, 10, 20, 12));
      repository.signIn(DemoLoginMethod.google, demoOmar.id);

      expect(
        repository.findInviteByCode(invite.code.toLowerCase())!.id,
        invite.id,
      );
      expect(repository.canViewAgreement(agreement), isFalse);
      final requested = repository.requestJoin(invite.code);
      expect(requested.status, InviteStatus.requested);
      expect(requested.requestedPersonId, demoOmar.id);
      expect(requested.role, ParticipantRole.witness);
      expect(invite.status, InviteStatus.pending);
      expect(repository.canViewAgreement(agreement), isFalse);
      expect(repository.participantsForAgreement(agreement), isEmpty);
      expect(repository.contactsForCurrentPerson, isEmpty);
      expect(() => repository.confirmRequest(invite.id), throwsStateError);

      repository.signIn(DemoLoginMethod.apple, demoAmina.id);
      final accepted = repository.confirmRequest(invite.id);
      expect(accepted.status, InviteStatus.accepted);
      final participants = repository.participantsForAgreement(agreement);
      expect(participants, hasLength(2));
      expect(participants.last.personId, demoOmar.id);
      expect(participants.last.role, ParticipantRole.witness);
      expect(repository.contactsForCurrentPerson, [demoOmar]);
      repository.signIn(DemoLoginMethod.google, demoOmar.id);
      expect(repository.canViewAgreement(agreement), isTrue);
      expect(repository.canViewAgreement(otherAgreement), isFalse);
      expect(repository.canManageParticipants(agreement), isFalse);
      expect(repository.contactsForCurrentPerson, [demoAmina]);
    });

    test(
      'a targeted invitation cannot be claimed through a forwarded code',
      () {
        final repository = ownedRepository();
        final invite = repository.createInvite(
          agreement,
          ParticipantRole.party,
          intendedPersonId: demoSara.id,
        );
        repository.signIn(DemoLoginMethod.google, demoOmar.id);
        expect(() => repository.requestJoin(invite.code), throwsStateError);
        expect(repository.invitesForAgreement(agreement), isEmpty);
        repository.signIn(DemoLoginMethod.apple, demoSara.id);
        final requested = repository.requestJoin(invite.code);
        expect(requested.requestedPersonId, demoSara.id);
        expect(repository.canViewAgreement(agreement), isFalse);
      },
    );

    test(
      'one request wins; replay and a competing fictional requester fail',
      () {
        final repository = ownedRepository();
        final invite = repository.createInvite(
          agreement,
          ParticipantRole.party,
        );
        repository.signIn(DemoLoginMethod.google, demoOmar.id);
        repository.requestJoin(invite.code);
        expect(() => repository.requestJoin(invite.code), throwsStateError);
        repository.signIn(DemoLoginMethod.apple, demoSara.id);
        expect(() => repository.requestJoin(invite.code), throwsStateError);
        expect(repository.canViewAgreement(agreement), isFalse);
        expect(() => repository.confirmRequest(invite.id), throwsStateError);
        repository.signIn(DemoLoginMethod.apple, demoAmina.id);
        repository.confirmRequest(invite.id);
        expect(() => repository.confirmRequest(invite.id), throwsStateError);
        expect(repository.participantsForAgreement(agreement), hasLength(2));
      },
    );

    test('only the registered owner can create, confirm or revoke', () {
      final repository = ownedRepository();
      final invite = repository.createInvite(agreement, ParticipantRole.party);
      repository.signIn(DemoLoginMethod.google, demoOmar.id);
      repository.requestJoin(invite.code);
      expect(
        () => repository.createInvite(agreement, ParticipantRole.witness),
        throwsStateError,
      );
      expect(() => repository.revokeInvite(invite.id), throwsStateError);
      expect(() => repository.confirmRequest(invite.id), throwsStateError);
      expect(
        () => repository.createInvite('unregistered', ParticipantRole.party),
        throwsStateError,
      );
    });

    test('owner must wait for a request and cannot join their own code', () {
      final repository = ownedRepository();
      final invite = repository.createInvite(agreement, ParticipantRole.party);
      expect(() => repository.confirmRequest(invite.id), throwsStateError);
      expect(() => repository.requestJoin(invite.code), throwsStateError);
      expect(
        () => repository.createInvite(
          agreement,
          ParticipantRole.witness,
          intendedPersonId: demoAmina.id,
        ),
        throwsStateError,
      );
    });
  });

  group('duplicates and role binding', () {
    test(
      'prevents duplicate pending codes and targeted invites across roles',
      () {
        final repository = ownedRepository();
        repository.createInvite(agreement, ParticipantRole.party);
        expect(
          () => repository.createInvite(agreement, ParticipantRole.party),
          throwsStateError,
        );
        repository.createInvite(
          agreement,
          ParticipantRole.witness,
          intendedPersonId: demoOmar.id,
        );
        expect(
          () => repository.createInvite(
            agreement,
            ParticipantRole.party,
            intendedPersonId: demoOmar.id,
          ),
          throwsStateError,
        );
      },
    );

    test(
      'one person cannot hold rival requests or become a duplicate member',
      () {
        final repository = ownedRepository();
        final party = repository.createInvite(agreement, ParticipantRole.party);
        final witness = repository.createInvite(
          agreement,
          ParticipantRole.witness,
        );
        repository.signIn(DemoLoginMethod.google, demoOmar.id);
        repository.requestJoin(party.code);
        expect(() => repository.requestJoin(witness.code), throwsStateError);
        repository.signIn(DemoLoginMethod.apple, demoAmina.id);
        expect(
          () => repository.createInvite(
            agreement,
            ParticipantRole.witness,
            intendedPersonId: demoOmar.id,
          ),
          throwsStateError,
        );
        repository.confirmRequest(party.id);
        expect(
          () => repository.createInvite(
            agreement,
            ParticipantRole.witness,
            intendedPersonId: demoOmar.id,
          ),
          throwsStateError,
        );
        repository.signIn(DemoLoginMethod.google, demoOmar.id);
        expect(() => repository.requestJoin(witness.code), throwsStateError);
        final member = repository.participantsForAgreement(agreement).last;
        expect(member.role, ParticipantRole.party);
      },
    );
  });

  group('decline, revocation and expiry', () {
    test('target can decline incoming invite; unrelated identity cannot', () {
      final repository = ownedRepository();
      final invite = repository.createInvite(
        agreement,
        ParticipantRole.witness,
        intendedPersonId: demoSara.id,
      );
      repository.signIn(DemoLoginMethod.google, demoOmar.id);
      expect(() => repository.declineInvite(invite.id), throwsStateError);
      repository.signIn(DemoLoginMethod.apple, demoSara.id);
      expect(repository.declineInvite(invite.id).status, InviteStatus.declined);
      expect(() => repository.requestJoin(invite.code), throwsStateError);
      expect(repository.canViewAgreement(agreement), isFalse);
    });

    test(
      'requester can decline their request and owner can reject a request',
      () {
        final repository = ownedRepository();
        final first = repository.createInvite(agreement, ParticipantRole.party);
        repository.signIn(DemoLoginMethod.google, demoOmar.id);
        repository.requestJoin(first.code);
        expect(
          repository.declineInvite(first.id).status,
          InviteStatus.declined,
        );
        repository.signIn(DemoLoginMethod.apple, demoAmina.id);
        final second = repository.createInvite(
          agreement,
          ParticipantRole.party,
        );
        repository.signIn(DemoLoginMethod.google, demoOmar.id);
        repository.requestJoin(second.code);
        repository.signIn(DemoLoginMethod.apple, demoAmina.id);
        expect(
          repository.declineInvite(second.id).status,
          InviteStatus.declined,
        );
        expect(() => repository.confirmRequest(second.id), throwsStateError);
        expect(repository.participantsForAgreement(agreement), hasLength(1));
      },
    );

    test('revoked codes cannot request or confirm and add no contacts', () {
      final repository = ownedRepository();
      final pending = repository.createInvite(agreement, ParticipantRole.party);
      repository.revokeInvite(pending.id);
      final requested = repository.createInvite(
        agreement,
        ParticipantRole.party,
      );
      repository.signIn(DemoLoginMethod.google, demoOmar.id);
      expect(() => repository.requestJoin(pending.code), throwsStateError);
      repository.requestJoin(requested.code);
      repository.signIn(DemoLoginMethod.apple, demoAmina.id);
      expect(
        repository.revokeInvite(requested.id).status,
        InviteStatus.revoked,
      );
      expect(() => repository.confirmRequest(requested.id), throwsStateError);
      expect(repository.contactsForCurrentPerson, isEmpty);
      expect(repository.participantsForAgreement(agreement), hasLength(1));
    });

    test(
      'expiry at the exact boundary fails closed for pending and requested',
      () {
        var now = DateTime(2026, 10, 13, 12);
        final repository = ownedRepository(clock: () => now);
        final pending = repository.createInvite(
          agreement,
          ParticipantRole.party,
        );
        final requested = repository.createInvite(
          agreement,
          ParticipantRole.witness,
          intendedPersonId: demoOmar.id,
        );
        repository.signIn(DemoLoginMethod.google, demoOmar.id);
        repository.requestJoin(requested.code);
        now = pending.expiresAt;
        expect(
          repository.findInviteByCode(pending.code)!.status,
          InviteStatus.expired,
        );
        expect(() => repository.requestJoin(pending.code), throwsStateError);
        expect(() => repository.declineInvite(requested.id), throwsStateError);
        repository.signIn(DemoLoginMethod.apple, demoAmina.id);
        expect(() => repository.confirmRequest(requested.id), throwsStateError);
        expect(() => repository.revokeInvite(requested.id), throwsStateError);
        expect(repository.participantsForAgreement(agreement), hasLength(1));
        expect(repository.contactsForCurrentPerson, isEmpty);
      },
    );

    test(
      'an accepted membership survives expiry and cannot replay or revoke',
      () {
        var now = DateTime(2026, 10, 13, 12);
        final repository = ownedRepository(clock: () => now);
        final invite = repository.createInvite(
          agreement,
          ParticipantRole.party,
        );
        repository.signIn(DemoLoginMethod.google, demoOmar.id);
        repository.requestJoin(invite.code);
        repository.signIn(DemoLoginMethod.apple, demoAmina.id);
        repository.confirmRequest(invite.id);
        now = invite.expiresAt.add(const Duration(days: 1));
        expect(
          repository.findInviteByCode(invite.code)!.status,
          InviteStatus.accepted,
        );
        expect(() => repository.revokeInvite(invite.id), throwsStateError);
        repository.signIn(DemoLoginMethod.google, demoOmar.id);
        expect(repository.canViewAgreement(agreement), isTrue);
        expect(() => repository.requestJoin(invite.code), throwsStateError);
      },
    );
  });

  group('local session boundaries', () {
    test(
      'incoming discovery reveals only invitations addressed to that identity',
      () {
        final repository = ownedRepository();
        final omar = repository.createInvite(
          agreement,
          ParticipantRole.party,
          intendedPersonId: demoOmar.id,
        );
        final sara = repository.createInvite(
          agreement,
          ParticipantRole.witness,
          intendedPersonId: demoSara.id,
        );
        repository.createInvite(otherAgreement, ParticipantRole.party);
        expect(repository.incomingInvites, isEmpty);
        repository.signIn(DemoLoginMethod.google, demoOmar.id);
        expect(repository.incomingInvites.map((invite) => invite.id), [
          omar.id,
        ]);
        expect(repository.canViewAgreement(agreement), isFalse);
        expect(repository.participantsForAgreement(agreement), isEmpty);
        expect(
          () => repository.incomingInvites.clear(),
          throwsUnsupportedError,
        );
        repository.declineInvite(omar.id);
        expect(repository.incomingInvites.single.status, InviteStatus.declined);
        repository.signIn(DemoLoginMethod.apple, demoSara.id);
        expect(repository.incomingInvites.map((invite) => invite.id), [
          sara.id,
        ]);
        repository.signOut();
        expect(repository.incomingInvites, isEmpty);
      },
    );

    test(
      'generic codes appear in incoming history only for their actual requester',
      () {
        final repository = ownedRepository();
        final invite = repository.createInvite(
          agreement,
          ParticipantRole.party,
        );
        repository.signIn(DemoLoginMethod.google, demoOmar.id);
        expect(repository.incomingInvites, isEmpty);
        repository.requestJoin(invite.code);
        expect(
          repository.incomingInvites.single.requestedPersonId,
          demoOmar.id,
        );
        expect(
          repository.incomingInvites.single.status,
          InviteStatus.requested,
        );
        expect(repository.canViewAgreement(agreement), isFalse);
        repository.signIn(DemoLoginMethod.apple, demoSara.id);
        expect(repository.incomingInvites, isEmpty);
        repository.signIn(DemoLoginMethod.apple, demoAmina.id);
        expect(repository.incomingInvites, isEmpty);
        repository.confirmRequest(invite.id);
        repository.signIn(DemoLoginMethod.google, demoOmar.id);
        expect(repository.incomingInvites.single.status, InviteStatus.accepted);
      },
    );

    test(
      'incoming history refreshes expiry without revealing participant rosters',
      () {
        var now = DateTime(2026, 10, 13, 12);
        final repository = ownedRepository(clock: () => now);
        final invite = repository.createInvite(
          agreement,
          ParticipantRole.witness,
          intendedPersonId: demoOmar.id,
        );
        repository.signIn(DemoLoginMethod.google, demoOmar.id);
        expect(repository.incomingInvites.single.status, InviteStatus.pending);
        now = invite.expiresAt;
        expect(repository.incomingInvites.single.status, InviteStatus.expired);
        expect(repository.canViewAgreement(agreement), isFalse);
        expect(repository.participantsForAgreement(agreement), isEmpty);
      },
    );

    test(
      'sign-out clears identity only; returning preserves contacts and members',
      () {
        final repository = ownedRepository();
        final invite = repository.createInvite(
          agreement,
          ParticipantRole.party,
        );
        repository.signIn(DemoLoginMethod.google, demoOmar.id);
        repository.requestJoin(invite.code);
        repository.signIn(DemoLoginMethod.apple, demoAmina.id);
        repository.confirmRequest(invite.id);
        repository.signOut();
        expect(repository.currentPerson, isNull);
        expect(repository.loginMethod, isNull);
        expect(repository.canViewAgreement(agreement), isFalse);
        repository.signIn(DemoLoginMethod.google, demoOmar.id);
        expect(repository.contactsForCurrentPerson, [demoAmina]);
        expect(repository.participantsForAgreement(agreement), hasLength(2));
      },
    );

    test('membership, invite and contact lists are immutable', () {
      final repository = ownedRepository();
      final invite = repository.createInvite(agreement, ParticipantRole.party);
      repository.signIn(DemoLoginMethod.google, demoOmar.id);
      repository.requestJoin(invite.code);
      repository.signIn(DemoLoginMethod.apple, demoAmina.id);
      repository.confirmRequest(invite.id);
      expect(
        () => repository.participantsForAgreement(agreement).clear(),
        throwsUnsupportedError,
      );
      expect(
        () => repository.invitesForAgreement(agreement).clear(),
        throwsUnsupportedError,
      );
      expect(
        () => repository.contactsForCurrentPerson.clear(),
        throwsUnsupportedError,
      );
      expect(repository.participantsForAgreement(agreement), hasLength(2));
    });

    test(
      'repositories do not share ownership, invites, contacts or identity',
      () {
        final first = ownedRepository();
        final invite = first.createInvite(agreement, ParticipantRole.party);
        final second = DemoConnectionsRepository();
        second.signIn(DemoLoginMethod.google, demoOmar.id);
        expect(second.findInviteByCode(invite.code), isNull);
        expect(second.canViewAgreement(agreement), isFalse);
        expect(second.contactsForCurrentPerson, isEmpty);
        expect(first.currentPerson, same(demoAmina));
      },
    );

    test(
      'unknown code, invite, person and blank agreement IDs reject cleanly',
      () {
        final repository = ownedRepository();
        expect(() => repository.requestJoin('unknown'), throwsArgumentError);
        expect(() => repository.confirmRequest('unknown'), throwsArgumentError);
        expect(() => repository.declineInvite('unknown'), throwsArgumentError);
        expect(() => repository.revokeInvite('unknown'), throwsArgumentError);
        expect(() => repository.registerAgreement(' '), throwsArgumentError);
        expect(
          () => repository.createInvite(
            agreement,
            ParticipantRole.party,
            intendedPersonId: 'unknown',
          ),
          throwsArgumentError,
        );
      },
    );
  });
}
