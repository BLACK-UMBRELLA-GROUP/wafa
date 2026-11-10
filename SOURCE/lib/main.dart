import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'domain/demo_models.dart';
import 'domain/demo_connections.dart';
import 'ui/wafa_ui.dart';
import 'ui/create_agreement.dart';
import 'ui/agreement_detail.dart';
import 'ui/demo_account.dart';
import 'ui/dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  runApp(const WafaApp());
}

class WafaApp extends StatefulWidget {
  const WafaApp({super.key, this.repository, this.connections, this.clock});
  final DemoAgreementRepository? repository;
  final DemoConnectionsRepository? connections;
  final DemoClock? clock;
  @override
  State<WafaApp> createState() => _WafaAppState();
}

class _WafaAppState extends State<WafaApp> {
  late final DemoAgreementRepository repository;
  late final DemoConnectionsRepository connections;
  @override
  void initState() {
    super.initState();
    repository = widget.repository ?? DemoAgreementRepository();
    connections = widget.connections ?? DemoConnectionsRepository();
    final wasSignedIn = connections.currentPerson != null;
    if (!wasSignedIn) connections.signIn(DemoLoginMethod.apple, demoAmina.id);
    for (final agreement in repository.agreements) {
      connections.registerAgreement(
        agreement.id,
        ownerId: demoAmina.id,
        invitationsAllowed: agreement.status == AgreementStatus.draft,
      );
    }
    if (!wasSignedIn) connections.signOut();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Wafa – Islamic Contracts',
    debugShowCheckedModeBanner: false,
    theme: wafaTheme,
    home: connections.currentPerson == null
        ? DemoSignIn(
            connections: connections,
            onSignedIn: () => setState(() {}),
          )
        : WafaHome(
            key: ValueKey(connections.currentPerson!.id),
            repository: repository,
            connections: connections,
            clock: widget.clock,
            onSignedOut: () => setState(connections.signOut),
          ),
  );
}

class WafaHome extends StatefulWidget {
  const WafaHome({
    super.key,
    required this.repository,
    required this.connections,
    required this.onSignedOut,
    this.clock,
  });
  final DemoAgreementRepository repository;
  final DemoConnectionsRepository connections;
  final VoidCallback onSignedOut;
  final DemoClock? clock;
  @override
  State<WafaHome> createState() => _WafaHomeState();
}

