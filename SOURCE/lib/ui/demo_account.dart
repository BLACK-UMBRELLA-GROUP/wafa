import 'package:flutter/material.dart';

import '../domain/demo_connections.dart';
import 'wafa_ui.dart';

/// A visual account rehearsal. Never opens a provider or collects credentials.
class DemoSignIn extends StatefulWidget {
  const DemoSignIn({
    super.key,
    required this.connections,
    required this.onSignedIn,
  });

  final DemoConnectionsRepository connections;
  final VoidCallback onSignedIn;

  @override
  State<DemoSignIn> createState() => _DemoSignInState();
}

class _DemoSignInState extends State<DemoSignIn> {
  String selectedId = demoAmina.id;

  void signIn(DemoLoginMethod method) {
    widget.connections.signIn(method, selectedId);
    widget.onSignedIn();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          const Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [BrandMark(), DemoBadge()],
          ),
          const SizedBox(height: 36),
          const PageHeading(
            'Good agreements start with you.',
            subtitle: 'One Wafa account. Your agreements, together.',
          ),
          const SizedBox(height: 24),
          const SoftNote(
            icon: Icons.science_outlined,
            title: 'Sign-in preview',
            body:
                'Choose a fictional person below. Apple and Google buttons '
                'simulate sign-in only: no provider opens, no account is '
                'created and no password is requested.',
          ),
          const SizedBox(height: 24),
          const Eyebrow('TRY THE FLOW AS'),
          const SizedBox(height: 12),
          for (final person in widget.connections.persons)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: selectedId == person.id ? WafaColors.mint : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: selectedId == person.id
                        ? WafaColors.green
                        : WafaColors.line,
                  ),
                ),
                child: InkWell(
                  key: ValueKey('demo-person-${person.id}'),
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => selectedId = person.id),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          color: WafaColors.green,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                person.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                person.wafaId,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: WafaColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selectedId == person.id)
                          const Icon(
                            Icons.check_circle,
                            color: WafaColors.green,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('demo-sign-in-apple'),
            onPressed: () => signIn(DemoLoginMethod.apple),
            icon: const Icon(Icons.apple),
            label: const Text('Continue with Apple'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('demo-sign-in-google'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => signIn(DemoLoginMethod.google),
            icon: const Icon(Icons.account_circle_outlined),
            label: const Text('Continue with Google'),
          ),
          const SizedBox(height: 16),
          const Text(
            'DEMO ONLY · Switch people in Profile to try both sides. '
            'Everything resets when the app process restarts.',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: WafaColors.muted,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Minimal invitation metadata only; a code never displays private terms.
class DemoInvitationsScreen extends StatefulWidget {
  const DemoInvitationsScreen({
    super.key,
    required this.connections,
    required this.onChanged,
  });

  final DemoConnectionsRepository connections;
  final VoidCallback onChanged;

  @override
  State<DemoInvitationsScreen> createState() => _DemoInvitationsScreenState();
}

class _DemoInvitationsScreenState extends State<DemoInvitationsScreen> {
  final codeController = TextEditingController();
  DemoInvite? preview;
  String? error;

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  void previewCode() {
    try {
      final invite = widget.connections.findInviteByCode(codeController.text);
      setState(() {
        preview = invite;
        error = invite == null ? 'That demo invitation is unavailable.' : null;
      });
    } on StateError catch (failure) {
      setState(() => error = failure.message);
    }
  }

  void act(DemoInvite invite, {bool decline = false}) {
    try {
      final updated = decline
          ? widget.connections.declineInvite(invite.id)
          : widget.connections.requestJoin(invite.code);
      setState(() {
        if (preview?.id == invite.id) preview = updated;
        error = null;
      });
      widget.onChanged();
    } on StateError catch (failure) {
      setState(() => error = failure.message);
    } on ArgumentError {
      setState(() => error = 'That demo invitation is unavailable.');
    }
  }

  Widget invitationCard(DemoInvite snapshot) {
    final invite =
        widget.connections.findInviteByCode(snapshot.code) ?? snapshot;
    final creator = widget.connections.person(invite.creatorId);
    final current = widget.connections.currentPerson;
    final intendedForCurrent =
        invite.intendedPersonId == null ||
        invite.intendedPersonId == current?.id;
    if (!intendedForCurrent && invite.requestedPersonId != current?.id) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 14),
        child: Surface(
          child: SoftNote(
            icon: Icons.lock_outline_rounded,
            title: 'Invitation for a different account',
            body:
                'This code reveals no agreement or sender details here. '
                'Switch to the intended fictional Wafa account.',
          ),
        ),
      );
    }
    final canRequest =
        invite.status == InviteStatus.pending &&
        invite.creatorId != current?.id &&
        intendedForCurrent;
    final canDecline =
        invite.status == InviteStatus.requested &&
            invite.requestedPersonId == current?.id ||
        invite.status == InviteStatus.pending &&
            invite.intendedPersonId == current?.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${creator?.name ?? 'Demo person'} invited you',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              creator?.wafaId ?? '',
              style: const TextStyle(color: WafaColors.muted),
            ),
            const SizedBox(height: 14),
            Text('Role: ${invite.role.label} · ${invite.status.label}'),
            const SizedBox(height: 8),
            Text('Demo code: ${invite.code}'),
            const SizedBox(height: 6),
            Text('Demo expiry: ${dateLabel(invite.expiresAt)}'),
            const SizedBox(height: 14),
            if (invite.status == InviteStatus.requested)
              const Text(
                'Waiting for the creator to confirm you. '
                'The private agreement is still hidden.',
              ),
            if (invite.status == InviteStatus.accepted)
              const Text(
                'Connection confirmed. The agreement is now listed '
                'in Agreements. This is not a signature.',
              ),
            if (canRequest) ...[
              const Text(
                'Check who invited you. Requesting to join does not '
                'accept the terms or sign anything.',
              ),
              const SizedBox(height: 12),
              FilledButton(
                key: ValueKey('request-join-${invite.id}'),
                onPressed: () => act(invite),
                child: const Text('Request to join · demo'),
              ),
            ],
            if (canDecline)
              TextButton(
                key: ValueKey('decline-invite-${invite.id}'),
                onPressed: () => act(invite, decline: true),
                child: const Text('Decline invitation'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final person = widget.connections.currentPerson;
    if (person == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invitations')),
        body: const Center(child: Text('Choose a demo account first.')),
      );
    }
    final incoming = widget.connections.incomingInvites;
    return Scaffold(
      appBar: AppBar(title: const Text('Invitations')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        children: [
          const DemoBadge(),
          const SizedBox(height: 20),
          const PageHeading(
            'A place at the table',
            subtitle: 'Choose who you make agreements with.',
          ),
          const SizedBox(height: 20),
          SoftNote(
            icon: Icons.person_outline,
            title: 'Joining as ${person.name}',
            body:
                '${person.wafaId}. If this is not the person you intended, '
                'go back to Profile and switch demo account first.',
          ),
          const SizedBox(height: 22),
          const FieldLabel('Enter a demo invitation code'),
          const SizedBox(height: 8),
          TextField(
            key: const Key('invitation-code'),
            controller: codeController,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            decoration: const InputDecoration(hintText: 'Example: WAFA-0001'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            key: const Key('preview-invitation'),
            onPressed: previewCode,
            child: const Text('Preview invitation · demo'),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          if (preview case final selected?) invitationCard(selected),
          for (final invite in incoming.where((i) => i.id != preview?.id))
            invitationCard(invite),
          if (incoming.isEmpty && preview == null)
            const SoftNote(
              icon: Icons.mail_outline,
              title: 'No demo invitations yet',
              body:
                  'As Amina, open an unsigned draft and add Omar or Sara. '
                  'Switch accounts in Profile to try receiving it here.',
            ),
          const SizedBox(height: 16),
          const Text(
            'Local rehearsal only. No link, message or real QR is sent. '
            'Knowing a code alone never grants agreement access.',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: WafaColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
