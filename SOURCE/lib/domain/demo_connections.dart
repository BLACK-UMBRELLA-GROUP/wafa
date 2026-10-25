/// Fictional sign-in and participant connections for the local Wafa prototype.
///
/// Provider choices are visual labels. No authentication, messages, credentials,
/// legal signatures, network calls, or persistent accounts are involved.
library;

enum DemoLoginMethod {
  apple('Apple'),
  google('Google');

  const DemoLoginMethod(this.label);
  final String label;
}

class DemoPerson {
  const DemoPerson({
    required this.id,
    required this.name,
    required this.wafaId,
  });

  final String id;
  final String name;
  final String wafaId;
}

const demoAmina = DemoPerson(
  id: 'demo-amina',
  name: 'Amina Noor',
  wafaId: 'WAFA-AMINA',
);
const demoOmar = DemoPerson(
  id: 'demo-omar',
  name: 'Omar Farooq',
  wafaId: 'WAFA-OMAR',
);
const demoSara = DemoPerson(
  id: 'demo-sara',
  name: 'Sara Malik',
  wafaId: 'WAFA-SARA',
);
const List<DemoPerson> demoPeople = [demoAmina, demoOmar, demoSara];

enum ParticipantRole {
  party('Party'),
  witness('Witness');

  const ParticipantRole(this.label);
  final String label;
}

enum InviteStatus {
  pending('Pending'),
  requested('Requested'),
  accepted('Accepted'),
  declined('Declined'),
  revoked('Revoked'),
  expired('Expired');

  const InviteStatus(this.label);
  final String label;
}

class DemoInvite {
  const DemoInvite({
    required this.id,
    required this.agreementId,
    required this.creatorId,
    required this.role,
    required this.status,
    required this.code,
    required this.createdAt,
    required this.expiresAt,
    this.intendedPersonId,
    this.requestedPersonId,
  });

  final String id;
  final String agreementId;
  final String creatorId;
  final ParticipantRole role;
  final InviteStatus status;
  final String code;
  final String? intendedPersonId;
  final String? requestedPersonId;
  final DateTime createdAt;
  final DateTime expiresAt;

  bool get isOpen =>
      status == InviteStatus.pending || status == InviteStatus.requested;

  DemoInvite _copyWith({InviteStatus? status, String? requestedPersonId}) =>
      DemoInvite(
        id: id,
        agreementId: agreementId,
        creatorId: creatorId,
        role: role,
        status: status ?? this.status,
        code: code,
        intendedPersonId: intendedPersonId,
        requestedPersonId: requestedPersonId ?? this.requestedPersonId,
        createdAt: createdAt,
        expiresAt: expiresAt,
      );
}

class DemoParticipant {
  const DemoParticipant({required this.personId, required this.role});

  final String personId;
  final ParticipantRole role;
}

/// Every repository is a separate in-memory session with fixed fictional people.
class DemoConnectionsRepository {
  DemoConnectionsRepository({DateTime Function()? clock})
    : _clock = clock ?? _defaultClock;

  final DateTime Function() _clock;
  final Map<String, String> _owners = {};
  final Map<String, bool> _invitationCapabilities = {};
  final Map<String, List<DemoParticipant>> _participants = {};
  final Map<String, Set<String>> _contacts = {};
  final List<DemoInvite> _invites = [];
  DemoPerson? _currentPerson;
  DemoLoginMethod? _loginMethod;
  int _nextInviteNumber = 1;

  static DateTime _defaultClock() => DateTime(2026, 10, 13, 12);

  List<DemoPerson> get persons => demoPeople;
  DemoPerson? get currentPerson => _currentPerson;
  DemoLoginMethod? get loginMethod => _loginMethod;

  DemoPerson? person(String personId) {
    for (final candidate in demoPeople) {
      if (candidate.id == personId) return candidate;
    }
    return null;
  }

  /// Selects a fictional identity; this is not a provider sign-in operation.
  void signIn(DemoLoginMethod method, String personId) {
    final selectedPerson = _requiredPerson(personId);
    _currentPerson = selectedPerson;
    _loginMethod = method;
  }

  /// Preserves local invitations, ownership, members and saved contacts.
  void signOut() {
    _currentPerson = null;
    _loginMethod = null;
  }

  List<DemoPerson> get contactsForCurrentPerson {
    final current = _currentPerson;
    if (current == null) return const [];
    final savedIds = _contacts[current.id] ?? const <String>{};
    return List<DemoPerson>.unmodifiable(
      demoPeople.where((candidate) => savedIds.contains(candidate.id)),
    );
  }

  /// Recipient metadata and history only; it conveys no private agreement access.
  List<DemoInvite> get incomingInvites {
    _refreshExpiry();
    final current = _currentPerson;
    if (current == null) return const [];
    return List<DemoInvite>.unmodifiable(
      _invites.where(
        (invite) =>
            invite.creatorId != current.id &&
            (invite.intendedPersonId == current.id ||
                invite.requestedPersonId == current.id),
      ),
    );
  }

