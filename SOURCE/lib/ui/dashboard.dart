/// WAFA dashboard and section views (DOC-WAFA-0009, LOCK 1).
library;

import 'package:flutter/material.dart';

import '../domain/demo_connections.dart';
import '../domain/demo_models.dart';
import 'wafa_ui.dart';

const _overdueInk = Color(0xffa3312a);
const _overdueBackground = Color(0xfffbecea);
const _signatureInk = Color(0xff9b541d);

const _sections = [
  AgreementStatus.active,
  AgreementStatus.draft,
  AgreementStatus.awaitingSignatures,
  AgreementStatus.completed,
  AgreementStatus.overdue,
];

extension on AgreementStatus {
  String get sectionLabel => this == AgreementStatus.draft ? 'Drafts' : label;

  String get emptyMessage => switch (this) {
    AgreementStatus.active => 'No active agreements.',
    AgreementStatus.draft =>
      "No drafts. Agreements you start but don't send wait here.",
    AgreementStatus.awaitingSignatures => 'Nothing waiting for a signature.',
    AgreementStatus.completed => 'No completed agreements yet.',
    AgreementStatus.overdue => 'Nothing overdue.',
  };
}

int _calendarDays(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

int _dueOrder(Agreement a, Agreement b) => a.dueDate.compareTo(b.dueDate);

class Dashboard extends StatelessWidget {
  const Dashboard({
    super.key,
    required this.agreements,
    required this.connections,
    required this.today,
    required this.hour,
    required this.onProfile,
    required this.onAll,
    required this.onInvitations,
    required this.onCreate,
    required this.onAgreement,
    required this.onSection,
  });

  final List<Agreement> agreements;
  final DemoConnectionsRepository connections;
  final DateTime today;
  final int hour;
  final VoidCallback onProfile, onAll, onInvitations, onCreate;
  final ValueChanged<Agreement> onAgreement;
  final ValueChanged<AgreementStatus> onSection;

  @override
  Widget build(BuildContext context) {
    final firstName = connections.currentPerson!.name.split(' ').first;
    final invites = connections.incomingInvites.where((i) => i.isOpen).toList();
    final isNew = agreements.isEmpty;
    final groups = {
      for (final status in _sections)
        status: agreements.where((a) => a.status == status).toList(),
    };
    final active = groups[AgreementStatus.active]!;
    final overdue = groups[AgreementStatus.overdue]!;
    final waiting = groups[AgreementStatus.awaitingSignatures]!;
    final running = active.length + overdue.length;
    final greeting = switch (hour) {
      < 12 => 'Good morning',
      < 18 => 'Good afternoon',
      _ => 'Good evening',
    };

    Widget agreementRow(Agreement agreement, Color stripe, String detail) =>
        _NeedsRow(
          stripe: stripe,
          title: '${agreement.title} · ${agreement.counterparty}',
          detail: detail,
          onTap: () => onAgreement(agreement),
        );

    final needsRows = <Widget>[
      for (final (index, invite) in invites.indexed)
        _NeedsRow(
          key: index == 0 ? const Key('open-invitations') : null,
          stripe: WafaColors.green,
          title: 'Invitation · ${connections.person(invite.creatorId)!.name}',
          detail: 'Asks you to join an agreement',
          onTap: onInvitations,
        ),
      for (final agreement in overdue)
        agreementRow(agreement, _overdueInk, _overdueDetail(agreement)),
      for (final agreement in waiting)
        agreementRow(agreement, _signatureInk, 'Waiting for your signature'),
      for (final agreement in active)
        if (_calendarDays(today, agreement.dueDate) <= 7)
          agreementRow(agreement, WafaColors.green, _dueDetail(agreement)),
    ];
    final next = needsRows.isEmpty && active.isNotEmpty
        ? (active.toList()..sort(_dueOrder)).first
        : null;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          sliver: SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FittedBox(fit: BoxFit.scaleDown, child: BrandMark()),
                          DemoBadge(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: 'Your profile',
                      style: IconButton.styleFrom(
                        backgroundColor: WafaColors.mint,
                        foregroundColor: WafaColors.green,
                        fixedSize: const Size.square(40),
                        minimumSize: const Size.square(40),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: onProfile,
                      icon: Text(
                        firstName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  isNew ? 'Welcome, $firstName' : '$greeting, $firstName',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.8,
                  ),
                ),
                if (isNew) ...[
                  const Expanded(
                    child: Center(
                      child: _EmptyAgreements(
                        title: 'No agreements yet',
                        detail:
                            'Write down what you agree with someone, sign it '
                            'together, and keep track of every payment.',
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    '${dateLabel(today, includeYear: false)} · $running '
                    '${running == 1 ? 'agreement' : 'agreements'} running',
                    style: const TextStyle(
                      fontSize: 14.5,
                      height: 1.5,
                      color: WafaColors.muted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (needsRows.isEmpty)
                    const _CalmCard()
                  else
                    _NeedsCard(rows: needsRows),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: _DashboardHeading('Your agreements'),
                      ),
                      TextButton(
                        onPressed: onAll,
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                  _sectionTiles(_sections.take(3), groups),
                  const SizedBox(height: 10),
                  _sectionTiles(_sections.skip(3), groups),
                  if (next != null) ...[
                    const SizedBox(height: 14),
                    const _DashboardHeading('Next payment'),
                    const SizedBox(height: 14),
                    AgreementTile(
                      agreement: next,
                      onTap: () => onAgreement(next),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Spacer(),
                ],
                FilledButton.icon(
                  key: const Key('create-agreement'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 49),
                    textStyle: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: onCreate,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    isNew
                        ? 'Create your first agreement'
                        : 'Create an agreement',
                  ),
                ),
                if (isNew && invites.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    key: const Key('open-invitations'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: WafaColors.ink,
                      minimumSize: const Size(48, 44),
                      side: const BorderSide(color: WafaColors.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onPressed: onInvitations,
                    icon: const Icon(Icons.mail_outline, size: 18),
                    label: Text('Invitations · ${invites.length} waiting'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _overdueDetail(Agreement agreement) {
    final days = _calendarDays(agreement.dueDate, today);
    return '$days ${days == 1 ? 'day' : 'days'} overdue · '
        '${money(agreement.remainingPence)} left';
  }

  String _dueDetail(Agreement agreement) {
    final days = _calendarDays(today, agreement.dueDate);
    final when = switch (days) {
      0 => 'Due today',
      1 => 'Due tomorrow',
      _ => 'Due in $days days',
    };
    return '$when · ${money(agreement.remainingPence)} left';
  }

  Widget _sectionTiles(
    Iterable<AgreementStatus> statuses,
    Map<AgreementStatus, List<Agreement>> groups,
  ) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        for (final status in statuses)
          Expanded(
            child: _SectionTile(
              key: ValueKey(status),
              status: status,
              count: groups[status]!.length,
              onTap: () => onSection(status),
            ),
          ),
      ],
    ),
  );
}

class DashboardSection extends StatelessWidget {
  const DashboardSection({
    super.key,
    required this.status,
    required this.agreements,
    required this.onBack,
    required this.onAgreement,
  });

  final AgreementStatus status;
  final List<Agreement> agreements;
  final VoidCallback onBack;
  final ValueChanged<Agreement> onAgreement;

  @override
  Widget build(BuildContext context) {
    final filtered = agreements.where((a) => a.status == status).toList()
      ..sort(_dueOrder);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          sliver: SliverToBoxAdapter(
            child: Row(
              spacing: 8,
              children: [
                IconButton(
                  tooltip: 'Back',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xfff5f7f6),
                    foregroundColor: WafaColors.ink,
                    fixedSize: const Size.square(38),
                    minimumSize: const Size.square(38),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onBack,
                  icon: const Icon(Icons.chevron_left, size: 22),
                ),
                Expanded(
                  child: Text(
                    status.sectionLabel,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          sliver: filtered.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _EmptyAgreements(
                      title: 'Nothing here yet',
                      detail: status.emptyMessage,
                    ),
                  ),
                )
              : SliverList.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final agreement = filtered[index];
                    return AgreementTile(
                      agreement: agreement,
                      onTap: () => onAgreement(agreement),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _DashboardHeading extends StatelessWidget {
  const _DashboardHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      letterSpacing: -.2,
    ),
  );
}

class _NeedsCard extends StatelessWidget {
  const _NeedsCard({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: WafaColors.line),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Needs you',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${rows.length} ${rows.length == 1 ? 'thing' : 'things'}',
                style: const TextStyle(fontSize: 12.5, color: WafaColors.muted),
              ),
            ],
          ),
        ),
        for (final (index, row) in rows.indexed) ...[
          if (index > 0) const Divider(height: 1),
          row,
        ],
      ],
    ),
  );
}

class _NeedsRow extends StatelessWidget {
  const _NeedsRow({
    super.key,
    required this.stripe,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final Color stripe;
  final String title, detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: stripe,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    detail,
                    style: const TextStyle(
                      fontSize: 13,
                      color: WafaColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const Center(
              child: Text(
                'Open ›',
                style: TextStyle(
                  color: WafaColors.green,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CalmCard extends StatelessWidget {
  const _CalmCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: WafaColors.mint,
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Row(
      spacing: 12,
      children: [
        Icon(Icons.check_circle_outline, size: 28, color: WafaColors.green),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nothing needs you today',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: WafaColors.green,
                ),
              ),
              Text(
                "We'll tell you when a payment or signature is due.",
                style: TextStyle(fontSize: 13, color: WafaColors.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    super.key,
    required this.status,
    required this.count,
    required this.onTap,
  });

  final AgreementStatus status;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hot = status == AgreementStatus.overdue && count > 0;
    return Material(
      color: hot ? _overdueBackground : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: hot ? const Color(0xfff1d3cf) : WafaColors.line,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 24,
                  letterSpacing: -.5,
                  fontWeight: FontWeight.w700,
                  color: hot
                      ? _overdueInk
                      : count == 0
                      ? const Color(0xffb3bfb8)
                      : WafaColors.ink,
                ),
              ),
              Text(
                status.sectionLabel,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.25,
                  color: WafaColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyAgreements extends StatelessWidget {
  const _EmptyAgreements({required this.title, required this.detail});

  final String title, detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 28),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: WafaColors.mint,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.description_outlined,
            size: 30,
            color: WafaColors.green,
          ),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14.5,
            height: 1.5,
            color: WafaColors.muted,
          ),
        ),
      ],
    ),
  );
}
