import 'package:flutter/material.dart';

import '../domain/demo_models.dart';
import 'wafa_ui.dart';

class CreateAgreement extends StatefulWidget {
  const CreateAgreement({super.key, required this.repository});

  final DemoAgreementRepository repository;

  @override
  State<CreateAgreement> createState() => _CreateAgreementState();
}

class _CreateAgreementState extends State<CreateAgreement> {
  final _detailsFormKey = GlobalKey<FormState>();
  final _counterparty = TextEditingController();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  ContractKind _kind = ContractKind.interestFreeLoan;
  int _step = 0;
  late DateTime _dueDate;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final today = widget.repository.today;
    _dueDate = DateTime(today.year, today.month, today.day + 14);
  }

  @override
  void dispose() {
    _counterparty.dispose();
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _step--;
      _saveError = null;
    });
  }

  void _advance() {
    if (_step == 1) {
      if (!(_detailsFormKey.currentState?.validate() ?? false)) return;
      if (_dueDate.isBefore(widget.repository.today)) {
        setState(() => _saveError = 'Choose today or a later due date.');
        return;
      }
    }
    FocusScope.of(context).unfocus();
    if (_step < 2) {
      setState(() {
        _step++;
        _saveError = null;
      });
      return;
    }
    _saveDraft();
  }

  String get _draftTitle {
    final title = _title.text.trim();
    return title.isEmpty
        ? '${kindLabel(_kind)} with ${_counterparty.text.trim()}'
        : title;
  }

  void _saveDraft() {
    final amountPence = parsePence(_amount.text);
    if (amountPence == null || amountPence <= 0) {
      setState(() {
        _step = 1;
        _saveError = 'Enter a valid amount before saving.';
      });
      return;
    }
    try {
      final draft = widget.repository.createDraft(
        kind: _kind,
        counterparty: _counterparty.text,
        title: _draftTitle,
        amountPence: amountPence,
        dueDate: _dueDate,
      );
      Navigator.of(context).pop(draft);
    } on ArgumentError {
      setState(() {
        _step = 1;
        _saveError = 'Check your details and choose today or a later due date.';
      });
    }
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
    setState(() {
      _dueDate = picked;
      _saveError = null;
    });
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
                if (_saveError != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _saveError!,
                    style: const TextStyle(color: Color(0xFFAD3737)),
                  ),
                ],
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
              child: FilledButton(
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        switch (_step) {
                          0 => 'Continue',
                          1 => 'Review draft',
                          _ => 'Save demo draft',
                        },
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      _step == 2
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      size: 20,
                    ),
                  ],
                ),
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
      const SizedBox(height: 8),
      _note(
        icon: Icons.info_outline_rounded,
        title: 'Try it with fictional details',
        body: 'This prototype keeps drafts in this demo session only.',
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
                        kindLabel(kind),
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

  Widget _detailsStep() => Form(
    key: _detailsFormKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          'Make the details clear.',
          'A few simple details help everyone understand the promise.',
        ),
        const SizedBox(height: 26),
        _fieldLabel('Who is this with?'),
        TextFormField(
          key: const Key('counterparty'),
          controller: _counterparty,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration('Fictional name, e.g. Amina Noor'),
          validator: (value) => (value?.trim().isEmpty ?? true)
              ? 'Enter a fictional counterparty name.'
              : null,
        ),
        const SizedBox(height: 22),
        _fieldLabel('Agreement title', optional: true),
        TextFormField(
          key: const Key('draft-title'),
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration('Give this promise a name'),
        ),
        const SizedBox(height: 22),
        _fieldLabel(
          _kind == ContractKind.interestFreeLoan
              ? 'Loan amount'
              : 'Agreement amount',
        ),
        TextFormField(
          key: const Key('amount'),
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          decoration: _inputDecoration(
            '0.00',
          ).copyWith(prefixText: '£  ', suffixText: 'GBP'),
          validator: (value) {
            final amountPence = parsePence(value ?? '');
            if (amountPence == null || amountPence <= 0) {
              return 'Enter an amount above £0 with up to 2 decimal places.';
            }
            return null;
          },
          onFieldSubmitted: (_) => _advance(),
        ),
        const SizedBox(height: 22),
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
        const SizedBox(height: 22),
        _note(
          icon: Icons.edit_note_rounded,
          title: 'Your draft, at your pace',
          body: 'You can go back and change these details before saving.',
        ),
      ],
    ),
  );

  Widget _reviewStep() {
    final amountPence = parsePence(_amount.text) ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          'A promise, put into words.',
          'Take a moment to check your draft. Nothing is signed or sent.',
        ),
        const SizedBox(height: 26),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: WafaColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(kindIcon(_kind), color: WafaColors.green, size: 23),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      kindLabel(_kind),
                      style: const TextStyle(
                        color: WafaColors.green,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Text(
                    'DRAFT',
                    style: TextStyle(
                      color: WafaColors.muted,
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                _draftTitle,
                style: const TextStyle(
                  color: WafaColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    money(amountPence),
                    style: const TextStyle(
                      color: WafaColors.green,
                      fontSize: 35,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(color: WafaColors.line, height: 1),
              const SizedBox(height: 20),
              _reviewRow('With', _counterparty.text.trim()),
              const SizedBox(height: 16),
              _reviewRow('Due date', dateLabel(_dueDate)),
              const SizedBox(height: 16),
              _reviewRow('Currency', 'British pound (GBP)'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _note(
          icon: Icons.info_outline_rounded,
          title: 'Demo draft only',
          body:
              'This is fictional, local demo data. Saving does not create a binding agreement, collect signatures or move money.',
        ),
        const SizedBox(height: 18),
        const Text(
          'Drafts reset when this demo session ends.',
          style: TextStyle(color: WafaColors.muted, fontSize: 12, height: 1.5),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: WafaColors.muted, fontSize: 14),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    filled: true,
    fillColor: Colors.white,
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
            '(optional)',
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

  Widget _note({
    required IconData icon,
    required String title,
    required String body,
  }) => SoftNote(icon: icon, title: title, body: body);
}
