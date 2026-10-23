import 'status_banner.dart';
import 'timeline_step.dart';

/// Everything on Case Detail that changes with the case stage.
class CaseStageContent {
  const CaseStageContent({
    required this.banner,
    required this.timeline,
    required this.checklist,
    this.timelineHasEarlierSteps = false,
  });

  final StatusBanner banner;
  final List<TimelineStepData> timeline;
  final List<String> checklist;
  final bool timelineHasEarlierSteps;
}
