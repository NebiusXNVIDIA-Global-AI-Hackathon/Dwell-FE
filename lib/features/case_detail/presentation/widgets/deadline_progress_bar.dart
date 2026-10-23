import 'package:material_ui/material_ui.dart';

import '../../../../core/theme.dart';
import '../../models/status_banner.dart';
import '../case_detail_tokens.dart';

/// Response deadline track with the time left beside it.
class DeadlineProgressBar extends StatelessWidget {
  const DeadlineProgressBar({super.key, required this.deadline});

  final DeadlineProgress deadline;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(CaseDetailSizes.deadlineHeight),
            child: SizedBox(
              height: CaseDetailSizes.deadlineHeight,
              child: ColoredBox(
                color: CaseDetailColors.deadlineTrack,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: deadline.elapsed.clamp(0, 1),
                  child: const ColoredBox(color: CaseDetailColors.notice),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: Gap.card),
        Text(deadline.label, maxLines: 1, style: CaseDetailText.deadline),
      ],
    );
  }
}
