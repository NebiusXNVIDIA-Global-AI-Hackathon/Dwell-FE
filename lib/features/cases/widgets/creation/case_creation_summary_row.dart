import 'package:material_ui/material_ui.dart';

class CaseCreationSummaryRow extends StatelessWidget {
  const CaseCreationSummaryRow({
    super.key,
    required this.stepNumber,
    required this.value,
    required this.onEdit,
  });

  final int stepNumber;
  final String value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    // Preserve the 32px badge at normal scale; enlarge for accessibility.
    final badgeSize =
        32.0 *
        (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(
          1.0,
          double.infinity,
        );
    return Row(
      children: [
        Container(
          width: badgeSize,
          height: badgeSize,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFF243B53),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$stepNumber',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF243B53),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onEdit,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF007AFF),
            minimumSize: const Size(0, 32),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('Edit'),
        ),
      ],
    );
  }
}
