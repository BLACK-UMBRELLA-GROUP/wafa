import 'package:flutter/material.dart';

import '../domain/demo_connections.dart';
import 'wafa_ui.dart';

/// A local, fictional invitation rehearsal. It sends nothing off this device.
class ParticipantsScreen extends StatefulWidget {
  const ParticipantsScreen({
    super.key,
    required this.connections,
    required this.agreementId,
    required this.onChanged,
  });

  final DemoConnectionsRepository connections;
  final String agreementId;
  final VoidCallback onChanged;

  @override
  State<ParticipantsScreen> createState() => _ParticipantsScreenState();
}

class _ParticipantsScreenState extends State<ParticipantsScreen> {
  Future<void> _addPerson() async {
    final draft = await showDialog<_InvitationDraft>(
      context: context,
      builder: (_) => _AddPersonDialog(connections: widget.connections),
    );
    if (!mounted || draft == null) return;
    try {
      final invitation = widget.connections.createInvite(
        widget.agreementId,
        draft.role,
        intendedPersonId: draft.personId,
      );
      _changed();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => _InvitationPreviewDialog(
          invitation: invitation,
          qrPreview: draft.qrPreview,
        ),
      );
    } on ArgumentError {
      _showUnavailable();
    } on StateError {
      _showUnavailable();
    }
  }

  Future<void> _confirm(DemoInvite invitation) async {
    final requesterId = invitation.requestedPersonId;
    final requester = requesterId == null
        ? null
        : widget.connections.person(requesterId);
    if (requester == null) {
      _showUnavailable();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Is this the right person?'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              requester.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Wafa ID: ${requester.wafaId}'),
            const SizedBox(height: 8),
            Text('Role: ${_roleLabel(invitation.role)}'),
            const SizedBox(height: 16),
            Text('Demo pairing code: ${invitation.code}'),
            const SizedBox(height: 8),
            const Text(
              'In the real flow, compare the Wafa ID and code in your existing '
              'trusted conversation or in person. A name alone is not proof.',
            ),
            const SizedBox(height: 16),
            const Text('Joining gives access. It does not sign an agreement.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            key: const ValueKey('participant-confirm-request'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm person', textAlign: TextAlign.center),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    try {
      // Do not let a stale confirmation silently approve a different account.
      final current = widget.connections
          .invitesForAgreement(widget.agreementId)
          .where((invite) => invite.id == invitation.id)
          .firstOrNull;
      if (current == null ||
          current.status != InviteStatus.requested ||
          current.requestedPersonId != requesterId) {
        _showUnavailable();
        return;
      }
      widget.connections.confirmRequest(invitation.id);
      _changed();
    } on ArgumentError {
      _showUnavailable();
    } on StateError {
      _showUnavailable();
    }
  }

  Future<void> _revoke(DemoInvite invitation) async {
    final revoke = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Revoke this invitation?'),
        content: const Text(
          'It can no longer be used to join. Other people already accepted '
          'onto this demo agreement are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep invitation'),
          ),
          FilledButton(
            key: const ValueKey('participant-revoke-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revoke', textAlign: TextAlign.center),
          ),
        ],
      ),
    );
    if (!mounted || revoke != true) return;
    try {
      widget.connections.revokeInvite(invitation.id);
      _changed();
    } on ArgumentError {
      _showUnavailable();
    } on StateError {
      _showUnavailable();
    }
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    widget.onChanged();
  }

  void _showUnavailable() {
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'This demo invitation is no longer available for that action. '
          'Check the person, role and latest status.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connections = widget.connections;
    final canView = connections.canViewAgreement(widget.agreementId);
    final canManage =
        canView && connections.canManageParticipants(widget.agreementId);
    return Scaffold(
      appBar: AppBar(
        title: const Text('People'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 22),
            child: Center(child: DemoBadge()),
          ),
        ],
      ),
      body: !canView
          ? ListView(
              key: const ValueKey('participant-list'),
              padding: const EdgeInsets.all(22),
              children: const [
                SoftNote(
                  icon: Icons.lock_outline,
                  title: 'This agreement is private',
                  body:
                      'Sign in with an accepted demo account to see its '
                      'people. Opening an invitation alone does not give access.',
                ),
              ],
            )
          : ListView(
              key: const ValueKey('participant-list'),
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
              children: [
                const PageHeading(
                  'Better, together.',
                  subtitle:
                      'Two people, or more. Each joins with their own '
                      'Wafa account and an explicit role.',
                ),
                const SizedBox(height: 20),
                const SoftNote(
                  icon: Icons.shield_outlined,
                  title: 'Joining is not signing',
                  body:
                      'This is an unsigned, fictional access rehearsal. '
                      'No real accounts, invitations or signatures are created.',
                ),
                const SizedBox(height: 22),
                if (canManage) ...[
                  FilledButton(
                    key: const ValueKey('participant-add-person'),
                    onPressed: _addPerson,
                    child: const Text(
                      'Add person',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
                const SectionTitle('Accepted people'),
                const SizedBox(height: 12),
                for (final participant in connections.participantsForAgreement(
                  widget.agreementId,
                ))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PersonCard(
                      key: ValueKey(
                        'participant-person-${participant.personId}',
                      ),
                      person: connections.person(participant.personId)!,
                      role: participant.role,
                      isCurrent:
                          participant.personId == connections.currentPerson?.id,
                    ),
                  ),
                if (canManage) ...[
                  const SizedBox(height: 14),
                  const SectionTitle('Invitations'),
                  const SizedBox(height: 8),
                  const Text(
                    'Make one invitation for each person. A saved contact '
                    'still needs a separate invitation for this agreement.',
                    style: TextStyle(color: WafaColors.muted, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  if (connections
                      .invitesForAgreement(widget.agreementId)
                      .isEmpty)
                    const Surface(
                      child: Text('No invitations yet. Start with Add person.'),
                    ),
                  for (final invitation in connections.invitesForAgreement(
                    widget.agreementId,
                  ))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _InvitationCard(
                        connections: connections,
                        invitation: invitation,
                        onConfirm: () => _confirm(invitation),
                        onRevoke: () => _revoke(invitation),
                      ),
                    ),
                ] else ...[
                  const SizedBox(height: 14),
                  const SoftNote(
                    icon: Icons.person_outline,
                    title: 'Your place on this agreement',
                    body:
                        'Only the creator can add people to an unsigned '
                        'draft. Active or closed examples are read-only; '
                        'use an unsigned draft instead.',
                  ),
                ],
              ],
            ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({
    super.key,
    required this.person,
    required this.role,
    required this.isCurrent,
  });

  final DemoPerson person;
  final ParticipantRole role;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${person.name}${isCurrent ? ' · You' : ''}',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(person.wafaId, style: const TextStyle(color: WafaColors.muted)),
        const SizedBox(height: 12),
        Text(
          '${_roleLabel(role)} · Access accepted · Not signed',
          style: const TextStyle(color: WafaColors.green, height: 1.4),
        ),
      ],
    ),
  );
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({
    required this.connections,
    required this.invitation,
    required this.onConfirm,
    required this.onRevoke,
  });

  final DemoConnectionsRepository connections;
  final DemoInvite invitation;
  final VoidCallback onConfirm;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final personId =
        invitation.requestedPersonId ?? invitation.intendedPersonId;
    final person = personId == null ? null : connections.person(personId);
    final canAct =
        invitation.status == InviteStatus.pending ||
        invitation.status == InviteStatus.requested;
    return Surface(
      key: ValueKey('participant-invite-${invitation.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            person?.name ?? 'Person to be confirmed',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          if (person != null) ...[
            const SizedBox(height: 6),
            Text(
              person.wafaId,
              style: const TextStyle(color: WafaColors.muted),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(_roleLabel(invitation.role)),
              Text(
                _statusLabel(invitation.status),
                style: const TextStyle(
                  color: WafaColors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (canAct) ...[
            const SizedBox(height: 12),
            Text('Demo code: ${invitation.code}'),
            const SizedBox(height: 6),
            Text(
              'Expires ${dateLabel(invitation.expiresAt)}',
              style: const TextStyle(color: WafaColors.muted, fontSize: 12),
            ),
          ],
          if (invitation.status == InviteStatus.requested) ...[
            const SizedBox(height: 16),
            const Text(
              'Check the person and Wafa ID before giving access. '
              'A request has not signed anything.',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: ValueKey('participant-confirm-${invitation.id}'),
              onPressed: onConfirm,
              child: const Text('Review person', textAlign: TextAlign.center),
            ),
          ],
          if (canAct)
            TextButton(
              key: ValueKey('participant-revoke-${invitation.id}'),
              onPressed: onRevoke,
              child: const Text(
                'Revoke invitation',
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

enum _FindMethod { contacts, wafaId, invitation, qr }

class _InvitationDraft {
  const _InvitationDraft(this.role, {this.personId, this.qrPreview = false});
  final ParticipantRole role;
  final String? personId;
  final bool qrPreview;
}

class _AddPersonDialog extends StatefulWidget {
  const _AddPersonDialog({required this.connections});
  final DemoConnectionsRepository connections;

  @override
  State<_AddPersonDialog> createState() => _AddPersonDialogState();
}

class _AddPersonDialogState extends State<_AddPersonDialog> {
  final _idController = TextEditingController();
  _FindMethod _method = _FindMethod.contacts;
  ParticipantRole _role = ParticipantRole.party;
  DemoPerson? _person;
  String? _error;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  void _find() {
    final found = widget.connections.findPersonByWafaId(_idController.text);
    setState(() {
      _person = found;
      _error = found == null
          ? 'No matching demo Wafa ID. Use the exact ID shown in the demo profile.'
          : found.id == widget.connections.currentPerson?.id
          ? 'You are already on your own agreement. Choose another person.'
          : null;
      if (_error != null) _person = null;
    });
  }

  void _submit() {
    final targeted =
        _method == _FindMethod.contacts || _method == _FindMethod.wafaId;
    if (targeted && _person == null) {
      setState(() => _error = 'Choose a contact or find their exact Wafa ID.');
      return;
    }
    Navigator.pop(
      context,
      _InvitationDraft(
        _role,
        personId: targeted ? _person!.id : null,
        qrPreview: _method == _FindMethod.qr,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contacts = widget.connections.contactsForCurrentPerson;
    return AlertDialog(
      scrollable: true,
      title: const Text('Add a person'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Choose how you would find them. This preview sends nothing.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in const {
                _FindMethod.contacts: 'Wafa contacts',
                _FindMethod.wafaId: 'Enter Wafa ID',
                _FindMethod.invitation: 'Invitation preview',
                _FindMethod.qr: 'QR preview',
              }.entries)
                ChoiceChip(
                  key: ValueKey('participant-method-${entry.key.name}'),
                  label: Text(entry.value),
                  selected: _method == entry.key,
                  onSelected: (_) => setState(() {
                    _method = entry.key;
                    _person = null;
                    _error = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (_method == _FindMethod.contacts) ...[
            const Text(
              'Previously accepted demo Wafa connections only. '
              'Your phone address book is not accessed.',
              style: TextStyle(color: WafaColors.muted, height: 1.5),
            ),
            const SizedBox(height: 12),
            if (contacts.isEmpty)
              const Text(
                'No accepted Wafa connections yet. Try their Wafa ID or an '
                'invitation preview. Phone contacts are not accessed.',
              ),
            for (final contact in contacts)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  key: ValueKey('participant-contact-${contact.id}'),
                  onPressed: () => setState(() {
                    _person = contact;
                    _error = null;
                  }),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(60),
                    backgroundColor: _person?.id == contact.id
                        ? WafaColors.mint
                        : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [Text(contact.name), Text(contact.wafaId)],
                    ),
                  ),
                ),
              ),
          ],
          if (_method == _FindMethod.wafaId) ...[
            TextField(
              key: const ValueKey('participant-wafa-id'),
              controller: _idController,
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Exact demo Wafa ID',
              ),
              onChanged: (_) => setState(() {
                _person = null;
                _error = null;
              }),
              onSubmitted: (_) => _find(),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const ValueKey('participant-find-id'),
              onPressed: _find,
              child: const Text('Find person'),
            ),
            if (_person != null) ...[
              Text(_person!.name),
              Text(_person!.wafaId),
              const SizedBox(height: 8),
              const Text('Check this is the person you intend to invite.'),
            ],
          ],
          if (_method == _FindMethod.invitation || _method == _FindMethod.qr)
            const Text(
              'One private invitation per person. Opening it would only let '
              'someone request to join. You confirm their Wafa account before '
              'they see the agreement. No real link is created here.',
              style: TextStyle(height: 1.5),
            ),
          const SizedBox(height: 20),
          const FieldLabel('Their role'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final role in ParticipantRole.values)
                ChoiceChip(
                  key: ValueKey('participant-role-${role.name}'),
                  label: Text(_roleLabel(role)),
                  selected: _role == role,
                  onSelected: (_) => setState(() => _role = role),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Roles are draft placeholders. Joining does not review terms '
            'or sign a contract.',
            style: TextStyle(color: WafaColors.muted, height: 1.5),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              key: const ValueKey('participant-add-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('participant-create-invite'),
          onPressed: _submit,
          child: const Text(
            'Create demo invitation',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _InvitationPreviewDialog extends StatelessWidget {
  const _InvitationPreviewDialog({
    required this.invitation,
    required this.qrPreview,
  });
  final DemoInvite invitation;
  final bool qrPreview;

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Invitation preview'),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (qrPreview) ...[
          const Center(
            child: Icon(Icons.qr_code_2, size: 84, color: WafaColors.green),
          ),
          const SizedBox(height: 16),
        ],
        const Text('DEMO CODE', style: TextStyle(color: WafaColors.muted)),
        const SizedBox(height: 8),
        Text(
          invitation.code,
          key: const ValueKey('participant-invitation-code'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: WafaColors.green,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Text('Role: ${_roleLabel(invitation.role)}'),
        const SizedBox(height: 8),
        Text('Expires ${dateLabel(invitation.expiresAt)}'),
        const SizedBox(height: 16),
        const Text('Demo code — no real QR or invitation is sent.'),
        const SizedBox(height: 12),
        const Text(
          'To rehearse receiving it, switch to the other fictional person in '
          'the demo profile and open their invitations. Joining is not signing.',
          style: TextStyle(height: 1.5),
        ),
      ],
    ),
    actions: [
      TextButton(
        key: const ValueKey('participant-preview-done'),
        onPressed: () => Navigator.pop(context),
        child: const Text('Done'),
      ),
    ],
  );
}

String _roleLabel(ParticipantRole role) => switch (role) {
  ParticipantRole.party => 'Agreement party',
  ParticipantRole.witness => 'Witness',
};

String _statusLabel(InviteStatus status) => switch (status) {
  InviteStatus.pending => 'Awaiting a request',
  InviteStatus.requested => 'Person needs confirmation',
  InviteStatus.accepted => 'Access accepted · Not signed',
  InviteStatus.declined => 'Declined',
  InviteStatus.revoked => 'Revoked',
  InviteStatus.expired => 'Expired',
};