class _WafaHomeState extends State<WafaHome> {
  int tab = 0;
  AgreementStatus? dashboardSection;
  String filter = 'All';
  String query = '';
  final searchController = TextEditingController();
  List<Agreement> get visibleAgreements => widget.repository.agreements
      .where((agreement) => widget.connections.canViewAgreement(agreement.id))
      .map(
        (agreement) =>
            agreement.forViewer(widget.connections.currentPerson?.id),
      )
      .toList(growable: false);
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> openAgreement(Agreement agreement) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AgreementDetail(
          repository: widget.repository,
          connections: widget.connections,
          id: agreement.id,
          onChanged: () {
            if (mounted) setState(() {});
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> createAgreement() async {
    final draft = await Navigator.of(context).push<Agreement>(
      MaterialPageRoute(
        builder: (_) => CreateAgreement(
          repository: widget.repository,
          connections: widget.connections,
        ),
      ),
    );
    if (!mounted || draft == null) return;
    setState(() {
      tab = 1;
      filter = 'Drafts';
      query = '';
      searchController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Demo draft saved for this session. No real contract created.',
        ),
      ),
    );
  }

  Future<void> openInvitations() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DemoInvitationsScreen(
          connections: widget.connections,
          onChanged: () {
            if (mounted) setState(() {});
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void selectTab(int value) => setState(() {
    dashboardSection = null;
    tab = value;
  });

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: dashboardSection == null,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && dashboardSection != null) selectTab(0);
    },
    child: Scaffold(
      body: SafeArea(
        child: switch (tab) {
          1 => agreementsPage(),
          2 => trackerPage(),
          3 => profilePage(),
          _ => dashboard(),
        },
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: WafaColors.line)),
        ),
        child: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: selectTab,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.description_outlined),
              label: 'Agreements',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: 'Tracker',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    ),
  );

  Widget dashboard() {
    final section = dashboardSection;
    if (section != null) {
      return DashboardSection(
        status: section,
        agreements: visibleAgreements,
        onBack: () => selectTab(0),
        onAgreement: openAgreement,
      );
    }
    return Dashboard(
      agreements: visibleAgreements,
      connections: widget.connections,
      today: widget.repository.today,
      hour: (widget.clock ?? DateTime.now)().hour,
      onProfile: () => selectTab(3),
      onAll: () => selectTab(1),
      onInvitations: openInvitations,
      onCreate: createAgreement,
      onAgreement: openAgreement,
      onSection: (status) => setState(() => dashboardSection = status),
    );
  }

  Widget agreementsPage() {
    final filtered = visibleAgreements.where((a) {
      final matches = switch (filter) {
        'Active' =>
          a.status == AgreementStatus.active ||
              a.status == AgreementStatus.overdue,
        'Waiting' => a.status == AgreementStatus.awaitingSignatures,
        'Drafts' => a.status == AgreementStatus.draft,
        'Completed' => a.status == AgreementStatus.completed,
        _ => true,
      };
      return matches &&
          '${a.title} ${a.counterparty}'.toLowerCase().contains(
            query.toLowerCase(),
          );
    }).toList();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageHeading(
          'Your agreements',
          subtitle: 'Everything agreed. Nothing lost in a chat.',
          trailing: IconButton.filled(
            onPressed: createAgreement,
            tooltip: 'Create an agreement',
            icon: const Icon(Icons.add),
          ),
        ),
        const SizedBox(height: 22),
        TextField(
          key: const Key('agreement-search'),
          controller: searchController,
          onChanged: (s) => setState(() => query = s),
          decoration: const InputDecoration(
            hintText: 'Search names or agreements',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 18),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', 'Active', 'Waiting', 'Drafts', 'Completed']
                .map(
                  (value) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(value),
                      selected: filter == value,
                      onSelected: (_) => setState(() => filter = value),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                '${filtered.length} AGREEMENTS',
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  color: WafaColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const DemoBadge(),
          ],
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: SoftNote(
              icon: Icons.search_off_outlined,
              title: 'Nothing here yet',
              body: 'Try another search or create a new demo draft.',
            ),
          ),
        ...filtered.map(
          (a) => AgreementTile(agreement: a, onTap: () => openAgreement(a)),
        ),
      ],
    );
  }

  Widget trackerPage() {
    final loans = visibleAgreements
        .where(
          (a) =>
              a.isLoan &&
              a.status != AgreementStatus.draft &&
              a.status != AgreementStatus.awaitingSignatures,
        )
        .toList();
    final remaining = loans.fold<int>(0, (sum, a) => sum + a.remainingPence);
    final collected = loans.fold<int>(0, (sum, a) => sum + a.paidPence);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const PageHeading(
          'A clearer picture',
          subtitle: 'A simple view of your example loan records.',
        ),
        const SizedBox(height: 26),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Eyebrow('REMAINING TO COLLECT · DEMO'),
              const SizedBox(height: 14),
              Text(
                money(remaining),
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -1.5,
                  color: WafaColors.green,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 17,
                    color: WafaColors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${money(collected)} recorded as repaid',
                      style: const TextStyle(color: WafaColors.muted),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SectionTitle('Loan progress'),
        const SizedBox(height: 12),
        for (final loan in loans)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Text(
                        loan.counterparty,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                        ),
                      ),
                      StatusBadge(loan.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loan.title,
                    style: const TextStyle(color: WafaColors.muted),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: loan.progress,
                      minHeight: 7,
                      backgroundColor: WafaColors.mint,
                      color: WafaColors.green,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${money(loan.paidPence)} of ${money(loan.amountPence)} recorded',
                    style: const TextStyle(
                      fontSize: 12,
                      color: WafaColors.muted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: () => openAgreement(loan),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: Text(
                      loan.canRecordRepayment
                          ? 'Record a demo repayment'
                          : 'View agreement',
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),
        const SoftNote(
          icon: Icons.account_balance_outlined,
          title: 'Tracking, not banking',
          body:
              'This preview does not connect to your bank, move money, verify transfers or offer financial advice.',
        ),
      ],
    );
  }

  Widget profilePage() => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const SoftNote(
        icon: Icons.info_outline,
        title: 'A first look at Wafa',
        body:
            'Fictional examples only. Changes last for this session. No real AI, signatures or payments are connected.',
      ),
      const SizedBox(height: 24),
      const PageHeading(
        'Your space',
        subtitle: 'Keep your agreements organised, your way.',
      ),
      const SizedBox(height: 28),
      const Center(
        child: CircleAvatar(
          radius: 38,
          backgroundColor: WafaColors.mint,
          child: Icon(Icons.person_outline, color: WafaColors.green, size: 36),
        ),
      ),
      const SizedBox(height: 12),
      const Center(
        child: Text(
          'Demo profile',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
      ),
      const SizedBox(height: 6),
      Center(
        child: Text(
          '${widget.connections.currentPerson!.name}\n'
          '${widget.connections.currentPerson!.wafaId}\n'
          '${widget.connections.loginMethod!.label} · simulated sign-in',
          textAlign: TextAlign.center,
          style: const TextStyle(color: WafaColors.muted, height: 1.6),
        ),
      ),
      const SizedBox(height: 30),
      Surface(
        child: Column(
          children: [
            settingsRow(
              Icons.mail_outline,
              'Invitations',
              'Request to join, then wait for creator confirmation',
              openInvitations,
            ),
            const Divider(height: 24),
            settingsRow(
              Icons.people_outline,
              'Wafa contacts',
              '${widget.connections.contactsForCurrentPerson.length} demo connections',
              () => showInfo(
                'Wafa contacts · demo',
                widget.connections.contactsForCurrentPerson.isEmpty
                    ? 'No connections yet. A confirmed invitation saves the '
                          'connection, but gives no access to other agreements. '
                          'Your phonebook is never read or uploaded.'
                    : widget.connections.contactsForCurrentPerson
                          .map((p) => '${p.name} · ${p.wafaId}')
                          .join('\n\n'),
              ),
            ),
            const Divider(height: 24),
            settingsRow(
              Icons.switch_account_outlined,
              'Switch demo account',
              'Try the invite as Amina, Omar or Sara',
              widget.onSignedOut,
            ),
            const Divider(height: 24),
            settingsRow(
              Icons.language,
              'Language',
              'English · first draft',
              () => showInfo(
                'Languages',
                'This first preview uses English. Arabic and other languages remain planned, not implemented.',
              ),
            ),
            const Divider(height: 24),
            settingsRow(
              Icons.shield_outlined,
              'Privacy in this preview',
              'No uploads or connected services',
              () => showInfo(
                'Local demo only',
                'Records are held in memory on this device. They reset when the app process restarts. Please use fictional names and amounts only.',
              ),
            ),
            const Divider(height: 24),
            settingsRow(
              Icons.info_outline,
              'About Wafa',
              'Islamic Contracts · version 0.1',
              () => showInfo(
                'Wafa – Islamic Contracts',
                'A prototype for creating and tracking Islamic-first agreements. This is not a legal service, scholarly certification or a guarantee of enforceability.',
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const SoftNote(
        icon: Icons.spa_outlined,
        title: 'Built around keeping your word',
        body:
            'Faithfulness, clarity and accountability are our design principles. Contract templates still need legal and qualified scholarly review.',
      ),
    ],
  );

  Widget settingsRow(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: WafaColors.green),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: WafaColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: WafaColors.muted),
        ],
      ),
    ),
  );
  void showInfo(String title, String text) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      scrollable: true,
      title: Text(title),
      content: Text(text),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}
