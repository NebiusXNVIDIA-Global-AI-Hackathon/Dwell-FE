import 'package:material_ui/material_ui.dart';

import '../case_detail_tokens.dart';

/// Shared checklist card shell with the left accent bar.
class ChecklistCardFrame extends StatelessWidget {
  const ChecklistCardFrame({
    super.key,
    required this.child,
    this.color = CaseDetailColors.surface,
    this.onTap,
  });

  final Widget child;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(CaseDetailSizes.checklistRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: CaseDetailColors.cardShadow,
            offset: CaseDetailSizes.shadowOffset,
            blurRadius: CaseDetailSizes.shadowBlur,
          ),
        ],
      ),
      child: Material(
        color: color,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: CaseDetailSizes.checklistHeight,
            child: Row(
              children: [
                const SizedBox(
                  width: CaseDetailSizes.checklistAccent,
                  height: double.infinity,
                  child: ColoredBox(color: CaseDetailColors.accent),
                ),
                const SizedBox(width: CaseDetailSizes.checklistTextStart),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
