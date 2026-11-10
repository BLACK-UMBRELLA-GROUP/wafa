import 'package:flutter/material.dart';

import '../domain/demo_connections.dart';
import '../domain/demo_models.dart';
import 'wafa_ui.dart';

IconData _evidenceIcon(EvidenceType type) => switch (type) {
  EvidenceType.photo => Icons.photo_camera_outlined,
  EvidenceType.receipt || EvidenceType.document => Icons.description_outlined,
  EvidenceType.bankConfirmation => Icons.check_circle_outline_rounded,
  EvidenceType.voiceNote => Icons.mic_none_rounded,
};

class EvidenceSection extends StatelessWidget {
  const EvidenceSection({
    super.key,
    required this.files,
    required this.removableBy,
    required this.onAdd,
    required this.onRemove,
  });

  final List<DemoEvidence> files;
  final String? removableBy;
  final VoidCallback onAdd;
  final ValueChanged<DemoEvidence> onRemove;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(child: SectionTitle('Evidence')),
          TextButton(
            key: const ValueKey('add-evidence'),
            onPressed: onAdd,
            child: const Text(
              '+ Add',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (files.isEmpty)
        const Text(
          'No evidence yet. Add receipts, photos or bank confirmations so '
          'everyone has the same record.',
          style: TextStyle(color: WafaColors.muted, fontSize: 13, height: 1.4),
        )
      else
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: WafaColors.line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              for (final (index, file) in files.indexed) ...[
                if (index != 0) const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: WafaColors.mint,
                        foregroundColor: WafaColors.green,
                        child: Icon(_evidenceIcon(file.type), size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${file.type.label} · ${file.sizeMb} MB · '
                              'added ${dateLabel(file.addedOn, includeYear: false)}',
                              style: const TextStyle(
                                color: WafaColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (file.addedByPersonId == removableBy)
                        IconButton(
                          tooltip: 'Remove evidence',
                          onPressed: () => onRemove(file),
                          icon: const CircleAvatar(
                            radius: 13,
                            backgroundColor: Color(0xfff4f7f5),
                            foregroundColor: WafaColors.muted,
                            child: Text('×', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      const SizedBox(height: 12),
      _EvidenceMeter(count: files.length),
    ],
  );
}

class _EvidenceMeter extends StatelessWidget {
  const _EvidenceMeter({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    const fileLimit = DemoAgreementRepository.evidenceFileLimit;
    const sizeLimit = DemoAgreementRepository.evidenceSizeLimitMb;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$count of $fileLimit files',
                style: const TextStyle(
                  color: WafaColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(
                text: ' on this agreement · up to $sizeLimit MB each',
              ),
            ],
          ),
          style: const TextStyle(color: WafaColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: count / fileLimit,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
          color: WafaColors.green,
          backgroundColor: WafaColors.line,
        ),
      ],
    );
  }
}

class AddEvidenceScreen extends StatefulWidget {
  const AddEvidenceScreen({
    super.key,
    required this.repository,
    required this.connections,
    required this.agreementId,
    required this.onAdded,
  });

  final DemoAgreementRepository repository;
  final DemoConnectionsRepository connections;
  final String agreementId;
  final VoidCallback onAdded;

  @override
  State<AddEvidenceScreen> createState() => _AddEvidenceScreenState();
}

class _AddEvidenceScreenState extends State<AddEvidenceScreen> {
  EvidenceType? _type;

  void _chooseFile() {
    final person = widget.connections.currentPerson;
    if (person == null ||
        !widget.connections.canViewAgreement(widget.agreementId)) {
      return;
    }
    if (widget.repository.evidenceFor(widget.agreementId).length >=
        DemoAgreementRepository.evidenceFileLimit) {
      _showMessage('This agreement has 25 files, the most it can hold.');
      return;
    }
    final type = _type;
    if (type == null) {
      _showMessage('Choose what you are adding first.');
      return;
    }
    widget.repository.addEvidence(
      widget.agreementId,
      type: type,
      addedByPersonId: person.id,
    );
    setState(() {});
    widget.onAdded();
    _showMessage(
      'Demo: file added. In the real app you choose it from your phone.',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final agreement = widget.repository.findById(widget.agreementId);
    if (agreement == null ||
        !widget.connections.canViewAgreement(widget.agreementId)) {
      return Scaffold(appBar: AppBar(title: const Text('Add evidence')));
    }
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 66,
        titleSpacing: 0,
        leading: Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xfff4f7f5),
              foregroundColor: WafaColors.ink,
            ),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
        ),
        title: const Text(
          'Add evidence',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        children: [
          Text(
            '${agreement.title} · what are you adding?',
            style: const TextStyle(color: WafaColors.muted, fontSize: 15),
          ),
          const SizedBox(height: 16),
          for (final type in EvidenceType.values) ...[
            _typeRow(type),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: WafaColors.mint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "Everyone on this agreement can see it. Once everyone has "
              "signed, evidence can't be removed - it stays with the agreement.",
              style: TextStyle(
                color: WafaColors.green,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _EvidenceMeter(
            count: widget.repository.evidenceFor(widget.agreementId).length,
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: FilledButton(
              key: const ValueKey('choose-evidence-file'),
              onPressed: _chooseFile,
              child: const Text('Choose a file'),
            ),
          ),
          WafaNavigationBar(
            selectedIndex: 1,
            hideIndicator: true,
            onSelected: (index) => Navigator.of(context).pop(index),
          ),
        ],
      ),
    );
  }

  Widget _typeRow(EvidenceType type) {
    final selected = _type == type;
    final radius = BorderRadius.circular(16);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? WafaColors.mint : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? WafaColors.green : WafaColors.line,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: () => setState(() => _type = type),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : WafaColors.mint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _evidenceIcon(type),
                    size: 20,
                    color: WafaColors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    type.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_outline_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? WafaColors.green : WafaColors.line,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
