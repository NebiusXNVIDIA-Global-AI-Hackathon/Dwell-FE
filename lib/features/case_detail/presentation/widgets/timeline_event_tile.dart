import 'package:material_ui/material_ui.dart';

import '../../../../core/theme.dart';
import '../../models/timeline_step.dart';
import '../case_detail_format.dart';
import '../case_detail_tokens.dart';

/// One row of the vertical timeline on the Case Timeline screen.
class TimelineEventTile extends StatelessWidget {
  const TimelineEventTile({
    super.key,
    required this.step,
    required this.isFirst,
    required this.isLast,
  });

  final TimelineStepData step;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    const line = SizedBox(
      width: CaseDetailSizes.timelineLine,
      child: ColoredBox(color: CaseDetailColors.eventLine),
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: CaseDetailSizes.eventDot,
            child: Column(
              children: [
                SizedBox(
                  height: CaseDetailSizes.eventDotTop,
                  child: isFirst ? null : line,
                ),
                _EventDot(state: step.state),
                Expanded(child: isLast ? const SizedBox.shrink() : line),
              ],
            ),
          ),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : CaseDetailSizes.eventGap,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Gap.xs,
                children: [
                  if (step.occurredAt case final date?)
                    Text(
                      CaseDetailFormat.eventTime(date),
                      style: CaseDetailText.eventDate,
                    ),
                  Text(
                    step.eventTitle ?? step.label.replaceAll('\n', ' '),
                    style: CaseDetailText.eventTitle,
                  ),
                  if (step.description case final description?)
                    Text(description, style: CaseDetailText.eventBody),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventDot extends StatelessWidget {
  const _EventDot({required this.state});

  final TimelineStepState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: CaseDetailSizes.eventDot,
      height: CaseDetailSizes.eventDot,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: state == TimelineStepState.alert
            ? CaseDetailColors.highText
            : CaseDetailColors.accent,
        shape: BoxShape.circle,
      ),
      child: state == TimelineStepState.current
          ? Container(
              width: CaseDetailSizes.eventInnerDot,
              height: CaseDetailSizes.eventInnerDot,
              decoration: const BoxDecoration(
                color: CaseDetailColors.surface,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}
