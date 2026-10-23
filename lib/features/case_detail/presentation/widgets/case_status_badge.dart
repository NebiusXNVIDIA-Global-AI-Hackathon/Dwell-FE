import 'package:material_ui/material_ui.dart';

import '../../../cases/models/case_model.dart';
import '../../../home/data/home_severity_colors.dart';
import '../../models/case_stage.dart';
import '../case_detail_format.dart';
import '../case_detail_tokens.dart';

class CaseStatusBadge extends StatelessWidget {
  const CaseStatusBadge({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  factory CaseStatusBadge.stage(CaseStageBadge badge) => CaseStatusBadge(
    label: CaseDetailFormat.stageBadge(badge),
    background: badge == CaseStageBadge.inProgress
        ? CaseDetailColors.inProgressSoft
        : CaseDetailColors.divider,
    foreground: badge == CaseStageBadge.inProgress
        ? CaseDetailColors.inProgressText
        : CaseDetailColors.body,
  );

  // High follows Figma; Medium and Low reuse the Home severity palette
  factory CaseStatusBadge.priority(CaseSeverity severity) => CaseStatusBadge(
    label: CaseDetailFormat.priority(severity),
    background: severity == CaseSeverity.high
        ? CaseDetailColors.highSoft
        : homeSeverityColor(severity),
    foreground: switch (severity) {
      CaseSeverity.high => CaseDetailColors.highText,
      CaseSeverity.medium => CaseDetailColors.warningText,
      CaseSeverity.low => CaseDetailColors.body,
    },
  );

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: CaseDetailSizes.badgeHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: CaseDetailSizes.badgePadding,
      ),
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: background,
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: CaseDetailText.badge.copyWith(color: foreground),
      ),
    );
  }
}