  /// Internal prototype wiring may supply an owner for a known demo agreement.
  /// Once registered, neither identity changes nor repeat wiring can replace it.
  void registerAgreement(
    String agreementId, {
    String? ownerId,
    bool invitationsAllowed = true,
  }) {
    final current = _requireSignedIn();
    final cleanId = _agreementId(agreementId);
    final owner = _requiredPerson(ownerId ?? current.id);
    final registeredOwner = _owners[cleanId];
    if (registeredOwner != null) {
      if (registeredOwner != owner.id) {
        throw StateError('The demo agreement owner cannot be changed.');
      }
      if (_invitationCapabilities[cleanId] != invitationsAllowed) {
        throw StateError('The demo invitation capability cannot be changed.');
      }
      return;
    }
    _owners[cleanId] = owner.id;
    _invitationCapabilities[cleanId] = invitationsAllowed;
    _participants[cleanId] = [
      DemoParticipant(personId: owner.id, role: ParticipantRole.party),
    ];
  }

  bool canManageParticipants(String agreementId) =>
      _isOwner(agreementId.trim()) &&
      _invitationCapabilities[agreementId.trim()] == true;

  bool canViewAgreement(String agreementId) {
    final current = _currentPerson;
    if (current == null) return false;
    return (_participants[agreementId.trim()] ?? const <DemoParticipant>[]).any(
      (participant) => participant.personId == current.id,
    );
  }

  List<DemoParticipant> participantsForAgreement(String agreementId) {
    final cleanId = agreementId.trim();
    if (!canViewAgreement(cleanId)) return const [];
    return List<DemoParticipant>.unmodifiable(
      _participants[cleanId] ?? const [],
    );
  }

  /// Owners see their invitations. A recipient sees only their own invitation.
  List<DemoInvite> invitesForAgreement(String agreementId) {
    _refreshExpiry();
    final current = _currentPerson;
    if (current == null) return const [];
    final cleanId = agreementId.trim();
    final owner = _isOwner(cleanId);
    return List<DemoInvite>.unmodifiable(
      _invites.where(
        (invite) =>
            invite.agreementId == cleanId &&
            (owner ||
                invite.intendedPersonId == current.id ||
                invite.requestedPersonId == current.id),
      ),
    );
  }

  DemoPerson? findPersonByWafaId(String wafaId) {
    final exactId = wafaId.trim().toUpperCase();
    for (final candidate in demoPeople) {
      if (candidate.wafaId.toUpperCase() == exactId) return candidate;
    }
    return null;
  }

  DemoInvite createInvite(
    String agreementId,
    ParticipantRole role, {
    String? intendedPersonId,
  }) {
    _refreshExpiry();
    final cleanId = _agreementId(agreementId);
    final owner = _requireInvitationManager(cleanId);
    if (intendedPersonId != null) {
      final target = _requiredPerson(intendedPersonId);
      if (target.id == owner.id) {
        throw StateError('The owner is already part of this demo agreement.');
      }
      if (_isParticipant(cleanId, target.id)) {
        throw StateError('This person is already a demo participant.');
      }
      if (_hasOpenInviteForPerson(cleanId, target.id)) {
        throw StateError('This person already has an open demo invitation.');
      }
    } else if (_invites.any(
      (invite) =>
          invite.agreementId == cleanId &&
          invite.role == role &&
          invite.intendedPersonId == null &&
          invite.isOpen,
    )) {
      throw StateError('An open demo code for this role already exists.');
    }

    final number = (_nextInviteNumber++).toString().padLeft(4, '0');
    final createdAt = _clock();
    final invite = DemoInvite(
      id: 'demo-invite-$number',
      agreementId: cleanId,
      creatorId: owner.id,
      role: role,
      status: InviteStatus.pending,
      code: 'WAFA-$number',
      intendedPersonId: intendedPersonId,
      createdAt: createdAt,
      // Seven days is a demo preset, not a production invitation policy.
      expiresAt: createdAt.add(const Duration(days: 7)),
    );
    _invites.add(invite);
    return invite;
  }

  /// Finds code metadata only; possession never grants agreement access.
  DemoInvite? findInviteByCode(String code) {
    _refreshExpiry();
    final normalized = code.trim().toUpperCase();
    for (final invite in _invites) {
      if (invite.code == normalized) return invite;
    }
    return null;
  }

  DemoInvite requestJoin(String code) {
    final requester = _requireSignedIn();
    final invite = findInviteByCode(code);
    if (invite == null) {
      throw ArgumentError.value(
        code,
        'code',
        'The demo invitation was not found.',
      );
    }
    _requireStatus(invite, InviteStatus.pending);
    if (invite.creatorId == requester.id) {
      throw StateError('The owner cannot request their own demo invitation.');
    }
    if (invite.intendedPersonId != null &&
        invite.intendedPersonId != requester.id) {
      throw StateError('This demo invitation is addressed to another person.');
    }
    if (_isParticipant(invite.agreementId, requester.id)) {
      throw StateError('This person is already a demo participant.');
    }
    if (_hasOpenInviteForPerson(
      invite.agreementId,
      requester.id,
      excludingId: invite.id,
    )) {
      throw StateError('This person already has an open demo invitation.');
    }

    return _replaceInvite(
      invite._copyWith(
        status: InviteStatus.requested,
        requestedPersonId: requester.id,
      ),
    );
  }

