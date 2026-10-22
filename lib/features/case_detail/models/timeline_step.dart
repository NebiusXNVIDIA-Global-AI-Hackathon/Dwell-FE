enum TimelineStepState { completed, current, upcoming }

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
}
