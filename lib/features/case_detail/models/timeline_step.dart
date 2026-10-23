enum TimelineStepState { completed, current, alert, upcoming, preview }

class TimelineStepData {
  const TimelineStepData({
    required this.label,
    required this.state,
    this.eventTitle,
    this.description,
    this.occurredAt,
  });

  final String label;
  final TimelineStepState state;
  final String? eventTitle;
  final String? description;
  final DateTime? occurredAt;

  bool get isReached =>
      state == TimelineStepState.completed ||
      state == TimelineStepState.current ||
      state == TimelineStepState.alert;
}
