import 'package:flutter/material.dart';
import '../domain/demo_models.dart';

abstract final class WafaColors {
  static const green = Color(0xff123f32);
  static const ink = Color(0xff182d25);
  static const muted = Color(0xff68776f);
  static const mint = Color(0xffedf5ef);
  static const line = Color(0xffe3eae5);
}

final wafaTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: Colors.white,
  colorScheme: ColorScheme.fromSeed(
    seedColor: WafaColors.green,
    primary: WafaColors.green,
    surface: Colors.white,
  ),
  textTheme: Typography.blackMountainView.apply(
    bodyColor: WafaColors.ink,
    displayColor: WafaColors.ink,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: WafaColors.ink,
    surfaceTintColor: Colors.transparent,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: WafaColors.ink,
    ),
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    indicatorColor: WafaColors.mint,
    height: 72,
    labelTextStyle: WidgetStatePropertyAll(
      TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: WafaColors.green,
      minimumSize: const Size(44, 44),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xfff7f9f7),
    contentPadding: const EdgeInsets.all(18),
    hintStyle: const TextStyle(color: WafaColors.muted, fontSize: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: WafaColors.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: WafaColors.line),
    ),
  ),
  chipTheme: ChipThemeData(
    side: const BorderSide(color: WafaColors.line),
    selectedColor: WafaColors.mint,
    backgroundColor: Colors.white,
    showCheckmark: false,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    labelStyle: const TextStyle(fontSize: 12, color: WafaColors.green),
  ),
  dividerTheme: const DividerThemeData(color: WafaColors.line, thickness: 1),
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: WafaColors.green,
    behavior: SnackBarBehavior.floating,
  ),
);

String money(int pence) {
  final whole = (pence ~/ 100).toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]},',
  );
  return '£$whole${pence % 100 == 0 ? '' : '.${(pence % 100).toString().padLeft(2, '0')}'}';
}

int? parsePence(String value) {
  if (!RegExp(r'^\d{1,7}(\.\d{1,2})?$').hasMatch(value.trim())) return null;
  final parts = value.trim().split('.');
  return int.parse(parts[0]) * 100 +
      (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
}

String dateLabel(DateTime date) =>
    '${date.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1]} ${date.year}';

String kindLabel(ContractKind kind) => switch (kind) {
  ContractKind.interestFreeLoan => 'Interest-free loan',
  ContractKind.sale => 'Sale agreement',
  ContractKind.rental => 'Rental agreement',
  ContractKind.service => 'Service agreement',
};
String kindDescription(ContractKind kind) => switch (kind) {
  ContractKind.interestFreeLoan =>
    'Qard Hasan · Record what is lent and repaid',
  ContractKind.sale => 'Make the item, price and handover clear',
  ContractKind.rental => 'Outline the use, dates and agreed amount',
  ContractKind.service => 'Set out the work, timing and agreed value',
};
IconData kindIcon(ContractKind kind) => switch (kind) {
  ContractKind.interestFreeLoan => Icons.handshake_outlined,
  ContractKind.sale => Icons.shopping_bag_outlined,
  ContractKind.rental => Icons.key_outlined,
  ContractKind.service => Icons.work_outline_rounded,
};

class BrandMark extends StatelessWidget {
  const BrandMark({super.key});
  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.spa_outlined, color: WafaColors.green, size: 29),
      SizedBox(width: 8),
      Text(
        'wafa',
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.5,
          color: WafaColors.green,
        ),
      ),
    ],
  );
}

class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: WafaColors.mint,
      borderRadius: BorderRadius.circular(7),
    ),
    child: const Text(
      'PREVIEW',
      style: TextStyle(
        color: WafaColors.green,
        fontSize: 9,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 10,
      letterSpacing: 1.4,
      color: WafaColors.muted,
      fontWeight: FontWeight.w600,
    ),
  );
}

class Surface extends StatelessWidget {
  const Surface({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: WafaColors.line),
    ),
    child: child,
  );
}

class SmallMetric extends StatelessWidget {
  const SmallMetric({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: WafaColors.green, size: 21),
        const SizedBox(height: 14),
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: WafaColors.green,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            height: 1.4,
            color: WafaColors.muted,
          ),
        ),
      ],
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading(
    this.title, {
    super.key,
    required this.subtitle,
    this.trailing,
  });
  final String title, subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -.8,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
      const SizedBox(height: 10),
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
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -.4,
          ),
        ),
      ),
      if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
    ],
  );
}

class SoftNote extends StatelessWidget {
  const SoftNote({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title, body;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: WafaColors.mint,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: WafaColors.green),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: WafaColors.green,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: WafaColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final AgreementStatus status;
  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      AgreementStatus.draft => 'Draft',
      AgreementStatus.awaitingSignatures => 'Awaiting signatures',
      AgreementStatus.active => 'Active',
      AgreementStatus.completed => 'Completed',
      AgreementStatus.overdue => 'Overdue',
    };
    final warning = status == AgreementStatus.overdue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: warning ? const Color(0xfffcf2e8) : WafaColors.mint,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: warning ? const Color(0xff9b541d) : WafaColors.green,
        ),
      ),
    );
  }
}

class KindMark extends StatelessWidget {
  const KindMark(this.kind, {super.key});
  final ContractKind kind;
  @override
  Widget build(BuildContext context) => Container(
    width: 46,
    height: 46,
    decoration: BoxDecoration(
      color: WafaColors.mint,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(kindIcon(kind), color: WafaColors.green, size: 22),
  );
}

class AgreementTile extends StatelessWidget {
  const AgreementTile({
    super.key,
    required this.agreement,
    required this.onTap,
  });
  final Agreement agreement;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: WafaColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KindMark(agreement.kind),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agreement.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      agreement.counterparty,
                      style: const TextStyle(
                        fontSize: 12,
                        color: WafaColors.muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusBadge(agreement.status),
                        Text(
                          dateLabel(agreement.dueDate),
                          style: const TextStyle(
                            fontSize: 10,
                            color: WafaColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                money(agreement.amountPence),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: WafaColors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Text(
      label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
  );
}

class DetailRow extends StatelessWidget {
  const DetailRow(this.label, this.value, {super.key});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: WafaColors.muted),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