  DemoInvite confirmRequest(String inviteId) {
    final invite = _requiredInvite(inviteId);
    final owner = _requireInvitationManager(invite.agreementId);
    _requireStatus(invite, InviteStatus.requested);
    final requesterId = invite.requestedPersonId;
    if (requesterId == null || requesterId == owner.id) {
      throw StateError('This demo invitation has no eligible request.');
    }
    _requiredPerson(requesterId);
    if (invite.intendedPersonId != null &&
        invite.intendedPersonId != requesterId) {
      throw StateError('The request does not match the intended demo person.');
    }
    if (_isParticipant(invite.agreementId, requesterId)) {
      throw StateError('This person is already a demo participant.');
    }

    _participants[invite.agreementId]!.add(
      DemoParticipant(personId: requesterId, role: invite.role),
    );
    (_contacts[owner.id] ??= <String>{}).add(requesterId);
    (_contacts[requesterId] ??= <String>{}).add(owner.id);
    return _replaceInvite(invite._copyWith(status: InviteStatus.accepted));
  }

  DemoInvite declineInvite(String inviteId) {
    final current = _requireSignedIn();
    final invite = _requiredInvite(inviteId);
    if (!invite.isOpen) {
      throw StateError('This demo invitation is no longer open.');
    }
    final ownsRequest =
        invite.status == InviteStatus.requested &&
        invite.requestedPersonId == current.id;
    final isPendingTarget =
        invite.status == InviteStatus.pending &&
        invite.intendedPersonId == current.id;
    final canRejectRequest =
        invite.status == InviteStatus.requested && _isOwner(invite.agreementId);
    if (!ownsRequest && !isPendingTarget && !canRejectRequest) {
      throw StateError(
        'Only the demo recipient or reviewing owner can decline.',
      );
    }
    return _replaceInvite(invite._copyWith(status: InviteStatus.declined));
  }

  DemoInvite revokeInvite(String inviteId) {
    final invite = _requiredInvite(inviteId);
    _requireOwner(invite.agreementId);
    if (!invite.isOpen) {
      throw StateError('Only an open demo invitation can be revoked.');
    }
    return _replaceInvite(invite._copyWith(status: InviteStatus.revoked));
  }

  DemoPerson _requireSignedIn() {
    final current = _currentPerson;
    if (current == null) {
      throw StateError('Select a fictional sign-in identity first.');
    }
    return current;
  }

  DemoPerson _requiredPerson(String personId) {
    final selected = person(personId);
    if (selected == null) {
      throw ArgumentError.value(
        personId,
        'personId',
        'The fictional demo person was not found.',
      );
    }
    return selected;
  }

  DemoPerson _requireOwner(String agreementId) {
    final current = _requireSignedIn();
    if (_owners[agreementId] != current.id) {
      throw StateError(
        'Only this demo agreement owner can manage invitations.',
      );
    }
    return current;
  }

  bool _isOwner(String agreementId) =>
      _currentPerson != null && _owners[agreementId] == _currentPerson!.id;

  DemoPerson _requireInvitationManager(String agreementId) {
    final owner = _requireOwner(agreementId);
    if (_invitationCapabilities[agreementId] != true) {
      throw StateError('This demo agreement is closed to new participants.');
    }
    return owner;
  }

  String _agreementId(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(
        value,
        'agreementId',
        'Enter a demo agreement ID.',
      );
    }
    return value.trim();
  }

  bool _isParticipant(String agreementId, String personId) =>
      (_participants[agreementId] ?? const <DemoParticipant>[]).any(
        (participant) => participant.personId == personId,
      );

  bool _hasOpenInviteForPerson(
    String agreementId,
    String personId, {
    String? excludingId,
  }) => _invites.any(
    (invite) =>
        invite.id != excludingId &&
        invite.agreementId == agreementId &&
        invite.isOpen &&
        (invite.intendedPersonId == personId ||
            invite.requestedPersonId == personId),
  );

  void _requireStatus(DemoInvite invite, InviteStatus expected) {
    if (invite.status != expected) {
      throw StateError(
        'This demo invitation is ${invite.status.label.toLowerCase()}.',
      );
    }
  }

  DemoInvite _requiredInvite(String inviteId) {
    _refreshExpiry();
    final index = _invites.indexWhere((invite) => invite.id == inviteId);
    if (index < 0) {
      throw ArgumentError.value(
        inviteId,
        'inviteId',
        'The demo invitation was not found.',
      );
    }
    return _invites[index];
  }

  DemoInvite _replaceInvite(DemoInvite updated) {
    final index = _invites.indexWhere((invite) => invite.id == updated.id);
    _invites[index] = updated;
    return updated;
  }

  void _refreshExpiry() {
    final now = _clock();
    for (var index = 0; index < _invites.length; index++) {
      final invite = _invites[index];
      if (invite.isOpen && !now.isBefore(invite.expiresAt)) {
        _invites[index] = invite._copyWith(status: InviteStatus.expired);
      }
    }
  }
}
