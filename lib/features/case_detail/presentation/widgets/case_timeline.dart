import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme.dart';
import '../../models/timeline_step.dart';
import '../case_detail_format.dart';
import '../case_detail_tokens.dart';

/// Horizontal stepper with fixed node spacing; the track fades out to the end.
class CaseTimeline extends StatelessWidget {
  const CaseTimeline({
    super.key,
    required this.steps,
    this.hasEarlierSteps = false,
    this.bleedStart = 0,
    this.bleedEnd = 0,
  });

  final List<TimelineStepData> steps;
  final bool hasEarlierSteps;
  final double bleedStart;
  final double bleedEnd;

  static const _center =
      CaseDetailSizes.timelineStart + CaseDetailSizes.timelineNode / 2;
  static const _lineTop =
      (CaseDetailSizes.timelineNode - CaseDetailSizes.timelineLine) / 2;

  static double _centerOf(int index) =>
      _center + CaseDetailSizes.timelineSpacing * index;

  static TextStyle _labelStyle(TimelineStepState state) => switch (state) {
    TimelineStepState.completed => CaseDetailText.timelineLabel.copyWith(
      color: CaseDetailColors.navy,
    ),
    TimelineStepState.current => CaseDetailText.timelineLabel.copyWith(
      color: CaseDetailColors.navy,
      fontWeight: FontWeight.w700,
    ),
    TimelineStepState.alert => CaseDetailText.timelineLabel.copyWith(
      color: CaseDetailColors.highText,
      fontWeight: FontWeight.w700,
    ),
    TimelineStepState.upcoming => CaseDetailText.timelineLabel.copyWith(
      color: CaseDetailColors.upcomingLabel,
    ),
    TimelineStepState.preview => CaseDetailText.timelineLabel.copyWith(
      color: CaseDetailColors.previewLabel,
    ),
  };

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
    final reached = steps.lastIndexWhere((step) => step.isReached);
    final lineStart = hasEarlierSteps ? -bleedStart : _center;
    final endsInAlert =
        reached > 0 && steps[reached].state == TimelineStepState.alert;
    final navyEnd = _centerOf(endsInAlert ? reached - 1 : reached);

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
                left: lineStart,
                right: -bleedEnd,
                top: _lineTop,
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
              if (navyEnd > lineStart)
                Positioned(
                  left: lineStart,
                  width: navyEnd - lineStart,
                  top: _lineTop,
                  height: CaseDetailSizes.timelineLine,
                  child: const ColoredBox(color: CaseDetailColors.navy),
                ),
              // The segment into an alert turns red
              if (endsInAlert)
                Positioned(
                  left: navyEnd,
                  width: CaseDetailSizes.timelineSpacing,
                  top: _lineTop,
                  height: CaseDetailSizes.timelineLine,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          CaseDetailColors.navy,
                          CaseDetailColors.navy,
                          CaseDetailColors.highText,
                        ],
                        stops: [0, CaseDetailSizes.timelineAlertStop, 1],
                      ),
                    ),
                  ),
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
              style: _labelStyle(step.state),
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
        TimelineStepState.upcoming ||
        TimelineStepState.preview => BoxDecoration(
          color: CaseDetailColors.background,
          shape: BoxShape.circle,
          border: Border.all(
            color: state == TimelineStepState.preview
                ? CaseDetailColors.previewBorder
                : CaseDetailColors.track,
            width: CaseDetailSizes.timelineBorder,
          ),
        ),
        TimelineStepState.alert => const BoxDecoration(
          color: CaseDetailColors.highText,
          shape: BoxShape.circle,
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
        TimelineStepState.alert => const Text(
          '!',
          textAlign: TextAlign.center,
          style: CaseDetailText.alertMark,
        ),
        TimelineStepState.upcoming || TimelineStepState.preview => null,
      },
    );
  }
}
