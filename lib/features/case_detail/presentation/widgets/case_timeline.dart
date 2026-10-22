import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme.dart';
import '../../models/timeline_step.dart';
import '../case_detail_format.dart';
import '../case_detail_tokens.dart';

/// Horizontal stepper with fixed node spacing; the track fades out to the end.
class CaseTimeline extends StatelessWidget {
  const CaseTimeline({super.key, required this.steps, this.bleedEnd = 0});

  final List<TimelineStepData> steps;
  final double bleedEnd;

  static const _center =
      CaseDetailSizes.timelineStart + CaseDetailSizes.timelineNode / 2;

  // Center each text on its node; a hidden sample keeps the row height
  Widget _textRow(
    List<Widget> children, {
    required String sample,
    TextStyle? style,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ExcludeSemantics(
          child: Opacity(opacity: 0, child: Text(sample, style: style)),
        ),
        for (final (index, child) in children.indexed)
          Positioned(
            left:
                _center +
                CaseDetailSizes.timelineSpacing * index -
                CaseDetailSizes.timelineLabelWidth / 2,
            width: CaseDetailSizes.timelineLabelWidth,
            top: 0,
            child: child,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final reached = steps.lastIndexWhere(
      (step) => step.state != TimelineStepState.upcoming,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _textRow(sample: ' ', style: CaseDetailText.timelineDate, [
          for (final step in steps)
            Text(
              step.occurredAt == null
                  ? ''
                  : CaseDetailFormat.stepDate(step.occurredAt!),
              maxLines: 1,
              textAlign: TextAlign.center,
              style: CaseDetailText.timelineDate,
            ),
        ]),
        const SizedBox(height: Gap.sm),
        SizedBox(
          height: CaseDetailSizes.timelineNode,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Track runs past the page inset and fades into the background
              Positioned(
                left: _center,
                right: -bleedEnd,
                top:
                    (CaseDetailSizes.timelineNode -
                        CaseDetailSizes.timelineLine) /
                    2,
                height: CaseDetailSizes.timelineLine,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        CaseDetailColors.track,
                        CaseDetailColors.track,
                        CaseDetailColors.background,
                      ],
                      stops: [0, CaseDetailSizes.timelineFadeStop, 1],
                    ),
                  ),
                ),
              ),
              if (reached > 0)
                Positioned(
                  left: _center,
                  width: CaseDetailSizes.timelineSpacing * reached,
                  top:
                      (CaseDetailSizes.timelineNode -
                          CaseDetailSizes.timelineLine) /
                      2,
                  height: CaseDetailSizes.timelineLine,
                  child: const ColoredBox(color: CaseDetailColors.navy),
                ),
              for (final (index, step) in steps.indexed)
                Positioned(
                  left:
                      CaseDetailSizes.timelineStart +
                      CaseDetailSizes.timelineSpacing * index,
                  top: 0,
                  child: TimelineStep(state: step.state),
                ),
            ],
          ),
        ),
        const SizedBox(height: Gap.sm),
        _textRow(sample: '\n', style: CaseDetailText.timelineLabel, [
          for (final step in steps)
            Text(
              step.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: CaseDetailText.timelineLabel.copyWith(
                color: step.state == TimelineStepState.upcoming
                    ? CaseDetailColors.upcomingLabel
                    : CaseDetailColors.navy,
              ),
            ),
        ]),
      ],
    );
  }
}

class TimelineStep extends StatelessWidget {
  const TimelineStep({super.key, required this.state});

  final TimelineStepState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: CaseDetailSizes.timelineNode,
      height: CaseDetailSizes.timelineNode,
      alignment: Alignment.center,
      decoration: switch (state) {
        TimelineStepState.upcoming => BoxDecoration(
          color: CaseDetailColors.background,
          shape: BoxShape.circle,
          border: Border.all(
            color: CaseDetailColors.track,
            width: CaseDetailSizes.timelineBorder,
          ),
        ),
        _ => const BoxDecoration(
          color: CaseDetailColors.navy,
          shape: BoxShape.circle,
        ),
      },
      child: switch (state) {
        TimelineStepState.completed => const Icon(
          LucideIcons.check,
          size: CaseDetailSizes.timelineCheck,
          color: CaseDetailColors.surface,
        ),
        TimelineStepState.current => Container(
          width: CaseDetailSizes.timelineInnerDot,
          height: CaseDetailSizes.timelineInnerDot,
          decoration: const BoxDecoration(
            color: CaseDetailColors.surface,
            shape: BoxShape.circle,
          ),
        ),
        TimelineStepState.upcoming => null,
      },
    );
  }
}
