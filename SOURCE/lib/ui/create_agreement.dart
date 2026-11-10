import 'package:flutter/material.dart';

import '../domain/demo_connections.dart';
import '../domain/demo_models.dart';
import 'participants_screen.dart';
import 'wafa_ui.dart';

class CreateAgreement extends StatefulWidget {
  const CreateAgreement({
    super.key,
    required this.repository,
    required this.connections,
  });

  final DemoAgreementRepository repository;
  final DemoConnectionsRepository connections;

  @override
  State<CreateAgreement> createState() => _CreateAgreementState();
}

class _DraftPerson {
  _DraftPerson(this.role, [this.person]);

  AgreementRole role;
  DemoPerson? person;
  String amount = '';
}

class _CreateAgreementState extends State<CreateAgreement> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _scroll = ScrollController();
  late final List<_DraftPerson> _people;
  bool _setEach = false;
  ContractKind _kind = ContractKind.interestFreeLoan;
  int _step = 0;
  late DateTime _dueDate;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _people = [
      _DraftPerson(AgreementRole.owesShare, widget.connections.currentPerson!),
      _DraftPerson(AgreementRole.isOwed),
    ];
    final today = widget.repository.today;
    _dueDate = DateTime(today.year, today.month, today.day + 14);
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    _scroll.jumpTo(0);
    _change(() => _step--);
  }

  void _change(VoidCallback update) => setState(() {
    update();
    _saveError = null;
  });

  String get _draftTitle =>
      _title.text.trim().isEmpty ? _kind.label : _title.text.trim();

  int get _equalTotal => parsePence(_amount.text) ?? 0;

  List<AgreementPerson> _shares() {
    final selected = _people.where((row) => row.person != null);
    final debtors = selected
        .where((row) => row.role == AgreementRole.owesShare)
        .length;
    final base = debtors == 0 ? 0 : _equalTotal ~/ debtors;
    final extra = debtors == 0 ? 0 : _equalTotal % debtors;
    var debtorIndex = 0;
    return [
      for (final row in selected)
        AgreementPerson(
          id: row.person!.id,
          name: row.person!.name,
          role: row.role,
          sharePence: switch (row.role) {
            AgreementRole.owesShare when _setEach =>
              parsePence(row.amount) ?? 0,
            AgreementRole.owesShare => base + (debtorIndex++ < extra ? 1 : 0),
            _ => 0,
          },
        ),
    ];
  }

  String? _detailsError(List<AgreementPerson> people) {
    final debtors = people.where(
      (person) => person.role == AgreementRole.owesShare,
    );
    if (debtors.isEmpty) return 'Someone needs to owe a share.';
    if (!people.any((person) => person.role == AgreementRole.isOwed)) {
      return 'Someone needs to be owed.';
    }
    if ((_setEach ? _total(people) : _equalTotal) <= 0) {
      return 'Enter an amount above £0.';
    }
    if (debtors.any((person) => person.sharePence <= 0)) {
      return 'Give everyone who owes a share an amount above £0.';
    }
    if (_dueDate.isBefore(widget.repository.today)) {
      return 'Choose today or a later due date.';
    }
    return null;
  }

  int _total(List<AgreementPerson> people) =>
      people.fold(0, (total, person) => total + person.sharePence);

  void _advance() {
    FocusScope.of(context).unfocus();
    if (_step == 0) {
      _scroll.jumpTo(0);
      _change(() => _step++);
      return;
    }
    final people = _shares();
    final error = _detailsError(people);
    if (error != null) {
      setState(() {
        _step = 1;
        _saveError = error;
      });
      return;
    }
    if (_step == 1) {
      _scroll.jumpTo(0);
      _change(() => _step++);
      return;
    }
    try {
      final draft = widget.connections.createAgreementDraft(
        widget.repository,
        kind: _kind,
        title: _draftTitle,
        dueDate: _dueDate,
        people: people,
      );
      Navigator.of(context).pop(draft);
    } on ArgumentError {
      _showSaveError();
    } on StateError {
      _showSaveError();
    }
  }

  void _showSaveError() => setState(() {
    _step = 1;
    _saveError = 'Check your details and try again.';
  });

  Future<void> _addPerson() async {
    FocusScope.of(context).unfocus();
    final person = await showAgreementPersonPicker(
      context,
      widget.connections,
      excludedPersonIds: {
        for (final row in _people)
          if (row.person case final person?) person.id,
      },
    );
    if (!mounted || person == null) return;
    _change(() {
      final slot = _people.where((row) => row.person == null).firstOrNull;
      if (slot != null) {
        slot.person = person;
      } else {
        _people.add(_DraftPerson(AgreementRole.owesShare, person));
      }
    });
  }

  Future<void> _chooseDate() async {
    FocusScope.of(context).unfocus();
    final today = widget.repository.today;
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate.isBefore(today) ? today : _dueDate,
      firstDate: today,
      lastDate: DateTime(today.year + 5, today.month, today.day),
      currentDate: today,
      helpText: 'Choose a due date',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked == null || !mounted) return;
    _change(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Agreement>(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            key: const Key('create-back'),
            tooltip: _step == 0 ? 'Close' : 'Previous step',
            onPressed: _back,
            icon: const Icon(Icons.arrow_back_rounded, color: WafaColors.ink),
          ),
          title: const Text(
            'New agreement',
            style: TextStyle(
              color: WafaColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 20),
              child: Center(child: DemoBadge()),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: SingleChildScrollView(
            controller: _scroll,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _stepIndicator(),
                const SizedBox(height: 32),
                switch (_step) {
                  0 => _typeStep(),
                  1 => _detailsStep(),
                  _ => _reviewStep(),
                },
              ],
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_saveError case final error?) ...[
                    Semantics(
                      liveRegion: true,
                      child: _message(
                        error,
                        background: const Color(0xfffaebe8),
                        foreground: const Color(0xffa93229),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton(
                    key: const Key('create-next'),
                    onPressed: _advance,
                    style: FilledButton.styleFrom(
                      backgroundColor: WafaColors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      switch (_step) {
                        0 => 'Continue',
                        1 => 'Review draft',
                        _ => 'Save draft',
                      },
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepIndicator() {
    const labels = ['Type', 'Details', 'Review'];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(3, (index) {
        final selected = index == _step;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 2 ? 0 : 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: index <= _step ? WafaColors.green : WafaColors.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${index + 1}  ${labels[index]}',
                  style: TextStyle(
                    color: selected ? WafaColors.green : WafaColors.muted,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _heading(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: WafaColors.ink,
          fontSize: 30,
          height: 1.15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.9,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        subtitle,
        style: const TextStyle(
          color: WafaColors.muted,
          fontSize: 14,
          height: 1.5,
        ),
      ),
    ],
  );

  Widget _typeStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _heading(
        'Every promise starts here.',
        'Choose what you would like to record. You can review everything before saving.',
      ),
      const SizedBox(height: 26),
      for (final kind in ContractKind.values) ...[
        _kindCard(kind),
        const SizedBox(height: 12),
      ],
      const Text(
        'Later, after review: business partnership, charity pledge, employment.',
        style: TextStyle(color: WafaColors.muted, fontSize: 13, height: 1.5),
      ),
    ],
  );

  Widget _kindCard(ContractKind kind) {
    final selected = _kind == kind;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? WafaColors.mint : Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          key: Key('kind-${kind.name}'),
          borderRadius: BorderRadius.circular(18),
          onTap: () => setState(() => _kind = kind),
          child: Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? WafaColors.green : WafaColors.line,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : WafaColors.mint,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    kindIcon(kind),
                    color: WafaColors.green,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kind.label,
                        style: const TextStyle(
                          color: WafaColors.ink,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        kindDescription(kind),
                        style: const TextStyle(
                          color: WafaColors.muted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 21,
                  color: selected ? WafaColors.green : WafaColors.line,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailsStep() {
    final shares = _shares();
    final byId = {for (final person in shares) person.id: person};
    final debtors = shares
        .where((person) => person.role == AgreementRole.owesShare)
        .length;
    final splitDescription = switch (debtors) {
      0 => 'Nobody owes a share yet',
      1 => '1 person owes ${money(_equalTotal)} each',
      _ => '$debtors people owe ${money(_equalTotal ~/ debtors)} each',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          'Make the details clear.',
          '${_kind.label} · add everyone who is part of it.',
        ),
        const SizedBox(height: 18),
        _fieldLabel('Agreement title', optional: true),
        TextFormField(
          key: const Key('draft-title'),
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration('Give this promise a name'),
          onChanged: (_) => _change(() {}),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(
              child: Text(
                "Who's in it",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '${_people.length} people',
              style: const TextStyle(color: WafaColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _peopleCard([
          for (final (index, row) in _people.indexed) ...[
            _personRow(
              name: row.person?.name ?? 'Choose a person',
              verification: widget.connections.verificationLevelFor(
                row.person?.id,
              ),
              isMember: index == 0,
              role: row.role,
              sharePence: byId[row.person?.id]?.sharePence ?? 0,
              onChoose: row.person == null ? _addPerson : null,
              onCycle: row.person == null
                  ? null
                  : () => _change(() {
                      row.role =
                          AgreementRole.values[(row.role.index + 1) %
                              AgreementRole.values.length];
                    }),
              onRemove: index == 0
                  ? null
                  : () => _change(() => _people.remove(row)),
              roleKey: Key('draft-role-${row.person?.id ?? 'unassigned'}'),
              amountField: _setEach && row.role == AgreementRole.owesShare
                  ? TextFormField(
                      key: Key('draft-share-${row.person!.id}'),
                      initialValue: row.amount,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _inputDecoration('0').copyWith(
                        prefixText: '£ ',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      onChanged: (value) => _change(() => row.amount = value),
                    )
                  : null,
            ),
            const Divider(height: 1),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('draft-add-person'),
              onPressed: _addPerson,
              icon: const Icon(Icons.add),
              label: const Text('Add a person'),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        _splitSelector(),
        const SizedBox(height: 14),
        if (!_setEach) ...[
          _fieldLabel('Total amount'),
          TextFormField(
            key: const Key('amount'),
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            decoration: _inputDecoration('0.00').copyWith(prefixText: '£  '),
            onChanged: (_) => _change(() {}),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          _setEach ? 'Total: ${money(_total(shares))}' : splitDescription,
          style: const TextStyle(color: WafaColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 18),
        _fieldLabel('Due date'),
        Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: WafaColors.line),
          ),
          child: InkWell(
            key: const Key('due-date'),
            onTap: _chooseDate,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: WafaColors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      dateLabel(_dueDate),
                      style: const TextStyle(
                        color: WafaColors.ink,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.expand_more_rounded,
                    color: WafaColors.muted,
                    size: 21,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_kind == ContractKind.customAgreement) ...[
          const SizedBox(height: 14),
          _message(
            'Your own terms must not include interest or anything prohibited. If you are unsure, ask a scholar before you sign.',
            background: const Color(0xfff9f0e5),
            foreground: const Color(0xff9d5318),
          ),
        ],
      ],
    );
  }

  Widget _splitSelector() => Material(
    color: const Color(0xfff5f7f5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: WafaColors.line),
    ),
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (final (setEach, label) in const [
            (false, 'Split equally'),
            (true, 'Set each amount'),
          ])
            Expanded(
              child: Semantics(
                selected: setEach == _setEach,
                child: TextButton(
                  onPressed: () => _change(() => _setEach = setEach),
                  style: TextButton.styleFrom(
                    backgroundColor: setEach == _setEach ? Colors.white : null,
                    foregroundColor: setEach == _setEach
                        ? WafaColors.green
                        : WafaColors.muted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _message(
    String text, {
    required Color background,
    required Color foreground,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(text, style: TextStyle(color: foreground, height: 1.4)),
  );

  Widget _reviewStep() {
    final people = _shares();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          _draftTitle,
          'Take a moment to check your draft. Nothing is signed or sent.',
        ),
        const SizedBox(height: 26),
        _peopleCard([
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _reviewRow('Type', _kind.label),
                const SizedBox(height: 8),
                _reviewRow('Total', money(_total(people))),
                const SizedBox(height: 8),
                _reviewRow('People', '${people.length}'),
                const SizedBox(height: 8),
                _reviewRow('Currency', 'British pound (GBP)'),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 24),
        _peopleCard([
          for (final (index, person) in people.indexed) ...[
            if (index > 0) const Divider(height: 1),
            _personRow(
              name: person.name,
              verification: widget.connections.verificationLevelFor(person.id),
              isMember: index == 0,
              role: person.role,
              sharePence: person.sharePence,
            ),
          ],
        ]),
        const SizedBox(height: 12),
        const Text(
          'Each person gets an invitation and signs the same agreement. It becomes active when everyone has signed, witnesses too.',
          style: TextStyle(color: WafaColors.muted, fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  Widget _peopleCard(List<Widget> children) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: WafaColors.line),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );

  Widget _personRow({
    required String name,
    required VerificationLevel verification,
    required bool isMember,
    required AgreementRole role,
    required int sharePence,
    VoidCallback? onChoose,
    VoidCallback? onCycle,
    VoidCallback? onRemove,
    Key? roleKey,
    Widget? amountField,
  }) {
    final canEdit = roleKey != null;
    final (background, foreground) = switch (role) {
      AgreementRole.owesShare => (
        const Color(0xfff9f0e5),
        const Color(0xff9d5318),
      ),
      AgreementRole.isOwed => (WafaColors.mint, WafaColors.green),
      AgreementRole.witness => (
        const Color(0xffebeef4),
        const Color(0xff3b4a65),
      ),
    };
    final showShare = role == AgreementRole.owesShare;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: WafaColors.mint,
            foregroundColor: WafaColors.green,
            child: Text(
              onChoose == null ? name.characters.first.toUpperCase() : '?',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (onChoose == null)
                  VerificationName(
                    isMember ? 'You' : name,
                    verification,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  TextButton(
                    key: const Key('draft-choose-person'),
                    onPressed: onChoose,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: Text(name, textAlign: TextAlign.left),
                  ),
                if (canEdit)
                  ActionChip(
                    key: roleKey,
                    label: Text('${role.label} ▾'),
                    labelStyle: TextStyle(
                      color: foreground,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: background,
                    disabledColor: background,
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: onCycle,
                  )
                else
                  Text(
                    role.label,
                    style: const TextStyle(
                      color: WafaColors.muted,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 80),
            child:
                amountField ??
                Text(
                  showShare ? money(sharePence) : '—',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: showShare ? WafaColors.ink : WafaColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: 'Remove $name',
              visualDensity: VisualDensity.compact,
              color: WafaColors.muted,
              iconSize: 18,
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: WafaColors.muted, fontSize: 14),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    filled: true,
    fillColor: const Color(0xfff5f7f5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: WafaColors.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: WafaColors.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: WafaColors.green, width: 1.5),
    ),
    errorMaxLines: 3,
  );

  Widget _fieldLabel(String label, {bool optional = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Wrap(
      spacing: 6,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: WafaColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (optional)
          const Text(
            'optional',
            style: TextStyle(color: WafaColors.muted, fontSize: 13),
          ),
      ],
    ),
  );

  Widget _reviewRow(String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        flex: 2,
        child: Text(
          label,
          style: const TextStyle(color: WafaColors.muted, fontSize: 13),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 3,
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: WafaColors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );
}
